import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/features/current_accounts/presentation/widgets/transaction_items_dialog.dart';
import 'package:mobile/features/current_accounts/presentation/providers/account_detail_provider.dart';
import 'package:mobile/features/current_accounts/presentation/widgets/payment_dialog.dart';

class CustomerDetailDialog extends ConsumerWidget {
  final String customerId;

  const CustomerDetailDialog({super.key, required this.customerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(customerDetailProvider(customerId));
    final currencyFormat = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm', 'tr_TR');

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: detailAsync.when(
        loading:
            () => const SizedBox(
              height: 300,
              child: Center(child: CircularProgressIndicator()),
            ),
        error:
            (e, _) => SizedBox(
              height: 300,
              child: Center(
                child: Text(
                  "Hata: $e",
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ),
        data: (response) {
          final profile = response.profile;
          final transactions = response.transactions;
          final payments = response.payments;

          // 🔥 MANTIK: Peşin ödemeleri Satışlarla eşleştirme
          // TransactionID -> Ödenen Tutar haritası çıkaralım
          final Map<String, double> linkedPayments = {};

          for (var p in payments) {
            if (p.transactionId != null) {
              // Eğer bu ödeme bir satışa bağlıysa, toplayarak map'e at
              linkedPayments[p.transactionId!] =
                  (linkedPayments[p.transactionId!] ?? 0) + p.amount;
            }
          }

          final List<Map<String, dynamic>> combinedHistory = [];

          // 1. SATIŞLARI LİSTEYE EKLE
          for (var t in transactions) {
            // Bu satışa ait peşin ödeme var mı?
            double downPayment = linkedPayments[t.id] ?? 0.0;

            combinedHistory.add({
              'type': 'SALE',
              'date': DateTime.tryParse(t.date) ?? DateTime.now(),
              'title': "Satış İşlemi #${t.id.toString().substring(0, 6)}",
              'subtitle':
                  (t.note != null && t.note!.isNotEmpty)
                      ? t.note
                      : "${t.items.length} Kalem Ürün",
              'amount': t.finalAmount, // Toplam Tutar
              'down_payment':
                  downPayment, // 🔥 Peşin Ödenen (Ekranda göstereceğiz)
              'is_debt': true,
              'data': t,
            });
          }

          // 2. TAHSİLATLARI LİSTEYE EKLE
          for (var p in payments) {
            // 🔥 EĞER BU ÖDEME BİR SATIŞA BAĞLIYSA LİSTEYE AYRI SATIR OLARAK EKLEME!
            if (p.transactionId != null) continue;

            combinedHistory.add({
              'type': 'PAYMENT',
              'date': DateTime.tryParse(p.date) ?? DateTime.now(),
              'title': "Tahsilat (${_translateMethod(p.paymentMethod)})",
              'subtitle':
                  p.description.isNotEmpty ? p.description : "Cari Ödeme",
              'amount': p.amount,
              'is_debt': false,
              'data': p,
            });
          }

          // Tarihe göre sırala
          combinedHistory.sort(
            (a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime),
          );

          return Container(
            constraints: const BoxConstraints(maxWidth: 500, maxHeight: 750),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // --- 1. HEADER (Profil) ---
                Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      child: Text(
                        profile.fullName.isNotEmpty
                            ? profile.fullName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          fontSize: 28,
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
                            profile.fullName,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (profile.phone != null)
                            Text(
                              profile.phone!,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          "Güncel Bakiye",
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                        Text(
                          currencyFormat.format(profile.currentBalance.abs()),
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color:
                                profile.currentBalance > 0
                                    ? Colors.red
                                    : Colors.green,
                          ),
                        ),
                        Text(
                          profile.currentBalance > 0
                              ? "BORÇLU"
                              : "ALACAKLI/YOK",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color:
                                profile.currentBalance > 0
                                    ? Colors.red
                                    : Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Divider(),

                // --- 2. HAREKET LİSTESİ ---
                Expanded(
                  child:
                      combinedHistory.isEmpty
                          ? const Center(
                            child: Text(
                              "Henüz işlem kaydı yok",
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                          : ListView.separated(
                            itemCount: combinedHistory.length,
                            separatorBuilder:
                                (_, __) => const Divider(
                                  height: 1,
                                  color: Color(0xFFEEEEEE),
                                ),
                            itemBuilder: (context, index) {
                              final item = combinedHistory[index];
                              final isSale = item['type'] == 'SALE';
                              final double amount = item['amount'];
                              final double downPayment =
                                  item['down_payment'] ?? 0.0;
                              final bool isFullyPaid =
                                  isSale && (downPayment >= amount);

                              return InkWell(
                                onTap:
                                    isSale
                                        ? () {
                                          showDialog(
                                            context: context,
                                            builder:
                                                (_) => TransactionItemsDialog(
                                                  transaction: item['data'],
                                                ),
                                          );
                                        }
                                        : null,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12.0,
                                    horizontal: 4,
                                  ),
                                  child: Row(
                                    children: [
                                      // İkon
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color:
                                              isSale
                                                  ? Colors.red.withOpacity(0.1)
                                                  : Colors.green.withOpacity(
                                                    0.1,
                                                  ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Icon(
                                          isSale
                                              ? Icons.shopping_cart_outlined
                                              : Icons.download_rounded,
                                          color:
                                              isSale
                                                  ? Colors.red
                                                  : Colors.green,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 16),

                                      // Bilgi
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item['title'],
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              "${dateFormat.format(item['date'])} • ${item['subtitle']}",
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 12,
                                              ),
                                            ),
                                            // 🔥 PEŞİNAT BİLGİSİ
                                            if (isSale && downPayment > 0)
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                  top: 4.0,
                                                ),
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      isFullyPaid
                                                          ? Icons.check_circle
                                                          : Icons.info_outline,
                                                      size: 12,
                                                      color: Colors.green,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      "Peşin Ödenen: ${currencyFormat.format(downPayment)}",
                                                      style: const TextStyle(
                                                        fontSize: 11,
                                                        color: Colors.green,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),

                                      // Tutar
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            "₺${amount.toStringAsFixed(2)}",
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                              color:
                                                  isSale
                                                      ? Colors.red
                                                      : Colors.green,
                                            ),
                                          ),
                                          if (isSale)
                                            const Text(
                                              "Detay >",
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.blue,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                ),

                const SizedBox(height: 20),

                // --- 4. AKSİYON BUTONLARI ---
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          /* Whatsapp/SMS */
                        },
                        icon: const Icon(Icons.message_outlined),
                        label: const Text("Mesaj At"),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // Tahsilat Dialogu
                          showDialog(
                            context: context,
                            builder:
                                (_) => PaymentDialog(
                                  accountId:
                                      customerId, // String olarak geçiyoruz, PaymentDialog'u buna göre güncellemelisin
                                  isCollection: true,
                                  personName: profile.fullName,
                                ),
                          );
                        },
                        icon: const Icon(
                          Icons.payments_outlined,
                          color: Colors.white,
                        ),
                        label: const Text(
                          "TAHSİLAT AL",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00BFA5),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _translateMethod(String method) {
    if (method == 'CASH') return 'Nakit';
    if (method == 'CREDIT_CARD') return 'Kredi Kartı';
    return method;
  }
}
