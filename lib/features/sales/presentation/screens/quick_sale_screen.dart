import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/barcode_handler.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/barcode_listener_wrapper.dart';
import '../../../../shared/widgets/barcode_scanner_sheet.dart';
import '../../../products/domain/models/product.dart';
import '../../../products/presentation/providers/product_controller.dart';
import '../../../products/presentation/widgets/product_card.dart';
import '../providers/cart_provider.dart';
import '../widgets/add_to_cart_dialog.dart';
import '../widgets/sale_cart_list.dart';
import '../widgets/sale_summary_panel.dart';

class QuickSaleScreen extends ConsumerStatefulWidget {
  const QuickSaleScreen({super.key});

  @override
  ConsumerState<QuickSaleScreen> createState() => _QuickSaleScreenState();
}

class _QuickSaleScreenState extends ConsumerState<QuickSaleScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  bool _isSellable(Product product) => !(product.buyingPrice <= 0 && product.sellingPrice <= 0);

  void _handleBarcodeScanned(String barcode) {
    final handler = ref.read(barcodeHandlerProvider);
    handler.handleBarcode(
      context,
      barcode,
      onFound: (result) {
        // Master'da barkod varsa backend her zaman tenant product döndürür - direkt sepete ekle
        Product? product = ref.read(productControllerProvider).findProductById(result.id);
        if (product == null) {
          try {
            product = Product.fromJson(result.data);
          } catch (_) {}
        }
        if (product != null) {
          _onProductTap(product);
        }
      },
    );
  }

  // --- SEPET İŞLEMLERİ ---
  void _onProductTap(Product product) {
    if (!_isSellable(product)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Bu ürün satışa uygun değil. Önce Fatura Girişi veya Açılış Stoğu ekranında fiyat/stok tanımlayın.",
          ),
        ),
      );
      return;
    }

    // Miktar seçme dialogunu aç
    showDialog(
      context: context,
      builder:
          (context) => AddToCartDialog(
            product: product,
            onConfirmed: (qty) {
              final cartItem = CartItem(
                productId: product.id,
                name: product.name,
                unitPrice: product.sellingPrice,
                quantity: qty,
              );
              ref.read(cartProvider.notifier).addItem(cartItem);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("${product.name} sepete eklendi!"),
                  duration: const Duration(milliseconds: 800),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                  width: 300,
                ),
              );
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Ürün listesini Products ekranındaki gibi filtered provider'dan alıyoruz
    final productsAsync = ref.watch(filteredProductListProvider);
    final cartItems = ref.watch(cartProvider);
    final cartNotifier = ref.read(cartProvider.notifier);

    return BarcodeListenerWrapper(
      onBarcodeScanned: _handleBarcodeScanned,
      onClearFocusedField: () => _searchCtrl.clear(),
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text("Hızlı Satış & POS"), elevation: 0),
        body: LayoutBuilder(
        builder: (context, constraints) {
          // Responsive Kırılma Noktası
          final isDesktop = constraints.maxWidth > 900;

          return Row(
            children: [
              // --- SOL TARAF (ÜRÜNLER + SEPET) ---
              Expanded(
                flex: 7,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // 1. ARAMA ÇUBUĞU (Products ekranındaki mantık)
                      TextField(
                        controller: _searchCtrl,
                        onChanged:
                            (val) => ref
                                .read(productControllerProvider)
                                .searchProducts(val),
                        decoration: InputDecoration(
                          hintText: "Ürün adı veya barkod okutun...",
                          prefixIcon: const Icon(
                            Icons.search,
                            color: AppColors.textSecondary,
                          ),
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

                      const SizedBox(height: 16),

                      // 2. ÜRÜN GRID (Kırmızı Alan)
                      Expanded(
                        flex: 3,
                        child: productsAsync.when(
                          loading:
                              () => const Center(
                                child: CircularProgressIndicator(),
                              ),
                          error: (err, _) => Center(child: Text("Hata: $err")),
                          data: (products) {
                            final sellableProducts = products.where(_isSellable).toList();
                            if (sellableProducts.isEmpty)
                              return const Center(
                                child: Text("Satışa uygun ürün bulunamadı."),
                              );

                            // Grid sütun sayısını dinamik ayarla
                            int crossAxisCount =
                                constraints.maxWidth > 1200
                                    ? 4
                                    : (isDesktop ? 3 : 2);

                            return GridView.builder(
                              cacheExtent: 1000,
                              physics: const BouncingScrollPhysics(),
                              itemCount: sellableProducts.length,
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: crossAxisCount,
                                    childAspectRatio: 0.75, // Kart oranı
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 12,
                                  ),
                              itemBuilder: (ctx, i) {
                                return ProductCard(
                                  product: sellableProducts[i],
                                  isPosMode: true, // 🔥 POS Modu Aktif
                                  onAddToCart: () => _onProductTap(sellableProducts[i]),
                                );
                              },
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 16),
                      const Divider(),

                      // 3. YATAY SEPET LİSTESİ (Yeşil Alan)
                      SizedBox(
                        height: 140, // Yeterli yükseklik
                        child:
                            cartItems.isEmpty
                                ? Center(
                                  child: Text(
                                    "Sepet Boş 🛒\nÜrün eklemek için yukarıdan seçin.",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                )
                                : ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: cartItems.length,
                                  separatorBuilder:
                                      (_, __) => const SizedBox(width: 12),
                                  itemBuilder: (ctx, i) {
                                    final item = cartItems[i];
                                    return _HorizontalCartItem(
                                      item: item,
                                      onAdd:
                                          () => cartNotifier.updateQuantity(
                                            i,
                                            item.quantity + 1,
                                          ),
                                      onRemove:
                                          () => cartNotifier.updateQuantity(
                                            i,
                                            item.quantity - 1,
                                          ),
                                      onDelete:
                                          () => cartNotifier.removeItem(i),
                                    );
                                  },
                                ),
                      ),
                    ],
                  ),
                ),
              ),

              // --- SAĞ TARAF (ÖZET PANELİ) ---
              // Mobilde bunu gizleyip bir butonla açılır yapabiliriz ama
              // şimdilik senin desktop layoutuna sadık kalıyorum.
              if (isDesktop)
                Expanded(
                  flex: 3,
                  child: SaleSummaryPanel(
                    // 1. Toplam Tutar: CartNotifier üzerinden hesaplanıyor
                    subTotal: cartNotifier.subTotal,

                    // 2. İskonto: Şimdilik 0 (İleride buraya logic ekleriz)
                    discount: 0,

                    // 3. Tamamlanma Callback'i:
                    // Satış mantığını panelin içine taşıdığımız için burası artık sadece
                    // "İşlem bitti, ekranda konfetiler patlat" gibi UI efektleri için kullanılabilir.
                    // Şimdilik boş bırakıyoruz çünkü panel kendi temizliğini yapıyor.
                    onCompleteSale: () {
                      debugPrint("Satış işlemi parent tarafından duyuldu.");
                    },
                  ),
                ),
            ],
          );
        },
      ),
    ),
    );
  }
}

// --- YENİ WIDGET: YATAY SEPET KARTI (Yeşil Alan İçin) ---
class _HorizontalCartItem extends StatelessWidget {
  final CartItem item;
  final VoidCallback onAdd;
  final VoidCallback onRemove;
  final VoidCallback onDelete;

  const _HorizontalCartItem({
    required this.item,
    required this.onAdd,
    required this.onRemove,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280, // Sabit genişlik
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Üst: İsim ve Silme
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              InkWell(
                onTap: onDelete,
                child: const Icon(Icons.close, size: 18, color: Colors.grey),
              ),
            ],
          ),

          // Orta: Birim Fiyat
          Text(
            "₺${item.unitPrice.toStringAsFixed(2)} / adet",
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),

          // Alt: Miktar ve Toplam
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Miktar Kontrolü
              Container(
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    _miniBtn(Icons.remove, onRemove),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        item.quantity.toStringAsFixed(0),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    _miniBtn(Icons.add, onAdd),
                  ],
                ),
              ),
              // Toplam
              Text(
                "₺${item.total.toStringAsFixed(2)}",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(6.0),
        child: Icon(icon, size: 16, color: AppColors.textPrimary),
      ),
    );
  }
}
