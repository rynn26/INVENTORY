import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../../core/services/product_service.dart';
import '../../../models/product_item.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import '../../../shared/widgets/custom_search_bar.dart';
import '../../admin/screens/barcode_generator_screen.dart';
import '../widgets/add_product_modal.dart';
import '../widgets/edit_product_modal.dart';
import '../widgets/product_card.dart';
import '../widgets/product_detail_modal.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'Semua';

  List<ProductItem> _products = [];
  bool _isLoading = true;
  String? _errorMessage;

  final List<String> _filters = [
    'Semua',
    'Rp5.000',
    'Rp10.000',
    'Stok Menipis',
  ];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final products = await ProductService.fetchAll();
      if (!mounted) return;
      setState(() {
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Gagal memuat produk: $e';
        _isLoading = false;
      });
    }
  }

  List<ProductItem> get _filteredProducts {
    final query = _searchController.text.toLowerCase().trim();
    return _products.where((p) {
      final matchesSearch = query.isEmpty ||
          p.name.toLowerCase().contains(query) ||
          p.penitipName.toLowerCase().contains(query) ||
          p.category.toLowerCase().contains(query) ||
          (p.barcode != null && p.barcode!.toLowerCase().contains(query));

      if (!matchesSearch) return false;

      if (_selectedFilter == 'Semua') return true;
      if (_selectedFilter == 'Rp5.000') return p.price <= 5000;
      if (_selectedFilter == 'Rp10.000') return p.price > 5000;
      if (_selectedFilter == 'Stok Menipis') return p.isLowStock || p.isOutOfStock;

      return true;
    }).toList();
  }

  void _openAddProductModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddProductModal(
        onProductAdded: (newProduct) {
          // Produk sudah tersimpan ke DB di dalam AddProductModal._submit()
          // Di sini cukup update list lokal dan tampilkan notifikasi sukses
          if (!mounted) return;
          setState(() {
            _products.insert(0, newProduct);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.primary,
              behavior: SnackBarBehavior.floating,
              content: Text('Produk "${newProduct.name}" berhasil ditambahkan!'),
            ),
          );
        },
      ),
    );
  }

  void _showProductDetail(ProductItem product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ProductDetailModal(
        product: product,
        onEdit: () => _openEditProductModal(product),
        onDelete: () => _confirmDeleteProduct(product),
        onPrintBarcode: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const BarcodeGeneratorScreen(),
            ),
          );
        },
      ),
    );
  }

  void _openEditProductModal(ProductItem product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => EditProductModal(
        product: product,
        onProductUpdated: (updated) async {
          try {
            final saved = await ProductService.update(updated);
            if (!mounted) return;
            setState(() {
              final idx = _products.indexWhere((p) => p.id == saved.id);
              if (idx != -1) {
                _products[idx] = saved;
              }
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: AppColors.primary,
                behavior: SnackBarBehavior.floating,
                content: Text('Produk "${saved.name}" berhasil diperbarui!'),
              ),
            );
          } catch (e) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: AppColors.danger,
                behavior: SnackBarBehavior.floating,
                content: Text('Gagal mengupdate produk: $e'),
              ),
            );
          }
        },
      ),
    );
  }

  void _confirmDeleteProduct(ProductItem product) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.delete_forever_rounded,
                color: AppColors.danger,
                size: 30,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Hapus Produk Makanan?',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Apakah Anda yakin ingin menghapus "${product.name}" (${product.penitipName}) dari daftar inventaris?',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: AppStyles.outlinedButtonStyle(),
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Batal'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.danger,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppStyles.radiusMedium),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () async {
                      Navigator.pop(ctx);
                      try {
                        await ProductService.delete(product.id);
                        if (!mounted) return;
                        setState(() {
                          _products.removeWhere((p) => p.id == product.id);
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: AppColors.danger,
                            behavior: SnackBarBehavior.floating,
                            content: Text(
                                'Produk "${product.name}" berhasil dihapus.'),
                          ),
                        );
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: AppColors.danger,
                            behavior: SnackBarBehavior.floating,
                            content: Text('Gagal menghapus produk: $e'),
                          ),
                        );
                      }
                    },
                    child: const Text(
                      'Hapus Produk',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(
        title: 'TitipKasir',
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: FloatingActionButton.extended(
          onPressed: _openAddProductModal,
          backgroundColor: AppColors.primary,
          elevation: 4,
          icon: const Icon(Icons.add, color: Colors.white, size: 22),
          label: const Text(
            'Tambah Produk',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 14.5,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Search & Filter Header Section
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Column(
              children: [
                CustomSearchBar(
                  controller: _searchController,
                  hintText: 'Cari makanan...',
                  onChanged: (val) => setState(() {}),
                  onClear: () {
                    _searchController.clear();
                    setState(() {});
                  },
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: _filters.map((filter) {
                      final isSelected = _selectedFilter == filter;
                      final isWarningFilter = filter == 'Stok Menipis';

                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: InkWell(
                          onTap: () => setState(() => _selectedFilter = filter),
                          borderRadius:
                              BorderRadius.circular(AppStyles.radiusPill),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.surface,
                              borderRadius:
                                  BorderRadius.circular(AppStyles.radiusPill),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.border,
                                width: 1.2,
                              ),
                            ),
                            child: Row(
                              children: [
                                if (isWarningFilter) ...[
                                  Icon(
                                    Icons.warning_amber_rounded,
                                    size: 15,
                                    color: isSelected
                                        ? Colors.white
                                        : AppColors.warningIcon,
                                  ),
                                  const SizedBox(width: 4),
                                ],
                                Text(
                                  filter,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: isSelected
                                        ? Colors.white
                                        : (isWarningFilter
                                            ? AppColors.warningText
                                            : AppColors.textPrimary),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          Container(height: 1, color: AppColors.divider),

          // Product Grid
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.cloud_off_rounded,
                                size: 48, color: AppColors.textMuted),
                            const SizedBox(height: 12),
                            Text(
                              _errorMessage!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _loadProducts,
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('Coba Lagi'),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        color: AppColors.primary,
                        backgroundColor: Colors.white,
                        onRefresh: _loadProducts,
                        child: _filteredProducts.isEmpty
                            ? const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.search_off_rounded,
                                      size: 48,
                                      color: AppColors.textMuted,
                                    ),
                                    SizedBox(height: 12),
                                    Text(
                                      'Tidak ada produk ditemukan',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : GridView.builder(
                                physics: const AlwaysScrollableScrollPhysics(
                                  parent: BouncingScrollPhysics(),
                                ),
                                padding:
                                    const EdgeInsets.fromLTRB(16, 16, 16, 90),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  mainAxisSpacing: 14,
                                  crossAxisSpacing: 12,
                                  childAspectRatio: 0.72,
                                ),
                                itemCount: _filteredProducts.length,
                                itemBuilder: (context, index) {
                                  final item = _filteredProducts[index];
                                  return ProductCard(
                                    product: item,
                                    onTap: () => _showProductDetail(item),
                                  );
                                },
                              ),
                      ),
          ),
        ],
      ),
    );
  }
}
