import 'package:flutter/material.dart';
import '../../../core/constants/app_categories.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../models/cart_item.dart';
import '../../../models/product_item.dart';
import '../../../shared/widgets/custom_search_bar.dart';

class EtalaseAllScreen extends StatefulWidget {
  final List<ProductItem> products;
  final List<CartItem> cart;
  final Function(ProductItem) onAddToCart;
  final Function(ProductItem) onDecrementCart;
  final VoidCallback onOpenCart;
  final VoidCallback onOpenPayment;

  const EtalaseAllScreen({
    super.key,
    required this.products,
    required this.cart,
    required this.onAddToCart,
    required this.onDecrementCart,
    required this.onOpenCart,
    required this.onOpenPayment,
  });

  @override
  State<EtalaseAllScreen> createState() => _EtalaseAllScreenState();
}

class _EtalaseAllScreenState extends State<EtalaseAllScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'Semua';
  String _selectedPenitip = 'Semua';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<String> get _penitipList {
    final list = widget.products
        .map((p) => p.penitipName.trim())
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList();
    list.sort();
    return ['Semua', ...list];
  }

  List<ProductItem> get _filteredProducts {
    final query = _searchController.text.toLowerCase().trim();
    return widget.products.where((p) {
      final matchesSearch = query.isEmpty ||
          p.name.toLowerCase().contains(query) ||
          p.penitipName.toLowerCase().contains(query) ||
          p.category.toLowerCase().contains(query) ||
          (p.barcode != null && p.barcode!.toLowerCase().contains(query));

      if (query.isNotEmpty) {
        return matchesSearch;
      }

      final matchesCategory = _selectedCategory == 'Semua' ||
          p.category.toLowerCase() == _selectedCategory.toLowerCase();

      final matchesPenitip = _selectedPenitip == 'Semua' ||
          p.penitipName.toLowerCase() == _selectedPenitip.toLowerCase();

      return matchesCategory && matchesPenitip;
    }).toList();
  }

  int _getItemQuantity(String productId) {
    final index = widget.cart.indexWhere((c) => c.id == productId);
    return index != -1 ? widget.cart[index].quantity : 0;
  }

  int get _totalCartItems =>
      widget.cart.fold(0, (sum, item) => sum + item.quantity);

  int get _totalCartAmount =>
      widget.cart.fold(0, (sum, item) => sum + item.totalPrice);

  @override
  Widget build(BuildContext context) {
    final displayedProducts = _filteredProducts;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Semua Produk Etalase',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              '${widget.products.length} Makanan & Titipan Siap Jual',
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.divider, height: 1),
        ),
      ),
      body: Column(
        children: [
          // Filter & Search Header
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search Bar
                CustomSearchBar(
                  controller: _searchController,
                  hintText: 'Cari makanan, snack, minuman, atau penitip...',
                  onChanged: (val) => setState(() {}),
                ),
                const SizedBox(height: 10),

                // Category Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: AppCategories.filterList.map((category) {
                      final isSelected = _selectedCategory == category;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                AppCategories.getIcon(category == 'Semua' ? null : category),
                                size: 13,
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.textSecondary,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                category,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? Colors.white
                                      : AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          selected: isSelected,
                          selectedColor: AppColors.primary,
                          backgroundColor: AppColors.background,
                          side: BorderSide(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.border,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _selectedCategory = category);
                            }
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),

                // Penitip Filter Chips if multiple
                if (_penitipList.length > 2) ...[
                  const SizedBox(height: 6),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: _penitipList.map((penitip) {
                        final isSelected = _selectedPenitip == penitip;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(
                              penitip == 'Semua' ? 'Semua Mitra' : 'Mitra: $penitip',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.textSecondary,
                              ),
                            ),
                            selected: isSelected,
                            selectedColor: AppColors.primaryDark,
                            backgroundColor: AppColors.background,
                            side: BorderSide(
                              color: isSelected
                                  ? AppColors.primaryDark
                                  : AppColors.border,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            onSelected: (selected) {
                              setState(() => _selectedPenitip = selected ? penitip : 'Semua');
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Main Product Grid
          Expanded(
            child: displayedProducts.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.search_off_rounded,
                            size: 56,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Produk tidak ditemukan',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Coba ubah kata kunci pencarian atau reset filter kategori',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton(
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                                _selectedCategory = 'Semua';
                                _selectedPenitip = 'Semua';
                              });
                            },
                            child: const Text('Reset Filter'),
                          ),
                        ],
                      ),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                    physics: const BouncingScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: 0.72,
                    ),
                    itemCount: displayedProducts.length,
                    itemBuilder: (context, index) {
                      final product = displayedProducts[index];
                      final qtyInCart = _getItemQuantity(product.id);

                      return _buildEtalaseItemCard(product, qtyInCart);
                    },
                  ),
          ),
        ],
      ),

      // Bottom Sticky Cart & Checkout Bar
      bottomSheet: _totalCartItems > 0
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: const Border(
                  top: BorderSide(color: AppColors.divider, width: 1.2),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    // Cart Quantity & Total Amount
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '$_totalCartItems item',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Total Belanja:',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            CurrencyFormatter.format(_totalCartAmount),
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Actions: Lihat Keranjang / Bayar
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary, width: 1.2),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        widget.onOpenCart();
                      },
                      child: const Row(
                        children: [
                          Icon(Icons.shopping_cart_outlined, size: 16),
                          SizedBox(width: 4),
                          Text(
                            'Keranjang',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: AppStyles.primaryButtonStyle(
                        radius: 10,
                        height: 44,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        widget.onOpenPayment();
                      },
                      child: const Text('Bayar'),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildEtalaseItemCard(ProductItem product, int qtyInCart) {
    return Container(
      decoration: AppStyles.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image + Penitip Badge
          Expanded(
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(15),
                  ),
                  child: Image.network(
                    product.imageUrl,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: AppColors.primaryLight,
                      child: const Center(
                        child: Icon(
                          Icons.fastfood_rounded,
                          color: AppColors.primary,
                          size: 36,
                        ),
                      ),
                    ),
                  ),
                ),
                // Penitip Badge
                Positioned(
                  top: 6,
                  left: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.storefront_rounded,
                          color: Colors.amber,
                          size: 10,
                        ),
                        const SizedBox(width: 3),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 80),
                          child: Text(
                            product.penitipName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Stok Badge
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Sisa: ${product.stock}',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: product.stock <= 5
                            ? AppColors.danger
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Body Info
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  CurrencyFormatter.format(product.price),
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),

                // Cart Button or Increment/Decrement Controls
                if (qtyInCart > 0)
                  Container(
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.primary),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        InkWell(
                          onTap: () {
                            widget.onDecrementCart(product);
                            setState(() {});
                          },
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Icon(
                              Icons.remove_rounded,
                              size: 16,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        Text(
                          '$qtyInCart',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            widget.onAddToCart(product);
                            setState(() {});
                          },
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Icon(
                              Icons.add_rounded,
                              size: 16,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    height: 32,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        widget.onAddToCart(product);
                        setState(() {});
                      },
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_shopping_cart_rounded, size: 14),
                          SizedBox(width: 4),
                          Text(
                            '+ Tambah',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
