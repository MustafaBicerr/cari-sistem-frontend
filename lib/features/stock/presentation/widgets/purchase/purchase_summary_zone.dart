import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../providers/purchase_form_provider.dart';

class PurchaseSummaryZone extends ConsumerStatefulWidget {
  const PurchaseSummaryZone({super.key});

  @override
  ConsumerState<PurchaseSummaryZone> createState() =>
      _PurchaseSummaryZoneState();
}

class _PurchaseSummaryZoneState extends ConsumerState<PurchaseSummaryZone> {
  final _discountPctCtrl = TextEditingController();
  final _discountAmtCtrl = TextEditingController();

  @override
  void dispose() {
    _discountPctCtrl.dispose();
    _discountAmtCtrl.dispose();
    super.dispose();
  }

  void _onPercentageChanged(String val, double subTotal) {
    if (subTotal == 0) return;
    final pct = double.tryParse(val) ?? 0;
    final amt = (subTotal * pct) / 100;

    // Sadece karşı tarafı güncelle (Kürsör zıplamasın diye)
    _discountAmtCtrl.text = amt > 0 ? amt.toStringAsFixed(2) : '';
    ref.read(purchaseFormProvider.notifier).updateGeneralDiscount(amt);
  }

  void _onAmountChanged(String val, double subTotal) {
    if (subTotal == 0) return;
    final amt = double.tryParse(val) ?? 0;
    final pct = (amt / subTotal) * 100;

    // Sadece karşı tarafı güncelle
    _discountPctCtrl.text = pct > 0 ? pct.toStringAsFixed(2) : '';
    ref.read(purchaseFormProvider.notifier).updateGeneralDiscount(amt);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(purchaseFormProvider);
    final notifier = ref.read(purchaseFormProvider.notifier);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // SOL TARAF: Ödeme ve Kasa İşlemleri
        Expanded(
          flex: 1,
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.shade300),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Ödeme Bilgileri",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    onChanged:
                        (val) => notifier.updatePaidAmount(
                          double.tryParse(val) ?? 0,
                        ),
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: "Ödenen Tutar (Peşinat)",
                      prefixIcon: const Icon(Icons.payments),
                      suffixText: "₺",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.green.shade50,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Kalan Borç:",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.deepOrange,
                          ),
                        ),
                        Text(
                          "₺${state.remainingDebt.toStringAsFixed(2)}",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepOrange,
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

        // SAĞ TARAF: Fatura Dip Toplamları
        Expanded(
          flex: 1,
          child: Card(
            elevation: 0,
            color: AppColors.primary.withOpacity(0.05),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: AppColors.primary.withOpacity(0.2)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  _SummaryRow("Ara Toplam", state.subTotal),
                  const Divider(),
                  _SummaryRow(
                    "Satır İskontoları Toplamı",
                    state.totalRowDiscount,
                    isDiscount: true,
                  ),
                  const Divider(),

                  // 🔥 YENİ DİNAMİK İSKONTO GİRİŞİ (% ve ₺)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Genel İskonto",
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Row(
                        children: [
                          // YÜZDE (%) GİRİŞİ
                          SizedBox(
                            width: 70,
                            child: TextFormField(
                              controller: _discountPctCtrl,
                              onChanged:
                                  (val) =>
                                      _onPercentageChanged(val, state.subTotal),
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              decoration: const InputDecoration(
                                isDense: true,
                                prefixText: "% ",
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 8,
                                ),
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            "=",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          // MİKTAR (₺) GİRİŞİ
                          SizedBox(
                            width: 100,
                            child: TextFormField(
                              controller: _discountAmtCtrl,
                              onChanged:
                                  (val) =>
                                      _onAmountChanged(val, state.subTotal),
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.right,
                              decoration: const InputDecoration(
                                isDense: true,
                                suffixText: "₺",
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 8,
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

                  const Divider(),
                  _SummaryRow("Hesaplanan KDV Toplamı", state.totalTax),
                  const Divider(thickness: 2),
                  // GENEL TOPLAM
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "GENEL TOPLAM",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
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
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String title;
  final double amount;
  final bool isDiscount;

  const _SummaryRow(this.title, this.amount, {this.isDiscount = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(
            "${isDiscount ? '-' : ''} ₺${amount.toStringAsFixed(2)}",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDiscount ? Colors.red : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
