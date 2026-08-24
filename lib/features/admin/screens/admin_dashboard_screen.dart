import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../../core/services/penitip_service.dart';
import '../../../core/services/product_service.dart';
import '../../../core/services/transaction_service.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import '../../penitip/screens/penitip_list_screen.dart';
import '../../product/screens/product_list_screen.dart';
import '../../reports/screens/reports_screen.dart';
import '../../stock/screens/stock_inventory_screen.dart';
import 'barcode_generator_screen.dart';
import 'admin_settlement_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _isLoadingSummary = true;
  int _totalGross = 0;
  int _totalCommission = 0;
  int _totalNetPayout = 0;
  int _activeProductCount = 0;
  int _activePenitipCount = 0;

  @override
  void initState() {
    super.initState();
    _loadFinancialSummary();
  }

  Future<void> _loadFinancialSummary() async {
    try {
      final results = await Future.wait([
        TransactionService.fetchOverallFinancialSummary(),
        ProductService.fetchAll(),
        PenitipService.fetchAll(),
      ]);

      final summary = results[0] as Map<String, int>;
      final products = results[1] as List;
      final penitips = results[2] as List;

      if (!mounted) return;
      setState(() {
        _totalGross = summary['gross'] ?? 0;
        _totalCommission = summary['commission'] ?? 0;
        _totalNetPayout = summary['netPayout'] ?? 0;
        _activeProductCount = products.length;
        _activePenitipCount = penitips.length;
        _isLoadingSummary = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingSummary = false);
    }
  }

  String _formatCurrency(int amount) {
    return CurrencyFormatter.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(
        title: 'Admin Control Center',
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: Colors.white,
          onRefresh: () async {
            setState(() => _isLoadingSummary = true);
            await _loadFinancialSummary();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              // Admin Greeting Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppStyles.radiusCard),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.shield_outlined,
                                color: Color(0xFF4ADE80), size: 18),
                            SizedBox(width: 6),
                            Text(
                              'Panel Pemilik & Administrator',
                              style: TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Owner Toko',
                            style: TextStyle(
                              color: Color(0xFF4ADE80),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Ringkasan Keuangan Toko',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _isLoadingSummary
                        ? const SizedBox(
                            height: 32,
                            width: 32,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Text(
                            _formatCurrency(_totalGross),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.6,
                            ),
                          ),
                    const SizedBox(height: 12),
                    const Divider(color: Color(0xFF334155), height: 1),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Komisi Toko',
                              style: TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 11.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _isLoadingSummary ? '—' : _formatCurrency(_totalCommission),
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
                              'Hak Bersih Mitra',
                              style: TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 11.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _isLoadingSummary ? '—' : _formatCurrency(_totalNetPayout),
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
              const SizedBox(height: 24),

              // Highlight Feature: Generate Barcode
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BarcodeGeneratorScreen(),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(AppStyles.radiusCard),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(AppStyles.radiusCard),
                    border:
                        Border.all(color: AppColors.primary, width: 1.6),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.qr_code_2_rounded,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Generate & Cetak Barcode Produk',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primaryDark,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Buat label barcode makanan titipan untuk discan kasir',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF334155),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: AppColors.primary,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Admin Action Grid
              const Text(
                'Manajemen Toko & Konsinyasi',
                style: TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _buildMenuCard(
                      context: context,
                      icon: Icons.grid_view_rounded,
                      title: 'Master Produk',
                      subtitle: _isLoadingSummary
                          ? 'Memuat...'
                          : '$_activeProductCount produk aktif',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ProductListScreen(),
                          ),
                        ).then((_) => _loadFinancialSummary());
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMenuCard(
                      context: context,
                      icon: Icons.inventory_2_rounded,
                      title: 'Stok Fisik',
                      subtitle: 'Pantau stok menipis',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const StockInventoryScreen(isModalMode: true),
                          ),
                        ).then((_) => _loadFinancialSummary());
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _buildMenuCard(
                      context: context,
                      icon: Icons.handshake_outlined,
                      title: 'Mitra Penitip',
                      subtitle: _isLoadingSummary
                          ? 'Memuat...'
                          : '$_activePenitipCount mitra terdaftar',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const PenitipListScreen(isModalMode: true),
                          ),
                        ).then((_) => _loadFinancialSummary());
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMenuCard(
                      context: context,
                      icon: Icons.account_balance_wallet_rounded,
                      title: 'Bagi Hasil Mitra',
                      subtitle: 'Settlement komisi',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const AdminSettlementScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Full Width Menu: Laporan Keuangan Harian/Bulanan/Tahunan
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ReportsScreen(isModalMode: true),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(AppStyles.radiusCard),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: AppStyles.cardDecoration(),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.bar_chart_rounded,
                          color: AppColors.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Laporan Keuangan & Penjualan',
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Rekapitulasi Harian, Bulanan & Tahunan',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.textMuted,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildMenuCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppStyles.radiusCard),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: AppStyles.cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.primary, size: 22),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 11.5,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
