import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/account_provider.dart';
// CustomerModel'i import etmeyi unutma
import '../../data/models/customer_model.dart';

class AddCustomerScreen extends ConsumerStatefulWidget {
  const AddCustomerScreen({super.key});

  @override
  ConsumerState<AddCustomerScreen> createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends ConsumerState<AddCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  bool _isLoading = false;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final repo = ref.read(customerRepositoryProvider);

      // 1. Müşteriyi Kaydet ve Dönen Veriyi (ID Dahil) Yakala
      final CustomerModel newCustomer = await repo.createCustomer({
        'full_name': _nameCtrl.text,
        'phone': _phoneCtrl.text,
        'email': _emailCtrl.text,
        'address': _addressCtrl.text,
      });

      // 2. Listeyi Arka Planda Yenile (UI'ı bekletme)
      ref.invalidate(customerListProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Müşteri başarıyla eklendi!"),
            backgroundColor: Colors.green,
          ),
        );

        // 3. EKRANI KAPAT VE MÜŞTERİ NESNESİNİ GERİ GÖNDER 🚀
        // Buradaki 'newCustomer' içinde ID var!
        Navigator.pop(context, newCustomer);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Hata: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // ... (Build metodu ve UI tamamen aynı kalabilir, sadece _save fonksiyonu değişti)
    return Scaffold(
      appBar: AppBar(title: const Text("Yeni Müşteri Ekle")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildTextField(
                _nameCtrl,
                "Müşteri Adı Soyadı",
                isRequired: true,
              ),
              const SizedBox(height: 16),
              _buildTextField(_phoneCtrl, "Telefon", type: TextInputType.phone),
              const SizedBox(height: 16),
              _buildTextField(
                _emailCtrl,
                "E-posta",
                type: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                _addressCtrl,
                "Adres",
                type: TextInputType.multiline,
                lines: 3,
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
    String label, {
    TextInputType? type,
    int lines = 1,
    bool isRequired = false,
  }) {
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
        if (isRequired && (val == null || val.isEmpty))
          return "Bu alan zorunludur";
        return null;
      },
    );
  }
}
