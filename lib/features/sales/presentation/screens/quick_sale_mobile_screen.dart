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

class QuickSaleMobileScreen extends ConsumerStatefulWidget {
  const QuickSaleMobileScreen({super.key});

  @override
  ConsumerState<QuickSaleMobileScreen> createState() => _QuickSaleMobileScreenState();
}

class _QuickSaleMobileScreenState extends ConsumerState<QuickSaleMobileScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  bool _isSellable(Product product) => !(product.buyingPrice <= 0 && product.sellingPrice <= 0);

  void _handleBarcodeScanned(String barcode) {
    final handler = ref.read(barcodeHandlerProvider);
    handler.handleBarcode(
      context,
      barcode,
      onFound: (result) {
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

    showDialog(
      context: context,
      builder: (context) => AddToCartDialog(
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
    final productsAsync = ref.watch(filteredProductListProvider);
    final cartItems = ref.watch(cartProvider);
    final cartNotifier = ref.read(cartProvider.notifier);

    return BarcodeListenerWrapper(
      onBarcodeScanned: _handleBarcodeScanned,
      onClearFocusedField: () => _searchCtrl.clear(),
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text("Hızlı Satış & POS"),
            elevation: 0,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(52),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: const TabBar(
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicator: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.all(Radius.circular(999)),
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: AppColors.textSecondary,
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    tabs: [
                      Tab(text: 'Ürünler & Sepet'),
                      Tab(text: 'Müşteri & Ödeme'),
                    ],
                  ),
                ),
              ),
            ),
          ),
          body: TabBarView(
            children: [
              _buildProductsTab(context, productsAsync, cartItems, cartNotifier),
              _buildSummaryTab(context, cartNotifier),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductsTab(
    BuildContext context,
    AsyncValue<List<Product>> productsAsync,
    List<CartItem> cartItems,
    CartNotifier cartNotifier,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: _searchCtrl,
                onChanged: (val) => ref.read(productControllerProvider).searchProducts(val),
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
              Expanded(
                child: productsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Center(child: Text("Hata: $err")),
                  data: (products) {
                    final sellableProducts = products.where(_isSellable).toList();
                    if (sellableProducts.isEmpty) {
                      return const Center(
                        child: Text("Satışa uygun ürün bulunamadı."),
                      );
                    }

                    int crossAxisCount = constraints.maxWidth > 500 ? 3 : 2;

                    return GridView.builder(
                      cacheExtent: 1000,
                      physics: const BouncingScrollPhysics(),
                      itemCount: sellableProducts.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        childAspectRatio: 0.75,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemBuilder: (ctx, i) {
                        return ProductCard(
                          product: sellableProducts[i],
                          isPosMode: true,
                          onAddToCart: () => _onProductTap(sellableProducts[i]),
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              const Divider(),
              SizedBox(
                height: 140,
                child: cartItems.isEmpty
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
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (ctx, i) {
                          final item = cartItems[i];
                          return _HorizontalCartItem(
                            item: item,
                            onAdd: () => cartNotifier.updateQuantity(i, item.quantity + 1),
                            onRemove: () => cartNotifier.updateQuantity(i, item.quantity - 1),
                            onDelete: () => cartNotifier.removeItem(i),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryTab(BuildContext context, CartNotifier cartNotifier) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Expanded(
            child: SaleSummaryPanel(
              subTotal: cartNotifier.subTotal,
              discount: 0,
              onCompleteSale: () {},
            ),
          ),
        ],
      ),
    );
  }
}

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
      width: 280,
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
          Text(
            "₺${item.unitPrice.toStringAsFixed(2)} / adet",
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
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

