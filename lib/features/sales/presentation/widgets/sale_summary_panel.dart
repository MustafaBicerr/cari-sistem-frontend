import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/sale_state_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/sales_controller.dart'; // Yeni controller
import 'customer_selection_widget.dart';
import 'split_payment_dialog.dart';
import 'debt_distribution_dialog.dart';

class SaleSummaryPanel extends ConsumerWidget {
  final double subTotal;
  final double discount;
  final VoidCallback onCompleteSale;

  const SaleSummaryPanel({
    super.key,
    required this.subTotal,
    required this.discount,
    required this.onCompleteSale,
  });

  double get grandTotal => subTotal - discount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saleState = ref.watch(saleStateProvider);
    final saleNotifier = ref.read(saleStateProvider.notifier);

    // Controller Durumunu İzle (Loading/Error/Success)
    final salesAsyncState = ref.watch(salesControllerProvider);

    // 🔥 SUCCESS/ERROR Listener (Ekranı çizdirmez, sadece aksiyon alır)
    ref.listen<AsyncValue<void>>(salesControllerProvider, (previous, next) {
      next.whenOrNull(
        error: (error, stack) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Hata: $error"),
              backgroundColor: AppColors.error,
            ),
          );
        },
        data: (_) {
          // Başarılı ise Dialog Aç ve Temizle
          _showSuccessDialog(context, ref);
        },
      );
    });

    return Stack(
      children: [
        // ANA İÇERİK
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              bottomLeft: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(-4, 0),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Müşteri Seçimi",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              const CustomerSelectionWidget(),

              const Spacer(),

              _SummaryRow(
                label: "Ara Toplam",
                value: "₺${subTotal.toStringAsFixed(2)}",
              ),
              const SizedBox(height: 8),
              _SummaryRow(
                label: "İskonto",
                value: "- ₺${discount.toStringAsFixed(2)}",
                isDiscount: true,
              ),
              const Divider(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "GENEL TOPLAM",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  Text(
                    "₺${grandTotal.toStringAsFixed(2)}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              const Text(
                "Ödeme Yöntemi",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _PaymentTypeButton(
                    label: "Nakit",
                    icon: Icons.payments_outlined,
                    isSelected: saleState.paymentMethod == 'CASH',
                    onTap: () => saleNotifier.setPaymentMethod('CASH'),
                  ),
                  const SizedBox(width: 8),
                  _PaymentTypeButton(
                    label: "Kart",
                    icon: Icons.credit_card,
                    isSelected: saleState.paymentMethod == 'CREDIT_CARD',
                    onTap: () => saleNotifier.setPaymentMethod('CREDIT_CARD'),
                  ),
                  const SizedBox(width: 8),
                  _PaymentTypeButton(
                    label: "Mix",
                    icon: Icons.call_split,
                    isSelected: saleState.paymentMethod == 'CASH_CARD',
                    onTap: () => saleNotifier.setPaymentMethod('CASH_CARD'),
                  ),
                  const SizedBox(width: 8),
                  _PaymentTypeButton(
                    label: "Veresiye",
                    icon: Icons.assignment_ind_outlined,
                    isSelected: saleState.paymentMethod == 'DEBT',
                    isDisabled: saleState.isAnonymous,
                    onTap: () {
                      if (!saleState.isAnonymous)
                        saleNotifier.setPaymentMethod('DEBT');
                    },
                  ),
                ],
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  // Eğer loading ise butonu disable et
                  onPressed:
                      salesAsyncState.isLoading
                          ? null
                          : () => _handleCompleteSale(context, ref, grandTotal),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline, color: Colors.white),
                      SizedBox(width: 12),
                      Text(
                        "SATIŞI TAMAMLA",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // 🔥 LOADING OVERLAY (Beyaz Ekran Sorununu Çözen Kahraman)
        if (salesAsyncState.isLoading)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.7),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  bottomLeft: Radius.circular(24),
                ),
              ),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      "Satış Tamamlanıyor...",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  // --- LOGIC ---

  void _handleCompleteSale(
    BuildContext context,
    WidgetRef ref,
    double totalAmount,
  ) {
    final saleState = ref.read(saleStateProvider);
    final cartItems = ref.read(cartProvider);

    // 1. Validasyonlar
    if (cartItems.isEmpty) {
      _showSnack(context, "Sepet boş! Ürün ekleyiniz.", isError: true);
      return;
    }

    if (!saleState.isAnonymous && saleState.selectedCustomer == null) {
      _showSnack(
        context,
        "Lütfen bir müşteri seçin veya 'Kaydedilmeyen Müşteri' seçeneğini işaretleyin.",
        isError: true,
      );
      return;
    }

    // 2. Yönlendirme (Dialog Açma Mantığı)
    if (saleState.paymentMethod == 'CASH_CARD') {
      // MIX DIALOG
      showDialog(
        context: context,
        builder:
            (_) => SplitPaymentDialog(
              totalAmount: totalAmount,
              onConfirmed: (cash, card) {
                _submitData(
                  ref,
                  _createStandardItems(ref, true),
                  'CASH_CARD',
                  "MİX ÖDEME: Nakit ₺$cash + Kart ₺$card",
                  // 👇 YENİ: Parçalı tutarları da gönderiyoruz
                  <String, dynamic>{"split_cash": cash, "split_card": card},
                );
              },
            ),
      );
    } else if (saleState.paymentMethod == 'DEBT') {
      // VERESİYE DIALOG
      showDialog(
        context: context,
        builder:
            (_) => DebtDistributionDialog(
              cartItems: cartItems,
              onConfirmed: (processedItems) {
                _submitData(
                  ref,
                  processedItems,
                  'DEBT',
                  "Veresiye / Parçalı Satış",
                  null,
                );
              },
            ),
      );
    } else {
      // STANDART (NAKİT / KART)
      _submitData(
        ref,
        _createStandardItems(ref, true),
        saleState.paymentMethod,
        "Hızlı Satış (${saleState.paymentMethod})",
        null,
      );
    }
  }

  // Veriyi Paketle ve Controller'a Yolla
  void _submitData(
    WidgetRef ref,
    List<Map<String, dynamic>> items,
    String method,
    String? note,
    Map<String, dynamic>? extraData, // 👈 YENİ PARAMETRE
  ) {
    final saleState = ref.read(saleStateProvider);

    // AuthProvider'dan alınmalı ama şimdilik sabit
    // const tenantId = "b8630ab4-b5ef-4810-ba63-bcc8aa77827a";

    final payload = {
      "customer_id":
          saleState.isAnonymous ? null : saleState.selectedCustomer?.id,
      "payment_method": method,
      "payment_status": "PAID",
      "note": note,
      "items": items,
      // 👇 YENİ: Eğer extraData varsa payload'a ekle (split_cash, split_card)
      ...?extraData,
    };

    // Controller'ı Tetikle
    ref.read(salesControllerProvider.notifier).submitSale(payload);
  }

  // Yardımcılar
  List<Map<String, dynamic>> _createStandardItems(WidgetRef ref, bool isPaid) {
    return ref
        .read(cartProvider)
        .map(
          (e) => {
            "product_id": e.productId,
            "quantity": e.quantity,
            "is_paid_now": isPaid,
          },
        )
        .toList();
  }

  void _showSnack(BuildContext context, String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppColors.error : AppColors.success,
      ),
    );
  }

  void _showSuccessDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 8),
                Text("Başarılı"),
              ],
            ),
            content: const Text("Satış işlemi başarıyla kaydedildi."),
            actions: [
              TextButton(
                onPressed: () {
                  // TEMİZLİK ZAMANI
                  ref.read(cartProvider.notifier).clearCart();
                  ref.read(saleStateProvider.notifier).removeCustomer();
                  Navigator.pop(ctx); // Dialogu kapat
                },
                child: const Text("YENİ SATIŞ"),
              ),
            ],
          ),
    );
  }
}

// _SummaryRow ve _PaymentTypeButton sınıflarını buraya eklemeyi unutma (değişiklik yok)
class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isDiscount;
  const _SummaryRow({
    required this.label,
    required this.value,
    this.isDiscount = false,
  });
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: isDiscount ? AppColors.error : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _PaymentTypeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final bool isDisabled;
  final VoidCallback onTap;
  const _PaymentTypeButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    this.isDisabled = false,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: isDisabled ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color:
                isDisabled
                    ? Colors.grey[200]
                    : (isSelected
                        ? AppColors.primary
                        : Colors.grey.withOpacity(0.05)),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color:
                  isSelected ? AppColors.primary : Colors.grey.withOpacity(0.2),
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color:
                    isDisabled
                        ? Colors.grey
                        : (isSelected ? Colors.white : AppColors.textSecondary),
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color:
                      isDisabled
                          ? Colors.grey
                          : (isSelected
                              ? Colors.white
                              : AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
