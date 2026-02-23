import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/sale_cart_list.dart'; // CartItem için

class DebtDistributionDialog extends StatefulWidget {
  final List<CartItem> cartItems;
  final Function(List<Map<String, dynamic>> processedItems) onConfirmed;

  const DebtDistributionDialog({
    super.key,
    required this.cartItems,
    required this.onConfirmed,
  });

  @override
  State<DebtDistributionDialog> createState() => _DebtDistributionDialogState();
}

class _DebtDistributionDialogState extends State<DebtDistributionDialog> {
  // Her ürün için "Kaç tanesi veresiye?" bilgisini tutar
  late List<double> _debtQuantities;
  late List<bool> _isChecked; // Checkbox durumu

  @override
  void initState() {
    super.initState();
    // Default: Hepsi seçili, hepsinin tamamı veresiye
    _debtQuantities = widget.cartItems.map((e) => e.quantity).toList();
    _isChecked = List.filled(widget.cartItems.length, true);
  }

  void _toggleAll(bool? val) {
    setState(() {
      for (int i = 0; i < _isChecked.length; i++) {
        _isChecked[i] = val ?? false;
        // Seçim kalkarsa veresiye miktarı 0 olur, seçilirse full olur
        _debtQuantities[i] = (val ?? false) ? widget.cartItems[i].quantity : 0;
      }
    });
  }

  double get _totalDebtAmount {
    double total = 0;
    for (int i = 0; i < widget.cartItems.length; i++) {
      total += _debtQuantities[i] * widget.cartItems[i].unitPrice;
    }
    return total;
  }

  double get _totalPaidAmount {
    double totalCart = widget.cartItems.fold(
      0,
      (sum, item) => sum + item.total,
    );
    return totalCart - _totalDebtAmount;
  }

  void _complete() {
    // Backend formatına dönüştür
    List<Map<String, dynamic>> finalItems = [];

    for (int i = 0; i < widget.cartItems.length; i++) {
      final item = widget.cartItems[i];
      final debtQty = _debtQuantities[i];
      final paidQty = item.quantity - debtQty;

      // 1. Ödenen Kısım (Varsa)
      if (paidQty > 0) {
        finalItems.add({
          "product_id": item.productId,
          "quantity": paidQty,
          "is_paid_now": true,
          // "batch_no": item.batchNo // İleride eklenebilir
        });
      }

      // 2. Veresiye Kısım (Varsa)
      if (debtQty > 0) {
        finalItems.add({
          "product_id": item.productId,
          "quantity": debtQty,
          "is_paid_now": false,
        });
      }
    }
    widget.onConfirmed(finalItems);
    // 🔥 EKSİK OLAN PARÇA BU: Dialogu kapat
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Veresiye Detayı",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    const Text("Tümü Veresiye"),
                    Checkbox(
                      value: _isChecked.every((e) => e),
                      onChanged: _toggleAll,
                      activeColor: AppColors.primary,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Liste
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: widget.cartItems.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final item = widget.cartItems[index];
                final debtQty = _debtQuantities[index];
                final paidQty = item.quantity - debtQty;

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Checkbox(
                            value: _isChecked[index],
                            activeColor: AppColors.primary,
                            onChanged: (val) {
                              setState(() {
                                _isChecked[index] = val ?? false;
                                _debtQuantities[index] =
                                    (val ?? false) ? item.quantity : 0;
                              });
                            },
                          ),
                          Expanded(
                            child: Text(
                              item.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          // Veresiye Miktar Ayarı
                          if (_isChecked[index])
                            Row(
                              children: [
                                _miniBtn(Icons.remove, () {
                                  if (debtQty > 0)
                                    setState(() => _debtQuantities[index]--);
                                }),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8.0,
                                  ),
                                  child: Text(
                                    "${debtQty.toStringAsFixed(0)} Veresiye",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red,
                                    ),
                                  ),
                                ),
                                _miniBtn(Icons.add, () {
                                  if (debtQty < item.quantity)
                                    setState(() => _debtQuantities[index]++);
                                }),
                              ],
                            ),
                        ],
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Birim: ₺${item.unitPrice}",
                            style: const TextStyle(color: Colors.grey),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                "Peşin: ₺${(paidQty * item.unitPrice).toStringAsFixed(2)}",
                                style: const TextStyle(color: Colors.green),
                              ),
                              Text(
                                "Borç: ₺${(debtQty * item.unitPrice).toStringAsFixed(2)}",
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Footer (Özet + Buton)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.05),
              border: Border(
                top: BorderSide(color: AppColors.primary.withOpacity(0.2)),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Peşin Alınacak:",
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "₺${_totalPaidAmount.toStringAsFixed(2)}",
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Toplam Borç:",
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "₺${_totalDebtAmount.toStringAsFixed(2)}",
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _complete,
                    icon: const Icon(
                      Icons.check_circle_outline,
                      color: Colors.white,
                    ),
                    label: const Text(
                      "SATIŞI TAMAMLA",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(icon, size: 16),
      ),
    );
  }
}
