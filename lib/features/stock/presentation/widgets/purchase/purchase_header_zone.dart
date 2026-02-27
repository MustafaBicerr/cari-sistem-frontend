import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../providers/purchase_form_provider.dart';
import 'supplier_autocomplete.dart'; // Bir sonraki adımda vereceğim

class PurchaseHeaderZone extends ConsumerWidget {
  const PurchaseHeaderZone({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(purchaseFormProvider);
    final notifier = ref.read(purchaseFormProvider.notifier);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.receipt_long, color: AppColors.primary),
                SizedBox(width: 8),
                Text(
                  "Fatura & Tedarikçi Bilgileri",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 32),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // SOL TARAF: TEDARİKÇİ
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SupplierAutocomplete(), // Tedarikçi Arama Kutusu
                      const SizedBox(height: 16),
                      TextFormField(
                        initialValue: state.note,
                        onChanged: notifier.updateNote,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: "Fatura Notu (Opsiyonel)",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 32),

                // SAĞ TARAF: TARİH VE NUMARA
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      TextFormField(
                        initialValue: state.invoiceNo,
                        onChanged: notifier.updateInvoiceNo,
                        decoration: InputDecoration(
                          labelText: "Fatura Numarası *",
                          prefixIcon: const Icon(Icons.tag),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        readOnly: true,
                        controller: TextEditingController(
                          text: DateFormat(
                            'dd.MM.yyyy',
                          ).format(state.invoiceDate),
                        ),
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: state.invoiceDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime.now(),
                          );
                          if (date != null) notifier.updateInvoiceDate(date);
                        },
                        decoration: InputDecoration(
                          labelText: "Fatura Tarihi *",
                          prefixIcon: const Icon(Icons.calendar_today),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        readOnly: true,
                        controller: TextEditingController(
                          text:
                              state.dueDate != null
                                  ? DateFormat(
                                    'dd.MM.yyyy',
                                  ).format(state.dueDate!)
                                  : '',
                        ),
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: state.dueDate ?? DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(
                              const Duration(days: 365),
                            ),
                          );
                          if (date != null) notifier.updateDueDate(date);
                        },
                        decoration: InputDecoration(
                          labelText: "Vade Tarihi (Opsiyonel)",
                          prefixIcon: const Icon(Icons.event_available),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
