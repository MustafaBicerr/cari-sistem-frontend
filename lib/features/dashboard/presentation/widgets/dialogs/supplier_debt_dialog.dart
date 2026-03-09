import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/dashboard_provider.dart';
import '../../../data/models/supplier_debt_model.dart';
import 'purchase_invoice_detail_dialog.dart';

class SupplierDebtDialog extends ConsumerWidget {
  const SupplierDebtDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final supplierAsync = ref.watch(supplierMasterProvider);
    final currency = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 900,
        height: 650,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Tedarikçi Borçları",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),

            const Divider(),

            Expanded(
              child: supplierAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) => Center(child: Text("Hata: $e")),
                data: (items) {
                  if (items.isEmpty) {
                    return const Center(
                      child: Text("Açık tedarikçi borcu yok."),
                    );
                  }

                  return ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, index) {
                      final item = items[index];

                      return ListTile(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => PurchaseInvoiceDetailDialog(invoiceId: item.id),
                          );
                        },
                        title: Text(
                          item.supplierName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),

                        subtitle: Text(
                          "Fatura: ${item.invoiceNo} • Vade: ${item.dueDate != null ? DateFormat('dd.MM.yyyy').format(item.dueDate!) : '-'}",
                        ),

                        trailing: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              currency.format(item.remainingAmount),
                              style: const TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "Toplam: ${currency.format(item.totalAmount)}",
                              style: const TextStyle(fontSize: 11),
                            ),
                          ],
                        ),
                      );
                    },
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
