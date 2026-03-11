import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/barcode_handler.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/image_utils.dart';
import '../../../../shared/widgets/barcode_listener_wrapper.dart';
import '../../../../shared/widgets/barcode_not_found_dialog.dart';
import '../../../../core/widgets/dialogs/info_dialog.dart';
import '../../../products/presentation/providers/product_provider.dart';
import '../providers/purchase_form_provider.dart';
import '../widgets/purchase/purchase_header_mobile_zone.dart';
import '../widgets/purchase/purchase_items_mobile_zone.dart';
import '../widgets/purchase/purchase_summary_mobile_zone.dart';

/// Mobil için çok adımlı stok giriş ekranı.
/// 1. Adım: Evrak Bilgileri
/// 2. Adım: Fatura Kalemleri
/// 3. Adım: Ödeme Şekli + Fatura Dip Toplamları
class StockEntryMobileScreen extends ConsumerStatefulWidget {
  const StockEntryMobileScreen({super.key});

  @override
  ConsumerState<StockEntryMobileScreen> createState() =>
      _StockEntryMobileScreenState();
}

class _StockEntryMobileScreenState
    extends ConsumerState<StockEntryMobileScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  String? _lastProcessedBarcode;
  DateTime? _lastProcessedTime;
  bool _isBarcodeLookupInProgress = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

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
            final imgUrl = ImageUtils.getImageUrl(
              product['image_path']?.toString(),
              product['full_image_url']?.toString(),
            );
            _addProductToPurchase(
              id,
              name,
              buyingPrice,
              sellingPrice,
              vatRate,
              'local',
              imgUrl,
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

  void _goToPage(int index) {
    if (index < 0 || index > 2) return;
    setState(() => _currentPage = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
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

    final steps = ["Evrak Bilgileri", "Fatura Kalemleri", "Ödeme & Özet"];

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
        ),
        body: Column(
          children: [
            // Adım başlığı ve küçük açıklama
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    steps[_currentPage],
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Parmağınızla kaydırarak veya aşağıdaki ileri/geri butonlarıyla adımlar arasında geçiş yapabilirsiniz.",
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildStepDots(),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                children: [
                  const _DocumentStepPage(),
                  _ItemsStepPage(onBarcodeScanned: _handleBarcodeScanned),
                  const _SummaryStepPage(),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _currentPage == 0
                            ? null
                            : () => _goToPage(_currentPage - 1),
                        icon: const Icon(Icons.chevron_left),
                        label: const Text("Geri"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _currentPage == steps.length - 1
                            ? null
                            : () => _goToPage(_currentPage + 1),
                        icon: const Icon(Icons.chevron_right),
                        label: const Text("İleri"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
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
                      onPressed: state.isLoading
                          ? null
                          : () async {
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
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: state.isLoading
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save),
                      label: const Text(
                        "Faturayı Kaydet",
                        style: TextStyle(
                          fontSize: 15,
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
      ),
    );
  }

  Widget _buildStepDots() {
    return Row(
      children: List.generate(3, (index) {
        final bool isActive = index == _currentPage;
        return Container(
          margin: const EdgeInsets.only(right: 6),
          width: isActive ? 16 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}

// --- ADIM SAYFALARI ---

class _DocumentStepPage extends StatelessWidget {
  const _DocumentStepPage();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          PurchaseHeaderMobileZone(),
          SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _ItemsStepPage extends StatelessWidget {
  final void Function(String barcode)? onBarcodeScanned;

  const _ItemsStepPage({this.onBarcodeScanned});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PurchaseItemsMobileZone(onBarcodeScanned: onBarcodeScanned),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _SummaryStepPage extends StatelessWidget {
  const _SummaryStepPage();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          PurchaseSummaryMobileZone(),
          SizedBox(height: 80),
        ],
      ),
    );
  }
}

