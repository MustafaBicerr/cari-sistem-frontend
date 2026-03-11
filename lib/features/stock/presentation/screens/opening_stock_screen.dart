import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/services/barcode_handler.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/core/utils/image_utils.dart';
import 'package:mobile/features/products/presentation/providers/product_provider.dart';
import 'package:mobile/core/widgets/section_card.dart';
import 'package:mobile/core/widgets/section_title.dart';
import 'package:mobile/features/stock/domain/entities/opening_stock_item_entity.dart';
import 'package:mobile/shared/widgets/barcode_listener_wrapper.dart';
import '../providers/opening_stock_provider.dart';
import '../widgets/opening_stocks/opening_stock_header.dart';
import '../widgets/opening_stocks/opening_stock_items_zone.dart';
import 'opening_stock_mobile_screen.dart';
import 'package:mobile/shared/widgets/barcode_not_found_dialog.dart';

class OpeningStockScreen extends ConsumerStatefulWidget {
  const OpeningStockScreen({super.key});

  @override
  ConsumerState<OpeningStockScreen> createState() => _OpeningStockScreenState();
}

class _OpeningStockScreenState extends ConsumerState<OpeningStockScreen> {
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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(openingStockProvider);
    final notifier = ref.read(openingStockProvider.notifier);

    final width = MediaQuery.of(context).size.width;

    // Mobil için yeni çok adımlı ekranı kullan.
    if (width < 700) {
      return const OpeningStockMobileScreen();
    }

    return BarcodeListenerWrapper(
      onBarcodeScanned: _handleBarcodeScanned,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("İlk Stok Girişi"),
          centerTitle: false,
          elevation: 0,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionTitle("Temel Bilgiler"),
                const SizedBox(height: 8),

                SectionCard(
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: const OpeningStockHeader(),
                  ),
                ),

                const SizedBox(height: 28),

                const SectionTitle("Ürünler"),
                const SizedBox(height: 8),

                SectionCard(
                  child: OpeningStockItemsZone(
                    onBarcodeScanned: _handleBarcodeScanned,
                  ),
                ),

                const SizedBox(height: 100),
              ],
            ),
          ),
        ),

        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.save_outlined),
              label:
                  state.isLoading
                      ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                      : const Text("Stok Kaydını Oluştur"),
              onPressed:
                  state.isLoading
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
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
