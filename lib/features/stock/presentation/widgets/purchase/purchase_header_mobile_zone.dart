import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../providers/purchase_form_provider.dart';
import 'supplier_autocomplete.dart';
import '../../screens/opening_stock_screen.dart';

/// Mobil için dikey yerleşimli "Evrak Bilgileri" kartı.
/// İş mantığı masaüstü `PurchaseHeaderZone` ile aynıdır; sadece layout mobil için optimize edilmiştir.
class PurchaseHeaderMobileZone extends ConsumerWidget {
  const PurchaseHeaderMobileZone({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(purchaseFormProvider);
    final notifier = ref.read(purchaseFormProvider.notifier);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlık satırı
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.receipt_long,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  "Evrak Bilgileri",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // "İlk Stok Girişi" bilgi kartı (tam genişlikte)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    color: Colors.blue.shade700,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const OpeningStockScreen(),
                              ),
                            );
                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            foregroundColor: AppColors.primary,
                          ),
                          child: const Text(
                            "İlk Stok Girişi",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                              decorationColor: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text.rich(
                          TextSpan(
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.45,
                              color: Colors.black87,
                            ),
                            children: [
                              TextSpan(
                                text: "İlk giriş stoğu, işletmenizin ",
                              ),
                              TextSpan(
                                text: "açılış anındaki stok bakiyesini",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              TextSpan(
                                text:
                                    " tek seferde kaydetmenizi sağlar. Daha önce hiç stok girişi yapmadıysanız önce buradan başlayın.",
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            const Divider(height: 1, color: AppColors.background),
            const SizedBox(height: 16),

            // Tedarikçi + Diğer alanlar (tamamen dikey)
            const SupplierAutocomplete(),
            const SizedBox(height: 16),

            _buildModernInput(
              label: "Fatura Numarası *",
              hint: "Örn: GİB2026...",
              icon: Icons.tag,
              initialValue: state.invoiceNo,
              onChanged: notifier.updateInvoiceNo,
            ),
            const SizedBox(height: 16),

            _buildModernInput(
              label: "Fatura Tarihi *",
              hint: "Seçiniz",
              icon: Icons.calendar_today,
              readOnly: true,
              controller: TextEditingController(
                text: DateFormat('dd.MM.yyyy').format(state.invoiceDate),
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
            ),
            const SizedBox(height: 16),

            _buildModernInput(
              label: "Vade Tarihi (Opsiyonel)",
              hint: "Belirtilmedi",
              icon: Icons.event_available,
              readOnly: true,
              controller: TextEditingController(
                text: state.dueDate != null
                    ? DateFormat('dd.MM.yyyy').format(state.dueDate!)
                    : '',
              ),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: state.dueDate ?? DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) notifier.updateDueDate(date);
              },
            ),
            const SizedBox(height: 16),

            _buildModernInput(
              label: "Fatura Notu (Opsiyonel)",
              hint: "Faturayla ilgili eklemek istedikleriniz...",
              icon: Icons.notes,
              initialValue: state.note,
              onChanged: notifier.updateNote,
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernInput({
    required String label,
    required String hint,
    required IconData icon,
    TextEditingController? controller,
    String? initialValue,
    Function(String)? onChanged,
    VoidCallback? onTap,
    bool readOnly = false,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        // Editable alanlar için controller kullanmayalım ki her rebuild'de
        // cursor başa dönüp karakterler ters sırada yazılmasın.
        readOnly || controller != null
            ? TextFormField(
                controller:
                    controller ??
                    TextEditingController(text: initialValue ?? ''),
                readOnly: readOnly,
                onTap: onTap,
                maxLines: maxLines,
                decoration: InputDecoration(
                  hintText: hint,
                  prefixIcon: Icon(icon, color: AppColors.primary),
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
              )
            : TextFormField(
                initialValue: initialValue ?? '',
                readOnly: false,
                onTap: onTap,
                maxLines: maxLines,
                onChanged: onChanged,
                decoration: InputDecoration(
                  hintText: hint,
                  prefixIcon: Icon(icon, color: AppColors.primary),
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
              ),
      ],
    );
  }
}

