import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile/features/dashboard/presentation/widgets/charts/hourly_payment_trend_chart.dart';
import 'package:mobile/features/dashboard/presentation/widgets/charts/hourly_sales_chart.dart';
import 'package:mobile/features/dashboard/presentation/widgets/charts/responsive_chart_carousel.dart';
import 'package:mobile/features/dashboard/presentation/widgets/charts/summary_pie_chart.dart';
import 'package:mobile/features/dashboard/presentation/widgets/charts/weekly_sales_bar_chart.dart';
import 'package:mobile/features/dashboard/presentation/widgets/dialogs/transaction_master_dialog.dart';
import 'package:mobile/features/dashboard/presentation/widgets/financial_stat_card.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/stat_card.dart';
import '../providers/dashboard_provider.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  // 🔥 SCROLL KİLİDİ İÇİN STATE
  bool _isChartHovered = false;

  @override
  Widget build(BuildContext context) {
    final dashboardAsyncValue = ref.watch(dashboardSummaryProvider);
    final chartsAsyncValue = ref.watch(dashboardChartsProvider);
    final currencyFormat = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');

    return SingleChildScrollView(
      // 🔥 KİLİT MEKANİZMASI: Grafik üzerindeyken sayfa kaymasın
      physics:
          _isChartHovered
              ? const NeverScrollableScrollPhysics()
              : const ClampingScrollPhysics(),
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

          // --- KARTLAR ---
          dashboardAsyncValue.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Veri alınamadı: $err')),
            data: (data) {
              return LayoutBuilder(
                builder: (context, constraints) {
                  int crossAxisCount =
                      constraints.maxWidth > 1100
                          ? 4
                          : (constraints.maxWidth > 700 ? 2 : 1);
                  double childAspectRatio =
                      constraints.maxWidth > 1100
                          ? 1.3
                          : (crossAxisCount == 1 ? 1.6 : 1.4);
                  double todayTotalVolume =
                      data.turnover.totalTurnover +
                      data.debtGiven.totalDebtGiven;

                  return GridView.count(
                    crossAxisCount: crossAxisCount,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                    childAspectRatio: childAspectRatio,
                    children: [
                      FinancialStatCard(
                        title: "Günlük Kasa",
                        mainValue: currencyFormat.format(
                          data.turnover.totalTurnover,
                        ),
                        subValueLabel: "Toplam İşlem:",
                        subValue: currencyFormat.format(todayTotalVolume),
                        icon: Icons.payments_outlined,
                        color: Colors.blue,
                        onTap:
                            () => showDialog(
                              context: context,
                              builder:
                                  (context) => const TransactionMasterDialog(
                                    viewType: TransactionViewType.dailyTurnover,
                                  ),
                            ),
                      ),
                      FinancialStatCard(
                        title: "Genel Alacak",
                        mainValue: currencyFormat.format(
                          data.financial.totalReceivable,
                        ),
                        subValueLabel: "Bugün Verilen:",
                        subValue:
                            "+${currencyFormat.format(data.debtGiven.totalDebtGiven)}",
                        icon: Icons.account_balance_wallet_outlined,
                        color: Colors.orange,
                        isDebtCard: true,
                        onTap:
                            () => showDialog(
                              context: context,
                              builder:
                                  (context) => const TransactionMasterDialog(
                                    viewType: TransactionViewType.totalDebt,
                                  ),
                            ),
                      ),
                      StatCard(
                        title: "Bugünkü Randevular",
                        value: "${data.appointments.todayCount} Hasta",
                        icon: Icons.calendar_today_outlined,
                        color: Colors.purple,
                        onTap: () {},
                      ),
                      StatCard(
                        title: "Kritik Stok",
                        value: "${data.inventory.criticalCount} Ürün",
                        icon: Icons.warning_amber_rounded,
                        color:
                            data.inventory.criticalCount > 0
                                ? Colors.red
                                : Colors.green,
                        isIncrease: false,
                        onTap: () {},
                      ),
                    ],
                  );
                },
              );
            },
          ),

          const SizedBox(height: 32),

          // --- GRAFİKLER ---
          chartsAsyncValue.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => const SizedBox(),
            data: (chartData) {
              double totalSales = 0;
              double totalCashFlow = 0;
              for (var h in chartData.hourlyStats) {
                totalSales += h.totalSalesVolume;
                totalCashFlow += (h.salesCashFlow + h.collectionCashFlow);
              }
              double totalCash = 0;
              double totalCard = 0;
              for (var p in chartData.paymentStats) {
                if (p.paymentMethod == 'CASH') totalCash += p.totalAmount;
                if (p.paymentMethod == 'CREDIT_CARD')
                  totalCard += p.totalAmount;
                debugPrint(
                  'Payment Method: ${p.paymentMethod}, Amount: ${p.totalAmount}',
                );
              }

              return Column(
                children: [
                  // 1. SATIR: PERFORMANS
                  ResponsiveChartCarousel(
                    title: "Satış Performansı",
                    // 🔥 GÜNCELLENDİ: Hover durumunu dinliyoruz
                    lineChart: HourlySalesChart(
                      hourlyStats: chartData.hourlyStats,
                      onHover: (isHovering) {
                        // Sadece durum değişirse setstate yap (Performans için)
                        if (_isChartHovered != isHovering) {
                          setState(() => _isChartHovered = isHovering);
                        }
                      },
                    ),
                    pieChart: SummaryPieChart(
                      value1: totalSales - totalCashFlow,
                      title1: "Borç Verilen",
                      color1: Colors.blue,
                      value2: totalCashFlow,
                      title2: "Ciro (Peşin)",
                      color2: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 24),
                  ResponsiveChartCarousel(
                    title: "Ödeme Dağılımı",
                    lineChart: HourlyPaymentTrendChart(
                      hourlyStats: chartData.hourlyStats,
                      onHover: (isHovering) {
                        if (_isChartHovered != isHovering) {
                          setState(() => _isChartHovered = isHovering);
                        }
                      },
                    ),
                    pieChart: SummaryPieChart(
                      value1: totalCash,
                      title1: "Nakit",
                      color1: AppColors.accent,
                      value2: totalCard,
                      title2: "Kart",
                      color2: Colors.purple,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 24),
                  WeeklySalesBarChart(weeklyStats: chartData.weeklyStats),
                  const SizedBox(height: 50),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
