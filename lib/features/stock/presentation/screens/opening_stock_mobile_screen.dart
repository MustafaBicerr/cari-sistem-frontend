import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mobile/core/services/barcode_handler.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/core/utils/image_utils.dart';
import 'package:mobile/shared/widgets/barcode_listener_wrapper.dart';
import 'package:mobile/shared/widgets/barcode_not_found_dialog.dart';
import 'package:mobile/features/products/presentation/providers/product_provider.dart';

import '../providers/opening_stock_provider.dart';
import '../widgets/opening_stocks/opening_stock_header_mobile.dart';
import '../widgets/opening_stocks/opening_stock_items_mobile_zone.dart';
import '../../domain/entities/opening_stock_item_entity.dart';

/// Mobil için çok adımlı "İlk Stok Girişi" ekranı.
/// 1. Adım: Temel Bilgiler
/// 2. Adım: Ürünler
class OpeningStockMobileScreen extends ConsumerStatefulWidget {
  const OpeningStockMobileScreen({super.key});

  @override
  ConsumerState<OpeningStockMobileScreen> createState() =>
      _OpeningStockMobileScreenState();
}

class _OpeningStockMobileScreenState
    extends ConsumerState<OpeningStockMobileScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _handleBarcodeScanned(String barcode) {
    final handler = ref.read(barcodeHandlerProvider);
    final openingNotifier = ref.read(openingStockProvider.notifier);
    final openingState = ref.read(openingStockProvider);

    handler.handleBarcode(
      context,
      barcode,
      onFound: (result) {
        final alreadyExists = openingState.items.any(
          (i) => i.productId == result.id,
        );
        if (alreadyExists) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Bu ürün zaten listede.")),
          );
          return;
        }
        final imgUrl =
            ImageUtils.getImageUrl(
              result.data['custom_image_path']?.toString(),
              result.data['full_image_url']?.toString(),
            ) ??
            result.data['image_path']?.toString();
        final newItem = OpeningStockItemEntity(
          productId: result.id,
          productName: result.name,
          imageUrl: imgUrl,
          productSource: result.isTenantProduct ? 'local' : 'global',
          quantity: 1.0,
          expirationDate: DateTime.now(),
          batchNo: '',
          location: '',
          buyingPrice: result.buyingPrice,
          sellingPrice: result.sellingPrice,
          vatRate: result.vatRate,
        );
        openingNotifier.addItem(newItem);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${result.name} listeye eklendi."),
            backgroundColor: AppColors.success,
          ),
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
                ? (product['vat_rate'] ?? 20)
                : 20;
            final imgUrl = ImageUtils.getImageUrl(
              product['image_path']?.toString(),
              product['full_image_url']?.toString(),
            );
            final newItem = OpeningStockItemEntity(
              productId: id,
              productName: name,
              imageUrl: imgUrl,
              productSource: 'local',
              quantity: 1.0,
              expirationDate: DateTime.now(),
              batchNo: '',
              location: '',
              buyingPrice: buyingPrice,
              sellingPrice: sellingPrice,
              vatRate: vatRate,
            );
            openingNotifier.addItem(newItem);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("$name listeye eklendi."),
                backgroundColor: AppColors.success,
              ),
            );
          },
        );
      },
    );
  }

  void _goToPage(int index) {
    if (index < 0 || index > 1) return;
    setState(() => _currentPage = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(openingStockProvider);
    final notifier = ref.read(openingStockProvider.notifier);

    final steps = ["Temel Bilgiler", "Ürünler"];

    return BarcodeListenerWrapper(
      onBarcodeScanned: _handleBarcodeScanned,
      child: Scaffold(
        backgroundColor: Colors.grey.shade100,
        appBar: AppBar(
          title: const Text(
            "İlk Stok Girişi",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.white,
          foregroundColor: AppColors.textPrimary,
          elevation: 0.5,
        ),
        body: Column(
          children: [
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
                  const _OpeningDocumentStepPage(),
                  _OpeningItemsStepPage(onBarcodeScanned: _handleBarcodeScanned),
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
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    icon: state.isLoading
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(
                      state.isLoading
                          ? "Kaydediliyor..."
                          : "Stok Kaydını Oluştur",
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: state.isLoading
                        ? null
                        : () async {
                            try {
                              await notifier.submitOpeningStock();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      "Opening stok başarıyla kaydedildi.",
                                    ),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(e.toString())),
                                );
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
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
      children: List.generate(2, (index) {
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

// --- Adım sayfaları ---

class _OpeningDocumentStepPage extends ConsumerWidget {
  const _OpeningDocumentStepPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Temel Bilgiler",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const OpeningStockHeaderMobile(),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _OpeningItemsStepPage extends StatelessWidget {
  final void Function(String barcode)? onBarcodeScanned;

  const _OpeningItemsStepPage({this.onBarcodeScanned});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Ürünler",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          OpeningStockItemsMobileZone(onBarcodeScanned: onBarcodeScanned),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

