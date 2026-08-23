import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../../core/services/penitip_service.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../models/penitip_item.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import '../../../shared/widgets/custom_search_bar.dart';
import '../widgets/add_penitip_modal.dart';
import '../widgets/edit_penitip_modal.dart';
import '../widgets/penitip_card_tile.dart';
import '../widgets/penitip_detail_modal.dart';

class PenitipListScreen extends StatefulWidget {
  final bool isModalMode;

  const PenitipListScreen({
    super.key,
    this.isModalMode = false,
  });

  @override
  State<PenitipListScreen> createState() => _PenitipListScreenState();
}

class _PenitipListScreenState extends State<PenitipListScreen> {
  final TextEditingController _searchController = TextEditingController();

  List<PenitipItem> _penitips = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPenitips();
  }

  Future<void> _loadPenitips() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final penitips = await PenitipService.fetchAll();
      if (!mounted) return;
      setState(() {
        _penitips = penitips;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Gagal memuat data penitip: $e';
        _isLoading = false;
      });
    }
  }

  List<PenitipItem> get _filteredPenitips {
    final query = _searchController.text.toLowerCase().trim();
    return _penitips.where((p) {
      return query.isEmpty ||
          p.name.toLowerCase().contains(query) ||
          (p.phoneNumber != null && p.phoneNumber!.toLowerCase().contains(query)) ||
          (p.address != null && p.address!.toLowerCase().contains(query)) ||
          (p.notes != null && p.notes!.toLowerCase().contains(query));
    }).toList();
  }

  String _formatCurrency(int amount) {
    return CurrencyFormatter.format(amount);
  }

  void _openAddPenitipModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddPenitipModal(
        onPenitipAdded: (newPenitip) async {
          try {
            final created = await PenitipService.create(newPenitip);
            if (!mounted) return;
            setState(() {
              _penitips.insert(0, created);
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: AppColors.primary,
                behavior: SnackBarBehavior.floating,
                content: Text('Mitra "${created.name}" berhasil didaftarkan!'),
              ),
            );
          } catch (e) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: AppColors.danger,
                behavior: SnackBarBehavior.floating,
                content: Text('Gagal mendaftarkan penitip: $e'),
              ),
            );
          }
        },
      ),
    );
  }

  void _showPenitipDetail(PenitipItem penitip) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PenitipDetailModal(
        penitip: penitip,
        onEdit: () => _openEditPenitipModal(penitip),
        onDelete: () => _confirmDeletePenitip(penitip),
        onWhatsAppShare: () => _shareWhatsAppRekap(penitip),
      ),
    );
  }

  void _openEditPenitipModal(PenitipItem penitip) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => EditPenitipModal(
        penitip: penitip,
        onPenitipUpdated: (updated) async {
          try {
            final saved = await PenitipService.update(updated);
            if (!mounted) return;
            setState(() {
              final idx = _penitips.indexWhere((p) => p.id == saved.id);
              if (idx != -1) {
                _penitips[idx] = saved;
              }
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: AppColors.primary,
                behavior: SnackBarBehavior.floating,
                content: Text(
                    'Profil Mitra "${saved.name}" berhasil diperbarui!'),
              ),
            );
          } catch (e) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: AppColors.danger,
                behavior: SnackBarBehavior.floating,
                content: Text('Gagal mengupdate penitip: $e'),
              ),
            );
          }
        },
      ),
    );
  }

  void _confirmDeletePenitip(PenitipItem penitip) {
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
                Icons.person_remove_rounded,
                color: AppColors.danger,
                size: 30,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Hapus Mitra Penitip?',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Apakah Anda yakin ingin menghapus data mitra "${penitip.name}"? Riwayat transaksi lama akan tetap tersimpan di arsip laporan.',
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
                        await PenitipService.delete(penitip.id);
                        if (!mounted) return;
                        setState(() {
                          _penitips.removeWhere((p) => p.id == penitip.id);
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: AppColors.danger,
                            behavior: SnackBarBehavior.floating,
                            content: Text(
                                'Mitra "${penitip.name}" telah dihapus.'),
                          ),
                        );
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: AppColors.danger,
                            behavior: SnackBarBehavior.floating,
                            content: Text('Gagal menghapus penitip: $e'),
                          ),
                        );
                      }
                    },
                    child: const Text(
                      'Hapus Mitra',
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

  void _shareWhatsAppRekap(PenitipItem penitip) {
    final commission =
        (penitip.totalRevenue * (penitip.commissionRate / 100)).round();
    final netPayout = penitip.totalRevenue - commission;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF25D366),
        behavior: SnackBarBehavior.floating,
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Rekap penjualan ${_formatCurrency(netPayout)} siap dikirim via WhatsApp ke ${penitip.name} (${penitip.phoneNumber ?? '-'})!',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
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
      appBar: CustomAppBar(
        title: 'Penitip',
        leading: widget.isModalMode
            ? IconButton(
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  color: AppColors.primary,
                ),
                onPressed: () => Navigator.pop(context),
              )
            : null,
      ),
      body: Column(
        children: [
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              children: [
                CustomSearchBar(
                  controller: _searchController,
                  hintText: 'Cari nama penitip...',
                  onChanged: (val) => setState(() {}),
                  onClear: () {
                    _searchController.clear();
                    setState(() {});
                  },
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: AppStyles.primaryButtonStyle(),
                    onPressed: _openAddPenitipModal,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add, color: Colors.white, size: 20),
                        SizedBox(width: 6),
                        Text(
                          'Tambah Penitip',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
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
                              onPressed: _loadPenitips,
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('Coba Lagi'),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        color: AppColors.primary,
                        backgroundColor: Colors.white,
                        onRefresh: _loadPenitips,
                        child: _filteredPenitips.isEmpty
                            ? const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.person_search_rounded,
                                      size: 48,
                                      color: AppColors.textMuted,
                                    ),
                                    SizedBox(height: 12),
                                    Text(
                                      'Tidak ada penitip ditemukan',
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
                                padding: const EdgeInsets.all(16),
                                itemCount: _filteredPenitips.length,
                                separatorBuilder: (context, index) =>
                                    const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  final item = _filteredPenitips[index];
                                  return PenitipCardTile(
                                    penitip: item,
                                    onTap: () => _showPenitipDetail(item),
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
