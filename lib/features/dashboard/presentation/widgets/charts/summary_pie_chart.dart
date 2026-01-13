import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../core/theme/app_colors.dart';

class SummaryPieChart extends StatefulWidget {
  final double value1;
  final String title1;
  final Color color1;

  final double value2;
  final String title2;
  final Color color2;

  const SummaryPieChart({
    super.key,
    required this.value1,
    required this.title1,
    required this.color1,
    required this.value2,
    required this.title2,
    required this.color2,
  });

  @override
  State<SummaryPieChart> createState() => _SummaryPieChartState();
}

class _SummaryPieChartState extends State<SummaryPieChart> {
  int touchedIndex = -1; // Dokunulan dilimi büyütmek için

  @override
  Widget build(BuildContext context) {
    final total = widget.value1 + widget.value2;
    // Veri yoksa boş dön
    if (total == 0) return const Center(child: Text("Veri Yok"));

    return Column(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                  setState(() {
                    if (!event.isInterestedForInteractions ||
                        pieTouchResponse == null ||
                        pieTouchResponse.touchedSection == null) {
                      touchedIndex = -1;
                      return;
                    }
                    touchedIndex =
                        pieTouchResponse.touchedSection!.touchedSectionIndex;
                  });
                },
              ),
              borderData: FlBorderData(show: false),
              sectionsSpace: 2, // Dilimler arası boşluk
              centerSpaceRadius: 0, // Ortası delik (Donut Chart)
              sections: _showingSections(total),
            ),
          ),
        ),
        // const SizedBox(height: 16),
        // Legend (Açıklama)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildIndicator(widget.color1, widget.title1, widget.value1, total),
            const SizedBox(width: 20),
            _buildIndicator(widget.color2, widget.title2, widget.value2, total),
          ],
        ),
      ],
    );
  }

  List<PieChartSectionData> _showingSections(double total) {
    return List.generate(2, (i) {
      final isTouched = i == touchedIndex;
      final fontSize = isTouched ? 18.0 : 14.0;
      final radius = isTouched ? 130.0 : 110.0; // Dokununca büyür

      if (i == 0) {
        final percentage = (widget.value1 / total * 100).toStringAsFixed(1);
        return PieChartSectionData(
          color: widget.color1,
          value: widget.value1,
          title: '$percentage%',
          radius: radius,
          titleStyle: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        );
      } else {
        final percentage = (widget.value2 / total * 100).toStringAsFixed(1);
        return PieChartSectionData(
          color: widget.color2,
          value: widget.value2,
          title: '$percentage%',
          radius: radius,
          titleStyle: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        );
      }
    });
  }

  Widget _buildIndicator(Color color, String text, double value, double total) {
    final currency = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(shape: BoxShape.circle, color: color),
            ),
            const SizedBox(width: 4),
            Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        Text(
          currency.format(value),
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
