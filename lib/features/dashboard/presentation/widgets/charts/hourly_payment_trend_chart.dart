import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile/features/dashboard/data/models/dashboard_chart_model.dart';
import 'dart:math';

import '../../../../../core/theme/app_colors.dart';

class HourlyPaymentTrendChart extends StatelessWidget {
  final List<HourlyStat> hourlyStats;

  const HourlyPaymentTrendChart({super.key, required this.hourlyStats});

  @override
  Widget build(BuildContext context) {
    if (hourlyStats.isEmpty) return const Center(child: Text("Veri yok"));

    // Max Y değerini bul
    double maxY = 0;
    for (var stat in hourlyStats) {
      maxY = max(maxY, stat.hourlyCash);
      maxY = max(maxY, stat.hourlyCard);
    }
    maxY = maxY == 0 ? 100 : maxY * 1.2;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Ödeme Akışı",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              // Legend
              Row(
                children: [
                  _buildLegendItem(AppColors.accent, "Nakit"),
                  const SizedBox(width: 12),
                  _buildLegendItem(Colors.purple, "Kart"),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Grafik
          Expanded(
            // aspectRatio: 1.70,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY / 5,
                  getDrawingHorizontalLine:
                      (value) => FlLine(
                        color: Colors.grey.withOpacity(0.1),
                        strokeWidth: 1,
                      ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 4,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < hourlyStats.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              hourlyStats[index].hourLabel.split(':')[0],
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: false,
                    ), // Soldaki sayıları gizledim (daha sade)
                  ),
                ),
                borderData: FlBorderData(show: false),

                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (touchedSpot) => Colors.blueGrey.shade900,
                    getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                      return touchedBarSpots.map((barSpot) {
                        final isCash = barSpot.barIndex == 0;
                        final color =
                            isCash
                                ? AppColors.accent.withOpacity(0.8)
                                : Colors.purple.withOpacity(0.8);
                        final label = isCash ? "Nakit:" : "Kart:";

                        return LineTooltipItem(
                          "$label ₺${NumberFormat('#,##0').format(barSpot.y)} \n",
                          TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),

                lineBarsData: [
                  // 1. Çizgi: NAKİT (Turuncu)
                  LineChartBarData(
                    spots:
                        hourlyStats.asMap().entries.map((e) {
                          return FlSpot(e.key.toDouble(), e.value.hourlyCash);
                        }).toList(),
                    isCurved: true,
                    color: AppColors.accent,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                  ),
                  // 2. Çizgi: KART (Mor)
                  LineChartBarData(
                    spots:
                        hourlyStats.asMap().entries.map((e) {
                          return FlSpot(e.key.toDouble(), e.value.hourlyCard);
                        }).toList(),
                    isCurved: true,
                    color: Colors.purple,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
