import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../../core/services/transaction_service.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/widgets/custom_app_bar.dart';

class AdminSettlementScreen extends StatefulWidget {
  const AdminSettlementScreen({super.key});

  @override
  State<AdminSettlementScreen> createState() => _AdminSettlementScreenState();
}

class _AdminSettlementScreenState extends State<AdminSettlementScreen> {
  List<SettlementRow> _settlements = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSettlements();
  }

  Future<void> _loadSettlements() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final data = await TransactionService.fetchSettlements();
      if (!mounted) return;
      setState(() {
        _settlements = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Gagal memuat bagi hasil: $e';
        _isLoading = false;
      });
    }
  }

  String _formatCurrency(int amount) {
    return CurrencyFormatter.format(amount);
  }

  int get _totalGross =>
      _settlements.fold(0, (sum, item) => sum + item.grossRevenue);
  int get _totalCommission =>
      _settlements.fold(0, (sum, item) => sum + item.commission);
  int get _totalPendingPayout => _settlements
      .where((s) => !s.isPaid)
      .fold(0, (sum, item) => sum + item.netPayout);

  void _processPayout(SettlementRow item) {
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Konfirmasi Pembayaran Bagi Hasil',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Bayar hak penjualan ke ${item.penitipName} (${item.phoneNumber})',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),

            // Breakdown card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Penjualan Kotor:'),
                      Text(_formatCurrency(item.grossRevenue),
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Komisi Toko (${item.commissionRate}%):'),
                      Text('- ${_formatCurrency(item.commission)}',
                          style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(height: 1),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Hak Bersih Penitip:',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                      Text(
                        _formatCurrency(item.netPayout),
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Confirm Action
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: AppStyles.primaryButtonStyle(),
                onPressed: () async {
                  Navigator.pop(ctx);
                  try {
                    await TransactionService.markSettlementPaid(item.id);
                    if (!mounted) return;
                    setState(() {
                      item.isPaid = true;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: AppColors.primary,
                        behavior: SnackBarBehavior.floating,
                        content: Text(
                          'Pembayaran bagi hasil ke ${item.penitipName} berhasil dicatat!',
                        ),
                      ),
                    );
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: AppColors.danger,
                        behavior: SnackBarBehavior.floating,
                        content: Text('Gagal memproses pembayaran: $e'),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                label: const Text('Tandai Telah Dibayar / Ditransfer'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(
        title: 'Laporan Bagi Hasil Penitip',
      ),
      body: _isLoading
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
                        onPressed: _loadSettlements,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: AppColors.primary,
                  backgroundColor: Colors.white,
                  onRefresh: _loadSettlements,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Summary Banner
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.primary, AppColors.primaryDark],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius:
                                BorderRadius.circular(AppStyles.radiusCard),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Total Bagi Hasil Belum Dibayar',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _formatCurrency(_totalPendingPayout),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Total Omzet: ${_formatCurrency(_totalGross)}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.white.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      'Komisi Toko: ${_formatCurrency(_totalCommission)}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Settlement List Section
                        const Text(
                          'Rincian Bagi Hasil Mitra',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),

                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _settlements.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final item = _settlements[index];

                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: AppStyles.cardDecoration(),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.penitipName,
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w800,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                          Text(
                                            '${item.totalSoldQty} item terjual',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: item.isPaid
                                              ? AppColors.successBg
                                              : AppColors.warningBg,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          item.isPaid
                                              ? 'Lunas'
                                              : 'Belum Dibayar',
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w700,
                                            color: item.isPaid
                                                ? AppColors.successText
                                                : AppColors.warningText,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  const Divider(height: 1),
                                  const SizedBox(height: 12),

                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Hak Bersih Penitip (${100 - item.commissionRate}%)',
                                            style: const TextStyle(
                                              fontSize: 11.5,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            _formatCurrency(item.netPayout),
                                            style: const TextStyle(
                                              fontSize: 17,
                                              fontWeight: FontWeight.w800,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (!item.isPaid)
                                        ElevatedButton(
                                          style: AppStyles.primaryButtonStyle(
                                            radius: AppStyles.radiusSmall,
                                          ),
                                          onPressed: () =>
                                              _processPayout(item),
                                          child: const Text(
                                            'Bayar',
                                            style: TextStyle(fontSize: 13),
                                          ),
                                        )
                                      else
                                        const Row(
                                          children: [
                                            Icon(Icons.check_circle_rounded,
                                                color: AppColors.primary,
                                                size: 18),
                                            SizedBox(width: 4),
                                            Text(
                                              'Selesai',
                                              style: TextStyle(
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}
