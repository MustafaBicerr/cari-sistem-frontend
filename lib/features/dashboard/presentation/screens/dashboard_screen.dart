import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile/features/dashboard/presentation/widgets/charts/hourly_payment_trend_chart.dart';
import 'package:mobile/features/dashboard/presentation/widgets/charts/hourly_sales_chart.dart';
import 'package:mobile/features/dashboard/presentation/widgets/charts/responsive_chart_carousel.dart';
import 'package:mobile/features/dashboard/presentation/widgets/charts/summary_pie_chart.dart';
import 'package:mobile/features/dashboard/presentation/widgets/charts/weekly_sales_bar_chart.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/stat_card.dart';
import '../providers/dashboard_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsyncValue = ref.watch(dashboardSummaryProvider);
    final chartsAsyncValue = ref.watch(dashboardChartsProvider);

    final currencyFormat = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Genel Bakış",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "İşletmenizin anlık performans raporu.",
            style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
          ),
          const SizedBox(height: 32),

          // --- KARTLAR BÖLÜMÜ ---
          dashboardAsyncValue.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error:
                (err, stack) => Center(
                  child: Text(
                    'Veri alınamadı: $err',
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
            data: (data) {
              return LayoutBuilder(
                builder: (context, constraints) {
                  int crossAxisCount =
                      constraints.maxWidth > 1100
                          ? 4
                          : (constraints.maxWidth > 700 ? 2 : 1);
                  double childAspectRatio =
                      constraints.maxWidth > 1100
                          ? 1.4
                          : (crossAxisCount == 1 ? 1.8 : 1.5);

                  return GridView.count(
                    crossAxisCount: crossAxisCount,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                    childAspectRatio: childAspectRatio,
                    children: [
                      // 3. ENFLASYON KAZANCI
                      StatCard(
                        title: "Toplam Satış Miktarı (Bugün)",
                        value: "₺1035,00",
                        icon: Icons.trending_up,
                        color: Colors.green,
                        isIncrease: true,
                        onTap: () {
                          print("İş hacmi detayları açılacak...");
                        },
                      ),
                      // 1. GÜNLÜK CİRO
                      StatCard(
                        title: "Ciro (Bugün)",
                        value: currencyFormat.format(
                          data.turnover.totalTurnover,
                        ),
                        icon: Icons.payments_outlined,
                        color: Colors.blue,
                        onTap: () {
                          print("Ciro detayları açılacak...");
                        },
                      ),
                      // 2. VERİLEN BORÇ
                      StatCard(
                        title: "Verilen Borç (Bugün)",
                        value: currencyFormat.format(
                          data.debtGiven.totalDebtGiven,
                        ),
                        icon: Icons.credit_score_outlined,
                        color: Colors.orange,
                        onTap: () {
                          print("Borç detayları açılacak...");
                        },
                      ),

                      // 4. KRİTİK STOK
                      StatCard(
                        title: "Kritik Stok",
                        value: "${data.inventory.criticalCount} Ürün",
                        icon: Icons.warning_amber_rounded,
                        color:
                            data.inventory.criticalCount > 0
                                ? Colors.red
                                : Colors.green,
                        isIncrease: false,
                        onTap: () {
                          print("Stok detayları açılacak...");
                        },
                      ),

                      StatCard(
                        title: "Toplam Alınacak Tahsilat",
                        value: "₺3.573,00",
                        icon: Icons.trending_up,
                        color: Colors.green,
                        isIncrease: true,
                        onTap: () {
                          print("İş hacmi detayları açılacak...");
                        },
                      ),
                      StatCard(
                        title: "Toplam Ciro",
                        value: "₺2.410,00",
                        icon: Icons.trending_up,
                        color: Colors.green,
                        isIncrease: true,
                        onTap: () {
                          print("İş hacmi detayları açılacak...");
                        },
                      ),
                    ],
                  );
                },
              );
            },
          ),

          // --- GRAFİKLER BÖLÜMÜ ---
          const SizedBox(height: 32),

          chartsAsyncValue.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => const SizedBox(),
            data: (chartData) {
              // --- VERİ HESAPLAMALARI (Client-Side) ---

              // 1. Grafik İçin: Toplam Satış vs Toplam Kasa (Satış + Tahsilat)
              double totalSales = 0;
              double totalCashFlow = 0;
              for (var h in chartData.hourlyStats) {
                totalSales += h.totalSalesVolume;
                // 🔥 YENİ MODEL UYUMU: Toplam Kasa = Satıştan Gelen + Tahsilattan Gelen
                totalCashFlow += (h.salesCashFlow + h.collectionCashFlow);
              }

              // 2. Grafik İçin: Toplam Nakit vs Toplam Kart
              double totalCash = 0;
              double totalCard = 0;
              for (var p in chartData.paymentStats) {
                if (p.paymentMethod == 'CASH') totalCash += p.totalAmount;
                if (p.paymentMethod == 'CREDIT_CARD')
                  totalCard += p.totalAmount;
              }

              return Column(
                children: [
                  // 1. SATIR: PERFORMANS (Çizgi + Pasta)
                  ResponsiveChartCarousel(
                    title: "Satış Performansı",
                    lineChart: HourlySalesChart(
                      hourlyStats: chartData.hourlyStats,
                    ), // Güncellenmiş 3 çizgili grafik
                    pieChart: SummaryPieChart(
                      value1: totalSales - totalCashFlow,
                      title1: "Borç Verilen",
                      color1: Colors.blue,
                      value2: totalCashFlow,
                      title2: "Ciro (Peşin Alınan)",
                      color2: Colors.green,
                    ),
                  ),

                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 24),

                  // 2. SATIR: ÖDEME YÖNTEMLERİ (Çizgi + Pasta)
                  ResponsiveChartCarousel(
                    title: "Ödeme Dağılımı",
                    lineChart: HourlyPaymentTrendChart(
                      hourlyStats: chartData.hourlyStats,
                    ),
                    pieChart: SummaryPieChart(
                      value1: totalCash,
                      title1: "Nakit",
                      color1: AppColors.accent, // Turuncu
                      value2: totalCard,
                      title2: "Kart",
                      color2: Colors.purple,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(
                    height: 24,
                  ), // 3. GRAFİK: HAFTALIK PERFORMANS (BAR CHART)
                  // Bu grafik tek başına geniş duracağı için Carousel içine koymaya gerek yok,
                  // doğrudan ekrana basabiliriz.
                  WeeklySalesBarChart(weeklyStats: chartData.weeklyStats),

                  const SizedBox(height: 50), // En alt boşluk
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
