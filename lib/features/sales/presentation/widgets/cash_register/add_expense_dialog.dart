import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/theme/app_colors.dart';
import '../../providers/cash_register_provider.dart';

class AddExpenseDialog extends ConsumerStatefulWidget {
  const AddExpenseDialog({super.key});

  @override
  ConsumerState<AddExpenseDialog> createState() => _AddExpenseDialogState();
}

class _AddExpenseDialogState extends ConsumerState<AddExpenseDialog> {
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _method = 'CASH';
  bool _isSubmitting = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_amountCtrl.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Geçerli bir tutar girin.")),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final repo = ref.read(financeRepositoryProvider);
      await repo.addExpense(
        amount: amount,
        paymentMethod: _method,
        description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      );

      if (!mounted) return;
      ref.read(cashRegisterProvider.notifier).loadDailyData();
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Masraf kaydı oluşturuldu.")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Hata: ${e.toString()}")),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

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
            onChanged: _isSubmitting ? null : (val) => setState(() => _method = val!),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text("İptal"),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text("KAYDET", style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
