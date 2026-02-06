import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/account_transaction_model.dart';

class TransactionHistoryList extends StatelessWidget {
  final List<AccountTransactionModel> transactions;

  const TransactionHistoryList({super.key, required this.transactions});

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 8),
            Text(
              "Henüz işlem hareketi yok",
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    final currencyFormat = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');
    final dateFormat = DateFormat('dd MMM yyyy HH:mm', 'tr_TR');

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: transactions.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = transactions[index];

        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            backgroundColor: item.amountColor.withOpacity(0.1),
            child: Icon(item.icon, color: item.amountColor, size: 20),
          ),
          title: Text(
            item.title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dateFormat.format(item.date),
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
              if (item.subtitle != null && item.subtitle!.isNotEmpty)
                Text(
                  item.subtitle!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textPrimary,
                  ),
                ),
            ],
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "${item.amountPrefix}${currencyFormat.format(item.amount)}",
                style: TextStyle(
                  color: item.amountColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              if (item.status != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color:
                        item.status == 'PAID'
                            ? Colors.green[50]
                            : Colors.orange[50],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    item.status == 'PAID' ? 'Ödendi' : 'Kısmi/Açık',
                    style: TextStyle(
                      fontSize: 10,
                      color:
                          item.status == 'PAID' ? Colors.green : Colors.orange,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
