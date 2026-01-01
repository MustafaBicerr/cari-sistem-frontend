import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/products/presentation/widgets/add_product_dialog.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/product_controller.dart';
import '../widgets/product_card.dart';
import '../widgets/product_edit_dialog.dart';

class ProductListScreen extends ConsumerStatefulWidget {
  const ProductListScreen({super.key});

  @override
  ConsumerState<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends ConsumerState<ProductListScreen> {
  final FocusNode _focusNode = FocusNode();
  final StringBuffer _barcodeBuffer = StringBuffer();
  DateTime? _lastEventTime;

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _handleKeyEvent(KeyEvent event) {
    // DEBUG: Gelen tuş olayını konsola bas
    debugPrint(
      "Key Event: ${event.runtimeType} | Key: ${event.logicalKey.keyLabel} | Char: ${event.character}",
    );

    if (event is KeyDownEvent) {
      final now = DateTime.now();
      final isEnter = event.logicalKey == LogicalKeyboardKey.enter;

      // Hız Algoritması:
      // 1. Enter tuşu hariç (Enter gecikmeli gelse de buffer'ı işlemeli)
      // 2. Tuşlar arası 250ms'den fazlaysa (Toleransı artırdık) manuel giriş kabul et
      if (!isEnter &&
          _lastEventTime != null &&
          now.difference(_lastEventTime!).inMilliseconds > 250) {
        debugPrint("--- Zaman aşımı (Süre > 250ms), Buffer temizleniyor ---");
        _barcodeBuffer.clear();
      }
      _lastEventTime = now;

      if (isEnter) {
        debugPrint("ENTER tuşu algılandı. Buffer içeriği: $_barcodeBuffer");
        if (_barcodeBuffer.isNotEmpty) {
          _handleScannedBarcode(_barcodeBuffer.toString());
          _barcodeBuffer.clear();
        }
      } else if (event.character != null && event.character!.isNotEmpty) {
        // Sadece yazdırılabilir karakterleri ekle
        _barcodeBuffer.write(event.character);
        debugPrint(
          "Buffer'a eklendi: ${event.character} | Güncel Buffer: $_barcodeBuffer",
        );
      }
    }
  }

  void _handleScannedBarcode(String barcode) {
    // Focus'u search bar'dan veya başka yerden alıp ana node'a verelim ki klavye açılmasın
    _focusNode.requestFocus();

    final controller = ref.read(productControllerProvider);
    final product = controller.findProductByBarcode(barcode);

    if (product != null) {
      // DURUM A: Ürün bulundu -> Düzenleme ekranını aç
      showDialog(
        context: context,
        builder: (context) => ProductEditDialog(product: product),
      );
    } else {
      // DURUM B: Ürün yok -> Ekleme ekranını aç (Barkod dolu şekilde)
      showDialog(
        context: context,
        builder: (context) => AddProductDialog(initialBarcode: barcode),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Artık filtrelenmiş listeyi dinliyoruz
    final productsAsync = ref.watch(filteredProductListProvider);

    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true, // Sayfa açılınca dinlemeye başla
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        // Sayfa başlığı ve Ekle butonu
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            // Dialogu aç
            showDialog(
              context: context,
              builder: (context) => const AddProductDialog(),
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

              // ARAMA ÇUBUĞU
              TextField(
                onChanged: (value) {
                  ref.read(productControllerProvider).searchProducts(value);
                },
                decoration: InputDecoration(
                  hintText: "Ürün adı veya barkod numarası arayın...",
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppColors.textSecondary,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // LİSTELEME ALANI
              Expanded(
                child: productsAsync.when(
                  loading:
                      () => const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => Center(child: Text('Hata: $err')),
                  data: (products) {
                    if (products.isEmpty) {
                      return const Center(
                        child: Text("Henüz ürün eklenmemiş."),
                      );
                    }

                    // Responsive Grid Builder
                    return LayoutBuilder(
                      builder: (context, constraints) {
                        int crossAxisCount = 2; // Mobil
                        if (constraints.maxWidth > 1100)
                          crossAxisCount = 5; // Desktop
                        else if (constraints.maxWidth > 700)
                          crossAxisCount = 3; // Tablet

                        return GridView.builder(
                          itemCount: products.length,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                childAspectRatio: 0.75, // Kartın boy/en oranı
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
