import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/theme/app_colors.dart';
import '../providers/finance_provider.dart';

class PaymentDialog extends ConsumerStatefulWidget {
  final String accountId;
  final bool isCollection; // true: Tahsilat (Müşteri), false: Ödeme (Tedarikçi)
  final String personName;

  const PaymentDialog({
    super.key,
    required this.accountId,
    required this.isCollection,
    required this.personName,
  });

  @override
  ConsumerState<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends ConsumerState<PaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _selectedMethod = 'CASH'; // CASH, CREDIT_CARD, IBAN

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.parse(
      _amountCtrl.text.replaceAll(',', '.'),
    ); // Virgül desteği
    final notifier = ref.read(financeProvider.notifier);

    if (widget.isCollection) {
      await notifier.collectDebt(
        customerId: widget.accountId,
        amount: amount,
        paymentMethod: _selectedMethod,
        description: _descCtrl.text,
      );
    } else {
      await notifier.paySupplier(
        supplierId: widget.accountId,
        amount: amount,
        paymentMethod: _selectedMethod,
        description: _descCtrl.text,
      );
    }

    // Durumu Kontrol Et
    final state = ref.read(financeProvider);
    if (state.isSuccess) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isCollection ? "Tahsilat alındı!" : "Ödeme yapıldı!",
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else if (state.error != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Hata: ${state.error}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(financeProvider);
    final isLoading = state.isLoading;
    final color = widget.isCollection ? Colors.green : Colors.red;
    final title = widget.isCollection ? "Tahsilat Al" : "Ödeme Yap";

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            widget.isCollection ? Icons.download : Icons.upload,
            color: color,
          ),
          const SizedBox(width: 8),
          Text(title, style: TextStyle(color: color)),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.personName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),

              // Tutar Alanı
              TextFormField(
                controller: _amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: "Tutar (₺)",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.currency_lira),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return "Tutar giriniz";
                  if (double.tryParse(val.replaceAll(',', '.')) == null)
                    return "Geçerli sayı giriniz";
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Ödeme Yöntemi Seçimi
              DropdownButtonFormField<String>(
                value: _selectedMethod,
                decoration: InputDecoration(
                  labelText: "Ödeme Yöntemi",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.credit_card),
                ),
                items: const [
                  DropdownMenuItem(value: 'CASH', child: Text("Nakit")),
                  DropdownMenuItem(
                    value: 'CREDIT_CARD',
                    child: Text("Kredi Kartı"),
                  ),
                  DropdownMenuItem(value: 'IBAN', child: Text("Havale / EFT")),
                ],
                onChanged: (val) => setState(() => _selectedMethod = val!),
              ),
              const SizedBox(height: 16),

              // Açıklama
              TextFormField(
                controller: _descCtrl,
                decoration: InputDecoration(
                  labelText: "Açıklama (Opsiyonel)",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.notes),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: isLoading ? null : () => Navigator.pop(context),
          child: const Text("İptal", style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child:
              isLoading
                  ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                  : Text(title, style: const TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
