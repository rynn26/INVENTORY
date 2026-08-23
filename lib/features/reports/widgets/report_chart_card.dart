import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../models/report_data.dart';

class ReportChartCard extends StatelessWidget {
  final String title;
  final List<ChartBarData> bars;
  final String yAxisUnit;

  const ReportChartCard({
    super.key,
    required this.title,
    required this.bars,
    this.yAxisUnit = 'k',
  });

  @override
  Widget build(BuildContext context) {
    final maxValue = bars.fold<double>(
      0,
      (max, bar) => bar.value > max ? bar.value : max,
    );
    final safeMax = maxValue > 0 ? maxValue : 1.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: AppStyles.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Satuan ($yAxisUnit)',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Chart Graph Area
          SizedBox(
            height: 160,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Y-Axis reference numbers
                SizedBox(
                  width: 38,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${safeMax.toInt()}$yAxisUnit',
                        style: const TextStyle(
                          fontSize: 10.5,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${(safeMax / 2).toInt()}$yAxisUnit',
                        style: const TextStyle(
                          fontSize: 10.5,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '0$yAxisUnit',
                        style: const TextStyle(
                          fontSize: 10.5,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                // Bars container
                Expanded(
                  child: Stack(
                    children: [
                      // Horizontal gridlines
                      Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(height: 1, color: AppColors.surfaceMuted),
                          Container(height: 1, color: AppColors.surfaceMuted),
                          Container(height: 1, color: const Color(0xFFCBD5E1)),
                        ],
                      ),

                      // Animated Dynamic Bars
                      Positioned.fill(
                        bottom: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: bars.map((bar) {
                            final ratio = (bar.value / safeMax).clamp(0.08, 1.0);
                            final barHeight = 135 * ratio;

                            return Tooltip(
                              message: '${bar.label}: ${bar.tooltipText}',
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 400),
                                    width: bars.length > 6 ? 14 : 24,
                                    height: barHeight,
                                    decoration: BoxDecoration(
                                      gradient: bar.isHighlight
                                          ? const LinearGradient(
                                              colors: [
                                                Color(0xFF00B048),
                                                AppColors.primaryDark
                                              ],
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                            )
                                          : const LinearGradient(
                                              colors: [
                                                Color(0xFF94A3B8),
                                                Color(0xFFCBD5E1)
                                              ],
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                            ),
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(5),
                                      ),
                                      boxShadow: bar.isHighlight
                                          ? [
                                              BoxShadow(
                                                color: AppColors.primary
                                                    .withValues(alpha: 0.35),
                                                blurRadius: 6,
                                                offset: const Offset(0, 2),
                                              ),
                                            ]
                                          : null,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
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
              children: bars.map((bar) {
                return SizedBox(
                  width: bars.length > 6 ? 22 : 44,
                  child: Text(
                    bar.label,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: bars.length > 6 ? 9.5 : 11,
                      fontWeight:
                          bar.isHighlight ? FontWeight.w700 : FontWeight.w500,
                      color: bar.isHighlight
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
