import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile/features/stock/presentation/screens/opening_stock_screen.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../providers/purchase_form_provider.dart';
import 'supplier_autocomplete.dart';

class PurchaseHeaderZone extends ConsumerWidget {
  const PurchaseHeaderZone({super.key});

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
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Row(
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
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "Evrak Bilgileri",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.all(16),
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
                                      builder:
                                          (_) => const OpeningStockScreen(),
                                    ),
                                  );
                                },
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
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
                              RichText(
                                text: const TextSpan(
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
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
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
                ),
              ],
            ),
            const Divider(height: 32, color: AppColors.background),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // SOL TARAF: TEDARİKÇİ
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SupplierAutocomplete(), // Tedarikçi Arama (Modern)
                      const SizedBox(height: 20),
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
                const SizedBox(width: 48), // Geniş ekranlar için ferahlık
                // SAĞ TARAF: TARİH VE NUMARA
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      _buildModernInput(
                        label: "Fatura Numarası *",
                        hint: "Örn: GİB2026...",
                        icon: Icons.tag,
                        initialValue: state.invoiceNo,
                        onChanged: notifier.updateInvoiceNo,
                      ),
                      const SizedBox(height: 20),
                      _buildModernInput(
                        label: "Fatura Tarihi *",
                        hint: "Seçiniz",
                        icon: Icons.calendar_today,
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
                      ),
                      const SizedBox(height: 20),
                      _buildModernInput(
                        label: "Vade Tarihi (Opsiyonel)",
                        hint: "Belirtilmedi",
                        icon: Icons.event_available,
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

  // 🔥 MODERN INPUT MİMARİSİ (SaaS Standardı)
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
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        TextFormField(
          controller: controller,
          initialValue: initialValue,
          onChanged: onChanged,
          onTap: onTap,
          readOnly: readOnly,
          maxLines: maxLines,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            prefixIcon:
                maxLines > 1
                    ? null
                    : Icon(icon, color: AppColors.primary, size: 20),
            filled: true,
            fillColor: Colors.grey.shade50, // Yumuşak arka plan
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: maxLines > 1 ? 16 : 0,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ), // Kenarlık yok
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
            ), // Çok hafif çerçeve
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.5,
              ),
            ), // Focuslanınca net çerçeve
          ),
        ),
      ],
    );
  }
}
