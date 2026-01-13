import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class StockEntryForm extends StatefulWidget {
  final Function(Map<String, dynamic>) onAdd;

  const StockEntryForm({super.key, required this.onAdd});

  @override
  State<StockEntryForm> createState() => _StockEntryFormState();
}

class _StockEntryFormState extends State<StockEntryForm> {
  final _formKey = GlobalKey<FormState>();

  // Form Alanları
  String? _selectedProduct; // Normalde Product objesi olur
  String _batchNo = "";
  DateTime? _expiryDate;
  double _quantity = 0;
  double _buyPrice = 0;

  // Dummy Ürünler
  final List<String> _products = [
    "Gentavet-G",
    "Rabenzole 100ml",
    "Amoksivet %80",
    "Vitamin K",
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlık
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "Ürün Girişi Ekle",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            // 1. Ürün Seçimi
            Autocomplete<String>(
              optionsBuilder:
                  (v) => _products.where(
                    (p) => p.toLowerCase().contains(v.text.toLowerCase()),
                  ),
              onSelected: (val) => _selectedProduct = val,
              fieldViewBuilder: (
                context,
                controller,
                focusNode,
                onEditingComplete,
              ) {
                return TextFormField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: InputDecoration(
                    labelText: "Ürün Ara",
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (val) => val!.isEmpty ? "Ürün seçmelisiniz" : null,
                );
              },
            ),
            const SizedBox(height: 16),

            // 2. Miktar ve Fiyat (Yan Yana)
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: "Miktar",
                      suffixText: "Adet",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onSaved:
                        (val) => _quantity = double.tryParse(val ?? "0") ?? 0,
                    validator:
                        (val) =>
                            (double.tryParse(val ?? "0") ?? 0) <= 0
                                ? "Geçersiz"
                                : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: "Alış Fiyatı (Birim)",
                      prefixText: "₺",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onSaved:
                        (val) => _buyPrice = double.tryParse(val ?? "0") ?? 0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 3. Parti No ve SKT (Yan Yana)
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: InputDecoration(
                      labelText: "Parti No (Batch)",
                      prefixIcon: const Icon(Icons.qr_code),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onSaved: (val) => _batchNo = val ?? "",
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now().add(
                          const Duration(days: 365),
                        ),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(
                          const Duration(days: 365 * 5),
                        ),
                      );
                      if (date != null) setState(() => _expiryDate = date);
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: "Son Kul. Tar. (SKT)",
                        prefixIcon: const Icon(Icons.calendar_today),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        _expiryDate == null
                            ? "Seçiniz"
                            : "${_expiryDate!.day}.${_expiryDate!.month}.${_expiryDate!.year}",
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Kaydet Butonu
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    widget.onAdd({
                      "product_name": _selectedProduct,
                      "quantity": _quantity,
                      "buy_price": _buyPrice,
                      "total_price": _quantity * _buyPrice,
                      "batch_no": _batchNo,
                      "expiry_date": _expiryDate,
                    });
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Listeye Ekle",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 16), // Keyboard safe area
          ],
        ),
      ),
    );
  }
}
