import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class CashRegisterScreen extends StatefulWidget {
  const CashRegisterScreen({super.key});

  @override
  State<CashRegisterScreen> createState() => _CashRegisterScreenState();
}

class _CashRegisterScreenState extends State<CashRegisterScreen> {
  // --- STATE (DUMMY DATA) ---
  final double _totalCash = 12500.00;
  final double _totalCard = 34000.50;
  final double _totalExpense = 1200.00;

  // Örnek Kasa Hareketleri
  final List<Map<String, dynamic>> _transactions = [
    {
      "type": "EXPENSE",
      "title": "Market Alışverişi (Çay/Şeker)",
      "amount": 450.0,
      "time": "14:30",
      "method": "Nakit",
    },
    {
      "type": "INCOME",
      "title": "Ahmet Yılmaz (Cari Tahsilat)",
      "amount": 5000.0,
      "time": "11:15",
      "method": "Kredi Kartı",
    },
    {
      "type": "SALE",
      "title": "Hızlı Satış #1023",
      "amount": 1250.0,
      "time": "09:45",
      "method": "Nakit",
    },
  ];

  // --- ACTIONS ---

  void _openTransactionDialog(String type) {
    // type: 'EXPENSE' (Gider) veya 'COLLECTION' (Tahsilat)
    showDialog(
      context: context,
      builder: (context) => _AddTransactionDialog(type: type),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Kasa & Gider Yönetimi"),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.print_outlined, color: AppColors.primary),
            tooltip: "Gün Sonu Raporu Yazdır",
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. ÖZET KARTLARI (Responsive Grid)
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 800;
                return Row(
                  children: [
                    Expanded(
                      child: _SummaryCard(
                        title: "NAKİT KASA",
                        amount: _totalCash,
                        icon: Icons.payments,
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _SummaryCard(
                        title: "POS / KART",
                        amount: _totalCard,
                        icon: Icons.credit_card,
                        color: AppColors.primary,
                      ),
                    ),
                    if (isWide) ...[
                      const SizedBox(width: 16),
                      Expanded(
                        child: _SummaryCard(
                          title: "GÜNLÜK GİDER",
                          amount: _totalExpense,
                          icon: Icons.trending_down,
                          color: AppColors.error,
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),

            // Mobilde 3. kart sığmadıysa alta ekleyelim
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth <= 800) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: _SummaryCard(
                      title: "GÜNLÜK GİDER",
                      amount: _totalExpense,
                      icon: Icons.trending_down,
                      color: AppColors.error,
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),

            const SizedBox(height: 24),

            // 2. HIZLI İŞLEM BUTONLARI
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _openTransactionDialog('EXPENSE'),
                    icon: const Icon(
                      Icons.remove_circle_outline,
                      color: Colors.white,
                    ),
                    label: const Text("MASRAF GİR"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _openTransactionDialog('COLLECTION'),
                    icon: const Icon(
                      Icons.add_circle_outline,
                      color: Colors.white,
                    ),
                    label: const Text("TAHSİLAT YAP"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // 3. HAREKET LİSTESİ BAŞLIĞI
            const Text(
              "Son Kasa Hareketleri",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // 4. LİSTE
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.withOpacity(0.1)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ListView.separated(
                shrinkWrap: true, // ScrollView içinde olduğu için
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _transactions.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = _transactions[index];
                  final isExpense = item['type'] == 'EXPENSE';

                  return ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color:
                            isExpense
                                ? AppColors.error.withOpacity(0.1)
                                : AppColors.success.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isExpense ? Icons.arrow_downward : Icons.arrow_upward,
                        color: isExpense ? AppColors.error : AppColors.success,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      item['title'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text("${item['time']} • ${item['method']}"),
                    trailing: Text(
                      "${isExpense ? '-' : '+'} ₺${item['amount'].toStringAsFixed(2)}",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isExpense ? AppColors.error : AppColors.success,
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
}

// --- YARDIMCI WIDGETLAR ---

class _SummaryCard extends StatelessWidget {
  final String title;
  final double amount;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.amount,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              Icon(icon, color: color, size: 20),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "₺${amount.toStringAsFixed(2)}",
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
        ],
      ),
    );
  }
}

// Basit Ekleme Dialogu
class _AddTransactionDialog extends StatelessWidget {
  final String type; // 'EXPENSE' or 'COLLECTION'

  const _AddTransactionDialog({required this.type});

  @override
  Widget build(BuildContext context) {
    final isExpense = type == 'EXPENSE';

    return AlertDialog(
      title: Text(isExpense ? "Masraf Ekle" : "Tahsilat Yap"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            autofocus: true,
            decoration: const InputDecoration(
              labelText: "Tutar (₺)",
              border: OutlineInputBorder(),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 16),
          TextField(
            decoration: InputDecoration(
              labelText:
                  isExpense
                      ? "Açıklama (Örn: Yemek)"
                      : "Müşteri Adı / Açıklama",
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          // Ödeme Yöntemi Seçimi (Basit Dropdown)
          DropdownButtonFormField<String>(
            value: "CASH",
            decoration: const InputDecoration(
              labelText: "İşlem Türü",
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: "CASH", child: Text("Nakit")),
              DropdownMenuItem(value: "CARD", child: Text("Kredi Kartı")),
            ],
            onChanged: (val) {},
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("İptal"),
        ),
        ElevatedButton(
          onPressed: () {
            // Backend isteği burada atılacak
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: isExpense ? AppColors.error : AppColors.success,
          ),
          child: const Text("Kaydet", style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
