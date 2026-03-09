import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/barcode_handler.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/barcode_listener_wrapper.dart';
import '../../../../shared/widgets/barcode_scanner_sheet.dart';
import '../../domain/models/product.dart';
import '../providers/product_controller.dart';
import '../widgets/product_card.dart';
import '../widgets/product_form_dialog.dart';
import '../widgets/non_tenant_product_info_dialog.dart';

class ProductListScreen extends ConsumerStatefulWidget {
  const ProductListScreen({super.key});

  @override
  ConsumerState<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends ConsumerState<ProductListScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _handleBarcodeScanned(String barcode) {
    final handler = ref.read(barcodeHandlerProvider);
    handler.handleBarcode(
      context,
      barcode,
      autoCreateTenantProduct: false,
      onFound: (result) {
        if (!result.isTenantProduct) {
          showDialog(
            context: context,
            builder: (_) => NonTenantProductInfoDialog(data: result.data),
          );
          return;
        }

        Product? product = ref.read(productControllerProvider).findProductById(result.id);
        if (product == null) {
          try {
            product = Product.fromJson(result.data);
          } catch (_) {}
        }
        if (product != null) {
          showDialog(
            context: context,
            builder: (_) => ProductFormDialog(product: product),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Artık filtrelenmiş listeyi dinliyoruz
    final productsAsync = ref.watch(filteredProductListProvider);

    debugPrint(
      '[PRODUCT DEBUG][SCREEN] ProductListScreen build\n'
      'AsyncValue state: ${productsAsync.runtimeType}',
    );

    return BarcodeListenerWrapper(
      onBarcodeScanned: _handleBarcodeScanned,
      onClearFocusedField: () => _searchCtrl.clear(),
      child: Scaffold(
        // Sayfa başlığı ve Ekle butonu
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            // Dialogu aç
            showDialog(
              context: context,
              builder: (context) => const ProductFormDialog(),
            );
          },
          backgroundColor: AppColors.primary,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text("Yeni Ürün", style: TextStyle(color: Colors.white)),
        ),
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Ürünler & Stok",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (value) {
                        ref.read(productControllerProvider).searchProducts(value);
                      },
                      decoration: InputDecoration(
                        hintText: "Ürün adı veya barkod numarası arayın...",
                        prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.qr_code_scanner, color: AppColors.primary),
                          tooltip: "Kamera ile barkod tara",
                          onPressed: () {
                            BarcodeScannerSheet.show(context, onScanned: _handleBarcodeScanned);
                          },
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // --- DÜZELTİLEN KISIM BİTİŞ ---
              const SizedBox(height: 16),

              // LİSTELEME ALANI
              Expanded(
                child: productsAsync.when(
                  loading:
                      () => const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => Center(child: Text('Hata: $err')),
                  data: (products) {
                    debugPrint(
                      '[PRODUCT DEBUG][SCREEN] Products loaded\n'
                      'Count: ${products.length}',
                    );

                    if (products.isEmpty) {
                      return const Center(
                        child: Text("Henüz ürün eklenmemiş."),
                      );
                    }

                    // Responsive Grid Builder
                    return LayoutBuilder(
                      builder: (context, constraints) {
                        int crossAxisCount = 2; // Mobil
                        if (constraints.maxWidth > 1100) {
                          crossAxisCount = 5; // Desktop
                        } else if (constraints.maxWidth > 700) {
                          crossAxisCount = 3; // Tablet
                        }

                        return GridView.builder(
                          // SİHİRLİ DOKUNUŞ 2: cacheExtent
                          // Ekranda görünmeyen ama sıradaki 1000 piksellik alandaki
                          // kartları önceden hazırlar. Scroll yaparken "çizim" beklemezsin.
                          cacheExtent: 1000,

                          // Fizik motorunu PC için iyileştir (Mouse ile kaydırmayı rahatlatır)
                          physics: const BouncingScrollPhysics(),

                          addAutomaticKeepAlives:
                              false, // Görünmeyenleri hafızada tutma, öldür.
                          addRepaintBoundaries: true, // Her elemanı izole et

                          padding: const EdgeInsets.only(
                            bottom: 80,
                          ), // Fab butonu altı için boşluk
                          itemCount: products.length,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                childAspectRatio: 0.75,
                              ),
                          itemBuilder: (context, index) {
                            return ProductCard(product: products[index]);
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
