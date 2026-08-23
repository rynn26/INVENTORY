import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../../core/services/stock_service.dart';
import '../../../models/stock_item.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import '../../../shared/widgets/custom_search_bar.dart';
import '../widgets/stock_adjust_modal.dart';
import '../widgets/stock_card_tile.dart';
import '../widgets/stock_detail_modal.dart';
import '../widgets/stock_in_modal.dart';
import '../widgets/stock_return_modal.dart';

class StockInventoryScreen extends StatefulWidget {
  final bool isModalMode;

  const StockInventoryScreen({
    super.key,
    this.isModalMode = false,
  });

  @override
  State<StockInventoryScreen> createState() => _StockInventoryScreenState();
}

class _StockInventoryScreenState extends State<StockInventoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'Semua';

  List<StockItem> _items = [];
  bool _isLoading = true;
  String? _errorMessage;

  final List<String> _filters = ['Semua', 'Aman', 'Menipis', 'Habis'];

  @override
  void initState() {
    super.initState();
    _loadStock();
  }

  Future<void> _loadStock() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final items = await StockService.fetchAll();
      if (!mounted) return;
      setState(() {
        _items = items;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Gagal memuat stok: $e';
        _isLoading = false;
      });
    }
  }

  List<StockItem> get _filteredItems {
    final query = _searchController.text.toLowerCase().trim();
    return _items.where((item) {
      final matchesQuery = query.isEmpty ||
          item.name.toLowerCase().contains(query) ||
          item.penitipName.toLowerCase().contains(query) ||
          item.category.toLowerCase().contains(query);
      if (!matchesQuery) return false;

      if (_selectedFilter == 'Semua') return true;
      if (_selectedFilter == 'Aman') return item.status == StockStatus.aman;
      if (_selectedFilter == 'Menipis') return item.status == StockStatus.menipis;
      if (_selectedFilter == 'Habis') return item.status == StockStatus.habis;

      return true;
    }).toList();
  }

  void _onExportStock() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppStyles.radiusSmall),
        ),
        content: const Row(
          children: [
            Icon(Icons.file_download_done_rounded, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Laporan mutasi & stok barang berhasil diekspor ke Excel & PDF.',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showStockDetail(StockItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StockDetailModal(
        item: item,
        onAdjust: () => _openStockAdjustModal(item),
        onReturn: () => _openStockReturnModal(item),
      ),
    );
  }

  void _openStockInModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StockInModal(
        availableItems: _items,
        onStockIn: (itemId, addedQty, notes) async {
          try {
            await StockService.addStockIn(
              productId: itemId,
              qty: addedQty,
              notes: notes,
            );
            if (!mounted) return;
            setState(() {
              final idx = _items.indexWhere((i) => i.id == itemId);
              if (idx != -1) {
                _items[idx].availableStock += addedQty;
                _items[idx].stockInToday += addedQty;
              }
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: AppColors.primary,
                behavior: SnackBarBehavior.floating,
                content: Text(
                    'Titipan masuk +$addedQty pcs berhasil dicatat ke inventaris!'),
              ),
            );
          } catch (e) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: AppColors.danger,
                behavior: SnackBarBehavior.floating,
                content: Text('Gagal mencatat stok masuk: $e'),
              ),
            );
          }
        },
      ),
    );
  }

  void _openStockReturnModal(StockItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StockReturnModal(
        item: item,
        onStockReturned: (returnQty, reason) async {
          try {
            await StockService.returnStock(
              productId: item.id,
              returnQty: returnQty,
              reason: reason,
            );
            if (!mounted) return;
            setState(() {
              item.availableStock -= returnQty;
              item.stockReturnedToday += returnQty;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: AppColors.danger,
                behavior: SnackBarBehavior.floating,
                content: Text(
                    'Retur $returnQty pcs "${item.name}" ke ${item.penitipName} berhasil dicatat.'),
              ),
            );
          } catch (e) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: AppColors.danger,
                behavior: SnackBarBehavior.floating,
                content: Text('Gagal mencatat retur: $e'),
              ),
            );
          }
        },
      ),
    );
  }

  void _openStockAdjustModal(StockItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StockAdjustModal(
        item: item,
        onStockUpdated: (newStock) async {
          try {
            await StockService.adjustStock(
              productId: item.id,
              newStock: newStock,
              reason: 'Koreksi manual dari app',
            );
            if (!mounted) return;
            setState(() {
              item.availableStock = newStock;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: AppColors.primary,
                behavior: SnackBarBehavior.floating,
                content:
                    Text('Stok "${item.name}" diperbarui menjadi $newStock pcs.'),
              ),
            );
          } catch (e) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: AppColors.danger,
                behavior: SnackBarBehavior.floating,
                content: Text('Gagal mengupdate stok: $e'),
              ),
            );
          }
        },
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
      appBar: CustomAppBar(
        title: 'Stok Barang',
        leading: widget.isModalMode
            ? IconButton(
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  color: AppColors.textPrimary,
                ),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton(
              icon: const Icon(
                Icons.file_download_outlined,
                color: AppColors.primary,
                size: 24,
              ),
              onPressed: _onExportStock,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openStockInModal,
        backgroundColor: AppColors.primary,
        elevation: 4,
        icon: const Icon(Icons.add_business_rounded, color: Colors.white, size: 22),
        label: const Text(
          'Terima Titipan Masuk',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Column(
              children: [
                CustomSearchBar(
                  controller: _searchController,
                  hintText: 'Cari nama produk...',
                  onChanged: (val) => setState(() {}),
                  onClear: () {
                    _searchController.clear();
                    setState(() {});
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: _filters.map((filter) {
                    final isSelected = _selectedFilter == filter;

                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: InkWell(
                          onTap: () => setState(() => _selectedFilter = filter),
                          borderRadius:
                              BorderRadius.circular(AppStyles.radiusPill),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 7),
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
                            alignment: Alignment.center,
                            child: Text(
                              filter,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          Container(height: 1, color: AppColors.divider),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.cloud_off_rounded,
                                size: 48, color: AppColors.textMuted),
                            const SizedBox(height: 12),
                            Text(_errorMessage!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary)),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _loadStock,
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('Coba Lagi'),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        color: AppColors.primary,
                        backgroundColor: Colors.white,
                        onRefresh: _loadStock,
                        child: _filteredItems.isEmpty
                            ? const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.inventory_2_outlined,
                                      size: 48,
                                      color: AppColors.textMuted,
                                    ),
                                    SizedBox(height: 12),
                                    Text(
                                      'Tidak ada produk dengan filter ini',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.separated(
                                physics: const AlwaysScrollableScrollPhysics(
                                  parent: BouncingScrollPhysics(),
                                ),
                                padding:
                                    const EdgeInsets.fromLTRB(16, 16, 16, 85),
                                itemCount: _filteredItems.length,
                                separatorBuilder: (context, index) =>
                                    const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  final item = _filteredItems[index];
                                  return StockCardTile(
                                    item: item,
                                    onTap: () => _showStockDetail(item),
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
