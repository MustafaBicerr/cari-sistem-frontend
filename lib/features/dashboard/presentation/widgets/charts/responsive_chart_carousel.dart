import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';

class ResponsiveChartCarousel extends StatefulWidget {
  final Widget lineChart;
  final Widget pieChart;
  final String title;

  const ResponsiveChartCarousel({
    super.key,
    required this.lineChart,
    required this.pieChart,
    required this.title,
  });

  @override
  State<ResponsiveChartCarousel> createState() =>
      _ResponsiveChartCarouselState();
}

class _ResponsiveChartCarouselState extends State<ResponsiveChartCarousel> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Desktop Modu (Yan Yana)
        if (constraints.maxWidth > 900) {
          return SizedBox(
            height: 400, // 🔥 KRİTİK DÜZELTME: Yüksekliği sabitledik
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch, // Tüm alanı kapla
              children: [
                Expanded(flex: 2, child: widget.lineChart),
                const SizedBox(width: 24),
                Expanded(flex: 1, child: widget.pieChart),
              ],
            ),
          );
        }

        // Mobil Modu (Carousel)
        return Container(
          height: 450, // Mobilde biraz daha yüksek olabilir
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
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Row(
                      children: List.generate(2, (index) {
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _currentIndex == index ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color:
                                _currentIndex == index
                                    ? AppColors.primary
                                    : Colors.grey.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged:
                      (index) => setState(() => _currentIndex = index),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: widget.lineChart,
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: widget.pieChart,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed:
                          () => _pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          ),
                      color:
                          _currentIndex == 0
                              ? Colors.grey.withOpacity(0.3)
                              : AppColors.textSecondary,
                    ),
                    Text(
                      _currentIndex == 0 ? "Detay Görünümü" : "Özet Görünümü",
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed:
                          () => _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          ),
                      color:
                          _currentIndex == 1
                              ? Colors.grey.withOpacity(0.3)
                              : AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
