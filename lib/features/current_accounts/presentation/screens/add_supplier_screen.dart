import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/warehouse_model.dart';
import '../providers/account_provider.dart';
import '../widgets/warehouse_autocomplete_field.dart';

class AddSupplierScreen extends ConsumerStatefulWidget {
  const AddSupplierScreen({super.key});

  @override
  ConsumerState<AddSupplierScreen> createState() => _AddSupplierScreenState();
}

class _AddSupplierScreenState extends ConsumerState<AddSupplierScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nameCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _taxNoCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _districtCtrl = TextEditingController();
  final _licenseCtrl = TextEditingController();

  bool _isLoading = false;

  // Autocomplete'den seçim yapılınca formu doldur
  void _onWarehouseSelected(WarehouseModel warehouse) {
    setState(() {
      _nameCtrl.text = warehouse.name; // Zaten yazılıdır ama garanti olsun
      _cityCtrl.text = warehouse.city ?? '';
      _districtCtrl.text = warehouse.district ?? '';
      _licenseCtrl.text = warehouse.licenseNo ?? '';
      _addressCtrl.text = warehouse.address ?? '';
      // Mesul müdürü ilgili kişi yapabiliriz
      if (warehouse.manager != null) {
        _contactCtrl.text = warehouse.manager!;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("${warehouse.name} bilgileri dolduruldu!"),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final repo = ref.read(supplierRepositoryProvider);
      await repo.createSupplier({
        'name': _nameCtrl.text,
        'contact_person': _contactCtrl.text,
        'phone': _phoneCtrl.text,
        'email': _emailCtrl.text,
        'tax_number': _taxNoCtrl.text,
        'address': _addressCtrl.text,
        'city': _cityCtrl.text,
        'district': _districtCtrl.text,
        'license_no': _licenseCtrl.text,
      });

      // Listeyi yenile
      ref.invalidate(supplierListProvider);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Tedarikçi başarıyla eklendi!")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Hata: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Yeni Tedarikçi Ekle")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Firma Bilgileri",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 16),

              // 🔥 AUTOCOMPLETE FIELD
              WarehouseAutocompleteField(
                controller: _nameCtrl,
                onSelected: _onWarehouseSelected,
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(child: _buildTextField(_licenseCtrl, "Ruhsat No")),
                  const SizedBox(width: 12),
                  Expanded(child: _buildTextField(_taxNoCtrl, "Vergi No")),
                ],
              ),
              const SizedBox(height: 24),

              const Text(
                "İletişim",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 16),
              _buildTextField(_contactCtrl, "İlgili Kişi / Müdür"),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      _phoneCtrl,
                      "Telefon",
                      TextInputType.phone,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(
                      _emailCtrl,
                      "E-posta",
                      TextInputType.emailAddress,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              const Text(
                "Adres",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildTextField(_cityCtrl, "Şehir")),
                  const SizedBox(width: 12),
                  Expanded(child: _buildTextField(_districtCtrl, "İlçe")),
                ],
              ),
              const SizedBox(height: 16),
              _buildTextField(
                _addressCtrl,
                "Açık Adres",
                TextInputType.multiline,
                3,
              ),

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child:
                      _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                            "KAYDET",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController ctrl,
    String label, [
    TextInputType? type,
    int lines = 1,
  ]) {
    return TextFormField(
      controller: ctrl,
      keyboardType: type,
      maxLines: lines,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
      validator: (val) {
        if (label.contains("Firma") && (val == null || val.isEmpty))
          return "Zorunlu alan";
        return null;
      },
    );
  }
}
