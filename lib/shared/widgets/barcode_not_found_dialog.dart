import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'add_barcode_dialog.dart';

/// Barkod bulunamadığında gösterilen dialog
class BarcodeNotFoundDialog extends StatelessWidget {
  final String barcode;
  final VoidCallback? onAddBarcodeSuccess;
  final void Function(Map<String, dynamic> product)? onAddBarcodeSuccessWithProduct;

  const BarcodeNotFoundDialog({
    super.key,
    required this.barcode,
    this.onAddBarcodeSuccess,
    this.onAddBarcodeSuccessWithProduct,
  });

  static Future<void> show(
    BuildContext context, {
    required String barcode,
    VoidCallback? onAddBarcodeSuccess,
    void Function(Map<String, dynamic> product)? onAddBarcodeSuccessWithProduct,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => BarcodeNotFoundDialog(
        barcode: barcode,
        onAddBarcodeSuccess: onAddBarcodeSuccess,
        onAddBarcodeSuccessWithProduct: onAddBarcodeSuccessWithProduct,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.qr_code_2_rounded, size: 48, color: AppColors.warning),
            ),
            const SizedBox(height: 20),
            const Text(
              "Barkod Bulunamadı",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              "Okuttuğunuz barkod numarası ($barcode) veritabanında kayıtlı değildir.\n\nKendi işletmenizde kullanmak üzere bu barkodu kliniğinizde kaydetmek ister misiniz?",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("İptal"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      final dialogContext = context;
                      AddBarcodeDialog.show(
                        context,
                        barcode: barcode,
                        initialMasterDrug: null,
                        onSuccessWithProduct: (product) {
                          Navigator.pop(dialogContext);
                          onAddBarcodeSuccessWithProduct?.call(product);
                          onAddBarcodeSuccess?.call();
                        },
                      );
                    },
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text("Kaydet"),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
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
