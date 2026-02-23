import 'package:flutter/material.dart';
import 'package:mobile/core/theme/app_colors.dart';

class AddExpenseDialog extends StatefulWidget {
  const AddExpenseDialog({super.key});

  @override
  State<AddExpenseDialog> createState() => _AddExpenseDialogState();
}

class _AddExpenseDialogState extends State<AddExpenseDialog> {
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _method = 'CASH';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.remove_circle_outline, color: AppColors.error),
          SizedBox(width: 8),
          Text("Masraf / Gider Ekle", style: TextStyle(color: AppColors.error)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: "Tutar (₺)",
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.currency_lira),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descCtrl,
            decoration: const InputDecoration(
              labelText: "Açıklama (Örn: Yemek, Fatura)",
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.notes),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _method,
            decoration: const InputDecoration(
              labelText: "Ödeme Kaynağı",
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'CASH', child: Text("Nakit Kasa")),
              DropdownMenuItem(
                value: 'CREDIT_CARD',
                child: Text("Şirket Kartı"),
              ),
            ],
            onChanged: (val) => setState(() => _method = val!),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("İptal"),
        ),
        ElevatedButton(
          onPressed: () {
            // TODO: Backend'e gönder
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Masraf kaydedildi (Demo)")),
            );
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
          child: const Text("KAYDET", style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
