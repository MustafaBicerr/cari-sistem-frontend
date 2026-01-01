import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/stat_card.dart';
import '../providers/dashboard_provider.dart'; // Provider'ı ekle

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Provider'ı izle (Watch)
    final dashboardAsyncValue = ref.watch(dashboardSummaryProvider);

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
            "İşletmenizin anlık performans raporu.", // Ronaldo odağı
            style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
          ),
          const SizedBox(height: 32),

          // --- BURASI ARTIK DİNAMİK ---
          dashboardAsyncValue.when(
            // 1. Durum: Yükleniyor (Loading)
            loading: () => const Center(child: CircularProgressIndicator()),

            // 2. Durum: Hata (Error)
            error:
                (err, stack) => Center(
                  child: Text(
                    'Hata: $err',
                    style: const TextStyle(color: Colors.red),
                  ),
                ),

            // 3. Durum: Veri Geldi (Data) - Gol Sevinci!
            data: (data) {
              return LayoutBuilder(
                builder: (context, constraints) {
                  int crossAxisCount = 1;
                  if (constraints.maxWidth > 1100)
                    crossAxisCount = 4;
                  else if (constraints.maxWidth > 700)
                    crossAxisCount = 2;

                  double childAspectRatio =
                      constraints.maxWidth > 1100 ? 1.4 : 1.5;
                  if (crossAxisCount == 1) childAspectRatio = 1.8;

                  return GridView.count(
                    crossAxisCount: crossAxisCount,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                    childAspectRatio: childAspectRatio,
                    children: [
                      StatCard(
                        title: "Günlük Satış",
                        value:
                            "₺${data['total_sales_today'] ?? 0}", // Backend'den gelen
                        icon: Icons.payments_outlined,
                        color: Colors.blue,
                      ),
                      StatCard(
                        title: "Toplam Müşteri",
                        value: "${data['total_customers'] ?? 0}",
                        icon: Icons.people_alt_outlined,
                        color: Colors.orange,
                        isIncrease: true,
                      ),
                      StatCard(
                        title: "Kritik Stok",
                        value: "${data['low_stock_count'] ?? 0} Ürün",
                        icon: Icons.warning_amber_rounded,
                        color:
                            (data['low_stock_count'] ?? 0) > 0
                                ? Colors.red
                                : Colors.green,
                        isIncrease: false,
                      ),
                      // Buraya son bir kart daha ekleyebilirsin veya boş bırakabilirsin
                      const StatCard(
                        title: "Aktif Kasa",
                        value: "Açık",
                        icon: Icons.point_of_sale,
                        color: Colors.green,
                      ),
                    ],
                  );
                },
              );
            },
          ),

          const SizedBox(height: 40),
          // Grafik alanı şimdilik boş kalsın, oraya sonra Chart kütüphanesi gömeceğiz.
          Container(
            height: 300,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.withOpacity(0.1)),
            ),
            child: const Center(
              child: Text(
                "Grafikler yükleniyor...",
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
