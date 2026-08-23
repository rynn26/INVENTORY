import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/transaction_service.dart';
import '../../../models/dashboard_data.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import '../../reports/screens/reports_screen.dart';
import '../widgets/quick_actions.dart';
import '../widgets/sales_chart.dart';
import '../widgets/stat_cards.dart';
import '../widgets/top_products.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback? onNavigateToKasir;
  final VoidCallback? onNavigateToProduk;
  final VoidCallback? onNavigateToStok;
  final VoidCallback? onNavigateToPenitip;

  const DashboardScreen({
    super.key,
    this.onNavigateToKasir,
    this.onNavigateToProduk,
    this.onNavigateToStok,
    this.onNavigateToPenitip,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  StatSummary _statSummary = const StatSummary(
    todayRevenue: 0,
    itemsSold: 0,
    transactions: 0,
    remainingStock: 0,
  );

  List<TopProduct> _topProducts = const [];

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final summary = await TransactionService.fetchTodaySummary();
      // Top produk dari transaksi hari ini
      final txList = await TransactionService.fetchTodayTransactions();

      // Hitung top produk dari item transaksi
      final Map<String, int> soldMap = {};
      final Map<String, int> priceMap = {};
      for (final tx in txList) {
        final items = tx['transaction_items'] as List? ?? [];
        for (final item in items) {
          final name = item['product_name'] as String;
          final qty = item['quantity'] as int;
          final price = item['unit_price'] as int;
          soldMap[name] = (soldMap[name] ?? 0) + qty;
          priceMap[name] = price;
        }
      }
      final sorted = soldMap.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final top = sorted.take(3).toList();

      if (!mounted) return;
      setState(() {
        _statSummary = StatSummary(
          todayRevenue: summary.totalRevenue,
          itemsSold: summary.totalItemsSold,
          transactions: summary.totalTransactions,
          remainingStock: 0,
        );
        _topProducts = top
            .asMap()
            .entries
            .map((e) => TopProduct(
                  rank: e.key + 1,
                  name: e.value.key,
                  soldCount: e.value.value,
                  price: priceMap[e.value.key] ?? 0,
                ))
            .toList();
      });
    } catch (_) {
      // Tetap tampilkan 0 jika gagal
    }
  }

  // Format tanggal hari ini
  String get _todayLabel {
    return DateFormat('EEEE, dd MMM', 'id_ID').format(DateTime.now());
  }

  void _showActionFeedback(String title, String message, IconData icon) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.primary, size: 36),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13.5,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text(
                  'Tutup',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
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
      appBar: CustomAppBar(
        title: 'TitipKasir',
        onProfileTap: () {
          _showActionFeedback(
            'Profil Kasir',
            'Kasir Utama sedang aktif pada shift pagi-sore.',
            Icons.person_outline_rounded,
          );
        },
        onNotificationTap: () {
          _showActionFeedback(
            'Notifikasi',
            'Belum ada notifikasi baru hari ini.',
            Icons.notifications_none_rounded,
          );
        },
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Selamat datang ',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '👋',
                            style: TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Halo, Kasir Utama',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.4,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    _todayLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Metric Cards Section (Tap Stok Tersisa navigates to Stok)
              InkWell(
                onTap: widget.onNavigateToStok,
                borderRadius: BorderRadius.circular(16),
                child: StatCardsSection(
                  todayRevenue: _statSummary.todayRevenue,
                  itemsSold: _statSummary.itemsSold,
                  transactions: _statSummary.transactions,
                  remainingStock: _statSummary.remainingStock,
                ),
              ),
              const SizedBox(height: 22),

              // Aksi Cepat Section
              QuickActionsSection(
                onScanBarcode: () {
                  if (widget.onNavigateToKasir != null) {
                    widget.onNavigateToKasir!();
                  } else {
                    _showActionFeedback(
                      'Scan Barcode',
                      'Beralih ke layar scanner barcode.',
                      Icons.qr_code_scanner_rounded,
                    );
                  }
                },
                onAddTitipan: () {
                  if (widget.onNavigateToPenitip != null) {
                    widget.onNavigateToPenitip!();
                  } else {
                    _showActionFeedback(
                      'Tambah Titipan',
                      'Beralih ke halaman daftar mitra penitip.',
                      Icons.add_box_outlined,
                    );
                  }
                },
                onAddProduct: () {
                  if (widget.onNavigateToProduk != null) {
                    widget.onNavigateToProduk!();
                  } else {
                    _showActionFeedback(
                      'Tambah Produk',
                      'Beralih ke halaman katalog produk.',
                      Icons.category_outlined,
                    );
                  }
                },
                onViewReport: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ReportsScreen(isModalMode: true),
                    ),
                  );
                },
              ),
              const SizedBox(height: 22),

              // Top Selling Products Section
              TopProductsSection(
                products: _topProducts,
                onViewAll: () {
                  if (widget.onNavigateToProduk != null) {
                    widget.onNavigateToProduk!();
                  }
                },
              ),
              const SizedBox(height: 20),

              // Sales Chart Section
              const SalesChartSection(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
