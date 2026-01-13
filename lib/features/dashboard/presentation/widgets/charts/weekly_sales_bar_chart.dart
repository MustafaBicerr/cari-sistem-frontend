import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile/features/dashboard/data/models/dashboard_chart_model.dart';
import 'dart:math';
import '../../../../../core/theme/app_colors.dart';

class WeeklySalesBarChart extends StatelessWidget {
  final List<WeeklyStat> weeklyStats;

  const WeeklySalesBarChart({super.key, required this.weeklyStats});

  @override
  Widget build(BuildContext context) {
    if (weeklyStats.isEmpty) return const Center(child: Text("Veri yok"));

    double maxY = 0;
    for (var stat in weeklyStats) {
      maxY = max(maxY, stat.totalSales);
      maxY = max(maxY, stat.salesCash);
      maxY = max(maxY, stat.collectionCash);
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
          // BAŞLIK
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Haftalık Performans",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              // Legend
              Expanded(
                // Legend sığmazsa taşmasın diye
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _buildLegendItem(Colors.blue, "Satış"),
                    const SizedBox(width: 8),
                    _buildLegendItem(Colors.green, "Peşin"),
                    const SizedBox(width: 8),
                    _buildLegendItem(Colors.orange, "Tahsilat"),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // GRAFİK
          AspectRatio(
            aspectRatio: 2.6,
            child: BarChart(
              BarChartData(
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY / 5,
                  getDrawingHorizontalLine:
                      (v) => FlLine(
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

                  // 🔥 X EKSENİ AYARLARI (GÜNCELLENDİ)
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize:
                          50, // İki satır olduğu için alanı genişlettik (30 -> 50)
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < weeklyStats.length) {
                          final stat = weeklyStats[index];
                          final trDayName = _getTurkishDayName(stat.dayName);

                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              "${stat.shortDate}\n$trDayName", // Tarih üstte, Gün altta
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                height: 1.2, // Satır arası boşluk
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
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const Text('');
                        if (value >= 1000) {
                          return Text(
                            '${(value / 1000).toStringAsFixed(1)}k',
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.textSecondary,
                            ),
                          );
                        }
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),

                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => Colors.blueGrey.shade900,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      String label = "";
                      if (rodIndex == 0)
                        label = "Satış";
                      else if (rodIndex == 1)
                        label = "Kasa";
                      else
                        label = "Tahsilat";

                      return BarTooltipItem(
                        "$label\n",
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        children: [
                          TextSpan(
                            text: "₺${NumberFormat('#,##0').format(rod.toY)}",
                            style: TextStyle(
                              color: rod.color,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),

                barGroups:
                    weeklyStats.asMap().entries.map((e) {
                      final index = e.key;
                      final stat = e.value;
                      return BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: stat.totalSales,
                            color: Colors.blue,
                            width: 8,
                            borderRadius: BorderRadius.circular(2),
                          ),
                          BarChartRodData(
                            toY: stat.salesCash,
                            color: Colors.green,
                            width: 8,
                            borderRadius: BorderRadius.circular(2),
                          ),
                          BarChartRodData(
                            toY: stat.collectionCash,
                            color: Colors.orange,
                            width: 8,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ],
                        barsSpace: 4,
                      );
                    }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // İngilizce gelen gün adlarını Türkçeye çevirir
  String _getTurkishDayName(String dayName) {
    // Gelen veri bazen boşluklu olabiliyor ("Monday   " gibi), trim() önemli.
    final cleanName = dayName.trim();
    switch (cleanName) {
      case 'Monday':
        return 'Pazartesi';
      case 'Tuesday':
        return 'Salı';
      case 'Wednesday':
        return 'Çarşamba';
      case 'Thursday':
        return 'Perşembe';
      case 'Friday':
        return 'Cuma';
      case 'Saturday':
        return 'Cumartesi';
      case 'Sunday':
        return 'Pazar';
      default:
        return cleanName.substring(
          0,
          min(3, cleanName.length),
        ); // Bilinmiyorsa ilk 3 harf
    }
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
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
