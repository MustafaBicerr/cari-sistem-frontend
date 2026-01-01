import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/product_controller.dart';

class AddProductDialog extends ConsumerStatefulWidget {
  final String? initialBarcode;

  const AddProductDialog({super.key, this.initialBarcode});

  @override
  ConsumerState<AddProductDialog> createState() => _AddProductDialogState();
}

class _AddProductDialogState extends ConsumerState<AddProductDialog> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _barcodeCtrl = TextEditingController();
  final _buyPriceCtrl = TextEditingController();
  final _sellPriceCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();
  final _criticalStockCtrl = TextEditingController(text: "10");
  final _taxRateCtrl = TextEditingController(text: "0"); // Varsayılan 0 vergi

  // Birim Tipi İçin Seçenekler
  // DB'ye gidecek değer (key) - Ekranda görünecek değer (value)
  final List<Map<String, String>> _unitTypes = [
    {'value': 'PIECE', 'label': 'Adet / Kutu'},
    {'value': 'WEIGHT', 'label': 'Ağırlık (Kg/Gr)'},
    {'value': 'VOLUME', 'label': 'Hacim (Lt/Ml)'},
  ];
  String _selectedUnit = 'PIECE'; // Varsayılan seçim

  bool _isLoading = false;
  XFile? _selectedImage;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _selectedImage = image;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialBarcode != null) {
      _barcodeCtrl.text = widget.initialBarcode!;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _barcodeCtrl.dispose();
    _buyPriceCtrl.dispose();
    _sellPriceCtrl.dispose();
    _stockCtrl.dispose();
    _criticalStockCtrl.dispose();
    _taxRateCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      ref
          .read(productControllerProvider)
          .addProduct(
            name: _nameCtrl.text.trim(),
            barcode: _barcodeCtrl.text.trim(),
            buyPrice: double.tryParse(_buyPriceCtrl.text) ?? 0,
            sellPrice: double.tryParse(_sellPriceCtrl.text) ?? 0,
            stock: double.tryParse(_stockCtrl.text) ?? 0,
            unitType: _selectedUnit, // Seçilen birimi gönderiyoruz
            taxRate: int.tryParse(_taxRateCtrl.text) ?? 0, // Vergi (Opsiyonel)
            lowStockLimit: int.tryParse(_criticalStockCtrl.text) ?? 10,
            image: _selectedImage,

            onSuccess: () {
              setState(() => _isLoading = false);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("✅ Ürün başarıyla eklendi!"),
                  backgroundColor: Colors.green,
                ),
              );
            },
            onError: (msg) {
              setState(() => _isLoading = false);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("❌ Hata: $msg"),
                  backgroundColor: Colors.red,
                ),
              );
            },
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(
          maxWidth: 600,
        ), // Biraz daha genişlettim
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Yeni Ürün Girişi",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(height: 30),

                // Resim Seçme Alanı
                Center(
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                        image:
                            _selectedImage != null
                                ? DecorationImage(
                                  image:
                                      kIsWeb
                                          ? NetworkImage(_selectedImage!.path)
                                          : FileImage(
                                                File(_selectedImage!.path),
                                              )
                                              as ImageProvider,
                                  fit: BoxFit.cover,
                                )
                                : null,
                      ),
                      child:
                          _selectedImage == null
                              ? const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_a_photo,
                                    color: Colors.grey,
                                    size: 32,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    "Resim Ekle",
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              )
                              : null,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // 1. Temel Bilgiler
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: "Ürün Adı *", // Zorunlu işareti
                    hintText: "Örn: Ağrı Kesici",
                    prefixIcon: Icon(Icons.label_outline),
                  ),
                  validator: (v) => v!.isEmpty ? "Ürün adı zorunludur" : null,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _barcodeCtrl,
                  decoration: const InputDecoration(
                    labelText: "Barkod *",
                    prefixIcon: Icon(Icons.qr_code_2),
                  ),
                  // SENİN İSTEĞİN: Barkod artık zorunlu
                  validator: (v) => v!.isEmpty ? "Barkod zorunludur" : null,
                ),
                const SizedBox(height: 16),

                // 2. Birim ve Fiyatlandırma
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // BİRİM TİPİ (Dropdown)
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        value: _selectedUnit,
                        decoration: const InputDecoration(
                          labelText: "Satış Birimi *",
                          prefixIcon: Icon(Icons.scale_outlined),
                        ),
                        items:
                            _unitTypes.map((unit) {
                              return DropdownMenuItem(
                                value: unit['value'],
                                child: Text(unit['label']!),
                              );
                            }).toList(),
                        onChanged:
                            (val) => setState(() => _selectedUnit = val!),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // KDV (Opsiyonel)
                    Expanded(
                      flex: 1,
                      child: TextFormField(
                        controller: _taxRateCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: "KDV %",
                          hintText: "0",
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _buyPriceCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: "Alış Fiyatı *",
                          suffixText: "₺",
                          filled: true,
                        ),
                        validator: (v) => v!.isEmpty ? "Zorunlu" : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _sellPriceCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: "Satış Fiyatı *",
                          suffixText: "₺",
                          filled: true,
                          fillColor: Color(0xFFEFF6FF),
                        ),
                        validator: (v) => v!.isEmpty ? "Zorunlu" : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 3. Stok Yönetimi
                const Text(
                  "Stok Ayarları",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _stockCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: "Mevcut Stok *",
                          prefixIcon: Icon(Icons.inventory),
                        ),
                        validator: (v) => v!.isEmpty ? "Zorunlu" : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _criticalStockCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: "Kritik Sınır",
                          prefixIcon: Icon(Icons.notifications_active_outlined),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Bilgilendirme Kutusu
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          "İpucu: 'Birim' seçimi önemlidir. Sıvı ilaçlar için Hacim, haplar için Adet seçiniz. KDV oranı boş bırakılırsa %0 olarak kaydedilir.",
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    backgroundColor: AppColors.primary,
                  ),
                  child:
                      _isLoading
                          ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                          : const Text(
                            "Ürünü Kaydet",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
