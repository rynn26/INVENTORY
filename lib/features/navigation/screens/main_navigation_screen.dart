import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../../models/cart_item.dart';
import '../../pos/screens/cart_shopee_screen.dart';
import '../../pos/screens/pos_scanner_screen.dart';
import '../../stock/screens/stock_inventory_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  // Shared cart state across tabs
  final List<CartItem> _sharedCart = [
    CartItem(
      id: '1',
      name: 'Risol Mayo',
      price: 5000,
      quantity: 2,
      imageUrl:
          'https://images.unsplash.com/photo-1541592106381-b31e9677c0e5?auto=format&fit=crop&w=200&q=80',
      penitipName: 'Bu Siti',
    ),
    CartItem(
      id: '2',
      name: 'Donat Coklat',
      price: 5000,
      quantity: 1,
      imageUrl:
          'https://images.unsplash.com/photo-1527515862127-a4fc05baf7a5?auto=format&fit=crop&w=200&q=80',
      penitipName: 'Pak Budi',
    ),
  ];

  int get _totalCartItems =>
      _sharedCart.fold(0, (sum, item) => sum + item.quantity);

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      const PosScannerScreen(),
      CartShopeeScreen(
        cartItems: _sharedCart,
        onCartUpdated: (updated) {
          setState(() {});
        },
      ),
      const StockInventoryScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(
            top: BorderSide(
              color: AppColors.divider,
              width: 1.2,
            ),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                index: 0,
                label: 'Jualan / POS',
                icon: Icons.point_of_sale_rounded,
              ),
              _buildCartNavItem(
                index: 1,
                label: 'Keranjang',
                icon: Icons.shopping_cart_outlined,
                badgeCount: _totalCartItems,
              ),
              _buildNavItem(
                index: 2,
                label: 'Stok Titipan',
                icon: Icons.inventory_2_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required String label,
    required IconData icon,
  }) {
    final isSelected = _currentIndex == index;

    if (isSelected) {
      return InkWell(
        onTap: () => setState(() => _currentIndex = index),
        borderRadius: BorderRadius.circular(AppStyles.radiusPill),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(AppStyles.radiusPill),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: AppColors.primary,
                size: 22,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: AppColors.textMuted,
              size: 22,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartNavItem({
    required int index,
    required String label,
    required IconData icon,
    required int badgeCount,
  }) {
    final isSelected = _currentIndex == index;

    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      borderRadius: BorderRadius.circular(AppStyles.radiusPill),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
        decoration: isSelected
            ? BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(AppStyles.radiusPill),
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  color: isSelected ? AppColors.primary : AppColors.textMuted,
                  size: 22,
                ),
                if (badgeCount > 0)
                  Positioned(
                    top: -4,
                    right: -8,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: AppColors.danger,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '$badgeCount',
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
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
