import 'package:flutter/material.dart';
import 'package:mobile/features/accounts/presentation/widgets/account_detail_dialog.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/account_list_item.dart';
import '../widgets/account_stats_card.dart';

class CustomerListScreen extends StatefulWidget {
  const CustomerListScreen({super.key});

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  // Dummy Data
  final List<Map<String, dynamic>> _customers = [
    {
      "name": "Ahmet Yılmaz",
      "phone": "0555 444 33 22",
      "balance": 1500.0,
    }, // Bize borçlu
    {"name": "Ayşe Demir", "phone": "0532 111 22 33", "balance": 0.0},
    {
      "name": "Mehmet Öz",
      "phone": "0544 999 88 77",
      "balance": -2000.0,
    }, // Biz ona borçluyuz (İade vs.)
    {"name": "Beritan Çiftliği", "phone": "0533 945 96 10", "balance": 12500.0},
    {
      "name": "Karlıova Veteriner Kliniği",
      "phone": "0525 945 86 17",
      "balance": 32500.0,
    },
  ];

  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    // Filtreleme
    final filteredList =
        _customers
            .where(
              (c) => c['name'].toString().toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ),
            )
            .toList();

    // İstatistikler (Frontend hesaplaması)
    double totalReceivable = 0;
    for (var c in _customers) {
      if (c['balance'] > 0) totalReceivable += c['balance'];
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Müşteriler & Cariler"),
        actions: [
          IconButton(
            onPressed: () {}, // Excel/PDF Rapor
            icon: const Icon(Icons.print_outlined, color: AppColors.primary),
            tooltip: "Listeyi Yazdır",
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Yeni Müşteri Ekle Dialogu
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text(
          "Yeni Müşteri",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          // 1. ÜST BİLGİ KARTLARI
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: AccountStatsCard(
                    title: "TOPLAM ALACAK",
                    amount: totalReceivable,
                    icon: Icons.account_balance_wallet,
                    color:
                        AppColors
                            .error, // Alacak kırmızı (Risk) veya mavi olabilir. Muhasebede genelde borç/alacak rengi değişir.
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: AccountStatsCard2(
                    title: "AKTİF MÜŞTERİ",
                    amount: 5,
                    icon: Icons.people,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),

          // 2. ARAMA ÇUBUĞU
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: "Müşteri adı, telefon veya vergi no ara...",
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

          // 3. MÜŞTERİ LİSTESİ
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: filteredList.length,
              itemBuilder: (context, index) {
                final customer = filteredList[index];
                return AccountListItem(
                  name: customer['name'],
                  phone: customer['phone'],
                  balance: customer['balance'],
                  onTap: () {
                    // Detay sayfasına veya dialoguna git
                    _showCustomerDetail(context, customer);
                  },
                  onQuickAction: () {
                    // Hızlı arama / Whatsapp
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // customer_list_screen.dart dosyasının en altındaki fonksiyon:

  void _showCustomerDetail(
    BuildContext context,
    Map<String, dynamic> customer,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Tam ekrana yakın açılması için
      backgroundColor: Colors.transparent,
      builder:
          (context) => FractionallySizedBox(
            heightFactor: 0.85, // Ekranın %85'ini kaplasın
            child: AccountDetailDialog(
              account: customer,
            ), // OLUŞTURDUĞUMUZ WIDGET
          ),
    );
  }
}
