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

  // Data harian dari Supabase
  int _dailyRevenue = 0;
  int _dailyItemsSold = 0;
  int _dailyTransactions = 0;
  List<TopSoldItem> _dailyTopProducts = [];
  List<ConsignorSalesSummary> _dailyConsignors = [];

  @override
  void initState() {
    super.initState();
    _loadDailyData();
  }

  Future<void> _loadDailyData() async {
    try {
      final summary = await TransactionService.fetchTodaySummary();
      final txList = await TransactionService.fetchTodayTransactions();

      // Hitung per-produk & per-penitip
      final Map<String, Map<String, dynamic>> productMap = {};
      for (final tx in txList) {
        final items = tx['transaction_items'] as List? ?? [];
        for (final item in items) {
          final name = item['product_name'] as String;
          final penitip = item['penitip_name'] as String;
          final qty = item['quantity'] as int;
          final subtotal = item['subtotal'] as int;
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

      // Top 3 produk
      final sortedProducts = productMap.entries.toList()
        ..sort((a, b) => (b.value['qty'] as int).compareTo(a.value['qty'] as int));

      // Per penitip
      final Map<String, Map<String, dynamic>> penitipMap = {};
      for (final entry in productMap.entries) {
        final p = entry.value['penitip'] as String;
        if (!penitipMap.containsKey(p)) {
          penitipMap[p] = {'qty': 0, 'revenue': 0};
        }
        penitipMap[p]!['qty'] =
            (penitipMap[p]!['qty'] as int) + (entry.value['qty'] as int);
        penitipMap[p]!['revenue'] =
            (penitipMap[p]!['revenue'] as int) + (entry.value['revenue'] as int);
      }

      if (!mounted) return;
      setState(() {
        _dailyRevenue = summary.totalRevenue;
        _dailyItemsSold = summary.totalItemsSold;
        _dailyTransactions = summary.totalTransactions;
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
          const rate = 10;
          final comm = (gross * rate / 100).round();
          return ConsignorSalesSummary(
            name: e.key,
            itemsSold: e.value['qty'] as int,
            grossAmount: gross,
            commission: comm,
            netAmount: gross - comm,
          );
        }).toList();
      });
    } catch (_) {
      // Tetap tampilkan 0 jika error
    }
  }

  String _formatCurrency(int amount) {
    return CurrencyFormatter.format(amount);
  }

  // Data laporan
  ReportData get _currentReportData {
    switch (_selectedPeriod) {
      case ReportPeriod.daily:
        return ReportData(
          periodTitle: 'Laporan Penjualan Harian',
          periodSubtitle: DateFormat('EEEE, dd MMMM yyyy', 'id_ID')
              .format(_currentDate),
          totalRevenue: _dailyRevenue,
          storeCommission: (_dailyRevenue * 0.1).round(),
          consignorPayout: (_dailyRevenue * 0.9).round(),
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
        return ReportData(
          periodTitle: 'Laporan Penjualan Bulanan',
          periodSubtitle:
              DateFormat('MMMM yyyy', 'id_ID').format(_currentDate),
          totalRevenue: 6850000,
          storeCommission: 685000, // 10%
          consignorPayout: 6165000, // 90%
          totalItemsSold: 890,
          totalTransactions: 540,
          chartBars: const [
            ChartBarData(
              label: 'Mg 1',
              value: 1550,
              tooltipText: 'Rp 1.550.000',
            ),
            ChartBarData(
              label: 'Mg 2',
              value: 1720,
              tooltipText: 'Rp 1.720.000',
            ),
            ChartBarData(
              label: 'Mg 3',
              value: 1980,
              tooltipText: 'Rp 1.980.000',
              isHighlight: true,
            ),
            ChartBarData(
              label: 'Mg 4',
              value: 1600,
              tooltipText: 'Rp 1.600.000',
            ),
          ],
          topProducts: const [
            TopSoldItem(
              name: 'Risol Mayo',
              consignor: 'Bu Siti',
              quantity: 410,
              revenue: 2050000,
            ),
            TopSoldItem(
              name: 'Rice Bowl Ayam',
              consignor: 'Dapur Mama',
              quantity: 260,
              revenue: 2600000,
            ),
            TopSoldItem(
              name: 'Donat Coklat',
              consignor: 'Pak Budi',
              quantity: 220,
              revenue: 770000,
            ),
          ],
          consignorSummaries: const [
            ConsignorSalesSummary(
              name: 'Bu Siti',
              itemsSold: 410,
              grossAmount: 2050000,
              commission: 205000,
              netAmount: 1845000,
            ),
            ConsignorSalesSummary(
              name: 'Dapur Mama',
              itemsSold: 260,
              grossAmount: 2600000,
              commission: 260000,
              netAmount: 2340000,
            ),
            ConsignorSalesSummary(
              name: 'Pak Budi',
              itemsSold: 220,
              grossAmount: 770000,
              commission: 77000,
              netAmount: 693000,
            ),
          ],
        );

      case ReportPeriod.yearly:
        return ReportData(
          periodTitle: 'Laporan Penjualan Tahunan',
          periodSubtitle: 'Tahun ${_currentDate.year}',
          totalRevenue: 78400000,
          storeCommission: 7840000, // 10%
          consignorPayout: 70560000, // 90%
          totalItemsSold: 10450,
          totalTransactions: 6200,
          chartBars: const [
            ChartBarData(label: 'Jan', value: 5.8, tooltipText: 'Rp 5.8 Juta'),
            ChartBarData(label: 'Feb', value: 6.2, tooltipText: 'Rp 6.2 Juta'),
            ChartBarData(label: 'Mar', value: 7.0, tooltipText: 'Rp 7.0 Juta'),
            ChartBarData(label: 'Apr', value: 6.5, tooltipText: 'Rp 6.5 Juta'),
            ChartBarData(label: 'Mei', value: 7.2, tooltipText: 'Rp 7.2 Juta'),
            ChartBarData(label: 'Jun', value: 6.8, tooltipText: 'Rp 6.8 Juta'),
            ChartBarData(label: 'Jul', value: 7.4, tooltipText: 'Rp 7.4 Juta'),
            ChartBarData(
              label: 'Agu',
              value: 8.1,
              tooltipText: 'Rp 8.1 Juta',
              isHighlight: true,
            ),
            ChartBarData(label: 'Sep', value: 6.9, tooltipText: 'Rp 6.9 Juta'),
            ChartBarData(label: 'Okt', value: 7.5, tooltipText: 'Rp 7.5 Juta'),
            ChartBarData(label: 'Nov', value: 7.8, tooltipText: 'Rp 7.8 Juta'),
            ChartBarData(label: 'Des', value: 8.5, tooltipText: 'Rp 8.5 Juta'),
          ],
          topProducts: const [
            TopSoldItem(
              name: 'Risol Mayo',
              consignor: 'Bu Siti',
              quantity: 4800,
              revenue: 24000000,
            ),
            TopSoldItem(
              name: 'Rice Bowl Ayam',
              consignor: 'Dapur Mama',
              quantity: 3100,
              revenue: 31000000,
            ),
            TopSoldItem(
              name: 'Donat Coklat',
              consignor: 'Pak Budi',
              quantity: 2550,
              revenue: 8925000,
            ),
          ],
          consignorSummaries: const [
            ConsignorSalesSummary(
              name: 'Bu Siti',
              itemsSold: 4800,
              grossAmount: 24000000,
              commission: 2400000,
              netAmount: 21600000,
            ),
            ConsignorSalesSummary(
              name: 'Dapur Mama',
              itemsSold: 3100,
              grossAmount: 31000000,
              commission: 3100000,
              netAmount: 27900000,
            ),
            ConsignorSalesSummary(
              name: 'Pak Budi',
              itemsSold: 2550,
              grossAmount: 8925000,
              commission: 892500,
              netAmount: 8032500,
            ),
          ],
        );
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
          await Future.delayed(const Duration(milliseconds: 500));
          if (!mounted) return;
          setState(() {});
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
            const SizedBox(height: 16),

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
                            'Laba Komisi Toko (10%)',
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
                            'Hak Bersih Penitip (90%)',
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
                                  'Penitip: ${item.consignor}',
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

            // 6. Rekapitulasi per Mitra Penitip
            Container(
              padding: const EdgeInsets.all(18),
              decoration: AppStyles.cardDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Rekapitulasi Penjualan per Mitra',
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
                    itemCount: data.consignorSummaries.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 16),
                    itemBuilder: (context, index) {
                      final item = data.consignorSummaries[index];
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${item.itemsSold} pcs terjual',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                _formatCurrency(item.netAmount),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                ),
                              ),
                              Text(
                                'Komisi: ${_formatCurrency(item.commission)}',
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
            const SizedBox(height: 24),

            // 7. Ekspor & Cetak Button
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

  Widget _buildPeriodTab({
    required ReportPeriod period,
    required String label,
    required IconData icon,
  }) {
    final isSelected = _selectedPeriod == period;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedPeriod = period),
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
}
