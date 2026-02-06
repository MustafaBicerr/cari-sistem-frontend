import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile/core/theme/app_colors.dart';
import '../../data/models/account_transaction_model.dart';
import '../../data/models/supplier_model.dart';
import '../providers/account_detail_provider.dart';
import '../widgets/payment_dialog.dart';
import '../widgets/transaction_history_list.dart';

class SupplierDetailScreen extends ConsumerWidget {
  final String supplierId;

  const SupplierDetailScreen({super.key, required this.supplierId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(supplierDetailProvider(supplierId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text("Tedarikçi Detayı")),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text("Hata: $e")),
        data: (response) {
          final profile = response.profile;

          // 🔥 VERİ DÖNÜŞTÜRME (MAPPING)
          // Tedarikçi geçmişi zaten Backend'de birleştirilmiş geliyor (SupplierHistoryItem)
          final history =
              response.history.map((h) {
                // Backend'den gelen 'type' alanına göre yön belirle
                // DEBT -> Alım Faturası (Borçlanma)
                // PAYMENT (varsa) -> Ödeme

                // Not: Backend şimdilik sadece 'DEBT' dönüyor, ödemeler transaction tablosunda değil cash_movements'da.
                // Ama biz SupplierModel'e payment geçmişini de ekleyebilirdik.
                // Şimdilik borçları listeliyoruz.

                return AccountTransactionModel(
                  id: h.id.toString(),
                  date: DateTime.tryParse(h.date) ?? DateTime.now(),
                  title:
                      h.description.isNotEmpty
                          ? h.description
                          : "Fatura / Borç",
                  subtitle:
                      "Vade: ${h.dueDate.isNotEmpty ? h.dueDate.substring(0, 10) : 'Yok'}",
                  amount: h.initialAmount, // Fatura Tutarı
                  type: TransactionType.purchase, // Alım işlemi
                  status: h.status, // PAID, PARTIAL
                );
              }).toList();

          return Column(
            children: [
              _buildProfileCard(profile),
              Expanded(child: TransactionHistoryList(transactions: history)),
            ],
          );
        },
      ),
      // 🔥 ÖDEME BUTONU
      floatingActionButton:
          detailAsync.hasValue
              ? FloatingActionButton.extended(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder:
                        (_) => PaymentDialog(
                          accountId: supplierId,
                          isCollection: false, // ÖDEME MODU (Para Çıkışı)
                          personName: detailAsync.value!.profile.name,
                        ),
                  );
                },
                label: const Text("Ödeme Yap"),
                icon: const Icon(Icons.upload),
                backgroundColor: Colors.red,
              )
              : null,
    );
  }

  Widget _buildProfileCard(SupplierModel profile) {
    final currency = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');
    // Tedarikçiye borç pozitifse KIRMIZI (Kötü), negatifse YEŞİL (Alacaklıyız)
    final balanceColor = profile.currentBalance > 0 ? Colors.red : Colors.green;

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
            backgroundColor: Colors.orange.withOpacity(0.1),
            child: Text(
              profile.name[0].toUpperCase(),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            profile.name,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          if (profile.contactPerson != null)
            Text(
              "İlgili: ${profile.contactPerson}",
              style: const TextStyle(color: Colors.grey),
            ),
          const Divider(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Güncel Borç",
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
}
