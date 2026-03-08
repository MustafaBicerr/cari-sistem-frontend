import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/transaction_master_model.dart';

class ExpandableTransactionCard extends StatefulWidget {
  final TransactionMasterModel transaction;
  final bool isInitiallyExpanded;

  const ExpandableTransactionCard({
    super.key,
    required this.transaction,
    this.isInitiallyExpanded = false,
  });

  @override
  State<ExpandableTransactionCard> createState() =>
      _ExpandableTransactionCardState();
}

class _ExpandableTransactionCardState extends State<ExpandableTransactionCard> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.isInitiallyExpanded;
  }

  void _showPriceHistoryDialog(BuildContext context, MasterItem item) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text("${item.productName} Fiyat Geçmişi"),
            content: SizedBox(
              width: double.maxFinite,
              child:
                  item.priceHistory.isEmpty
                      ? const Text("Geçmiş bilgisi yok.")
                      : ListView.builder(
                        shrinkWrap: true,
                        itemCount: item.priceHistory.length,
                        itemBuilder: (c, i) {
                          final h = item.priceHistory[i];
                          return ListTile(
                            dense: true,
                            leading: const Icon(Icons.history, size: 16),
                            title: Text("${h.oldPrice} ➔ ${h.newPrice}"),
                            subtitle: Text(h.date),
                          );
                        },
                      ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Kapat"),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.transaction;
    final currency = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');
    final isIncome = t.isIncome;
    final isExpense = t.isExpense;
    final isCollection = t.entryType == 'COLLECTION';

    String title = t.customerName.isEmpty ? 'Misafir Müşteri' : t.customerName;
    if (isExpense) title = t.description.isEmpty ? 'Masraf' : t.description;

    String subtitle = "${t.timeStr} • ${t.paymentMethod} • ${t.cashierName}";
    if (isCollection) subtitle = "Tahsilat • $subtitle";
    if (isExpense) subtitle = "${t.timeStr} • ${t.paymentMethod}";

    double totalInflationDiff = 0;
    for (var item in t.items) {
      if (item.paymentStatus == 'UNPAID' &&
          item.currentPrice > item.snapshotPrice) {
        totalInflationDiff +=
            (item.currentPrice - item.snapshotPrice) * item.quantity;
      }
    }

    final canExpand = t.items.isNotEmpty;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          ListTile(
            onTap: canExpand ? () => setState(() => _isExpanded = !_isExpanded) : null,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
            ),
            leading: CircleAvatar(
              backgroundColor:
                  isIncome
                      ? AppColors.success.withOpacity(0.1)
                      : AppColors.error.withOpacity(0.1),
              child: Icon(
                isCollection
                    ? Icons.payments
                    : isExpense
                        ? Icons.arrow_upward
                        : Icons.arrow_downward,
                color: isIncome ? AppColors.success : AppColors.error,
              ),
            ),
            title: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(subtitle),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  currency.format(t.finalAmount),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: isIncome ? AppColors.success : AppColors.error,
                  ),
                ),
                if (canExpand)
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 18,
                    color: Colors.grey,
                  ),
              ],
            ),
          ),

          if (_isExpanded && canExpand)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50], // Hafif gri arka plan
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(12),
                ),
              ),
              child: Column(
                children: [
                  // Zam Uyarısı (Global)
                  if (totalInflationDiff > 0)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.orange,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Dikkat: Bu işlemde toplam ${currency.format(totalInflationDiff)} tutarında zam farkı oluşmuştur.",
                              style: const TextStyle(
                                color: Colors.orange,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Ürün Listesi
                  ...t.items.map((item) {
                    final isItemPaid = item.paymentStatus == 'PAID';
                    final hasItemInflation =
                        !isItemPaid && (item.currentPrice > item.snapshotPrice);
                    final itemDiff =
                        hasItemInflation
                            ? (item.currentPrice - item.snapshotPrice) *
                                item.quantity
                            : 0.0;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Miktar x Ad
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.productName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  "${item.quantity.toStringAsFixed(0)} x ${currency.format(item.snapshotPrice)}",
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Durum & Fiyat
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  currency.format(item.displayTotalPrice),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                if (hasItemInflation)
                                  InkWell(
                                    onTap:
                                        () => _showPriceHistoryDialog(
                                          context,
                                          item,
                                        ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        const Icon(
                                          Icons.trending_up,
                                          size: 12,
                                          color: Colors.red,
                                        ),
                                        const SizedBox(width: 2),
                                        Text(
                                          "+${currency.format(itemDiff)}",
                                          style: const TextStyle(
                                            color: Colors.red,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                else
                                  Text(
                                    isItemPaid ? "Ödendi" : "Borç",
                                    style: TextStyle(
                                      fontSize: 10,
                                      color:
                                          isItemPaid
                                              ? Colors.green
                                              : Colors.orange,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
