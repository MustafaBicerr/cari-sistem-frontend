import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/sale_cart_list.dart';
import '../widgets/sale_product_search.dart';
import '../widgets/sale_summary_panel.dart';

class QuickSaleScreen extends StatefulWidget {
  const QuickSaleScreen({super.key});

  @override
  State<QuickSaleScreen> createState() => _QuickSaleScreenState();
}

class _QuickSaleScreenState extends State<QuickSaleScreen> {
  // --- STATE ---
  final List<CartItem> _cartItems = [];
  String _selectedPaymentMethod = 'CASH';
  // Aktif kullanıcı bilgisi (Normalde AuthProvider'dan gelir)
  final String _activeUserName = "Vet. Hasan ELÇİN";

  // --- LOGIC ---

  void _addProduct(String query) {
    // Burada backend'den ürün aranacak. Şimdilik dummy ekliyoruz.
    setState(() {
      _cartItems.add(
        CartItem(
          productId: DateTime.now().toString(), // Dummy ID
          name: "Örnek Ürün ($query)",
          unitPrice: 150.0,
        ),
      );
    });
  }

  void _updateQuantity(int index, double newQty) {
    setState(() {
      _cartItems[index].quantity = newQty;
    });
  }

  void _removeItem(int index) {
    setState(() {
      _cartItems.removeAt(index);
    });
  }

  double get _subTotal => _cartItems.fold(0, (sum, item) => sum + item.total);
  double get _discount => 0.0; // İleride indirim mantığı eklenebilir

  // Backend'e Gönderilecek Veri Paketi
  void _completeSale() {
    if (_cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Sepet boş! Lütfen ürün ekleyin.")),
      );
      return;
    }

    // 1. Transaction (Başlık) Verisi
    final transactionData = {
      "tenant_id": "CURRENT_TENANT_ID",
      "user_id": "CURRENT_USER_ID", // Auth'dan gelecek
      "customer_id": "SELECTED_CUSTOMER_ID", // Autocomplete'den gelecek
      "total_amount": _subTotal,
      "discount_amount": _discount,
      "final_amount": _subTotal - _discount,
      "payment_status": _selectedPaymentMethod == 'DEBT' ? 'UNPAID' : 'PAID',
      "payment_method": _selectedPaymentMethod,
      "note": "Hızlı Satış Ekranı",
    };

    // 2. Transaction Items (Satırlar) Verisi
    final transactionItemsData =
        _cartItems
            .map(
              (item) => {
                "product_id": item.productId,
                "quantity": item.quantity,
                "snapshot_price": item.unitPrice,
                "total_row_price": item.total,
              },
            )
            .toList();

    // 3. Debug: Konsola bas (İleride Controller'a gidecek)
    debugPrint("--- SATIŞ TAMAMLANIYOR ---");
    debugPrint("Başlık: $transactionData");
    debugPrint("Kalemler: $transactionItemsData");

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Satış başarıyla oluşturuldu! (Simülasyon)"),
        backgroundColor: AppColors.success,
      ),
    );

    // Temizle
    setState(() {
      _cartItems.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Hızlı Satış & POS"),
        actions: [
          // Aktif Kullanıcı Bilgisi
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.account_circle,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  _activeUserName,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // RESPONSIVE LOGIC
          if (constraints.maxWidth > 900) {
            // DESKTOP LAYOUT (Split View)
            return Row(
              children: [
                // Sol Taraf: Arama ve Liste
                Expanded(
                  flex: 7, // %70 Genişlik
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: SaleProductSearch(
                          onSearch: _addProduct,
                          onScanTap: () => debugPrint("Kamera açılacak"),
                        ),
                      ),
                      Expanded(
                        child: SaleCartList(
                          items: _cartItems,
                          onQuantityChanged: _updateQuantity,
                          onRemove: _removeItem,
                        ),
                      ),
                    ],
                  ),
                ),
                // Sağ Taraf: Özet ve İşlem
                Expanded(
                  flex: 3, // %30 Genişlik
                  child: SaleSummaryPanel(
                    subTotal: _subTotal,
                    discount: _discount,
                    selectedPaymentMethod: _selectedPaymentMethod,
                    onPaymentMethodChanged: (val) {
                      if (val != null)
                        setState(() => _selectedPaymentMethod = val);
                    },
                    onCompleteSale: _completeSale,
                  ),
                ),
              ],
            );
          } else {
            // MOBILE LAYOUT (Stack)
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: SaleProductSearch(
                    onSearch: _addProduct,
                    onScanTap: () => debugPrint("Kamera açılacak"),
                  ),
                ),
                Expanded(
                  child: SaleCartList(
                    items: _cartItems,
                    onQuantityChanged: _updateQuantity,
                    onRemove: _removeItem,
                  ),
                ),
                // Mobilde özet paneli biraz daha kompakt olabilir veya
                // BottomSheet olarak açılabilir. Şimdilik alta sabitliyoruz.
                Container(
                  height: 220, // Sabit yükseklik
                  child: SaleSummaryPanel(
                    subTotal: _subTotal,
                    discount: _discount,
                    selectedPaymentMethod: _selectedPaymentMethod,
                    onPaymentMethodChanged: (val) {
                      if (val != null)
                        setState(() => _selectedPaymentMethod = val);
                    },
                    onCompleteSale: _completeSale,
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }
}
