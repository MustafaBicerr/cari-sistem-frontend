import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../providers/purchase_form_provider.dart';

// 🔥 Ödeme Tipleri Enum'ı
enum PaymentOption { credit, cash, partial }

class PurchaseSummaryZone extends ConsumerStatefulWidget {
  const PurchaseSummaryZone({super.key});

  @override
  ConsumerState<PurchaseSummaryZone> createState() =>
      _PurchaseSummaryZoneState();
}

class _PurchaseSummaryZoneState extends ConsumerState<PurchaseSummaryZone> {
  final _discountPctCtrl = TextEditingController();
  final _discountAmtCtrl = TextEditingController();
  final _paidAmtCtrl = TextEditingController(); // Kısmi ödeme inputu

  PaymentOption _paymentOption = PaymentOption.credit; // Varsayılan: Açık Hesap

  @override
  void dispose() {
    _discountPctCtrl.dispose();
    _discountAmtCtrl.dispose();
    _paidAmtCtrl.dispose();
    super.dispose();
  }

  // --- İSKONTO SENKRONİZASYONU ---
  void _onPercentageChanged(String val, double subTotal) {
    if (subTotal == 0) return;
    final pct = double.tryParse(val) ?? 0;
    final amt = (subTotal * pct) / 100;

    _discountAmtCtrl.text = amt > 0 ? amt.toStringAsFixed(2) : '';
    ref.read(purchaseFormProvider.notifier).updateGeneralDiscount(amt);
    _recalculatePaymentOption(); // İskonto değişirse ödemeyi yeniden hesapla
  }

  void _onAmountChanged(String val, double subTotal) {
    if (subTotal == 0) return;
    final amt = double.tryParse(val) ?? 0;
    final pct = (amt / subTotal) * 100;

    _discountPctCtrl.text = pct > 0 ? pct.toStringAsFixed(2) : '';
    ref.read(purchaseFormProvider.notifier).updateGeneralDiscount(amt);
    _recalculatePaymentOption(); // İskonto değişirse ödemeyi yeniden hesapla
  }

  // --- ÖDEME TİPİ SEÇİMİ VE DİNAMİK YÖNETİM ---
  void _onPaymentOptionChanged(PaymentOption option, double grandTotal) {
    setState(() => _paymentOption = option);

    if (option == PaymentOption.cash) {
      ref.read(purchaseFormProvider.notifier).updatePaidAmount(grandTotal);
    } else if (option == PaymentOption.credit) {
      ref.read(purchaseFormProvider.notifier).updatePaidAmount(0);
    } else {
      final val = double.tryParse(_paidAmtCtrl.text) ?? 0;
      ref.read(purchaseFormProvider.notifier).updatePaidAmount(val);
    }
  }

