import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/features/stock/presentation/widgets/stock_summary_card.dart';
import '../../../../core/theme/app_colors.dart';

class StockMenuScreen extends StatelessWidget {
  const StockMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text("Stok Yönetimi")),
      body: GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        children: [
          _MenuCard(
            title: "Mal Kabul",
            subtitle: "Fatura Girişi",
            icon: Icons.inventory,
            color: AppColors.primary,
            onTap: () => context.push('/stock/entry'),
          ),
          _MenuCard(
            title: "Ürünler",
            subtitle: "Listele & Düzenle",
            icon: Icons.list_alt,
            color: Colors.orange,
            onTap: () => context.push('/stock/products'),
          ),
          _MenuCard(
            title: "Stok Sayımı",
            subtitle: "Hızlı Düzenleme",
            icon: Icons.qr_code_scanner,
            color: Colors.purple,
            onTap: () {
              // Sayım ekranına git
            },
          ),
          _MenuCard(
            title: "Kritik Stok",
            subtitle: "Azalanlar",
            icon: Icons.warning_amber_rounded,
            color: AppColors.error,
            onTap: () {
              // Rapor ekranına git
            },
          ),
        ],
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _MenuCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  // stock_menu_screen.dart dosyasının build metodunun içini şöyle güncelle:

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text("Stok Yönetimi")),
      body: SingleChildScrollView(
        // Scroll eklendi
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. ÖZET KARTLARI (Yeni Eklenen Kısım)
            const Text(
              "Stok Durumu",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: StockSummaryCard(
                    title: "Toplam Stok Değeri",
                    value: "₺450.2K",
                    icon: Icons.monetization_on,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: StockSummaryCard(
                    title: "Kritik Ürün",
                    value: "12 Adet",
                    subValue: "Acil Sipariş",
                    icon: Icons.warning_amber,
                    color: AppColors.error,
                    onTap: () {
                      // Kritik stok listesine git
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
            const Text(
              "İşlemler",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // 2. MEVCUT BUTONLAR (GridView yerine Wrap veya Column içinde Row kullanabiliriz)
            // GridView.count scroll sorunu yaratabilir, o yüzden GridView.builder
            // veya shrinkWrap: true kullanacağız.
            GridView.count(
              shrinkWrap: true, // ScrollView içinde olduğu için şart
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.3, // Kartları biraz yatay yapalım
              children: [
                _MenuCard(
                  title: "Mal Kabul",
                  subtitle: "Fatura Girişi",
                  icon: Icons.inventory,
                  color: AppColors.primary,
                  onTap: () => context.push('/stock/entry'),
                ),
                _MenuCard(
                  title: "Ürünler",
                  subtitle: "Listele & Düzenle",
                  icon: Icons.list_alt,
                  color: Colors.orange,
                  onTap:
                      () => context.push(
                        '/stock/products',
                      ), // Zaten var olan rotaya
                ),
                // ... Diğer butonlar aynen kalabilir
              ],
            ),
          ],
        ),
      ),
    );
  }
}
