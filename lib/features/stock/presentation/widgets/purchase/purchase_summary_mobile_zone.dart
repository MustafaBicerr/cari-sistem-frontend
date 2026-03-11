import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../providers/purchase_form_provider.dart';
import 'purchase_summary_zone.dart' show PaymentOption;

/// Mobil için dikey yerleşimli "Ödeme Şekli + Fatura Dip Toplamları" alanı.
/// İş mantığı `PurchaseSummaryZone` ile aynıdır; sadece layout mobil için optimize edilmiştir.
class PurchaseSummaryMobileZone extends ConsumerWidget {
  const PurchaseSummaryMobileZone({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(purchaseFormProvider);
    final notifier = ref.read(purchaseFormProvider.notifier);

    // Ara Toplam (Brüt - Satır İskontoları)
    final logicalSubTotal = state.totalGross - state.totalRowDiscount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Fatura Dip Toplamları (üstte)
        Container(
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
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Fatura Dip Toplamları",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 12),

                _MobileSummaryRow("Brüt Toplam (İskontosuz)", state.totalGross),
                _MobileSummaryRow(
                  "Satır İskontoları Toplamı",
                  state.totalRowDiscount,
                  isDiscount: true,
                ),

                const Divider(height: 24),
                _MobileSummaryRow("Ara Toplam", logicalSubTotal, isBold: true),
                const SizedBox(height: 12),

                // Genel İskonto (kısmen sadeleştirilmiş)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Fatura Altı İskonto",
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Row(
                      children: [
                        SizedBox(
                          width: 70,
                          child: TextFormField(
                            controller:
                                (_discountPctCtrlMobile ??= TextEditingController(
                              text: state.generalDiscountAmount == 0
                                  ? ''
                                  : ((state.generalDiscountAmount /
                                              (logicalSubTotal == 0
                                                  ? 1
                                                  : logicalSubTotal)) *
                                          100)
                                      .toStringAsFixed(2),
                            )),
                            onChanged: (val) =>
                                _onPercentageChangedMobile(
                                  val,
                                  logicalSubTotal,
                                  notifier,
                                ),
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            decoration: const InputDecoration(
                              isDense: true,
                              prefixText: '%',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 90,
                          child: TextFormField(
                            controller:
                                (_discountAmtCtrlMobile ??= TextEditingController(
                              text: state.generalDiscountAmount == 0
                                  ? ''
                                  : state.generalDiscountAmount
                                      .toStringAsFixed(2),
                            )),
                            onChanged: (val) =>
                                _onAmountChangedMobile(
                                  val,
                                  logicalSubTotal,
                                  notifier,
                                ),
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.right,
                            decoration: const InputDecoration(
                              isDense: true,
                              suffixText: '₺',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const Divider(height: 24),
                _MobileSummaryRow("Hesaplanan KDV Toplamı", state.totalTax),
                const SizedBox(height: 8),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
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
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        "₺${state.grandTotal.toStringAsFixed(2)}",
                        style: const TextStyle(
                          fontSize: 20,
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

        const SizedBox(height: 16),

        // Ödeme Şekli (altta)
        Container(
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
            padding: const EdgeInsets.all(16.0),
            child: _PaymentSectionMobile(
              state: state,
              notifier: notifier,
            ),
          ),
        ),
      ],
    );
  }
}

// --- Genel iskonto kontrolcüleri (mobilde sade bir yaklaşım için static) ---

TextEditingController? _discountPctCtrlMobile;
TextEditingController? _discountAmtCtrlMobile;

void _onPercentageChangedMobile(
  String val,
  double subTotal,
  PurchaseFormNotifier notifier,
) {
  if (subTotal == 0) return;
  final pct = double.tryParse(val) ?? 0;
  final amt = (subTotal * pct) / 100;

  _discountAmtCtrlMobile?.text = amt > 0 ? amt.toStringAsFixed(2) : '';
  notifier.updateGeneralDiscount(amt);
}

void _onAmountChangedMobile(
  String val,
  double subTotal,
  PurchaseFormNotifier notifier,
) {
  if (subTotal == 0) return;
  final amt = double.tryParse(val) ?? 0;
  final pct = (amt / subTotal) * 100;

  _discountPctCtrlMobile?.text = pct > 0 ? pct.toStringAsFixed(2) : '';
  notifier.updateGeneralDiscount(amt);
}

// `_SummaryRow` ve `_PaymentTypeCard`'ı mevcut dosyadan yeniden kullanıyoruz.

class _PaymentSectionMobile extends StatefulWidget {
  final PurchaseFormState state;
  final PurchaseFormNotifier notifier;

  const _PaymentSectionMobile({
    required this.state,
    required this.notifier,
  });

  @override
  State<_PaymentSectionMobile> createState() => _PaymentSectionMobileState();
}

class _PaymentSectionMobileState extends State<_PaymentSectionMobile> {
  final _paidAmtCtrl = TextEditingController();
  PaymentOption _paymentOption = PaymentOption.credit;

  @override
  void dispose() {
    _paidAmtCtrl.dispose();
    super.dispose();
  }

  void _onPaymentOptionChanged(PaymentOption option) {
    setState(() => _paymentOption = option);

    final grandTotal = widget.state.grandTotal;

    if (option == PaymentOption.cash) {
      widget.notifier.updatePaidAmount(grandTotal);
    } else if (option == PaymentOption.credit) {
      widget.notifier.updatePaidAmount(0);
    } else {
      final val = double.tryParse(_paidAmtCtrl.text) ?? 0;
      widget.notifier.updatePaidAmount(val);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;

    return Column(
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
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: _MobilePaymentTypeCard(
                title: "Kapatıldı",
                subtitle: "Tamamı Ödendi",
                icon: Icons.check_circle_outline,
                isSelected: _paymentOption == PaymentOption.cash,
                onTap: () => _onPaymentOptionChanged(PaymentOption.cash),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _MobilePaymentTypeCard(
                title: "Açık Hesap",
                subtitle: "Tamamı Vadeli",
                icon: Icons.history,
                isSelected: _paymentOption == PaymentOption.credit,
                onTap: () => _onPaymentOptionChanged(PaymentOption.credit),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _MobilePaymentTypeCard(
                title: "Parçalı",
                subtitle: "Kısmi Peşinat",
                icon: Icons.pie_chart_outline,
                isSelected: _paymentOption == PaymentOption.partial,
                onTap: () => _onPaymentOptionChanged(PaymentOption.partial),
              ),
            ),
          ],
        ),

        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          child: _paymentOption == PaymentOption.partial
              ? Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: TextFormField(
                    controller: _paidAmtCtrl,
                    onChanged: (val) {
                      final amt = double.tryParse(val) ?? 0;
                      widget.notifier.updatePaidAmount(amt);
                    },
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Ödenen Peşinat Tutarı",
                      prefixIcon: Icon(
                        Icons.payments,
                        color: Colors.green,
                      ),
                      suffixText: "₺",
                      border: OutlineInputBorder(),
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),

        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: state.remainingDebt <= 0
                ? Colors.green.shade50
                : Colors.orange.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: state.remainingDebt <= 0
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
                      color: state.remainingDebt <= 0
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
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: state.remainingDebt <= 0
                      ? Colors.green.shade700
                      : Colors.deepOrange,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// --- Yardımcı mobil summary row widget'ı ---

class _MobileSummaryRow extends StatelessWidget {
  final String title;
  final double amount;
  final bool isDiscount;
  final bool isBold;

  const _MobileSummaryRow(
    this.title,
    this.amount, {
    this.isDiscount = false,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
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

// --- Mobil ödeme tipi kartı ---

class _MobilePaymentTypeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _MobilePaymentTypeCard({
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
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.12) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade300,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : Colors.grey.shade600,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color:
                          isSelected ? AppColors.primary : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


