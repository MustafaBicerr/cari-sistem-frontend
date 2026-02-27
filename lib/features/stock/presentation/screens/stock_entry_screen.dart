import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/dialogs/info_dialog.dart';
import '../providers/purchase_form_provider.dart';
import '../widgets/purchase/purchase_header_zone.dart';
import '../widgets/purchase/purchase_items_zone.dart';
import '../widgets/purchase/purchase_summary_zone.dart';

class StockEntryScreen extends ConsumerWidget {
  const StockEntryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(purchaseFormProvider);
    final notifier = ref.read(purchaseFormProvider.notifier);

    // Hata dinleyicisi (Eğer provider'da hata olursa dialog gösterir)
    ref.listen<PurchaseFormState>(purchaseFormProvider, (previous, next) {
      if (next.error != null && (previous?.error != next.error)) {
        InfoDialog.show(
          context,
          title: "Hata",
          message: next.error!,
          type: InfoDialogType.error,
        );
      }
    });

    return Scaffold(
      backgroundColor: Colors.grey.shade100, // Hafif gri arka plan
      appBar: AppBar(
        title: const Text(
          "Yeni Alım Faturası (Mal Kabul)",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
        actions: [
          IconButton(
            tooltip: "Formu Temizle",
            icon: const Icon(Icons.refresh),
            onPressed: () => notifier.resetForm(),
          ),
        ],
      ),
      body:
          state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  // ANA SCROLL ALANI (ZONELAR BURADA)
                  const Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          PurchaseHeaderZone(), // ZONE A: Başlık ve Tedarikçi
                          SizedBox(height: 24),
                          PurchaseItemsZone(), // ZONE B: Ürün Tablosu
                          SizedBox(height: 24),
                          PurchaseSummaryZone(), // ZONE C: Alt Toplamlar
                        ],
                      ),
                    ),
                  ),

                  // SABİT ALT BAR (KAYDET BUTONU)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, -5),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            "İptal Et",
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          onPressed: () async {
                            final success = await notifier.saveInvoice();
                            if (success && context.mounted) {
                              InfoDialog.show(
                                context,
                                title: "Başarılı",
                                message:
                                    "Fatura ve stoklar başarıyla kaydedildi.",
                                type: InfoDialogType.success,
                              );
                              notifier.resetForm(); // Formu sıfırla
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.save),
                          label: const Text(
                            "Faturayı Kaydet",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
    );
  }
}