  // Fatura toplamı değiştiğinde (örn: yeni ürün eklendiğinde) peşin ödemeyi güncel tut
  void _recalculatePaymentOption() {
    final state = ref.read(purchaseFormProvider);
    if (_paymentOption == PaymentOption.cash) {
      ref
          .read(purchaseFormProvider.notifier)
          .updatePaidAmount(state.grandTotal);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(purchaseFormProvider);
    final notifier = ref.read(purchaseFormProvider.notifier);

    // Ürün değiştiğinde/silindiğinde Peşin ödemenin senkron kalması için dinleyici
    ref.listen<PurchaseFormState>(purchaseFormProvider, (prev, next) {
      if (prev?.grandTotal != next.grandTotal &&
          _paymentOption == PaymentOption.cash) {
        Future.microtask(() => notifier.updatePaidAmount(next.grandTotal));
      }
    });

    // Ara Toplamın Mantıksal Hesabı (Brüt - Satır İskontoları)
    final logicalSubTotal = state.totalGross - state.totalRowDiscount;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // -----------------------------------------------------
        // SOL TARAF: Ödeme Durumu ve Kasa İşlemleri
        // -----------------------------------------------------
        Expanded(
          flex: 1,
          child: Container(
            // 🔥 Card Yerine Container ve Shadow
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.account_balance_wallet,
                        color: AppColors.primary,
                      ),
                      SizedBox(width: 8),
                      Text(
                        "Ödeme Şekli",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 32),

                  // ŞIK SEÇENEK BUTONLARI
                  Row(
                    children: [
                      Expanded(
                        child: _PaymentTypeCard(
                          title: "Kapatıldı",
                          subtitle: "Tamamı Ödendi",
                          icon: Icons.check_circle_outline,
                          isSelected: _paymentOption == PaymentOption.cash,
                          onTap:
                              () => _onPaymentOptionChanged(
                                PaymentOption.cash,
                                state.grandTotal,
                              ),
                        ),
                      ),
                      Expanded(
                        child: _PaymentTypeCard(
                          title: "Açık Hesap",
                          subtitle: "Tamamı Vadeli",
                          icon: Icons.history,
                          isSelected: _paymentOption == PaymentOption.credit,
                          onTap:
                              () => _onPaymentOptionChanged(
                                PaymentOption.credit,
                                state.grandTotal,
                              ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      const SizedBox(width: 8),
                      Expanded(
                        child: _PaymentTypeCard(
                          title: "Parçalı",
                          subtitle: "Kısmi Peşinat",
                          icon: Icons.pie_chart_outline,
                          isSelected: _paymentOption == PaymentOption.partial,
                          onTap:
                              () => _onPaymentOptionChanged(
                                PaymentOption.partial,
                                state.grandTotal,
                              ),
                        ),
                      ),
                    ],
                  ),

                  // EĞER KISMİ ÖDEME SEÇİLİYSE INPUT ÇIKSIN
                  AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    child:
                        _paymentOption == PaymentOption.partial
                            ? Padding(
                              padding: const EdgeInsets.only(top: 24.0),
                              child: TextFormField(
                                controller: _paidAmtCtrl,
                                onChanged: (val) {
                                  final amt = double.tryParse(val) ?? 0;
                                  notifier.updatePaidAmount(amt);
                                },
                                keyboardType: TextInputType.number,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                decoration: InputDecoration(
                                  labelText: "Ödenen Peşinat Tutarı",
                                  prefixIcon: const Icon(
                                    Icons.payments,
                                    color: Colors.green,
                                  ),
                                  suffixText: "₺",
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: Colors.green.shade50,
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Colors.green,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                            )
                            : const SizedBox.shrink(),
                  ),

                  const SizedBox(height: 24),

                  // KALAN BORÇ ÖZETİ
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color:
                          state.remainingDebt <= 0
                              ? Colors.green.shade50
                              : Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            state.remainingDebt <= 0
                                ? Colors.green.shade200
                                : Colors.orange.shade200,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              state.remainingDebt <= 0
                                  ? "Borç Kapatıldı"
                                  : "Cari Hesaba İşlenecek Borç",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color:
                                    state.remainingDebt <= 0
                                        ? Colors.green.shade700
                                        : Colors.deepOrange,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Ödenen: ₺${state.paidAmount.toStringAsFixed(2)}",
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          "₺${state.remainingDebt.toStringAsFixed(2)}",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color:
                                state.remainingDebt <= 0
                                    ? Colors.green.shade700
                                    : Colors.deepOrange,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(width: 24),

        // -----------------------------------------------------
        // SAĞ TARAF: Fatura Dip Toplamları (Standart Muhasebe)
        // -----------------------------------------------------
        Expanded(
          flex: 1,
          child: Container(
            // 🔥 Card Yerine Container ve Shadow
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const Text(
                    "Fatura Dip Toplamları",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 1. Brüt (İskontosuz Orijinal Fiyat)
                  _SummaryRow("Brüt Toplam (İskontosuz)", state.totalGross),

                  // 2. Satır İskontoları
                  _SummaryRow(
                    "Satır İskontoları Toplamı",
                    state.totalRowDiscount,
                    isDiscount: true,
                  ),

                  const Divider(height: 24),

                  // 3. Ara Toplam
                  _SummaryRow("Ara Toplam", logicalSubTotal, isBold: true),

                  const SizedBox(height: 12),

                  // 4. Genel İskonto
                  // 4. Genel İskonto
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Fatura Altı İskonto",
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Row(
                        children: [
                          // YÜZDE (%) GİRİŞİ
                          SizedBox(
                            width: 80, // Genişlik biraz artırıldı
                            child: TextFormField(
                              controller: _discountPctCtrl,
                              onChanged:
                                  (val) => _onPercentageChanged(
                                    val,
                                    logicalSubTotal,
                                  ),
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              decoration: const InputDecoration(
                                isDense: true,
                                // 🔥 prefixText YERİNE KALICI prefixIcon KULLANILDI
                                prefixIcon: Padding(
                                  padding: EdgeInsets.only(
                                    left: 8.0,
                                    right: 4.0,
                                  ),
                                  child: Text(
                                    "%",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black54,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                prefixIconConstraints: BoxConstraints(
                                  minWidth: 0,
                                  minHeight: 0,
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 8,
                                ),
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8.0),
                            child: Text(
                              "=",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          // MİKTAR (₺) GİRİŞİ
                          SizedBox(
                            width: 100,
                            child: TextFormField(
                              controller: _discountAmtCtrl,
                              onChanged:
                                  (val) =>
                                      _onAmountChanged(val, logicalSubTotal),
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.right,
                              decoration: const InputDecoration(
                                isDense: true,
                                // 🔥 suffixText YERİNE KALICI suffixIcon KULLANILDI
                                suffixIcon: Padding(
                                  padding: EdgeInsets.only(
                                    left: 4.0,
                                    right: 8.0,
                                  ),
                                  child: Text(
                                    "₺",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black54,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                suffixIconConstraints: BoxConstraints(
                                  minWidth: 0,
                                  minHeight: 0,
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 8,
                                ),
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const Divider(height: 24),

                  // 5. KDV
                  _SummaryRow("Hesaplanan KDV Toplamı", state.totalTax),

                  const SizedBox(height: 16),

                  // 6. NET TOPLAM
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "ÖDENECEK NET TUTAR",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        Text(
                          "₺${state.grandTotal.toStringAsFixed(2)}",
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Sağ taraftaki satırları çizen yardımcı widget
class _SummaryRow extends StatelessWidget {
  final String title;
  final double amount;
  final bool isDiscount;
  final bool isBold;

  const _SummaryRow(
    this.title,
    this.amount, {
    this.isDiscount = false,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: isBold ? Colors.black87 : Colors.black54,
            ),
          ),
          Text(
            "${isDiscount ? '-' : ''} ₺${amount.toStringAsFixed(2)}",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: isBold ? 16 : 14,
              color: isDiscount ? Colors.red : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

// Sol taraftaki şık Seçenek Butonlarını çizen yardımcı widget
class _PaymentTypeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaymentTypeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : Colors.grey.shade500,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? AppColors.primary : Colors.black87,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
