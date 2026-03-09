import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/barcode_handler.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/image_utils.dart';
import '../../../../shared/widgets/barcode_listener_wrapper.dart';
import '../../../../shared/widgets/barcode_not_found_dialog.dart';
import '../../../../core/widgets/dialogs/info_dialog.dart';
import '../../../../features/products/presentation/providers/product_provider.dart';
import '../providers/purchase_form_provider.dart';
import '../widgets/purchase/purchase_header_zone.dart';
import '../widgets/purchase/purchase_items_zone.dart';
import '../widgets/purchase/purchase_summary_zone.dart';

class StockEntryScreen extends ConsumerStatefulWidget {
  const StockEntryScreen({super.key});

  @override
  ConsumerState<StockEntryScreen> createState() => _StockEntryScreenState();
}

class _StockEntryScreenState extends ConsumerState<StockEntryScreen> {
  String? _lastProcessedBarcode;
  DateTime? _lastProcessedTime;
  bool _isBarcodeLookupInProgress = false;

  void _addProductToPurchase(
    String id,
    String name,
    double buyingPrice,
    double sellingPrice,
    double vatRate,
    String source,
    String? imgUrl,
  ) {
    final purchaseNotifier = ref.read(purchaseFormProvider.notifier);
    final purchaseState = ref.read(purchaseFormProvider);
    if (purchaseState.items.any((i) => i.productId.toString() == id)) {
      return;
    }
    purchaseNotifier.addItem(
      id,
      name,
      buyingPrice,
      sellingPrice,
      vatRate,
      source,
      imgUrl,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("$name faturaya eklendi."),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _handleBarcodeScanned(String barcode) {
    final normalizedBarcode = barcode.trim();
    if (normalizedBarcode.isEmpty) return;

    if (_isBarcodeLookupInProgress) return;

    final now = DateTime.now();
    if (_lastProcessedBarcode == normalizedBarcode &&
        _lastProcessedTime != null &&
        now.difference(_lastProcessedTime!).inMilliseconds < 1200) {
      return;
    }

    _lastProcessedBarcode = normalizedBarcode;
    _lastProcessedTime = now;
    _isBarcodeLookupInProgress = true;

    final handler = ref.read(barcodeHandlerProvider);
    handler
        .handleBarcode(
      context,
      normalizedBarcode,
      onFound: (result) {
        final imgUrl = ImageUtils.getImageUrl(
          result.data['custom_image_path']?.toString(),
          result.data['full_image_url']?.toString(),
        ) ?? result.data['image_path']?.toString();
        _addProductToPurchase(
          result.id,
          result.name,
          result.buyingPrice,
          result.sellingPrice,
          result.vatRate.toDouble(),
          result.isTenantProduct ? 'local' : 'global',
          imgUrl,
        );
      },
      onNotFound: (b) {
        BarcodeNotFoundDialog.show(
          context,
          barcode: b,
          onAddBarcodeSuccessWithProduct: (product) {
            ref.invalidate(productListProvider);
            final id = product['id']?.toString() ?? '';
            final name = product['name']?.toString() ?? '';
            final buyingPrice = (product['buying_price'] ?? 0) is num
                ? (product['buying_price'] ?? 0).toDouble()
                : 0.0;
            final sellingPrice = (product['selling_price'] ?? 0) is num
                ? (product['selling_price'] ?? 0).toDouble()
                : 0.0;
            final vatRate = (product['vat_rate'] ?? 20) is int
                ? (product['vat_rate'] ?? 20).toDouble()
                : 20.0;
            final imgUrl = product['full_image_url'] ?? product['image_path'];
            _addProductToPurchase(
              id,
              name,
              buyingPrice,
              sellingPrice,
              vatRate,
              'local',
              imgUrl?.toString(),
            );
          },
        );
      },
    )
        .whenComplete(() {
      if (mounted) {
        _isBarcodeLookupInProgress = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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

    return BarcodeListenerWrapper(
      onBarcodeScanned: _handleBarcodeScanned,
      child: Scaffold(
        backgroundColor: Colors.grey.shade100,
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
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const PurchaseHeaderZone(), // ZONE A: Başlık ve Tedarikçi
                            const SizedBox(height: 24),
                            PurchaseItemsZone(
                              onBarcodeScanned: _handleBarcodeScanned,
                            ), // ZONE B
                            const SizedBox(height: 24),
                            const PurchaseSummaryZone(), // ZONE C: Alt Toplamlar
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
      ),
    );
  }
}
