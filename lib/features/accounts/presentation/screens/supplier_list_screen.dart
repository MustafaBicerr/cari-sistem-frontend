import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/account_list_item.dart';
import '../widgets/account_stats_card.dart';

class SupplierListScreen extends StatefulWidget {
  const SupplierListScreen({super.key});

  @override
  State<SupplierListScreen> createState() => _SupplierListScreenState();
}

class _SupplierListScreenState extends State<SupplierListScreen> {
  // Dummy Data (Depolar/Firmalar)
  final List<Map<String, dynamic>> _suppliers = [
    {
      "name": "Ecza Deposu A.Ş.",
      "phone": "0212 123 45 67",
      "balance": -50000.0,
    }, // Biz borçluyuz (Negatif)
    {"name": "Vet İlaç Deposu", "phone": "0212 687 25 96", "balance": -5000.0},
    {"name": "Bayern Pharma", "phone": "0212 531 42 57", "balance": -27500.0},
    {
      "name": "Mama Dünyası Ltd.",
      "phone": "0216 987 65 43",
      "balance": -12500.0,
    },
    {"name": "Medikal Ürünler", "phone": "0532 555 55 55", "balance": 0.0},
  ];

  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    final filteredList =
        _suppliers
            .where(
              (s) => s['name'].toString().toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ),
            )
            .toList();

    // Toplam Borcumuz (Negatif bakiyelerin toplamı)
    double totalPayable = 0;
    for (var s in _suppliers) {
      if (s['balance'] < 0) totalPayable += s['balance'].abs();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Tedarikçiler & Depolar"),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.picture_as_pdf, color: AppColors.primary),
            tooltip: "Borç Raporu",
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Yeni Tedarikçi Ekle
        },
        backgroundColor: AppColors.accent, // Tedarikçi için farklı renk tonu
        icon: const Icon(Icons.domain_add, color: Colors.white),
        label: const Text(
          "Yeni Tedarikçi",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          // 1. ÜST BİLGİ
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: AccountStatsCard(
                    title: "TOPLAM BORÇ",
                    amount: totalPayable,
                    icon: Icons.money_off,
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: AccountStatsCard2(
                    title: "TEDARİKÇİ SAYISI",
                    amount: _suppliers.length.toDouble(),
                    icon: Icons.store,
                    color: AppColors.accent,
                  ),
                ),
              ],
            ),
          ),

          // 2. ARAMA
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: "Depo veya firma adı ara...",
                prefixIcon: const Icon(
                  Icons.search,
                  color: AppColors.textSecondary,
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 3. LİSTE
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: filteredList.length,
              itemBuilder: (context, index) {
                final supplier = filteredList[index];
                return AccountListItem(
                  name: supplier['name'],
                  phone: supplier['phone'],
                  balance:
                      supplier['balance'], // Widget içinde negatif kontrolü yapılıyor
                  onTap: () {
                    // Depo Detay
                  },
                  onQuickAction: () {
                    // Depoyu Ara
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
