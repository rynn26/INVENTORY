import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../../core/services/transaction_service.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import '../models/report_data.dart';
import '../widgets/report_chart_card.dart';

class ReportsScreen extends StatefulWidget {
  final bool isModalMode;

  const ReportsScreen({
    super.key,
    this.isModalMode = false,
  });

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  ReportPeriod _selectedPeriod = ReportPeriod.daily;
  DateTime _currentDate = DateTime.now();

  // ── Harian ──
  bool _isLoadingDaily = false;
  int _dailyRevenue = 0;
  int _dailyItemsSold = 0;
  int _dailyTransactions = 0;
  List<TopSoldItem> _dailyTopProducts = [];
  List<ConsignorSalesSummary> _dailyConsignors = [];
  List<Map<String, dynamic>> _dailyTransactionsList = [];

  // ── Bulanan ──
  bool _isLoadingMonthly = false;
  int _monthlyRevenue = 0;
  int _monthlyItemsSold = 0;
  int _monthlyTransactions = 0;
  List<ChartBarData> _monthlyChartBars = [];
  List<TopSoldItem> _monthlyTopProducts = [];
  List<ConsignorSalesSummary> _monthlyConsignors = [];

  // ── Tahunan ──
  bool _isLoadingYearly = false;
  int _yearlyRevenue = 0;
  int _yearlyItemsSold = 0;
  int _yearlyTransactions = 0;
  List<ChartBarData> _yearlyChartBars = [];
  List<TopSoldItem> _yearlyTopProducts = [];
  List<ConsignorSalesSummary> _yearlyConsignors = [];

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    await Future.wait([
      _loadDailyData(),
      _loadMonthlyData(),
      _loadYearlyData(),
    ]);
  }

  Future<void> _loadDailyData() async {
    if (_isLoadingDaily) return;
    if (mounted) setState(() => _isLoadingDaily = true);
    try {
      // Gunakan _currentDate, bukan hanya hari ini
      final date = _currentDate;
      final dateStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      final txList = await TransactionService.fetchTransactionsByDateRange(
        '${dateStr}T00:00:00',
        '${dateStr}T23:59:59',
      );

      final Map<String, Map<String, dynamic>> productMap = {};
      int totalRevenue = 0;
      for (final tx in txList) {
        totalRevenue += (tx['total_amount'] as int? ?? 0);
        final items = tx['transaction_items'] as List? ?? [];
        for (final item in items) {
          final name = item['product_name'] as String? ?? '-';
          final penitip = item['penitip_name'] as String? ?? '-';
          final qty = item['quantity'] as int? ?? 0;
          final subtotal = item['subtotal'] as int? ?? 0;
          if (!productMap.containsKey(name)) {
            productMap[name] = {
              'penitip': penitip,
              'qty': 0,
              'revenue': 0,
            };
          }
          productMap[name]!['qty'] = (productMap[name]!['qty'] as int) + qty;
          productMap[name]!['revenue'] =
              (productMap[name]!['revenue'] as int) + subtotal;
        }
      }

      final sortedProducts = productMap.entries.toList()
        ..sort((a, b) =>
            (b.value['qty'] as int).compareTo(a.value['qty'] as int));

      final Map<String, Map<String, dynamic>> penitipMap = {};
      for (final entry in productMap.entries) {
        final p = entry.value['penitip'] as String;
        if (!penitipMap.containsKey(p)) {
          penitipMap[p] = {'qty': 0, 'revenue': 0};
        }
        penitipMap[p]!['qty'] =
            (penitipMap[p]!['qty'] as int) + (entry.value['qty'] as int);
        penitipMap[p]!['revenue'] = (penitipMap[p]!['revenue'] as int) +
            (entry.value['revenue'] as int);
      }

      int totalItemsSold = 0;
      for (final e in productMap.values) {
        totalItemsSold += e['qty'] as int;
      }

      if (!mounted) return;

      // Fetch commission_nominal per penitip dari DB (di luar setState)
      Map<String, int> penitipNominals = {};
      try {
        penitipNominals = await TransactionService.fetchPenitipNominals();
      } catch (_) {}

      if (!mounted) return;
      setState(() {
        _dailyRevenue = totalRevenue;
        _dailyItemsSold = totalItemsSold;
        _dailyTransactions = txList.length;
        _dailyTransactionsList = txList;
        _dailyTopProducts = sortedProducts.take(3).map((e) {
          return TopSoldItem(
            name: e.key,
            consignor: e.value['penitip'] as String,
            quantity: e.value['qty'] as int,
            revenue: e.value['revenue'] as int,
          );
        }).toList();
        _dailyConsignors = penitipMap.entries.map((e) {
          final gross = e.value['revenue'] as int;
          final qty = e.value['qty'] as int;
          final nominalPerItem = penitipNominals[e.key] ?? 0;
          final comm = nominalPerItem > 0 ? nominalPerItem * qty : 0;
          return ConsignorSalesSummary(
            name: e.key,
            itemsSold: qty,
            grossAmount: gross,
            commission: comm,
            netAmount: gross - comm,
          );
        }).toList();
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _dailyTransactionsList = [];
        });
      }
    } finally {
      if (mounted) setState(() => _isLoadingDaily = false);
    }
  }

  Future<void> _loadMonthlyData() async {
    if (_isLoadingMonthly) return;
    if (mounted) setState(() => _isLoadingMonthly = true);
    try {
      final result = await TransactionService.fetchMonthlySummary(
          _currentDate.year, _currentDate.month);
      final summary = result['summary'] as PeriodSummary;
      final bars =
          (result['chartBars'] as List).cast<Map<String, dynamic>>();

      if (!mounted) return;
      setState(() {
        _monthlyRevenue = summary.totalRevenue;
        _monthlyItemsSold = summary.totalItemsSold;
        _monthlyTransactions = summary.totalTransactions;
        _monthlyChartBars = bars.map((b) {
          return ChartBarData(
            label: b['label'] as String,
            value: (b['value'] as num).toDouble(),
            tooltipText: b['tooltipText'] as String,
          );
        }).toList();
        _monthlyTopProducts = summary.topProducts.map((p) {
          return TopSoldItem(
            name: p['name'] as String,
            consignor: p['consignor'] as String,
            quantity: p['qty'] as int,
            revenue: p['revenue'] as int,
          );
        }).toList();
        _monthlyConsignors = summary.consignors.map((c) {
          final gross = c['revenue'] as int;
          final qty = c['qty'] as int;
          final nominalPerItem = (c['commission_nominal'] as int?) ?? 0;
          final comm = nominalPerItem > 0 ? nominalPerItem * qty : 0;
          return ConsignorSalesSummary(
            name: c['name'] as String,
            itemsSold: qty,
            grossAmount: gross,
            commission: comm,
            netAmount: gross - comm,
          );
        }).toList();
      });
    } catch (_) {
      if (mounted) setState(() => _isLoadingMonthly = false);
    } finally {
      if (mounted) setState(() => _isLoadingMonthly = false);
    }
  }

  Future<void> _loadYearlyData() async {
    if (_isLoadingYearly) return;
    if (mounted) setState(() => _isLoadingYearly = true);
    try {
      final result =
          await TransactionService.fetchYearlySummary(_currentDate.year);
      final summary = result['summary'] as PeriodSummary;
      final bars =
          (result['chartBars'] as List).cast<Map<String, dynamic>>();

      // Tentukan bar bulan dengan revenue tertinggi sebagai highlight
      double maxVal = 0;
      int maxIdx = 0;
      for (int i = 0; i < bars.length; i++) {
        final v = (bars[i]['value'] as num).toDouble();
        if (v > maxVal) {
          maxVal = v;
          maxIdx = i;
        }
      }

      if (!mounted) return;
      setState(() {
        _yearlyRevenue = summary.totalRevenue;
        _yearlyItemsSold = summary.totalItemsSold;
        _yearlyTransactions = summary.totalTransactions;
        _yearlyChartBars = bars.asMap().entries.map((entry) {
          final b = entry.value;
          return ChartBarData(
            label: b['label'] as String,
            value: (b['value'] as num).toDouble(),
            tooltipText: b['tooltipText'] as String,
            isHighlight: entry.key == maxIdx,
          );
        }).toList();
        _yearlyTopProducts = summary.topProducts.map((p) {
          return TopSoldItem(
            name: p['name'] as String,
            consignor: p['consignor'] as String,
            quantity: p['qty'] as int,
            revenue: p['revenue'] as int,
          );
        }).toList();
        _yearlyConsignors = summary.consignors.map((c) {
          final gross = c['revenue'] as int;
          final qty = c['qty'] as int;
          final nominalPerItem = (c['commission_nominal'] as int?) ?? 0;
          final comm = nominalPerItem > 0 ? nominalPerItem * qty : 0;
          return ConsignorSalesSummary(
            name: c['name'] as String,
            itemsSold: qty,
            grossAmount: gross,
            commission: comm,
            netAmount: gross - comm,
          );
        }).toList();
      });
    } catch (_) {
      // Tampilkan 0 jika error
    } finally {
      if (mounted) setState(() => _isLoadingYearly = false);
    }
  }

  String _formatCurrency(int amount) {
    return CurrencyFormatter.format(amount);
  }

  // Data laporan (dari state yang sudah di-load)
  ReportData get _currentReportData {
    switch (_selectedPeriod) {
      case ReportPeriod.daily:
        final dailyTotalComm = _dailyConsignors.fold(
            0, (sum, c) => sum + c.commission);
        return ReportData(
          periodTitle: 'Laporan Penjualan Harian',
          periodSubtitle: DateFormat('EEEE, dd MMMM yyyy', 'id_ID')
              .format(_currentDate),
          totalRevenue: _dailyRevenue,
          storeCommission: dailyTotalComm,
          consignorPayout: _dailyRevenue - dailyTotalComm,
          totalItemsSold: _dailyItemsSold,
          totalTransactions: _dailyTransactions,
          chartBars: const [
            ChartBarData(label: 'Pagi', value: 0, tooltipText: '-'),
            ChartBarData(label: 'Siang', value: 0, tooltipText: '-'),
            ChartBarData(label: 'Sore', value: 0, tooltipText: '-', isHighlight: true),
            ChartBarData(label: 'Malam', value: 0, tooltipText: '-'),
          ],
          topProducts: _dailyTopProducts,
          consignorSummaries: _dailyConsignors,
        );

      case ReportPeriod.monthly:
        final monthlyTotalComm = _monthlyConsignors.fold(
            0, (sum, c) => sum + c.commission);
        return ReportData(
          periodTitle: 'Laporan Penjualan Bulanan',
          periodSubtitle:
              DateFormat('MMMM yyyy', 'id_ID').format(_currentDate),
          totalRevenue: _monthlyRevenue,
          storeCommission: monthlyTotalComm,
          consignorPayout: _monthlyRevenue - monthlyTotalComm,
          totalItemsSold: _monthlyItemsSold,
          totalTransactions: _monthlyTransactions,
          chartBars: _monthlyChartBars,
          topProducts: _monthlyTopProducts,
          consignorSummaries: _monthlyConsignors,
        );

      case ReportPeriod.yearly:
        final yearlyTotalComm = _yearlyConsignors.fold(
            0, (sum, c) => sum + c.commission);
        return ReportData(
          periodTitle: 'Laporan Penjualan Tahunan',
          periodSubtitle: 'Tahun ${_currentDate.year}',
          totalRevenue: _yearlyRevenue,
          storeCommission: yearlyTotalComm,
          consignorPayout: _yearlyRevenue - yearlyTotalComm,
          totalItemsSold: _yearlyItemsSold,
          totalTransactions: _yearlyTransactions,
          chartBars: _yearlyChartBars,
          topProducts: _yearlyTopProducts,
          consignorSummaries: _yearlyConsignors,
        );
    }
  }

  /// Reload hanya data untuk periode yang sedang aktif
  void _reloadCurrentPeriodData() {
    switch (_selectedPeriod) {
      case ReportPeriod.daily:
        _loadDailyData();
        break;
      case ReportPeriod.monthly:
        _loadMonthlyData();
        break;
      case ReportPeriod.yearly:
        _loadYearlyData();
        break;
    }
  }

  bool get _isLoading {
    switch (_selectedPeriod) {
      case ReportPeriod.daily:
        return _isLoadingDaily;
      case ReportPeriod.monthly:
        return _isLoadingMonthly;
      case ReportPeriod.yearly:
        return _isLoadingYearly;
    }
  }

  void _onExportReport() {
    final periodName = _selectedPeriod == ReportPeriod.daily
        ? 'Harian'
        : (_selectedPeriod == ReportPeriod.monthly ? 'Bulanan' : 'Tahunan');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppStyles.radiusSmall),
        ),
        content: Row(
          children: [
            const Icon(Icons.file_download_done_rounded,
                color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Laporan $periodName berhasil diekspor ke format Excel & PDF!',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeleteDailyReport() async {
    final dateStr = DateFormat('dd MMMM yyyy', 'id_ID').format(_currentDate);
    bool restoreStock = true;

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: 60,
                    height: 60,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFEE2E2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.delete_forever_rounded,
                      color: Color(0xFFDC2626),
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Hapus Laporan $dateStr?',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tindakan ini akan menghapus semua $_dailyTransactions transaksi '
                    'senilai ${_formatCurrency(_dailyRevenue)} pada tanggal ini.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13.5,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Checkbox(
                          value: restoreStock,
                          activeColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          onChanged: (val) {
                            setModalState(() {
                              restoreStock = val ?? true;
                            });
                          },
                        ),
                        const SizedBox(width: 6),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Kembalikan stok produk',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                'Stok barang akan otomatis dipulihkan ke inventaris',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(color: AppColors.border),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text(
                            'Batal',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: const Color(0xFFDC2626),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text(
                            'Ya, Hapus Semua',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (confirmed == true && mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );

      try {
        final count = await TransactionService.deleteTransactionsByDate(
          _currentDate,
          restoreStock: restoreStock,
        );

        if (mounted) {
          Navigator.pop(context); // Close progress dialog
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFF16A34A),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppStyles.radiusSmall),
              ),
              content: Row(
                children: [
                  const Icon(Icons.check_circle_rounded,
                      color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Berhasil menghapus $count transaksi laporan tanggal $dateStr!',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          );
          await _loadAllData();
        }
      } catch (e) {
        if (mounted) {
          Navigator.pop(context); // Close progress dialog
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFFDC2626),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppStyles.radiusSmall),
              ),
              content: Text('Gagal menghapus laporan: $e'),
            ),
          );
        }
      }
    }
  }

  Future<void> _confirmDeleteSingleTransaction(Map<String, dynamic> tx) async {
    final receiptNumber = tx['receipt_number'] as String? ?? '-';
    final totalAmount = tx['total_amount'] as int? ?? 0;
    final items = (tx['transaction_items'] as List?) ?? [];
    bool restoreStock = true;

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: 56,
                    height: 56,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFEE2E2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      color: Color(0xFFDC2626),
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Hapus Transaksi?',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$receiptNumber • ${_formatCurrency(totalAmount)} (${items.length} item)',
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Checkbox(
                          value: restoreStock,
                          activeColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          onChanged: (val) {
                            setModalState(() {
                              restoreStock = val ?? true;
                            });
                          },
                        ),
                        const SizedBox(width: 6),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Kembalikan stok produk',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                'Stok barang akan otomatis dipulihkan ke katalog',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(color: AppColors.border),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text(
                            'Batal',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: const Color(0xFFDC2626),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text(
                            'Hapus Transaksi',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (confirmed == true && mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );

      try {
        await TransactionService.deleteTransaction(
          tx['id'] as String,
          restoreStock: restoreStock,
        );

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFF16A34A),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppStyles.radiusSmall),
              ),
              content: Row(
                children: [
                  const Icon(Icons.check_circle_rounded,
                      color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Transaksi $receiptNumber berhasil dihapus!',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          );
          await _loadAllData();
        }
      } catch (e) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFFDC2626),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppStyles.radiusSmall),
              ),
              content: Text('Gagal menghapus transaksi: $e'),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _currentReportData;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        title: 'Laporan Penjualan',
        leading: widget.isModalMode
            ? IconButton(
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  color: AppColors.primary,
                ),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        actions: [
          if (_selectedPeriod == ReportPeriod.daily && _dailyTransactions > 0)
            IconButton(
              icon: const Icon(
                Icons.delete_sweep_rounded,
                color: Color(0xFFDC2626),
              ),
              tooltip: 'Hapus Laporan Hari Ini',
              onPressed: _confirmDeleteDailyReport,
            ),
          IconButton(
            icon: const Icon(
              Icons.file_download_outlined,
              color: AppColors.primary,
            ),
            onPressed: _onExportReport,
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: Colors.white,
        onRefresh: () async {
          await _loadAllData();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // 1. Period Toggle Tab (Harian / Bulanan / Tahunan)
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppStyles.radiusPill),
                border: Border.all(color: AppColors.border, width: 1.2),
              ),
              child: Row(
                children: [
                  _buildPeriodTab(
                    period: ReportPeriod.daily,
                    label: 'Per Hari',
                    icon: Icons.calendar_today_rounded,
                  ),
                  _buildPeriodTab(
                    period: ReportPeriod.monthly,
                    label: 'Per Bulan',
                    icon: Icons.calendar_view_month_rounded,
                  ),
                  _buildPeriodTab(
                    period: ReportPeriod.yearly,
                    label: 'Per Tahun',
                    icon: Icons.auto_graph_rounded,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            // Loading indicator
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: LinearProgressIndicator(
                  backgroundColor: AppColors.border,
                  color: AppColors.primary,
                  minHeight: 2,
                ),
              ),

            // 2. Date / Period Selector Navigator Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: AppStyles.cardDecoration(),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded, size: 22),
                    onPressed: () {
                      setState(() {
                        if (_selectedPeriod == ReportPeriod.daily) {
                          _currentDate =
                              _currentDate.subtract(const Duration(days: 1));
                        } else if (_selectedPeriod == ReportPeriod.monthly) {
                          _currentDate = DateTime(
                              _currentDate.year, _currentDate.month - 1);
                        } else {
                          _currentDate = DateTime(_currentDate.year - 1);
                        }
                      });
                      _reloadCurrentPeriodData();
                    },
                  ),
                  Column(
                    children: [
                      Text(
                        data.periodTitle,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        data.periodSubtitle,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded, size: 22),
                    onPressed: () {
                      setState(() {
                        if (_selectedPeriod == ReportPeriod.daily) {
                          _currentDate =
                              _currentDate.add(const Duration(days: 1));
                        } else if (_selectedPeriod == ReportPeriod.monthly) {
                          _currentDate = DateTime(
                              _currentDate.year, _currentDate.month + 1);
                        } else {
                          _currentDate = DateTime(_currentDate.year + 1);
                        }
                      });
                      _reloadCurrentPeriodData();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 3. Omzet & Financial Summary Gradient Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppStyles.radiusCard),
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
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Omzet Penjualan',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Icon(
                        Icons.insights_rounded,
                        color: Colors.white70,
                        size: 20,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatCurrency(data.totalRevenue),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.6,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Divider(color: Colors.white24, height: 1),
                  const SizedBox(height: 12),

                  // 2 Columns: Komisi Toko vs Hak Penitip
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Laba Komisi Toko',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatCurrency(data.storeCommission),
                            style: const TextStyle(
                              color: Color(0xFF4ADE80),
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'Hak Bersih Penitip',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatCurrency(data.consignorPayout),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Item Terjual & Transaksi Mini Row
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: AppStyles.cardDecoration(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Total Terjual',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${data.totalItemsSold} Item',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: AppStyles.cardDecoration(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Jumlah Transaksi',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${data.totalTransactions} Trx',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 4. Dynamic Chart Section
            ReportChartCard(
              title: _selectedPeriod == ReportPeriod.daily
                  ? 'Grafik Penjualan per Sesi'
                  : (_selectedPeriod == ReportPeriod.monthly
                      ? 'Grafik Penjualan Mingguan'
                      : 'Grafik Penjualan 12 Bulan'),
              bars: data.chartBars,
              yAxisUnit: _selectedPeriod == ReportPeriod.yearly ? 'Jt' : 'k',
            ),
            const SizedBox(height: 20),

            // 5. Produk Terlaris Periode Ini
            Container(
              padding: const EdgeInsets.all(18),
              decoration: AppStyles.cardDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Produk Terlaris',
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
                    itemCount: data.topProducts.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = data.topProducts[index];
                      return Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: index == 0
                                  ? AppColors.primaryTint
                                  : AppColors.surfaceMuted,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: index == 0
                                    ? AppColors.primaryDark
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.name,
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  item.consignor.isEmpty || item.consignor == '-'
                                      ? 'Dagangan Sendiri'
                                      : 'Penitip: ${item.consignor}',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                _formatCurrency(item.revenue),
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                              Text(
                                '${item.quantity} terjual',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 6. Rekapitulasi — pisah dagangan sendiri & penitip
            Builder(builder: (context) {
              final ownItems = data.consignorSummaries
                  .where((c) => c.name == 'Dagangan Sendiri')
                  .toList();
              final penitipItems = data.consignorSummaries
                  .where((c) => c.name != 'Dagangan Sendiri')
                  .toList();

              // Hitung total komisi seluruh penitip & total hak sendiri
              final totalOwnRevenue = ownItems.fold(0, (s, c) => s + c.grossAmount);
              final totalOwnItems   = ownItems.fold(0, (s, c) => s + c.itemsSold);
              final totalComm       = penitipItems.fold(0, (s, c) => s + c.commission);
              final totalPayout     = penitipItems.fold(0, (s, c) => s + c.netAmount);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ── HEADER LABEL ─────────────────────────────
                  const Text(
                    'Rincian Pendapatan',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ── A. DAGANGAN SENDIRI ──────────────────────
                  if (ownItems.isNotEmpty || data.consignorSummaries.isEmpty) ...[
                    Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF16A34A), Color(0xFF15803D)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF16A34A).withValues(alpha: 0.30),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header row
                            Row(
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.store_rounded,
                                      color: Colors.white, size: 22),
                                ),
                                const SizedBox(width: 12),
                                const Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Dagangan Sendiri',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Text(
                                      'Laba 100% masuk kas kamu',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.white70,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Divider
                            Container(height: 1, color: Colors.white24),
                            const SizedBox(height: 14),

                            // Stats row
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Total Item Terjual',
                                          style: TextStyle(
                                              fontSize: 11, color: Colors.white70)),
                                      const SizedBox(height: 4),
                                      Text(
                                        '$totalOwnItems item',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  height: 40,
                                  color: Colors.white24,
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Total Laba Bersih',
                                            style: TextStyle(
                                                fontSize: 11, color: Colors.white70)),
                                        const SizedBox(height: 4),
                                        Text(
                                          _formatCurrency(totalOwnRevenue),
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),

                            // Komisi = 0 tag
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 7, horizontal: 12),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_circle_rounded,
                                      size: 14, color: Colors.white),
                                  SizedBox(width: 6),
                                  Text(
                                    'Tidak ada komisi — semua masuk ke kamu',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ── B. LAPORAN PER MITRA PENITIP ─────────────
                  if (penitipItems.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.fromLTRB(18, 16, 18, 4),
                      decoration: AppStyles.cardDecoration(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Section header
                          Row(
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.people_rounded,
                                    color: AppColors.primary, size: 22),
                              ),
                              const SizedBox(width: 12),
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Rekap per Mitra Penitip',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    'Omzet, komisi, & hak bersih penitip',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          const Divider(height: 1, color: AppColors.border),
                          const SizedBox(height: 12),

                          // Per-penitip cards
                          ...penitipItems.asMap().entries.map((entry) {
                            final idx  = entry.key;
                            final item = entry.value;
                            final pct  = item.grossAmount > 0
                                ? (item.commission / item.grossAmount * 100)
                                    .toStringAsFixed(1)
                                : '0';
                            return Column(
                              children: [
                                if (idx > 0)
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 10),
                                    child: Divider(height: 1, color: AppColors.border),
                                  ),
                                // Name row
                                Row(
                                  children: [
                                    Container(
                                      width: 34,
                                      height: 34,
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryLight,
                                        shape: BoxShape.circle,
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        item.name.isNotEmpty
                                            ? item.name[0].toUpperCase()
                                            : '?',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        item.name,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryLight,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '${item.itemsSold} pcs',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),

                                // Financial breakdown rows
                                _buildFinanceRow(
                                  label: 'Total Omzet',
                                  value: _formatCurrency(item.grossAmount),
                                  valueColor: AppColors.textPrimary,
                                  icon: Icons.trending_up_rounded,
                                  iconColor: AppColors.primary,
                                ),
                                const SizedBox(height: 6),
                                _buildFinanceRow(
                                  label: 'Komisi Toko ($pct%)',
                                  value: '− ${_formatCurrency(item.commission)}',
                                  valueColor: const Color(0xFFEF4444),
                                  icon: Icons.storefront_rounded,
                                  iconColor: const Color(0xFFEF4444),
                                ),
                                const SizedBox(height: 6),
                                // Net payout highlight
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0F766E).withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                        color: const Color(0xFF0F766E)
                                            .withValues(alpha: 0.2)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.account_balance_wallet_rounded,
                                          size: 16, color: Color(0xFF0F766E)),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'Hak Bersih Penitip',
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF0F766E),
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        _formatCurrency(item.netAmount),
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF0F766E),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 10),
                              ],
                            );
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Footer summary total semua penitip
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.primaryDark,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Total Komisi Toko',
                                    style: TextStyle(
                                        fontSize: 11, color: Colors.white60)),
                                const SizedBox(height: 3),
                                Text(
                                  _formatCurrency(totalComm),
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(width: 1, height: 36, color: Colors.white24),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(left: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Total Hak Semua Penitip',
                                      style: TextStyle(
                                          fontSize: 11, color: Colors.white60)),
                                  const SizedBox(height: 3),
                                  Text(
                                    _formatCurrency(totalPayout),
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
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
                ],
              );
            }),
            const SizedBox(height: 24),

            // 7. Daftar Transaksi Harian (Hanya muncul pada mode Per Hari)
            if (_selectedPeriod == ReportPeriod.daily) ...[
              _buildDailyTransactionsSection(),
              const SizedBox(height: 20),
            ],

            // 8. Ekspor & Cetak Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: AppStyles.primaryButtonStyle(),
                onPressed: _onExportReport,
                icon: const Icon(Icons.print_rounded,
                    color: Colors.white, size: 20),
                label: const Text('Cetak & Ekspor Laporan Lengkap'),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildFinanceRow({
    required String label,
    required String value,
    required Color valueColor,
    required IconData icon,
    required Color iconColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 14, color: iconColor),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12.5,
            color: AppColors.textSecondary,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildPeriodTab({
    required ReportPeriod period,
    required String label,
    required IconData icon,
  }) {
    final isSelected = _selectedPeriod == period;

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() => _selectedPeriod = period);
          _reloadCurrentPeriodData();
        },
        borderRadius: BorderRadius.circular(AppStyles.radiusPill),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(AppStyles.radiusPill),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDailyTransactionsSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppStyles.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.receipt_long_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Daftar Transaksi',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '${_dailyTransactionsList.length} transaksi tercatat',
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (_dailyTransactionsList.isNotEmpty)
                TextButton.icon(
                  onPressed: _confirmDeleteDailyReport,
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFDC2626),
                    backgroundColor: const Color(0xFFFEE2E2),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.delete_sweep_rounded, size: 16),
                  label: const Text(
                    'Reset Hari Ini',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 12),
          if (_dailyTransactionsList.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  Icon(Icons.receipt_outlined,
                      size: 40, color: Colors.grey.shade400),
                  const SizedBox(height: 8),
                  Text(
                    'Belum ada transaksi pada tanggal ini',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _dailyTransactionsList.length,
              separatorBuilder: (context, index) =>
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(height: 1, color: AppColors.border),
                  ),
              itemBuilder: (context, index) {
                final tx = _dailyTransactionsList[index];
                final receiptNo = tx['receipt_number'] as String? ?? '-';
                final total = tx['total_amount'] as int? ?? 0;
                final method = (tx['payment_method'] as String? ?? 'tunai').toUpperCase();
                final rawAt = tx['transaction_at'] as String?;
                String timeStr = '';
                if (rawAt != null) {
                  try {
                    final dt = DateTime.parse(rawAt);
                    timeStr = DateFormat('HH:mm').format(dt);
                  } catch (_) {}
                }
                final items = (tx['transaction_items'] as List?) ?? [];

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  method,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                receiptNo,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              color: Color(0xFFDC2626),
                              size: 20,
                            ),
                            tooltip: 'Hapus Transaksi',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => _confirmDeleteSingleTransaction(tx),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Item summary
                      if (items.isNotEmpty)
                        Text(
                          items.map((it) {
                            final q = it['quantity'] ?? 1;
                            final n = it['product_name'] ?? '-';
                            return '${q}x $n';
                          }).join(', '),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (timeStr.isNotEmpty)
                            Row(
                              children: [
                                const Icon(Icons.access_time_rounded,
                                    size: 13, color: AppColors.textMuted),
                                const SizedBox(width: 4),
                                Text(
                                  '$timeStr WIB',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            )
                          else
                            const SizedBox(),
                          Text(
                            _formatCurrency(total),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
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
    );
  }
}
