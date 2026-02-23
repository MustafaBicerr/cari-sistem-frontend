import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class SplitPaymentDialog extends StatefulWidget {
  final double totalAmount;
  final Function(double cash, double card) onConfirmed;

  const SplitPaymentDialog({
    super.key,
    required this.totalAmount,
    required this.onConfirmed,
  });

  @override
  State<SplitPaymentDialog> createState() => _SplitPaymentDialogState();
}

class _SplitPaymentDialogState extends State<SplitPaymentDialog> {
  late TextEditingController _cashCtrl;
  late TextEditingController _cardCtrl;
  bool _isValid = true;

  @override
  void initState() {
    super.initState();
    // Varsayılan: Hepsi Nakit
    _cashCtrl = TextEditingController(
      text: widget.totalAmount.toStringAsFixed(2),
    );
    _cardCtrl = TextEditingController(text: "0.00");
  }

  void _updateValues(String val, bool isCashChanged) {
    double inputVal = double.tryParse(val.replaceAll(',', '.')) ?? 0.0;

    if (inputVal > widget.totalAmount) {
      setState(() => _isValid = false);
      return;
    } else {
      setState(() => _isValid = true);
    }

    double remainder = widget.totalAmount - inputVal;
    // Yuvarlama hatasını önlemek için fix
    remainder = double.parse(remainder.toStringAsFixed(2));

    if (isCashChanged) {
      _cardCtrl.text = remainder.toStringAsFixed(2);
    } else {
      _cashCtrl.text = remainder.toStringAsFixed(2);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Nakit + Kart Ödeme"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Toplam Tutar: ₺${widget.totalAmount.toStringAsFixed(2)}",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 20),

          // NAKİT GİRİŞİ
          TextField(
            controller: _cashCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: "Nakit Miktarı",
              prefixIcon: const Icon(Icons.money),
              border: const OutlineInputBorder(),
              errorText: _isValid ? null : "Tutar aşıldı!",
            ),
            onChanged: (val) => _updateValues(val, true),
          ),
          const SizedBox(height: 16),

          // KART GİRİŞİ
          TextField(
            controller: _cardCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: "Kart Miktarı (Otomatik)",
              prefixIcon: const Icon(Icons.credit_card),
              border: const OutlineInputBorder(),
              errorText: _isValid ? null : "Tutar aşıldı!",
            ),
            onChanged: (val) => _updateValues(val, false),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("İptal"),
        ),
        ElevatedButton(
          onPressed:
              _isValid
                  ? () {
                    double cash = double.tryParse(_cashCtrl.text) ?? 0;
                    double card = double.tryParse(_cardCtrl.text) ?? 0;
                    widget.onConfirmed(cash, card);
                    Navigator.pop(context);
                  }
                  : null,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          child: const Text("Onayla", style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
