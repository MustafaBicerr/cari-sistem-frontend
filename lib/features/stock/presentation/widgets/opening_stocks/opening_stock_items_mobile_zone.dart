import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/features/stock/domain/entities/opening_stock_item_entity.dart';
import 'package:mobile/features/stock/presentation/providers/opening_stock_provider.dart';
import 'package:mobile/features/products/presentation/providers/product_provider.dart';
import 'package:mobile/features/products/domain/models/product.dart';
import 'package:mobile/core/utils/image_utils.dart';
import 'package:mobile/features/products/presentation/providers/product_controller.dart';
import 'package:mobile/features/products/presentation/widgets/product_form_dialog.dart';
import 'package:mobile/shared/widgets/barcode_scanner_sheet.dart';

/// Mobil için sadeleştirilmiş "Açılış Stoğu Ürünleri" alanı.
class OpeningStockItemsMobileZone extends ConsumerStatefulWidget {
  final void Function(String barcode)? onBarcodeScanned;

  const OpeningStockItemsMobileZone({super.key, this.onBarcodeScanned});

  @override
  ConsumerState<OpeningStockItemsMobileZone> createState() =>
      _OpeningStockItemsMobileZoneState();
}

class _OpeningStockItemsMobileZoneState
    extends ConsumerState<OpeningStockItemsMobileZone> {
  TextEditingController? _searchController;
  bool _isSearching = false;

  final _currency = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');

  Future<List<Map<String, dynamic>>> _searchCombinedProducts(
    String query,
    List<Product> localProducts,
  ) async {
    if (query.trim().isEmpty) return [];

    setState(() => _isSearching = true);

    try {
      final localMatches =
          localProducts
              .where((p) {
                final nameMatch = p.name.toLowerCase().contains(
                      query.toLowerCase(),
                    );
                final barcodeMatch =
                    (p.barcode?.toLowerCase().contains(query.toLowerCase()) ??
                        false);
                return nameMatch || barcodeMatch;
              })
              .map(
                (p) => {
                  'id': p.id,
                  'name': p.name,
                  'image_url': ImageUtils.getImageUrl(
                    p.customImagePath,
                    p.fullImageUrl,
                  ),
                  'source': 'local',
                  'buy_price': p.buyingPrice,
                  'sell_price': p.sellingPrice,
                  'vat_rate': p.vatRate,
                },
              )
              .toList();

      final productController = ref.read(productControllerProvider);
      final masterDrugsRes = await productController.searchMasterDrugs(query);

      final localNameSet =
          localProducts.map((p) => p.name.toLowerCase().trim()).toSet();

      final masterDrugsMatches =
          masterDrugsRes
              .where((v) {
                final globalName =
                    (v['name'] ?? '').toString().toLowerCase().trim();
                final existsLocally = localNameSet.contains(globalName);
                return !existsLocally;
              })
              .map((v) {
                return {
                  'id': v['id'],
                  'name': v['name'],
                  'image_url': ImageUtils.getImageUrl(
                    v['image_path'],
                    v['full_image_url'],
                  ),
                  'source': 'global',
                  'buy_price': 0.0,
                  'sell_price': 0.0,
                  'vat_rate': 10,
                };
              })
              .toList();

      return [...localMatches, ...masterDrugsMatches];
    } finally {
      setState(() => _isSearching = false);
    }
  }

  Future<void> _openItemDialogForNewSelection(
    Map<String, dynamic> selection,
  ) async {
    final openingNotifier = ref.read(openingStockProvider.notifier);

    final newItem = OpeningStockItemEntity(
      productId: selection['id'].toString(),
      productName: selection['name'] ?? '',
      imageUrl: selection['image_url']?.toString(),
      productSource: selection['source'] ?? 'local',
      quantity: 1.0,
      expirationDate: DateTime.now(),
      batchNo: '',
      location: '',
      buyingPrice: (selection['buy_price'] ?? 0).toDouble(),
      sellingPrice: (selection['sell_price'] ?? 0).toDouble(),
      vatRate: (selection['vat_rate'] ?? 0) as int,
    );

    openingNotifier.addItem(newItem);
    final state = ref.read(openingStockProvider);
    if (state.items.isEmpty) return;
    final added = state.items.last;

    final result = await showDialog<_OpeningDialogResult>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => _OpeningItemMobileDialog(initialItem: added),
        );

    if (!mounted || result == null) {
      // İptal → satırı sil
      final index = state.items.indexOf(added);
      if (index != -1) {
        openingNotifier.removeItem(index);
      }
      return;
    }

    final index = state.items.indexOf(added);
    if (index == -1) return;

    if (result.delete) {
      openingNotifier.removeItem(index);
    } else {
      openingNotifier.updateItem(index, result.item);
    }
  }

  Future<void> _openItemDialogForExisting(int index) async {
    final state = ref.read(openingStockProvider);
    if (index < 0 || index >= state.items.length) return;
    final item = state.items[index];

    final result = await showDialog<_OpeningDialogResult>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => _OpeningItemMobileDialog(initialItem: item),
        );

    if (!mounted || result == null) return;

    final notifier = ref.read(openingStockProvider.notifier);

    if (result.delete) {
      notifier.removeItem(index);
    } else {
      notifier.updateItem(index, result.item);
    }
  }

  @override
  Widget build(BuildContext context) {
    final openingState = ref.watch(openingStockProvider);
    final productListState = ref.watch(productListProvider);
    final localProducts = productListState.value ?? [];

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Ürünler",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Arama + Yeni ürün
            Autocomplete<Map<String, dynamic>>(
              optionsBuilder: (textEditingValue) {
                return _searchCombinedProducts(
                  textEditingValue.text,
                  localProducts,
                );
              },
              displayStringForOption: (o) => o['name'] ?? '',
              onSelected: (selection) async {
                final alreadyExists = openingState.items.any(
                  (item) =>
                      item.productId.toString() ==
                      selection['id'].toString(),
                );
                if (alreadyExists) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Bu ürün zaten listede."),
                    ),
                  );
                  return;
                }
                _searchController?.clear();
                await _openItemDialogForNewSelection(selection);
              },
              fieldViewBuilder: (
                context,
                controller,
                focusNode,
                onFieldSubmitted,
              ) {
                _searchController = controller;
                return TextFormField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: InputDecoration(
                    labelText: "Barkod okutun veya ürün adı...",
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _isSearching
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : (widget.onBarcodeScanned != null
                            ? IconButton(
                                icon: const Icon(
                                  Icons.qr_code_scanner,
                                  color: AppColors.primary,
                                ),
                                tooltip: "Kamera ile barkod tara",
                                onPressed: () {
                                  BarcodeScannerSheet.show(
                                    context,
                                    onScanned: widget.onBarcodeScanned!,
                                  );
                                },
                              )
                            : null),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              },
              optionsViewBuilder: (context, onSelected, options) {
                return Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    elevation: 8,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: MediaQuery.of(context).size.width - 32,
                      constraints: const BoxConstraints(maxHeight: 350),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: ListView.separated(
                        padding: EdgeInsets.zero,
                        itemCount: options.length,
                        separatorBuilder: (c, i) =>
                            const Divider(height: 1, indent: 70),
                        itemBuilder: (context, index) {
                          final option = options.elementAt(index);
                          final imgUrl = option['image_url'];
                          final isLocal = option['source'] == 'local';
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            leading: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                                border:
                                    Border.all(color: Colors.grey.shade300),
                              ),
                              child: imgUrl != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: CachedNetworkImage(
                                        imageUrl: imgUrl.toString(),
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.medication,
                                      color: AppColors.primary,
                                    ),
                            ),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    option['name'] ?? '',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                                Icon(
                                  isLocal
                                      ? Icons.verified
                                      : Icons.cloud_download,
                                  size: 16,
                                  color: isLocal
                                      ? AppColors.success
                                      : AppColors.primary,
                                ),
                              ],
                            ),
                            subtitle: Text(
                              isLocal
                                  ? "Klinikte Kayıtlı"
                                  : "Referans kataloğundan",
                              style: const TextStyle(fontSize: 12),
                            ),
                            onTap: () => onSelected(option),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await showDialog(
                    context: context,
                    builder: (context) => const ProductFormDialog(),
                  );
                  ref.invalidate(productListProvider);
                },
                icon: const Icon(Icons.add_box),
                label: const Text("Yeni Ürün Tanımla"),
              ),
            ),

            const SizedBox(height: 16),

            if (openingState.items.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: const Column(
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 40,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 8),
                    Text(
                      "Henüz ürün eklenmedi.",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: openingState.items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final item = openingState.items[index];
                  return InkWell(
                    onTap: () => _openItemDialogForExisting(index),
                    child: _buildItemCard(item),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemCard(OpeningStockItemEntity item) {
    final dateStr = DateFormat('dd.MM.yyyy').format(item.expirationDate);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: item.imageUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: item.imageUrl!,
                      fit: BoxFit.cover,
                    ),
                  )
                : const Icon(
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
                  item.productName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Parti: ${item.batchNo ?? '-'}  •  SKT: $dateStr",
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Miktar: ${item.quantity.toStringAsFixed(0)}  •  Konum: ${item.location ?? '-'}",
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _currency.format(item.buyingPrice),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              const Icon(
                Icons.chevron_right,
                size: 18,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// --- Satır detay dialogu ---

class _OpeningItemMobileDialog extends StatefulWidget {
  final OpeningStockItemEntity initialItem;

  const _OpeningItemMobileDialog({required this.initialItem});

  @override
  State<_OpeningItemMobileDialog> createState() =>
      _OpeningItemMobileDialogState();
}

class _OpeningItemMobileDialogState extends State<_OpeningItemMobileDialog> {
  late TextEditingController _batchCtrl;
  late TextEditingController _qtyCtrl;
  late TextEditingController _buyCtrl;
  late TextEditingController _sellCtrl;
  late TextEditingController _vatCtrl;
  late TextEditingController _locationCtrl;

  late DateTime _expirationDate;
  late OpeningStockItemEntity _previewItem;

  final _currency = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');

  @override
  void initState() {
    super.initState();
    final i = widget.initialItem;
    _batchCtrl = TextEditingController(text: i.batchNo ?? '');
    _qtyCtrl = TextEditingController(text: i.quantity.toStringAsFixed(0));
    _buyCtrl = TextEditingController(text: i.buyingPrice.toString());
    _sellCtrl = TextEditingController(text: i.sellingPrice.toString());
    _vatCtrl = TextEditingController(text: i.vatRate.toString());
    _locationCtrl = TextEditingController(text: i.location ?? '');
    _expirationDate = i.expirationDate;
    _previewItem = i;
  }

  @override
  void dispose() {
    _batchCtrl.dispose();
    _qtyCtrl.dispose();
    _buyCtrl.dispose();
    _sellCtrl.dispose();
    _vatCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  void _rebuildPreview() {
    final i = widget.initialItem;
    setState(() {
      _previewItem = i.copyWith(
        batchNo: _batchCtrl.text,
        quantity: double.tryParse(_qtyCtrl.text) ?? 0,
        buyingPrice: double.tryParse(_buyCtrl.text) ?? 0,
        sellingPrice: double.tryParse(_sellCtrl.text) ?? 0,
        vatRate: int.tryParse(_vatCtrl.text) ?? 0,
        location: _locationCtrl.text,
        expirationDate: _expirationDate,
      );
    });
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _expirationDate,
      firstDate: now.subtract(const Duration(days: 3650)),
      lastDate: now.add(const Duration(days: 3650)),
    );
    if (picked != null) {
      setState(() => _expirationDate = picked);
      _rebuildPreview();
    }
  }

  void _resetFields() {
    final i = widget.initialItem;
    _batchCtrl.text = '';
    _qtyCtrl.text = '1';
    _buyCtrl.text = i.buyingPrice.toString();
    _sellCtrl.text = i.sellingPrice.toString();
    _vatCtrl.text = i.vatRate.toString();
    _locationCtrl.text = '';
    _expirationDate = i.expirationDate;
    _rebuildPreview();
  }

  @override
  Widget build(BuildContext context) {
    final i = widget.initialItem;
    final dateStr = DateFormat('dd.MM.yyyy').format(_expirationDate);

    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      contentPadding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
              child: Row(
                children: [
                  const Text(
                    "Satır Detayı",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(null),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: i.imageUrl != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: CachedNetworkImage(
                                    imageUrl: i.imageUrl!,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : const Icon(
                                  Icons.medication,
                                  color: AppColors.primary,
                                ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            i.productName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    _buildCard(
                      children: [
                        const Text(
                          "Parti & SKT",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _batchCtrl,
                          decoration: const InputDecoration(
                            labelText: "Parti",
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (_) => _rebuildPreview(),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: _selectDate,
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: "SKT",
                              border: OutlineInputBorder(),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(dateStr),
                                const Icon(Icons.calendar_today, size: 18),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    _buildCard(
                      children: [
                        const Text(
                          "Miktar",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _qtyCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: "Miktar",
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (_) => _rebuildPreview(),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    _buildCard(
                      children: [
                        const Text(
                          "Alış & Satış Fiyatı",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _buyCtrl,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: "Alış Fiyatı (₺)",
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: (_) => _rebuildPreview(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                controller: _sellCtrl,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: "Satış Fiyatı (₺)",
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: (_) => _rebuildPreview(),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    _buildCard(
                      children: [
                        const Text(
                          "KDV ve Konum",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            SizedBox(
                              width: 90,
                              child: TextFormField(
                                controller: _vatCtrl,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: "KDV (%)",
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: (_) => _rebuildPreview(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                controller: _locationCtrl,
                                decoration: const InputDecoration(
                                  labelText: "Konum",
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: (_) => _rebuildPreview(),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.4),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Tahmini Toplam Değer (Alış)",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _currency.format(
                              _previewItem.quantity * _previewItem.buyingPrice,
                            ),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(
                children: [
                  IconButton(
                    tooltip: "Satırı Sil",
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => Navigator.of(context).pop(
                      _OpeningDialogResult(delete: true, item: _previewItem),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: _resetFields,
                    child: const Text("Temizle"),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(
                        _OpeningDialogResult(delete: false, item: _previewItem),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "Kaydet",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _OpeningDialogResult {
  final bool delete;
  final OpeningStockItemEntity item;

  _OpeningDialogResult({required this.delete, required this.item});
}

