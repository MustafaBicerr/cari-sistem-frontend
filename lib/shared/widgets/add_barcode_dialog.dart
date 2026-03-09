import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/image_utils.dart';
import '../../features/stock/presentation/screens/opening_stock_screen.dart';
import '../../features/products/presentation/providers/product_controller.dart';
import '../../features/products/presentation/providers/product_provider.dart';
import 'barcode_listener_wrapper.dart';
import 'barcode_scanner_sheet.dart';

/// Barkod bulunamadığında veya master'da bulunup tenant'ta yoksa
class AddBarcodeDialog extends ConsumerStatefulWidget {
  final String barcode;
  final Map<String, dynamic>? initialMasterDrug;
  final VoidCallback? onSuccess;
  final void Function(Map<String, dynamic> product)? onSuccessWithProduct;

  const AddBarcodeDialog({
    super.key,
    required this.barcode,
    this.initialMasterDrug,
    this.onSuccess,
    this.onSuccessWithProduct,
  });

  static Future<void> show(
    BuildContext context, {
    required String barcode,
    Map<String, dynamic>? initialMasterDrug,
    VoidCallback? onSuccess,
    void Function(Map<String, dynamic> product)? onSuccessWithProduct,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AddBarcodeDialog(
        barcode: barcode,
        initialMasterDrug: initialMasterDrug,
        onSuccess: onSuccess,
        onSuccessWithProduct: onSuccessWithProduct,
      ),
    );
  }

  @override
  ConsumerState<AddBarcodeDialog> createState() => _AddBarcodeDialogState();
}

class _AddBarcodeDialogState extends ConsumerState<AddBarcodeDialog> {
  final _barcodeCtrl = TextEditingController();
  Map<String, dynamic>? _selectedMasterDrug;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    barcodeDialogOpen = true;
    _barcodeCtrl.text = widget.barcode;
    if (widget.initialMasterDrug != null) {
      _selectedMasterDrug = widget.initialMasterDrug;
    }
  }

  @override
  void dispose() {
    barcodeDialogOpen = false;
    _barcodeCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedMasterDrug == null) {
      setState(() => _error = 'Lütfen bir ilaç seçin.');
      return;
    }
    final barcode = _barcodeCtrl.text.trim();
    if (barcode.isEmpty) {
      setState(() => _error = 'Barkod girin veya taratın.');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repo = ref.read(productRepositoryProvider);
      final product = await repo.createProductFromMasterWithBarcode(
        masterDrugId: _selectedMasterDrug!['id'].toString(),
        barcode: barcode,
      );
      ref.invalidate(productListProvider);
      if (mounted) {
        Navigator.of(context).pop();
        widget.onSuccessWithProduct?.call(product);
        widget.onSuccess?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Barkod başarıyla kaydedildi."),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 760),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.qr_code_scanner, color: AppColors.primary, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Barkodu Klinikte Kaydet",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Bu barkodu kendi işletmenizde kullanmak üzere kaydedin.",
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withOpacity(0.35)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, color: AppColors.primary, size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Bu adım yalnızca ilacı kliniğinize tanımlar.",
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Stok girişleri ile alış/satış fiyatı ayarları için Fatura Girişi veya Açılış Stoğu ekranlarını kullanmalısınız.",
                    style: TextStyle(fontSize: 12.5, height: 1.4),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Aksi durumda ürün 0 stok, 0 alış ve 0 satış fiyatı ile görünebilir.",
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ActionChip(
                        avatar: const Icon(Icons.receipt_long, size: 16, color: AppColors.primary),
                        label: const Text("Fatura Girişi"),
                        onPressed: () {
                          if (context.canPop()) Navigator.of(context).pop();
                          context.push('/stock/entry');
                        },
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.inventory_2_outlined, size: 16, color: AppColors.primary),
                        label: const Text("Açılış Stoğu"),
                        onPressed: () {
                          if (context.canPop()) Navigator.of(context).pop();
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const OpeningStockScreen()),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // 1. Ürün adı (Autocomplete)
            Text(
              "İlaç / Ürün",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Autocomplete<Map<String, dynamic>>(
              optionsBuilder: (value) async {
                if (value.text.trim().length < 2) return [];
                final ctrl = ref.read(productControllerProvider);
                return ctrl.searchMasterDrugs(value.text);
              },
              displayStringForOption: (o) => o['name'] ?? '',
              fieldViewBuilder: (ctx, ctrl, focusNode, onSubmitted) {
                if (widget.initialMasterDrug != null && ctrl.text.isEmpty) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (ctrl.text.isEmpty) {
                      ctrl.text = widget.initialMasterDrug!['name'] ?? '';
                    }
                  });
                }
                return TextFormField(
                  controller: ctrl,
                  focusNode: focusNode,
                  decoration: InputDecoration(
                    hintText: "İlaç adı yazın...",
                    prefixIcon: const Icon(Icons.medication, color: AppColors.primary),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                );
              },
              onSelected: (selection) {
                setState(() {
                  _selectedMasterDrug = selection;
                  _error = null;
                });
              },
              optionsViewBuilder: (ctx, onSelected, options) {
                return Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    elevation: 8,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 220),
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        itemCount: options.length,
                        itemBuilder: (ctx, i) {
                          final o = options.elementAt(i);
                          final imgUrl = ImageUtils.getImageUrl(
                            o['image_path']?.toString(),
                            o['full_image_url']?.toString(),
                          );
                          return ListTile(
                            leading: imgUrl != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: CachedNetworkImage(
                                      imageUrl: imgUrl,
                                      width: 44,
                                      height: 44,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : const Icon(Icons.medication, color: AppColors.primary),
                            title: Text(o['name'] ?? ''),
                            onTap: () => onSelected(o),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
            if (_selectedMasterDrug != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.success.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: AppColors.success, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      _selectedMasterDrug!['name'] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),

            // 2. Barkod alanı
            Text(
              "Barkod",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _barcodeCtrl,
              decoration: InputDecoration(
                hintText: "Barkod girin veya taratın",
                prefixIcon: const Icon(Icons.qr_code, color: AppColors.primary),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.camera_alt, color: AppColors.primary),
                  tooltip: "Kamera ile tara",
                  onPressed: () {
                    BarcodeScannerSheet.show(context, onScanned: (b) {
                      _barcodeCtrl.text = b;
                    });
                  },
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),

            if (_error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.error, size: 20),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13))),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            Row(
              children: [
                TextButton(
                  onPressed: _isLoading ? null : () => Navigator.pop(context),
                  child: const Text("İptal"),
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: _isLoading ? null : _submit,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.save, size: 18),
                  label: Text(_isLoading ? "Kaydediliyor..." : "Kaydet"),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
            ],
          ),
        ),
      ),
    );
  }
}
