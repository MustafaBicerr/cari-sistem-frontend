import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile/features/current_accounts/data/models/customer_model.dart';

class TransactionItemsDialog extends StatelessWidget {
  final CustomerTransactionItem transaction;

  const TransactionItemsDialog({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');
    final List items = transaction.items;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "İşlem Detayı",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(
            "Tarih: ${transaction.date}",
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ÜRÜN LİSTESİ
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: items.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (context, index) {
                  final item = items[index];

                  final name = item['product_name'] ?? 'Bilinmeyen Ürün';
                  final qty = _safeDouble(item['quantity']);
                  final price = _safeDouble(item['unit_price']);
                  final total = qty * price;

                  final status = item['payment_status'] ?? 'UNPAID';
                  final isPaid = status == 'PAID';

                  // 🔥 ENFLASYON UYARISI
                  final inflationDiff = _safeDouble(
                    item['inflation_diff_total'],
                  );
                  final hasInflationWarning = inflationDiff > 0;
                  // Geçmiş verisi (List olarak gelmeli)
                  final priceHistory = item['price_history'] as List?;

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    // 1. Satır: Ürün Adı ve Durum Badge'i
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isPaid ? Colors.green[50] : Colors.red[50],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isPaid ? "ÖDENDİ" : "BORÇ",
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: isPaid ? Colors.green : Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                    // 2. Satır: Miktar x Fiyat ve Varsa Uyarı
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${qty.toStringAsFixed(0)} Adet x ${currency.format(price)}",
                        ),

                        // 🚨 TIKLANABİLİR UYARI ALANI
                        if (hasInflationWarning)
                          GestureDetector(
                            // InkWell yerine GestureDetector daha hassas olabilir burada
                            onTap: () {
                              if (priceHistory != null &&
                                  priceHistory.isNotEmpty) {
                                _showPriceHistory(context, priceHistory, name);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Geçmiş bilgisi bulunamadı."),
                                  ),
                                );
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.only(
                                top: 6.0,
                                bottom: 2.0,
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.info_outline,
                                    size: 16,
                                    color: Colors.red,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    "Fiyat Güncellendi (+${currency.format(inflationDiff)})",
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                      decoration:
                                          TextDecoration
                                              .underline, // Tıklanabilir hissi verir
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                    // Sağ Taraf: Toplam Tutar
                    trailing: Text(
                      currency.format(total),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  );
                },
              ),
            ),
            const Divider(thickness: 2),

            // GENEL TOPLAM
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Genel Toplam (Enflasyon Dahil)",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  currency.format(transaction.finalAmount),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Kapat"),
        ),
      ],
    );
  }

  // 🔥 Fiyat Geçmişi Popup'ı
  void _showPriceHistory(
    BuildContext context,
    List history,
    String productName,
  ) {
    final currency = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm');

    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(
              "$productName Fiyat Geçmişi",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: history.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (c, i) {
                  final h = history[i];
                  // Backend'den gelen yapı: {date, reason, new_price, old_price, diff_per_unit}
                  final dateStr = h['date'] ?? '';
                  final date = DateTime.tryParse(dateStr);
                  final formattedDate =
                      date != null ? dateFormat.format(date) : dateStr;

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    leading: const Icon(
                      Icons.history,
                      color: Colors.grey,
                      size: 20,
                    ),
                    title: Text(
                      "${currency.format(h['old_price'])} ➔ ${currency.format(h['new_price'])}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      "$formattedDate\n${h['reason'] ?? 'Güncelleme'}",
                    ),
                    trailing: Text(
                      "+${currency.format(h['diff_per_unit'])}",
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Tamam"),
              ),
            ],
          ),
    );
  }

  double _safeDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is int) return val.toDouble();
    if (val is double) return val;
    if (val is String) return double.tryParse(val) ?? 0.0;
    return 0.0;
  }
}
