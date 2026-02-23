import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/features/dashboard/presentation/widgets/expandable_transaction_card.dart';
import '../../providers/cash_register_provider.dart';

class CashTransactionList extends ConsumerWidget {
  const CashTransactionList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(cashRegisterProvider.notifier);
    final transactions = notifier.filteredTransactions; // Filtrelenmiş liste
    final currencyFormat = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');
    final timeFormat = DateFormat('HH:mm');

    if (transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long,
              size: 64,
              color: Colors.grey.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              "Bu tarih için işlem bulunamadı.",
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: transactions.length,
      separatorBuilder:
          (_, __) => const SizedBox(height: 8), // Kartlar arası boşluk
      itemBuilder: (context, index) {
        final item = transactions[index];
        // 🔥 İşte o muazzam widget burada!
        return ExpandableTransactionCard(transaction: item);
      },
    );
  }
}
