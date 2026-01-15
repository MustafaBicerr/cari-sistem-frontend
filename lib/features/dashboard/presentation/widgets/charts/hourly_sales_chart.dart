import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile/features/dashboard/data/models/dashboard_chart_model.dart';
import 'dart:math';
import '../../../../../core/theme/app_colors.dart';

class HourlySalesChart extends StatefulWidget {
  final List<HourlyStat> hourlyStats;
  // Scroll Kilidi İçin Callback
  final Function(bool isHovering)? onHover;

  const HourlySalesChart({super.key, required this.hourlyStats, this.onHover});

  @override
  State<HourlySalesChart> createState() => _HourlySalesChartState();
}

class _HourlySalesChartState extends State<HourlySalesChart> {
  // Zoom ve Pan State
  double _minX = 0;
  double _maxX = 24; // 23 yerine 24 yaptık ki 23:59 tam sığsın
  late double _initialMinX;
  late double _initialMaxX;
  bool _isInit = false;

  // Sol eksen genişliği (Zoom hesabında sapma olmaması için sabitliyoruz)
  final double _leftTitleReservedSize = 40;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit) {
      _calculateInitialView();
      _isInit = true;
    }
  }

  // YARDIMCI: "HH:MM" stringini Double'a çevirir (09:30 -> 9.5)
  double _timeToDouble(String time) {
    if (!time.contains(':')) return 0.0;
    final parts = time.split(':');
    final hour = double.parse(parts[0]);
    final minute = double.parse(parts[1]);
    return hour + (minute / 60.0);
  }

  // YARDIMCI: Double'ı Saate çevirir (Güvenli Versiyon)
  String _formatTime(double value) {
    // 24'ü geçerse mod al veya 23:59'a sabitle
    if (value >= 24) return "00:00";
    if (value < 0) return "00:00";

    int totalMinutes = (value * 60).round();
    int hour = totalMinutes ~/ 60;
    int minute = totalMinutes % 60;

    return "${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}";
  }

  // 🔥 DÜZELTİLDİ: Index yerine Gerçek Zaman Değerlerini Kullanıyoruz
  void _calculateInitialView() {
    if (widget.hourlyStats.isEmpty) {
      _minX = 0;
      _maxX = 24;
      return;
    }

    double firstActiveTime = 0;
    double lastActiveTime = 24;
    bool found = false;

    // Listeyi gez, veri olan SAATLERİ (0-24) bul
    for (var stat in widget.hourlyStats) {
      final totalVal = stat.totalSalesVolume + stat.collectionCashFlow;
      if (totalVal > 0) {
        final timeVal = _timeToDouble(stat.hourLabel);

        if (!found) {
          firstActiveTime = timeVal;
          found = true;
        }
        lastActiveTime = timeVal;
      }
    }

    // Hiç veri yoksa varsayılan olarak 08:00 - 18:00 göster
    if (!found) {
      _minX = 8;
      _maxX = 18;
    } else {
      // Kenarlara 1'er saat boşluk bırak
      _minX = max(0, firstActiveTime - 1);
      _maxX = min(24, lastActiveTime + 1);

      // Aralık çok darsa (örn: sadece 1 işlem varsa) en az 4 saatlik pencere aç
      if ((_maxX - _minX) < 4) {
        double center = (_minX + _maxX) / 2;
        _minX = max(0, center - 2);
        _maxX = min(24, center + 2);
      }
    }

    _initialMinX = _minX;
    _initialMaxX = _maxX;
  }

  void _zoom(double scale, {double? focalPoint}) {
    setState(() {
      final currentRange = _maxX - _minX;
      final newRange = currentRange * scale;

      final anchor = focalPoint ?? (_minX + _maxX) / 2;
      final ratio = (anchor - _minX) / currentRange;

      double newMinX = anchor - (newRange * ratio);
      double newMaxX = newMinX + newRange;

      // Sınırları 0-24 arasında tut
      if (newMinX < 0) {
        newMinX = 0;
        newMaxX = newRange;
      }
      if (newMaxX > 24) {
        newMaxX = 24;
        newMinX = 24 - newRange;
      }

      // Max zoom: 30 dakika aralığına kadar inebilsin (0.5)
      if (newMaxX - newMinX < 0.5) return;

      _minX = max(0, newMinX);
      _maxX = min(24, newMaxX);
    });
  }

  void _pan(double delta, double chartWidth) {
    setState(() {
      double pixelToX = (_maxX - _minX) / chartWidth;
      double shift = delta * pixelToX;

      if (_minX - shift >= 0 && _maxX - shift <= 24) {
        _minX -= shift;
        _maxX -= shift;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.hourlyStats.isEmpty)
      return const Center(child: Text("Veri yok"));

    double maxY = 0;
    for (var stat in widget.hourlyStats) {
      maxY = max(maxY, stat.totalSalesVolume);
      maxY = max(maxY, stat.salesCashFlow);
      maxY = max(maxY, stat.collectionCashFlow);
    }
    maxY = maxY == 0 ? 100 : maxY * 1.2;

    // 🔥 X EKSENİ ARALIK HESABI (30dk, 15dk, 10dk)
    double visibleRange = _maxX - _minX;
    double xInterval;

    if (visibleRange > 12)
      xInterval = 4.0; // 4 saat
    else if (visibleRange > 6)
      xInterval = 2.0; // 2 saat
    else if (visibleRange > 3)
      xInterval = 1.0; // 1 saat
    else if (visibleRange > 1.5)
      xInterval = 0.5; // 30 dk
    else if (visibleRange > 0.8)
      xInterval = 0.25; // 15 dk
    else
      xInterval = 0.166666; // 10 dk

    return MouseRegion(
      onEnter: (_) => widget.onHover?.call(true),
      onExit: (_) => widget.onHover?.call(false),
      child: Container(
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
          children: [
            // HEADER & CONTROLS
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Saatlik Satış Grafiği",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      "Tekerlek: Zoom | Sürükle: Gez",
                      style: TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ],
                ),
                Row(
                  children: [
                    _ZoomButton(
                      icon: Icons.refresh,
                      onTap:
                          () => setState(() {
                            _minX = _initialMinX;
                            _maxX = _initialMaxX;
                          }),
                    ),
                    const SizedBox(width: 4),
                    _ZoomButton(icon: Icons.remove, onTap: () => _zoom(1.2)),
                    const SizedBox(width: 4),
                    _ZoomButton(icon: Icons.add, onTap: () => _zoom(0.8)),
                  ],
                ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Wrap(
                spacing: 12,
                children: [
                  _buildLegendItem(Colors.blue, "Satış Hacmi"),
                  _buildLegendItem(Colors.green, "Kasa (Peşin)"),
                  _buildLegendItem(Colors.orange, "Tahsilat"),
                ],
              ),
            ),

            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Listener(
                    onPointerSignal: (event) {
                      if (event is PointerScrollEvent) {
                        // Mouse odaklı zoom
                        double localX = event.localPosition.dx;
                        double chartAreaX = max(
                          0,
                          localX - _leftTitleReservedSize,
                        );
                        double chartAreaWidth =
                            constraints.maxWidth - _leftTitleReservedSize;
                        double ratio = chartAreaX / chartAreaWidth;
                        double focusHour = _minX + (ratio * (_maxX - _minX));

                        if (event.scrollDelta.dy > 0) {
                          _zoom(1.1, focalPoint: focusHour);
                        } else {
                          _zoom(0.9, focalPoint: focusHour);
                        }
                      }
                    },
                    child: GestureDetector(
                      onHorizontalDragUpdate:
                          (details) =>
                              _pan(details.primaryDelta!, constraints.maxWidth),
                      child: LineChart(
                        LineChartData(
                          minX: _minX,
                          maxX: _maxX,
                          minY: 0,
                          maxY: maxY,
                          clipData: const FlClipData.all(),

                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: true,
                            horizontalInterval: maxY / 4,
                            verticalInterval: xInterval,
                            getDrawingHorizontalLine:
                                (v) => FlLine(
                                  color: Colors.grey.withOpacity(0.1),
                                  strokeWidth: 1,
                                ),
                            getDrawingVerticalLine:
                                (v) => FlLine(
                                  color: Colors.grey.withOpacity(0.05),
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
                                reservedSize: 32,
                                interval: xInterval,
                                getTitlesWidget: (value, meta) {
                                  // Saat başlarını kalın, dakikaları ince yap
                                  // 0.001 gibi float hatalarını tolere et
                                  final isMainHour = (value % 1).abs() < 0.01;

                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      _formatTime(value),
                                      style: TextStyle(
                                        color:
                                            isMainHour
                                                ? AppColors.textPrimary
                                                : AppColors.textSecondary,
                                        fontSize: isMainHour ? 11 : 9,
                                        fontWeight:
                                            isMainHour
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),

                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: _leftTitleReservedSize,
                                getTitlesWidget: (value, meta) {
                                  if (value == 0) return const Text('');
                                  if (value >= 1000)
                                    return Text(
                                      '${(value / 1000).toStringAsFixed(1)}k',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: AppColors.textSecondary,
                                      ),
                                    );
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

                          lineTouchData: LineTouchData(
                            touchTooltipData: LineTouchTooltipData(
                              getTooltipColor:
                                  (_) => Colors.blueGrey.shade900.withOpacity(
                                    0.95,
                                  ),
                              fitInsideHorizontally: true,
                              getTooltipItems: (spots) {
                                if (spots.isEmpty) return [];
                                final timeStr = _formatTime(spots.first.x);
                                return spots.map((spot) {
                                  final isFirst = spot == spots.first;
                                  Color color = Colors.white;
                                  String label = "";
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

                                  if (isFirst) {
                                    return LineTooltipItem(
                                      "$timeStr\n",
                                      const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        height: 1.5,
                                      ),
                                      children: [
                                        TextSpan(
                                          text:
                                              "$label: ₺${NumberFormat('#,##0').format(spot.y)}",
                                          style: TextStyle(
                                            color: color,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    );
                                  } else {
                                    return LineTooltipItem(
                                      "$label: ₺${NumberFormat('#,##0').format(spot.y)}",
                                      TextStyle(
                                        color: color,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    );
                                  }
                                }).toList();
                              },
                            ),
                            handleBuiltInTouches: true,
                          ),

                          lineBarsData: [
                            _buildLine(
                              widget.hourlyStats
                                  .map(
                                    (e) => FlSpot(
                                      _timeToDouble(e.hourLabel),
                                      e.totalSalesVolume,
                                    ),
                                  )
                                  .toList(),
                              Colors.blue,
                              true,
                            ),
                            _buildLine(
                              widget.hourlyStats
                                  .map(
                                    (e) => FlSpot(
                                      _timeToDouble(e.hourLabel),
                                      e.salesCashFlow,
                                    ),
                                  )
                                  .toList(),
                              Colors.green,
                              false,
                            ),
                            _buildLine(
                              widget.hourlyStats
                                  .map(
                                    (e) => FlSpot(
                                      _timeToDouble(e.hourLabel),
                                      e.collectionCashFlow,
                                    ),
                                  )
                                  .toList(),
                              Colors.orange,
                              false,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  LineChartBarData _buildLine(List<FlSpot> spots, Color color, bool filled) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      curveSmoothness: 0.2,
      color: color,
      barWidth: 3,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(
        show: filled,
        gradient:
            filled
                ? LinearGradient(
                  colors: [color.withOpacity(0.2), Colors.transparent],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                )
                : null,
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _ZoomButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _ZoomButton({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Icon(icon, size: 18, color: Colors.grey[700]),
      ),
    );
  }
}
