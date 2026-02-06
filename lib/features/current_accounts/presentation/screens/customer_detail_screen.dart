import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile/core/theme/app_colors.dart';
import '../../data/models/account_transaction_model.dart';
import '../../data/models/customer_model.dart';
import '../providers/account_detail_provider.dart';
import '../widgets/payment_dialog.dart';
import '../widgets/transaction_history_list.dart';

class CustomerDetailScreen extends ConsumerWidget {
  final String customerId;

  const CustomerDetailScreen({super.key, required this.customerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(customerDetailProvider(customerId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text("Müşteri Detayı")),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text("Hata: $e")),
        data: (response) {
          final profile = response.profile;

          // 🔥 VERİ BİRLEŞTİRME VE DÖNÜŞTÜRME (MAPPING)
          // Satışları ve Ödemeleri tek bir listeye çevirip tarihe göre sıralıyoruz.
          final List<AccountTransactionModel> history = [];

          // 1. Satışları Ekle
          for (var t in response.transactions) {
            history.add(
              AccountTransactionModel(
                id: "S-${t.id}",
                date: DateTime.tryParse(t.date) ?? DateTime.now(),
                title: "Satış İşlemi",
                subtitle:
                    t.note ??
                    (t.items.isNotEmpty
                        ? "${t.items.length} Kalem Ürün"
                        : "Detay Yok"),
                amount: t.finalAmount, // Borç artırır
                type: TransactionType.sale,
                status:
                    'UNPAID', // Backend tam status dönmediği için varsayılan
              ),
            );
          }

          // 2. Tahsilatları Ekle
          for (var p in response.payments) {
            history.add(
              AccountTransactionModel(
                id: "P-${p.date}",
                date: DateTime.tryParse(p.date) ?? DateTime.now(),
                title: "Tahsilat (${_methodToTR(p.paymentMethod)})",
                subtitle: p.description,
                amount: p.amount,
                type: TransactionType.collection,
              ),
            );
          }

          // 3. Tarihe Göre Yeniden Eskiye Sırala
          history.sort((a, b) => b.date.compareTo(a.date));

          return Column(
            children: [
              // 🟢 PROFİL KARTI
              _buildProfileCard(profile),

              // 📜 HAREKET LİSTESİ
              Expanded(child: TransactionHistoryList(transactions: history)),
            ],
          );
        },
      ),
      // 🔥 TAHSİLAT BUTONU
      floatingActionButton:
          detailAsync.hasValue
              ? FloatingActionButton.extended(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder:
                        (_) => PaymentDialog(
                          accountId: customerId,
                          isCollection: true, // Tahsilat Modu
                          personName: detailAsync.value!.profile.fullName,
                        ),
                  );
                },
                label: const Text("Tahsilat Al"),
                icon: const Icon(Icons.payments),
                backgroundColor: Colors.green,
              )
              : null,
    );
  }

  Widget _buildProfileCard(CustomerModel profile) {
    final currency = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');
    // Müşteri borcu pozitifse YEŞİL (Bizim alacağımız var), negatifse KIRMIZI (Biz borçluyuz)
    // Ancak muhasebede Alacak Bakiye (Receivable) pozitiftir.
    final balanceColor =
        profile.currentBalance >= 0 ? Colors.green : Colors.red;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.blue.withOpacity(0.1),
            child: Text(
              profile.fullName[0].toUpperCase(),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            profile.fullName,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          if (profile.phone != null)
            Text(profile.phone!, style: const TextStyle(color: Colors.grey)),
          const Divider(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Güncel Bakiye",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              Text(
                currency.format(profile.currentBalance),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: balanceColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _methodToTR(String method) {
    switch (method) {
      case 'CASH':
        return 'Nakit';
      case 'CREDIT_CARD':
        return 'Kredi Kartı';
      case 'IBAN':
        return 'Havale';
      default:
        return method;
    }
  }
}
