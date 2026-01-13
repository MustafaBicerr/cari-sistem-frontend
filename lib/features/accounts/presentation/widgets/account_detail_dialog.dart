import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class AccountDetailDialog extends StatelessWidget {
  final Map<String, dynamic> account; // Müşteri veya Tedarikçi objesi
  final bool isSupplier; // Tedarikçi mi?

  const AccountDetailDialog({
    super.key,
    required this.account,
    this.isSupplier = false,
  });

  // Dummy Transaction History (Burası backend'den 'debt_history_logs' veya 'transactions' tablosundan gelecek)
  static final List<Map<String, dynamic>> _dummyHistory = [
    {
      "date": "06.01.2026",
      "type": "SATIŞ",
      "desc": "Hızlı Satış #1023",
      "amount": -1500.0,
    }, // Borçlandı
    {
      "date": "05.01.2026",
      "type": "TAHSİLAT",
      "desc": "Nakit Ödeme",
      "amount": 500.0,
    }, // Ödedi
    {
      "date": "01.01.2026",
      "type": "DEVİR",
      "desc": "2025 Devir Bakiyesi",
      "amount": -2000.0,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final double balance = account['balance'] ?? 0.0;
    final bool isDebtor =
        balance < 0; // Negatifse borçlu (Tedarikçi için mantık değişebilir)

    // Tedarikçi ise (Supplier): Negatif bakiye -> Biz borçluyuz.
    // Müşteri ise (Customer): Pozitif bakiye -> O bize borçlu.
    // Bu mantığı projendeki muhasebe standardına göre ayarlayabilirsin.
    // Şimdilik Müşteri mantığı: Artı (+) ise alacaklıyız.

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ), // BottomSheet için
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, // İçerik kadar yer kapla
        children: [
          // 1. HEADER (Tutamak ve İsim)
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  account['name'].substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account['name'],
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.phone, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          account['phone'] ?? "Tel Yok",
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    "Güncel Bakiye",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Text(
                    "₺${balance.abs().toStringAsFixed(2)}",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color:
                          balance == 0
                              ? Colors.grey
                              : (balance > 0
                                  ? AppColors.error
                                  : AppColors.success),
                    ),
                  ),
                  Text(
                    balance > 0
                        ? (isSupplier ? "Alacaklı" : "Borçlu")
                        : (balance == 0
                            ? "-"
                            : (isSupplier ? "Borçluyuz" : "Alacaklı")),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 24),
          const Divider(),

          // 2. HAREKET GEÇMİŞİ (EKSTRE)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Hesap Hareketleri (Son 5)",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextButton.icon(
                onPressed: () {}, // Tümünü gör
                icon: const Icon(Icons.history, size: 16),
                label: const Text("Tüm Ekstre"),
              ),
            ],
          ),

          Expanded(
            child: ListView.separated(
              itemCount: _dummyHistory.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = _dummyHistory[index];
                final isPositive = item['amount'] > 0;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    isPositive ? Icons.arrow_downward : Icons.arrow_upward,
                    color: isPositive ? AppColors.success : AppColors.error,
                    size: 20,
                  ),
                  title: Text(
                    item['desc'],
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text("${item['date']} • ${item['type']}"),
                  trailing: Text(
                    "₺${item['amount'].abs().toStringAsFixed(2)}",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isPositive ? AppColors.success : AppColors.error,
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // 3. AKSİYON BUTONLARI
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // Whatsapp açma kodu buraya
                  },
                  icon: const Icon(Icons.message),
                  label: const Text("Mesaj At"),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Tahsilat Dialogu Aç
                  },
                  icon: const Icon(Icons.add_card, color: Colors.white),
                  label: const Text(
                    "İŞLEM EKLE",
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16), // Alt boşluk (iOS home bar için)
        ],
      ),
    );
  }
}
