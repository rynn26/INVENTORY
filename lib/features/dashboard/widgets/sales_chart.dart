import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';

class SalesChartSection extends StatelessWidget {
  const SalesChartSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: AppStyles.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Penjualan Hari Ini',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),

          // Chart area
          SizedBox(
            height: 160,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Y-Axis Labels
                const SizedBox(
                  width: 38,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '100k',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '50k',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '0',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                // Chart Grid & Bars
                Expanded(
                  child: Stack(
                    children: [
                      // Background dotted/subtle horizontal lines
                      Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            height: 1,
                            color: AppColors.surfaceMuted,
                          ),
                          Container(
                            height: 1,
                            color: AppColors.surfaceMuted,
                          ),
                          Container(
                            height: 1,
                            color: const Color(0xFFE2E8F0),
                          ),
                        ],
                      ),

                      // Chart Bars
                      Positioned.fill(
                        bottom: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            _buildBar(height: 55, label: 'Pagi', isActive: false),
                            _buildBar(height: 110, label: 'Siang', isActive: false),
                            _buildBar(height: 135, label: 'Sore', isActive: true),
                            _buildBar(height: 30, label: 'Malam', isActive: false),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // X-Axis Labels Row
          Padding(
            padding: const EdgeInsets.only(left: 38),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildXLabel('Pagi', false),
                _buildXLabel('Siang', false),
                _buildXLabel('Sore', true),
                _buildXLabel('Malam', false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBar({
    required double height,
    required String label,
    required bool isActive,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 22,
          height: height,
          decoration: BoxDecoration(
            gradient: isActive
                ? const LinearGradient(
                    colors: [Color(0xFF00B048), AppColors.primaryDark],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  )
                : const LinearGradient(
                    colors: [Color(0xFFCBD5E1), Color(0xFFE2E8F0)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildXLabel(String label, bool isActive) {
    return SizedBox(
      width: 44,
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
          color: isActive ? AppColors.primary : AppColors.textSecondary,
        ),
      ),
    );
  }
}
