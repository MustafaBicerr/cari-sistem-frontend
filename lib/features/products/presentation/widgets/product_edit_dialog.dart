import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/product.dart';
import '../providers/product_controller.dart';

class ProductEditDialog extends ConsumerStatefulWidget {
  final Product product;

  const ProductEditDialog({super.key, required this.product});

  @override
  ConsumerState<ProductEditDialog> createState() => _ProductEditDialogState();
}

class _ProductEditDialogState extends ConsumerState<ProductEditDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameCtrl;
  late TextEditingController _barcodeCtrl;
  late TextEditingController _buyPriceCtrl;
  late TextEditingController _sellPriceCtrl;
  late TextEditingController _stockCtrl;
  late TextEditingController _lowStockCtrl;

  XFile? _newImage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Mevcut verileri controller'lara yükle
    _nameCtrl = TextEditingController(text: widget.product.name);
    _barcodeCtrl = TextEditingController(text: widget.product.barcode);
    _buyPriceCtrl = TextEditingController(
      text: widget.product.buyPrice.toString(),
    );
    _sellPriceCtrl = TextEditingController(
      text: widget.product.sellPrice.toString(),
    );
    _stockCtrl = TextEditingController(
      text: widget.product.currentStock.toString(),
    );
    _lowStockCtrl = TextEditingController(
      text: widget.product.lowStockLimit.toString(),
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _barcodeCtrl.dispose();
    _buyPriceCtrl.dispose();
    _sellPriceCtrl.dispose();
    _stockCtrl.dispose();
    _lowStockCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _newImage = image;
      });
    }
  }

  // --- DEĞİŞİKLİK DEDEKTİFİ ---
  Map<String, dynamic> _getChanges() {
    final changes = <String, dynamic>{};
    final p = widget.product;

    if (_nameCtrl.text.trim() != p.name) {
      changes['name'] = _nameCtrl.text.trim();
    }
    if (double.tryParse(_buyPriceCtrl.text) != p.buyPrice) {
      changes['buy_price'] = double.tryParse(_buyPriceCtrl.text);
    }
    if (double.tryParse(_sellPriceCtrl.text) != p.sellPrice) {
      changes['sell_price'] = double.tryParse(_sellPriceCtrl.text);
    }
    if (double.tryParse(_stockCtrl.text) != p.currentStock) {
      changes['current_stock'] = double.tryParse(_stockCtrl.text);
    }
    if (int.tryParse(_lowStockCtrl.text) != p.lowStockLimit) {
      changes['low_stock_limit'] = int.tryParse(_lowStockCtrl.text);
    }

    return changes;
  }

  String _getFieldLabel(String key) {
    switch (key) {
      case 'name':
        return 'Ürün Adı';
      case 'buy_price':
        return 'Alış Fiyatı';
      case 'sell_price':
        return 'Satış Fiyatı';
      case 'current_stock':
        return 'Stok Durumu';
      case 'low_stock_limit':
        return 'Kritik Stok Sınırı';
      default:
        return key;
    }
  }

  // --- AKSİYONLAR ---

  void _handleDelete() {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text("Ürünü Sil"),
            content: const Text(
              "Bu ürünü silmek istediğinize emin misiniz? Bu işlem geri alınamaz.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("İptal"),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx); // Alert'i kapat
                  _performDelete();
                },
                child: const Text("Sil", style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
  }

  void _performDelete() {
    setState(() => _isLoading = true);
    ref
        .read(productControllerProvider)
        .deleteProduct(
          id: widget.product.id,
          onSuccess: () {
            Navigator.pop(context); // Ana dialogu kapat
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Ürün başarıyla silindi.")),
            );
          },
          onError: (err) {
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text("Hata: $err")));
          },
        );
  }

  void _handleCancel() {
    final changes = _getChanges();
    final hasImageChange = _newImage != null;

    if (changes.isNotEmpty || hasImageChange) {
      showDialog(
        context: context,
        builder:
            (ctx) => AlertDialog(
              title: const Text("Değişiklikler Kaybolacak"),
              content: const Text(
                "Kaydetmediğiniz değişiklikler silinecek, emin misiniz?",
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Hayır"),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx); // Alert'i kapat
                    Navigator.pop(context); // Ana dialogu kapat
                  },
                  child: const Text("Evet, Çık"),
                ),
              ],
            ),
      );
    } else {
      Navigator.pop(context);
    }
  }

  void _handleSave() {
    if (!_formKey.currentState!.validate()) return;

    final changes = _getChanges();
    final hasImageChange = _newImage != null;

    if (changes.isEmpty && !hasImageChange) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Herhangi bir değişiklik yapılmadı.")),
      );
      Navigator.pop(context);
      return;
    }

    // Değişiklik Onay Listesi
    final changeListWidgets =
        changes.keys.map((key) {
          return Text("• ${_getFieldLabel(key)}");
        }).toList();

    if (hasImageChange) {
      changeListWidgets.add(const Text("• Ürün Görseli"));
    }

    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text("Değişiklik Onayı"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Ürün hakkında aşağıdaki alanlarda değişiklikler yapıldı:",
                ),
                const SizedBox(height: 10),
                ...changeListWidgets,
                const SizedBox(height: 10),
                const Text(
                  "Bu değişiklikleri onaylıyor musunuz?",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("İptal"),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _performUpdate(changes);
                },
                child: const Text("Onayla"),
              ),
            ],
          ),
    );
  }

  void _performUpdate(Map<String, dynamic> changes) {
    setState(() => _isLoading = true);
    ref
        .read(productControllerProvider)
        .updateProduct(
          id: widget.product.id,
          updates: changes,
          image: _newImage,
          onSuccess: () {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Ürün başarıyla güncellendi!"),
                backgroundColor: Colors.green,
              ),
            );
          },
          onError: (err) {
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Hata: $err"),
                backgroundColor: Colors.red,
              ),
            );
          },
        );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Başlık
                const Text(
                  "Ürün Düzenle",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),

                // --- RESİM ALANI ---
                Center(
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Stack(
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                            image:
                                _newImage != null
                                    ? DecorationImage(
                                      image:
                                          kIsWeb
                                              ? NetworkImage(_newImage!.path)
                                              : FileImage(File(_newImage!.path))
                                                  as ImageProvider,
                                      fit: BoxFit.cover,
                                    )
                                    : (widget.product.imageUrl != null
                                        ? DecorationImage(
                                          image: NetworkImage(
                                            widget.product.imageUrl!,
                                          ),
                                          fit: BoxFit.cover,
                                        )
                                        : null),
                          ),
                          child:
                              (_newImage == null &&
                                      widget.product.imageUrl == null)
                                  ? const Icon(
                                    Icons.add_a_photo,
                                    color: Colors.grey,
                                    size: 40,
                                  )
                                  : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.edit,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // --- FORM ALANLARI ---

                // Barkod (Read-Only)
                TextFormField(
                  controller: _barcodeCtrl,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: "Barkod (Değiştirilemez)",
                    filled: true,
                    fillColor: Colors.grey[200],
                    prefixIcon: const Icon(Icons.qr_code_2, color: Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Ürün Adı
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: "Ürün Adı",
                    prefixIcon: Icon(Icons.label_outline),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v!.isEmpty ? "Zorunlu alan" : null,
                ),
                const SizedBox(height: 16),

                // Fiyatlar
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _buyPriceCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: "Alış Fiyatı",
                          suffixText: "₺",
                          border: OutlineInputBorder(),
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
                          labelText: "Satış Fiyatı",
                          suffixText: "₺",
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => v!.isEmpty ? "Zorunlu" : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Stoklar
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _stockCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: "Mevcut Stok",
                          prefixIcon: Icon(Icons.inventory),
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => v!.isEmpty ? "Zorunlu" : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _lowStockCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: "Kritik Sınır",
                          prefixIcon: Icon(Icons.warning_amber_rounded),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // --- BUTONLAR ---
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else
                  Row(
                    children: [
                      // 1. Sil Butonu
                      Expanded(
                        flex: 1,
                        child: ElevatedButton(
                          onPressed: _handleDelete,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text("Sil"),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // 2. Vazgeç Butonu
                      Expanded(
                        flex: 1,
                        child: ElevatedButton(
                          onPressed: _handleCancel,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text("Vazgeç"),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // 3. Kaydet Butonu
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _handleSave,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text("Kaydet"),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
