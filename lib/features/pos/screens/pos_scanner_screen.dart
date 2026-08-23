import 'package:flutter/material.dart';
import '../../../core/constants/app_categories.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../../core/services/penitip_service.dart';
import '../../../core/services/product_service.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../models/cart_item.dart';
import '../../../models/product_item.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import '../../../shared/widgets/custom_search_bar.dart';
import '../../penitip/widgets/add_penitip_modal.dart';
import '../widgets/barcode_scanner_viewfinder.dart';
import 'cart_shopee_screen.dart';
import 'etalase_all_screen.dart';
import 'payment_screen.dart';

class PosScannerScreen extends StatefulWidget {
  const PosScannerScreen({super.key});

  @override
  State<PosScannerScreen> createState() => _PosScannerScreenState();
}

class _PosScannerScreenState extends State<PosScannerScreen> {
  final TextEditingController _searchController = TextEditingController();

  // Cart
  final List<CartItem> _cart = [];

  // Produk & penitip dari Supabase
  List<ProductItem> _availableProducts = [];
  List<String> _penitipList = ['Semua'];
  String _selectedPenitip = 'Semua';
  String _selectedCategory = 'Semua';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final products = await ProductService.fetchAll();
      final penitips = await PenitipService.fetchAll();
      if (!mounted) return;
      final penitipNames = penitips.map((p) => p.name).toList();
      setState(() {
        _availableProducts = products.where((p) => p.stock > 0).toList();
        _penitipList = ['Semua', ...penitipNames];
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  List<ProductItem> get _filteredProducts {
    final query = _searchController.text.trim().toLowerCase();
    return _availableProducts.where((prod) {
      final matchesQuery = query.isEmpty ||
          prod.name.toLowerCase().contains(query) ||
          prod.penitipName.toLowerCase().contains(query) ||
          prod.category.toLowerCase().contains(query) ||
          (prod.barcode != null &&
              prod.barcode!.toLowerCase().contains(query)) ||
          prod.id.toLowerCase().contains(query);

      // Jika user sedang mengetik pencarian, cari di semua penitip & kategori
      if (query.isNotEmpty) {
        return matchesQuery;
      }

      final matchesPenitip = _selectedPenitip == 'Semua' ||
          prod.penitipName.toLowerCase() == _selectedPenitip.toLowerCase();
      final matchesCategory = _selectedCategory == 'Semua' ||
          prod.category.toLowerCase() == _selectedCategory.toLowerCase();
      return matchesPenitip && matchesCategory;
    }).toList();
  }

  int get _totalItems => _cart.fold(0, (sum, item) => sum + item.quantity);
  int get _totalAmount => _cart.fold(0, (sum, item) => sum + item.totalPrice);

  String _formatCurrency(int amount) {
    return CurrencyFormatter.format(amount);
  }

  void _openAddPenitipModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddPenitipModal(
        onPenitipAdded: (newPenitip) {
          setState(() {
            if (!_penitipList.contains(newPenitip.name)) {
              _penitipList.add(newPenitip.name);
            }
            _selectedPenitip = newPenitip.name;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.primary,
              behavior: SnackBarBehavior.floating,
              content: Row(
                children: [
                  const Icon(Icons.check_circle_outline_rounded,
                      color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Mitra penitip "${newPenitip.name}" berhasil ditambahkan!',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _addToCart(ProductItem product) {
    final existingIndex = _cart.indexWhere((item) => item.id == product.id);

    setState(() {
      if (existingIndex != -1) {
        _cart[existingIndex].quantity += 1;
      } else {
        _cart.add(
          CartItem(
            id: product.id,
            name: product.name,
            price: product.price,
            quantity: 1,
            imageUrl: product.imageUrl,
            penitipName: product.penitipName,
          ),
        );
      }
    });

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 1000),
        content: Row(
          children: [
            const Icon(Icons.shopping_cart_checkout_rounded,
                color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '+1 ${product.name} (${product.penitipName}) ke keranjang',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onBarcodeDetected(String rawCode) {
    final cleanCode = rawCode.trim();
    final matched = _availableProducts.where((p) =>
        p.barcode == cleanCode ||
        p.id == cleanCode ||
        p.name.toLowerCase().contains(cleanCode.toLowerCase()));

    final productToAdd = matched.isNotEmpty
        ? matched.first
        : _availableProducts[_cart.length % _availableProducts.length];

    _addToCart(productToAdd);
  }

  void _onSimulateScan() {
    final nextProd =
        _availableProducts[_cart.length % _availableProducts.length];
    _addToCart(nextProd);
  }

  void _decrementFromCart(ProductItem product) {
    final index = _cart.indexWhere((item) => item.id == product.id);
    if (index != -1) {
      setState(() {
        if (_cart[index].quantity > 1) {
          _cart[index].quantity -= 1;
        } else {
          _cart.removeAt(index);
        }
      });
    }
  }

  void _openEtalaseAllScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EtalaseAllScreen(
          products: _availableProducts,
          cart: _cart,
          onAddToCart: (product) => _addToCart(product),
          onDecrementCart: (product) => _decrementFromCart(product),
          onOpenCart: _openCartShopeeScreen,
          onOpenPayment: _openPaymentScreen,
        ),
      ),
    ).then((_) => setState(() {}));
  }

  void _openCartShopeeScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CartShopeeScreen(
          cartItems: _cart,
          onCartUpdated: (updatedItems) {
            setState(() {});
          },
        ),
      ),
    ).then((_) => setState(() {}));
  }

  void _openPaymentScreen() {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Keranjang kasir masih kosong.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentScreen(
          totalAmount: _totalAmount,
          cartItems: List.from(_cart),
        ),
      ),
    ).then((_) => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final displayedProducts = _filteredProducts;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        title: 'Kasir Jualan',
        actions: [
          // Shopee Style Header Cart Badge Button
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: InkWell(
                onTap: _openCartShopeeScreen,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.border, width: 1.2),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Icon(
                        Icons.shopping_cart_outlined,
                        color: AppColors.textPrimary,
                        size: 22,
                      ),
                      if (_totalItems > 0)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: AppColors.danger,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              '$_totalItems',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              backgroundColor: Colors.white,
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search Bar & Scan Trigger
                    Row(
                      children: [
                        Expanded(
                          child: CustomSearchBar(
                            controller: _searchController,
                            hintText: 'Cari makanan, barcode, atau nama penitip...',
                            onChanged: (val) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: 10),
                        InkWell(
                          onTap: _onSimulateScan,
                          borderRadius:
                              BorderRadius.circular(AppStyles.radiusMedium),
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius:
                                  BorderRadius.circular(AppStyles.radiusMedium),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      AppColors.primary.withValues(alpha: 0.25),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.qr_code_2_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Jika sedang mencari: Tampilkan Hasil Pencarian Langsung di Bawah Search Bar
                    if (_searchController.text.trim().isNotEmpty) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.search_rounded,
                                  size: 18, color: AppColors.primary),
                              const SizedBox(width: 6),
                              Text(
                                'Hasil Pencarian (${displayedProducts.length})',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          TextButton.icon(
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                            icon: const Icon(Icons.close_rounded, size: 16),
                            label: const Text('Batal'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (displayedProducts.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 32),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius:
                                BorderRadius.circular(AppStyles.radiusMedium),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            children: [
                              const Icon(Icons.search_off_rounded,
                                  size: 44, color: AppColors.textMuted),
                              const SizedBox(height: 10),
                              Text(
                                'Tidak ada makanan cocok dengan "${_searchController.text.trim()}"',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary),
                              ),
                              const SizedBox(height: 12),
                              OutlinedButton.icon(
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {});
                                },
                                icon: const Icon(Icons.refresh_rounded, size: 16),
                                label: const Text('Reset Pencarian'),
                              ),
                            ],
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: displayedProducts.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final prod = displayedProducts[index];
                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: AppStyles.cardDecoration(),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.network(
                                      prod.imageUrl,
                                      width: 56,
                                      height: 56,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        width: 56,
                                        height: 56,
                                        color: AppColors.primaryLight,
                                        child: const Icon(
                                            Icons.fastfood_rounded,
                                            color: AppColors.primary),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          prod.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            Text(
                                              '${prod.penitipName} • ',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                            Text(
                                              'Stok: ${prod.stock}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: prod.stock <= 5
                                                    ? AppColors.warningText
                                                    : AppColors.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _formatCurrency(prod.price),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 14,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 8),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    onPressed: () => _addToCart(prod),
                                    icon: const Icon(
                                        Icons.add_shopping_cart_rounded,
                                        size: 16),
                                    label: const Text('+ Tambah',
                                        style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700)),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      const SizedBox(height: 16),
                    ] else ...[
                      // Live Camera Viewfinder
                      BarcodeScannerViewfinder(
                        onSimulateScan: _onSimulateScan,
                        onBarcodeScanned: _onBarcodeDetected,
                      ),
                      const SizedBox(height: 18),

                      // Section: Mitra Penitip Chips & Tambah Penitip Button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.groups_rounded,
                                size: 19,
                                color: AppColors.primary,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Mitra Penitip',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          InkWell(
                            onTap: _openAddPenitipModal,
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppColors.primary.withValues(alpha: 0.3),
                                ),
                              ),
                              child: const Row(
                                children: [
                                  Icon(
                                    Icons.person_add_alt_1_rounded,
                                    size: 15,
                                    color: AppColors.primary,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    '+ Tambah Penitip',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Penitip Filter Chips Carousel
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: [
                            ..._penitipList.map((penitip) {
                              final isSelected = _selectedPenitip == penitip;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (penitip != 'Semua') ...[
                                        Icon(
                                          Icons.storefront_rounded,
                                          size: 13,
                                          color: isSelected
                                              ? Colors.white
                                              : AppColors.textSecondary,
                                        ),
                                        const SizedBox(width: 4),
                                      ],
                                      Text(
                                        penitip,
                                        style: TextStyle(
                                          fontSize: 12,
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
                                  backgroundColor: AppColors.surface,
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
                                      setState(() {
                                        _selectedPenitip = penitip;
                                      });
                                    }
                                  },
                                ),
                              );
                            }),
                            // Quick Add Penitip Chip
                            InkWell(
                              onTap: _openAddPenitipModal,
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 7),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceMuted,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: AppColors.border,
                                    style: BorderStyle.solid,
                                  ),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(
                                      Icons.add_circle_outline_rounded,
                                      size: 14,
                                      color: AppColors.textSecondary,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Tambah',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Section: Kategori Produk Chips Carousel
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
                                backgroundColor: AppColors.surface,
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
                                    setState(() {
                                      _selectedCategory = category;
                                    });
                                  }
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Quick Tap Food Items Section (Etalase Makanan)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'Etalase Makanan',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${_availableProducts.length}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          InkWell(
                            onTap: _openEtalaseAllScreen,
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppColors.primary.withValues(alpha: 0.3),
                                ),
                              ),
                              child: const Row(
                                children: [
                                  Text(
                                    'Lihat Semua',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 11,
                                    color: AppColors.primary,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Horizontal Food Quick Pick Carousel
                      if (_isLoading)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else if (displayedProducts.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 28),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius:
                                BorderRadius.circular(AppStyles.radiusMedium),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.fastfood_outlined,
                                size: 40,
                                color: AppColors.textMuted,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Tidak ada produk dari "$_selectedPenitip"',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              OutlinedButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _selectedPenitip = 'Semua';
                                    _searchController.clear();
                                  });
                                },
                                icon: const Icon(Icons.refresh_rounded, size: 16),
                                label: const Text('Reset Filter'),
                              ),
                            ],
                          ),
                        )
                      else
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            children: [
                              ...displayedProducts.map((prod) {
                                return Container(
                                width: 148,
                                margin: const EdgeInsets.only(right: 12),
                                decoration: AppStyles.cardDecoration(),
                                child: InkWell(
                                  onTap: () => _addToCart(prod),
                                  borderRadius:
                                      BorderRadius.circular(AppStyles.radiusCard),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Food Image with Penitip Name Badge
                                      Stack(
                                        children: [
                                          ClipRRect(
                                            borderRadius:
                                                const BorderRadius.vertical(
                                              top: Radius.circular(15),
                                            ),
                                            child: Image.network(
                                              prod.imageUrl,
                                              height: 90,
                                              width: double.infinity,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (context, error, stackTrace) =>
                                                      Container(
                                                height: 90,
                                                color: AppColors.primaryLight,
                                                child: const Icon(
                                                  Icons.fastfood_rounded,
                                                  color: AppColors.primary,
                                                  size: 32,
                                                ),
                                              ),
                                            ),
                                          ),
                                          // Badge Nama Penitip on Image
                                          Positioned(
                                            top: 6,
                                            left: 6,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 6, vertical: 2.5),
                                              decoration: BoxDecoration(
                                                color: Colors.black
                                                    .withValues(alpha: 0.72),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(
                                                    Icons.storefront_rounded,
                                                    color: Colors.amber,
                                                    size: 10.5,
                                                  ),
                                                  const SizedBox(width: 3),
                                                  Text(
                                                    prod.penitipName,
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 9.5,
                                                      fontWeight: FontWeight.w700,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(8),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              prod.name,
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
                                              'Stok: ${prod.stock} pcs',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: prod.stock <= 5
                                                    ? AppColors.warningText
                                                    : AppColors.textSecondary,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              _formatCurrency(prod.price),
                                              style: const TextStyle(
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.w800,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Container(
                                              width: double.infinity,
                                              padding: const EdgeInsets.symmetric(
                                                  vertical: 4),
                                              decoration: BoxDecoration(
                                                color: AppColors.primaryLight,
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              alignment: Alignment.center,
                                              child: const Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    Icons.add,
                                                    size: 14,
                                                    color: AppColors.primary,
                                                  ),
                                                  SizedBox(width: 2),
                                                  Text(
                                                    'Tambah',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w700,
                                                      color: AppColors.primary,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                            // Card "Lihat Semua" di akhir carousel
                            Container(
                              width: 124,
                              margin: const EdgeInsets.only(right: 12),
                              decoration: AppStyles.cardDecoration(),
                              child: InkWell(
                                onTap: _openEtalaseAllScreen,
                                borderRadius:
                                    BorderRadius.circular(AppStyles.radiusCard),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 16),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: const BoxDecoration(
                                          color: AppColors.primaryLight,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.grid_view_rounded,
                                          color: AppColors.primary,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      const Text(
                                        'Lihat Semua',
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        '${_availableProducts.length} Produk',
                                        style: const TextStyle(
                                          fontSize: 10.5,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],


                  // Shopee Style Quick Cart Summary Box
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius:
                          BorderRadius.circular(AppStyles.radiusMedium),
                      border: Border.all(color: AppColors.border, width: 1.2),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.shopping_bag_outlined,
                              color: AppColors.primary,
                              size: 24,
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Keranjang: $_totalItems Item',
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  'Total: ${_formatCurrency(_totalAmount)}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryLight,
                            foregroundColor: AppColors.primary,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: _openCartShopeeScreen,
                          child: const Text(
                            'Lihat Detail',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),

          // Shopee-Style Sticky Bottom Checkout Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: const Border(
                top: BorderSide(
                  color: AppColors.divider,
                  width: 1.2,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Flexible(
                    child: InkWell(
                      onTap: _openCartShopeeScreen,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Total Pembayaran',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            _formatCurrency(_totalAmount),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              color: AppColors.primary,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    height: 46,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: _cart.isEmpty ? null : _openPaymentScreen,
                      icon: const Icon(Icons.payment_rounded, size: 18),
                      label: Text(
                        'Bayar ($_totalItems)',
                        style: const TextStyle(
                          fontSize: 14,
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
