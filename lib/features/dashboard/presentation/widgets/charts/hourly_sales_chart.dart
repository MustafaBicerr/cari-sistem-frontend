import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile/features/dashboard/data/models/dashboard_chart_model.dart';
import 'dart:math';
import '../../../../../core/theme/app_colors.dart';

class HourlySalesChart extends StatelessWidget {
  final List<HourlyStat> hourlyStats;

  const HourlySalesChart({super.key, required this.hourlyStats});

  @override
  Widget build(BuildContext context) {
    if (hourlyStats.isEmpty) {
      return const Center(child: Text("Veri yok"));
    }

    // Maksimum Y değerini bulurken 3 veriyi de kontrol ediyoruz
    double maxY = 0;
    for (var stat in hourlyStats) {
      maxY = max(maxY, stat.totalSalesVolume);
      maxY = max(maxY, stat.salesCashFlow); // 🟢 Satıştan Gelen
      maxY = max(maxY, stat.collectionCashFlow); // 🟠 Tahsilattan Gelen
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
          // 1. BAŞLIK VE LEGEND
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Saatlik Satış Grafiği",
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      "Bugün",
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Legend (3 Kalem)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildLegendItem(Colors.blue, "Toplam Satış Miktarı"),
                  const SizedBox(height: 4),
                  _buildLegendItem(Colors.green, "Peşin Satış Miktarı"),
                  const SizedBox(height: 4),
                  _buildLegendItem(
                    Colors.orange,
                    "Borç/Tahsilat Ödemeleri",
                  ), // 🟠 Yeni
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 2. GRAFİK ALANI
          Expanded(
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY / 4,
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
                      reservedSize: 24,
                      interval: 4,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < hourlyStats.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              hourlyStats[index].hourLabel.split(':')[0],
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 10,
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
                      showTitles: true,
                      reservedSize: 35,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const Text('');
                        if (value >= 1000) {
                          return Text(
                            '${(value / 1000).toStringAsFixed(1)}k',
                            style: const TextStyle(
                              fontSize: 9,
                              color: AppColors.textSecondary,
                            ),
                          );
                        }
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(
                            fontSize: 9,
                            color: AppColors.textSecondary,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),

                // TOOLTIP AYARLARI (3 Satırlı)
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (spot) => Colors.blueGrey.shade900,
                    getTooltipItems:
                        (spots) =>
                            spots.map((spot) {
                              Color color = Colors.white;
                              String label = "";

                              // Index'e göre renk ve isim belirle
                              if (spot.barIndex == 0) {
                                color = Colors.blue.shade200;
                                label = "Satış";
                              } else if (spot.barIndex == 1) {
                                color = Colors.green.shade200;
                                label = "Kasa";
                              } else if (spot.barIndex == 2) {
                                color = Colors.orange.shade200;
                                label = "Tahsilat";
                              }

                              return LineTooltipItem(
                                "$label: ₺${NumberFormat('#,##0').format(spot.y)}",
                                TextStyle(
                                  color: color,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            }).toList(),
                  ),
                ),

                lineBarsData: [
                  // 🔵 1. Çizgi: Toplam Satış Hacmi
                  LineChartBarData(
                    spots:
                        hourlyStats
                            .asMap()
                            .entries
                            .map(
                              (e) => FlSpot(
                                e.key.toDouble(),
                                e.value.totalSalesVolume,
                              ),
                            )
                            .toList(),
                    isCurved: true,
                    color: Colors.blue,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          Colors.blue.withOpacity(0.2),
                          Colors.transparent,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),

                  // 🟢 2. Çizgi: Satıştan Gelen Nakit
                  LineChartBarData(
                    spots:
                        hourlyStats
                            .asMap()
                            .entries
                            .map(
                              (e) => FlSpot(
                                e.key.toDouble(),
                                e.value.salesCashFlow,
                              ),
                            )
                            .toList(),
                    isCurved: true,
                    color: Colors.green,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(show: false),
                  ),

                  // 🟠 3. Çizgi: Tahsilat (Collection)
                  LineChartBarData(
                    spots:
                        hourlyStats
                            .asMap()
                            .entries
                            .map(
                              (e) => FlSpot(
                                e.key.toDouble(),
                                e.value.collectionCashFlow,
                              ),
                            )
                            .toList(),
                    isCurved: true,
                    color: Colors.orange,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(show: false),
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
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
