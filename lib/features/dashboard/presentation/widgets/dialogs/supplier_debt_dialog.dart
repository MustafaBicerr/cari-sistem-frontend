import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/dashboard_provider.dart';
import '../../../data/models/supplier_debt_model.dart';
import '../../screens/purchase_invoice_detail_screen.dart';
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

                // 🔄 Aynı tedarikçiye ait birden fazla faturayı grupla
                final Map<String, _SupplierDebtGroup> grouped = {};

                for (final item in items) {
                  final key = item.supplierId.isNotEmpty
                      ? item.supplierId
                      : item.supplierName; // Fallback olarak isim

                  final group = grouped.putIfAbsent(
                    key,
                    () => _SupplierDebtGroup(
                      supplierId: item.supplierId,
                      supplierName: item.supplierName,
                      invoices: [],
                      totalRemaining: 0,
                    ),
                  );

                  group.invoices.add(item);
                  group.totalRemaining += item.remainingAmount;
                }

                final groups = grouped.values.toList()
                  ..sort(
                    (a, b) => b.totalRemaining.compareTo(a.totalRemaining),
                  );

                return ListView.separated(
                  itemCount: groups.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final group = groups[index];

                    return ExpansionTile(
                      title: Text(
                        group.supplierName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        "Borçlu fatura sayısı: ${group.invoices.length}",
                      ),
                      trailing: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            currency.format(group.totalRemaining),
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      children: group.invoices.map((invoice) {
                        return ListTile(
                          onTap: () {
                            final isMobile =
                                MediaQuery.of(context).size.width < 600;
                            if (isMobile) {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => PurchaseInvoiceDetailScreen(
                                    invoiceId: invoice.id,
                                  ),
                                ),
                              );
                            } else {
                              showDialog(
                                context: context,
                                builder:
                                    (context) => PurchaseInvoiceDetailDialog(
                                      invoiceId: invoice.id,
                                    ),
                              );
                            }
                          },
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          title: Text(
                            "Fatura: ${invoice.invoiceNo}",
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            "Vade: ${invoice.dueDate != null ? DateFormat('dd.MM.yyyy').format(invoice.dueDate!) : '-'}",
                          ),
                          trailing: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                currency.format(invoice.remainingAmount),
                                style: const TextStyle(
                                  color: Colors.redAccent,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                "Toplam: ${currency.format(invoice.totalAmount)}",
                                style: const TextStyle(fontSize: 11),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
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

class _SupplierDebtGroup {
  _SupplierDebtGroup({
    required this.supplierId,
    required this.supplierName,
    required this.invoices,
    required this.totalRemaining,
  });

  final String supplierId;
  final String supplierName;
  final List<SupplierDebtMasterModel> invoices;
  double totalRemaining;
}
