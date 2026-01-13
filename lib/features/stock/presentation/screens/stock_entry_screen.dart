import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/stock_entry_form.dart';

class StockEntryScreen extends StatefulWidget {
  const StockEntryScreen({super.key});

  @override
  State<StockEntryScreen> createState() => _StockEntryScreenState();
}

class _StockEntryScreenState extends State<StockEntryScreen> {
  // Fatura Başlık Bilgileri
  String? _selectedSupplier;
  final TextEditingController _invoiceNoController = TextEditingController();
  DateTime _invoiceDate = DateTime.now();

  // Eklenen Ürünler Listesi
  final List<Map<String, dynamic>> _items = [];

  // Dummy Tedarikçiler
  final List<String> _suppliers = [
    "Ecza Deposu A.Ş.",
    "Mama Dünyası",
    "Medikal Ltd.",
  ];

  void _addItem() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: StockEntryForm(
              onAdd: (item) {
                setState(() {
                  _items.add(item);
                });
              },
            ),
          ),
    );
  }

  void _saveInvoice() {
    if (_items.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Listeye ürün ekleyiniz!")));
      return;
    }
    // Backend'e Gönderilecek Paket (Purchase Invoice & Stock Movements)
    final invoiceData = {
      "supplier": _selectedSupplier,
      "invoice_no": _invoiceNoController.text,
      "date": _invoiceDate.toIso8601String(),
      "items": _items, // Batch, Expiry, Qty hepsi burada
      "total_amount": _items.fold(
        0.0,
        (sum, item) => sum + item['total_price'],
      ),
    };

    debugPrint("FATURA KAYDEDİLİYOR: $invoiceData");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Fatura ve Stok Girişi Başarılı!"),
        backgroundColor: AppColors.success,
      ),
    );
    Navigator.pop(context); // Çıkış
  }

  @override
  Widget build(BuildContext context) {
    double totalAmount = _items.fold(
      0.0,
      (sum, item) => sum + item['total_price'],
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text("Mal Kabul (Fatura)")),
      body: Column(
        children: [
          // 1. FATURA BAŞLIĞI (HEADER)
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  value: _selectedSupplier,
                  hint: const Text("Tedarikçi / Depo Seç"),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.store),
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                  items:
                      _suppliers
                          .map(
                            (s) => DropdownMenuItem(value: s, child: Text(s)),
                          )
                          .toList(),
                  onChanged: (val) => setState(() => _selectedSupplier = val),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _invoiceNoController,
                        decoration: const InputDecoration(
                          labelText: "Fatura / Evrak No",
                          prefixIcon: Icon(Icons.receipt),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _invoiceDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime.now(),
                          );
                          if (date != null) setState(() => _invoiceDate = date);
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: "Tarih",
                            prefixIcon: Icon(Icons.calendar_month),
                            border: OutlineInputBorder(),
                          ),
                          child: Text(
                            "${_invoiceDate.day}.${_invoiceDate.month}.${_invoiceDate.year}",
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // 2. EKLENEN ÜRÜNLER LİSTESİ
          Expanded(
            child:
                _items.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_shopping_cart,
                            size: 64,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            "Henüz ürün eklenmedi.\nSağ alttaki + butonuna basınız.",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                    : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = _items[index];
                        final date = item['expiry_date'] as DateTime?;
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.grey.withOpacity(0.1),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.medication,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['product_name'],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        if (item['batch_no'] != "")
                                          _Tag(
                                            text: "Parti: ${item['batch_no']}",
                                            color: Colors.orange,
                                          ),
                                        if (date != null)
                                          _Tag(
                                            text:
                                                "SKT: ${date.day}/${date.month}/${date.year}",
                                            color: Colors.red,
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    "${item['quantity']} Adet",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    "₺${item['total_price'].toStringAsFixed(2)}",
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.grey,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _items.removeAt(index);
                                  });
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
          ),

          // 3. TOPLAM VE KAYDET (FOOTER)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Genel Toplam",
                      style: TextStyle(color: Colors.grey),
                    ),
                    Text(
                      "₺${totalAmount.toStringAsFixed(2)}",
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _saveInvoice,
                  icon: const Icon(Icons.save, color: Colors.white),
                  label: const Text(
                    "Faturayı Kaydet",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addItem,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;
  final Color color;
  const _Tag({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
