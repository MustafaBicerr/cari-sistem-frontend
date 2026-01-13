import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class SaleSummaryPanel extends StatelessWidget {
  final double subTotal;
  final double discount;
  final Function(String?) onPaymentMethodChanged;
  final String selectedPaymentMethod;
  final VoidCallback onCompleteSale;

  // Müşteri seçimi için (Autocomplete verisi backend'den gelecek)
  static const List<String> _dummyCustomers = [
    "Ahmet Yılmaz (0555...)",
    "Ayşe Demir (0532...)",
    "Beritan Çiftliği (Vergi: 123...)",
  ];

  const SaleSummaryPanel({
    super.key,
    required this.subTotal,
    required this.discount,
    required this.onPaymentMethodChanged,
    required this.selectedPaymentMethod,
    required this.onCompleteSale,
  });

  double get grandTotal => subTotal - discount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          bottomLeft: Radius.circular(24), // Desktop için
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
          // 1. Müşteri Seçimi
          const Text(
            "Müşteri Seçimi",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          Autocomplete<String>(
            optionsBuilder: (TextEditingValue textEditingValue) {
              if (textEditingValue.text == '') {
                return const Iterable<String>.empty();
              }
              return _dummyCustomers.where((String option) {
                return option.toLowerCase().contains(
                  textEditingValue.text.toLowerCase(),
                );
              });
            },
            fieldViewBuilder: (
              context,
              controller,
              focusNode,
              onEditingComplete,
            ) {
              return TextField(
                controller: controller,
                focusNode: focusNode,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.person_search_outlined),
                  hintText: "Müşteri Ara...",
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              );
            },
            onSelected: (String selection) {
              debugPrint('Seçilen Müşteri: $selection');
              // Controller'a haber ver
            },
          ),

          const Spacer(), // Boşluğu doldur
          // 2. Özet Bilgiler
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

          // 3. Ödeme Yöntemi
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
                isSelected: selectedPaymentMethod == 'CASH',
                onTap: () => onPaymentMethodChanged('CASH'),
              ),
              const SizedBox(width: 12),
              _PaymentTypeButton(
                label: "Kredi Kartı",
                icon: Icons.credit_card,
                isSelected: selectedPaymentMethod == 'CARD',
                onTap: () => onPaymentMethodChanged('CARD'),
              ),
              const SizedBox(width: 12),
              _PaymentTypeButton(
                label: "Veresiye",
                icon: Icons.assignment_ind_outlined,
                isSelected: selectedPaymentMethod == 'DEBT',
                onTap: () => onPaymentMethodChanged('DEBT'),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // 4. Tamamla Butonu
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: onCompleteSale,
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
    );
  }
}

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
  final VoidCallback onTap;

  const _PaymentTypeButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color:
                isSelected ? AppColors.primary : Colors.grey.withOpacity(0.05),
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
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
