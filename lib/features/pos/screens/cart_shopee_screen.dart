import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../../models/cart_item.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import 'payment_screen.dart';

import '../../../core/utils/currency_formatter.dart';

class CartShopeeScreen extends StatefulWidget {
  final List<CartItem> cartItems;
  final Function(List<CartItem>)? onCartUpdated;

  const CartShopeeScreen({
    super.key,
    required this.cartItems,
    this.onCartUpdated,
  });

  @override
  State<CartShopeeScreen> createState() => _CartShopeeScreenState();
}

class _CartShopeeScreenState extends State<CartShopeeScreen> {
  late List<CartItem> _items;
  final Set<String> _selectedItemIds = {};

  @override
  void initState() {
    super.initState();
    _items = widget.cartItems;
    // Default select all items like Shopee
    for (var item in _items) {
      _selectedItemIds.add(item.id);
    }
  }

  String _formatCurrency(int amount) {
    return CurrencyFormatter.format(amount);
  }

  bool get _isAllSelected =>
      _items.isNotEmpty && _selectedItemIds.length == _items.length;

  List<CartItem> get _selectedItems =>
      _items.where((item) => _selectedItemIds.contains(item.id)).toList();

  int get _selectedTotalAmount => _selectedItems.fold(
        0,
        (sum, item) => sum + item.totalPrice,
      );

  int get _selectedTotalQuantity => _selectedItems.fold(
        0,
        (sum, item) => sum + item.quantity,
      );

  void _toggleSelectAll(bool? value) {
    setState(() {
      if (value == true) {
        for (var item in _items) {
          _selectedItemIds.add(item.id);
        }
      } else {
        _selectedItemIds.clear();
      }
    });
  }

  void _toggleSelectItem(String id) {
    setState(() {
      if (_selectedItemIds.contains(id)) {
        _selectedItemIds.remove(id);
      } else {
        _selectedItemIds.add(id);
      }
    });
  }

  void _incrementQuantity(CartItem item) {
    setState(() {
      item.quantity += 1;
    });
    widget.onCartUpdated?.call(_items);
  }

  void _decrementQuantity(int index, CartItem item) {
    setState(() {
      if (item.quantity > 1) {
        item.quantity -= 1;
      } else {
        _selectedItemIds.remove(item.id);
        _items.removeAt(index);
      }
    });
    widget.onCartUpdated?.call(_items);
  }

  void _removeItem(int index, CartItem item) {
    setState(() {
      _selectedItemIds.remove(item.id);
      _items.removeAt(index);
    });
    widget.onCartUpdated?.call(_items);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.textPrimary,
        behavior: SnackBarBehavior.floating,
        content: Text('${item.name} dihapus dari keranjang.'),
        duration: const Duration(milliseconds: 1200),
      ),
    );
  }

  void _proceedToCheckout() {
    if (_selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih minimal 1 item untuk checkout.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentScreen(
          totalAmount: _selectedTotalAmount,
          cartItems: List.from(_selectedItems),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(
        title: 'Keranjang Kasir',
      ),
      body: Column(
        children: [
          // Shopee Style Cart Top Header (Store Name & Total Items)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(
                bottom: BorderSide(color: AppColors.divider, width: 1),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.storefront_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Etalase TitipKasir',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_items.length} Macam',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Items List
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              backgroundColor: Colors.white,
              onRefresh: () async {
                await Future.delayed(const Duration(milliseconds: 500));
                if (!mounted) return;
                setState(() {});
              },
              child: _items.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: const BoxDecoration(
                            color: AppColors.surfaceMuted,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.remove_shopping_cart_rounded,
                            size: 40,
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Keranjang Kasir Kosong',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Pindai barcode atau pilih makanan di menu Kasir',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(12),
                    itemCount: _items.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      final isSelected = _selectedItemIds.contains(item.id);

                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius:
                              BorderRadius.circular(AppStyles.radiusCard),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.border,
                            width: isSelected ? 1.4 : 1.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // 1. Shopee Checkbox
                            SizedBox(
                              width: 28,
                              height: 28,
                              child: Checkbox(
                                value: isSelected,
                                activeColor: AppColors.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                onChanged: (val) => _toggleSelectItem(item.id),
                              ),
                            ),
                            const SizedBox(width: 6),

                            // 2. Product Thumbnail
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: SizedBox(
                                width: 64,
                                height: 64,
                                child: Image.network(
                                  item.imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: AppColors.primaryLight,
                                      child: const Icon(
                                        Icons.fastfood_rounded,
                                        color: AppColors.primary,
                                        size: 28,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // 3. Product Info & Stepper Row
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                      ),
                                      InkWell(
                                        onTap: () =>
                                            _removeItem(index, item),
                                        child: const Icon(
                                          Icons.delete_outline_rounded,
                                          color: AppColors.textMuted,
                                          size: 19,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (item.penitipName != null &&
                                      item.penitipName!.isNotEmpty) ...[
                                    const SizedBox(height: 3),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryLight,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.storefront_rounded,
                                            size: 11,
                                            color: AppColors.primary,
                                          ),
                                          const SizedBox(width: 3),
                                          Text(
                                            'Penitip: ${item.penitipName}',
                                            style: const TextStyle(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 4),

                                  // Price tag
                                  Text(
                                    _formatCurrency(item.price),
                                    style: const TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 8),

                                  // Shopee Style Quantity Stepper `[-] [qty] [+]`
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Subtotal: ${_formatCurrency(item.totalPrice)}',
                                        style: const TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      Container(
                                        decoration: BoxDecoration(
                                          color: AppColors.surfaceMuted,
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          border: Border.all(
                                            color: AppColors.border,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            InkWell(
                                              onTap: () =>
                                                  _decrementQuantity(index, item),
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 4,
                                                ),
                                                child: const Icon(
                                                  Icons.remove,
                                                  size: 14,
                                                  color: AppColors.textPrimary,
                                                ),
                                              ),
                                            ),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 10,
                                                vertical: 4,
                                              ),
                                              color: AppColors.surface,
                                              child: Text(
                                                '${item.quantity}',
                                                style: const TextStyle(
                                                  fontSize: 12.5,
                                                  fontWeight: FontWeight.w700,
                                                  color: AppColors.textPrimary,
                                                ),
                                              ),
                                            ),
                                            InkWell(
                                              onTap: () =>
                                                  _incrementQuantity(item),
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 4,
                                                ),
                                                child: const Icon(
                                                  Icons.add,
                                                  size: 14,
                                                  color: AppColors.primary,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
            ),
          ),

          // Shopee-Style Sticky Bottom Checkout Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: const Border(
                top: BorderSide(color: AppColors.divider, width: 1.2),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  // Select All Checkbox
                  Row(
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: _isAllSelected,
                          activeColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          onChanged: _toggleSelectAll,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Semua',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),

                  // Total Text
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Total:',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          _formatCurrency(_selectedTotalAmount),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                            letterSpacing: -0.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Checkout Button (Shopee Style)
                  SizedBox(
                    height: 44,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: _selectedItems.isEmpty
                          ? null
                          : _proceedToCheckout,
                      child: Text(
                        'Bayar ($_selectedTotalQuantity)',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
