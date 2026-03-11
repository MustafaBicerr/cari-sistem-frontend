import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/image_utils.dart';
import '../../../../products/domain/models/product.dart';
import '../../../../products/presentation/providers/product_controller.dart';
import '../../../../products/presentation/providers/product_provider.dart';
import '../../../../products/presentation/widgets/product_form_dialog.dart';
import 'package:mobile/shared/widgets/barcode_scanner_sheet.dart';
import '../../providers/purchase_form_provider.dart';
import '../../providers/purchase_items_provider.dart';

/// Mobil için sadeleştirilmiş "Fatura Kalemleri" alanı.
/// Ürünler autocomplete ile seçilir ve detaylar satır dialogu üzerinden girilir.
class PurchaseItemsMobileZone extends ConsumerStatefulWidget {
  final void Function(String barcode)? onBarcodeScanned;

  const PurchaseItemsMobileZone({super.key, this.onBarcodeScanned});

  @override
  ConsumerState<PurchaseItemsMobileZone> createState() =>
      _PurchaseItemsMobileZoneState();
}

class _PurchaseItemsMobileZoneState
    extends ConsumerState<PurchaseItemsMobileZone> {
  TextEditingController? _searchController;
  bool _isSearching = false;

  final _currency = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');

  Future<List<Map<String, dynamic>>> _searchCombinedProducts(
    String query,
    List<Product> localProducts,
  ) async {
    if (query.isEmpty) return [];

    setState(() => _isSearching = true);

    // 1) Lokal ürünler
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
                'buy_price': p.buyingPrice,
                'sell_price': p.sellingPrice,
                'tax_rate': p.vatRate,
                'image_url': ImageUtils.getImageUrl(
                  p.customImagePath,
                  p.fullImageUrl,
                ),
                'source': 'local',
              },
            )
            .toList();

    // 2) Global katalog
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
                'buy_price': 0.0,
                'sell_price': 0.0,
                'tax_rate': 10.0,
                'image_url': ImageUtils.getImageUrl(
                  v['image_path'],
                  v['full_image_url'],
                ),
                'source': 'global',
              };
            })
            .toList();

    setState(() => _isSearching = false);

    return [...localMatches, ...masterDrugsMatches];
  }

  Future<void> _openItemDialogForNewSelection(
    Map<String, dynamic> selection,
  ) async {
    // Debug: seçilen ürünün görsel URL'sini logla
    // Böylece image_url gerçekten dolu mu görebiliriz.
    // ignore: avoid_print
    print('[MOBILE ITEMS] Selected product: '
        'id=${selection['id']}, '
        'name=${selection['name']}, '
        'image_url=${selection['image_url']}');
    final purchaseNotifier = ref.read(purchaseFormProvider.notifier);

    // Önce satırı ekle (masaüstü ile aynı mantık)
    purchaseNotifier.addItem(
      selection['id'],
      selection['name'],
      (selection['buy_price'] ?? 0).toDouble(),
      (selection['sell_price'] ?? 0).toDouble(),
      (selection['tax_rate'] ?? 0).toDouble(),
      selection['source'] ?? 'local',
      selection['image_url']?.toString(),
    );

    // Eklenen son item'i al
    final state = ref.read(purchaseFormProvider);
    if (state.items.isEmpty) return;
    final newItem = state.items.last;

    final result = await showDialog<_DialogResult>(
          context: context,
          barrierDismissible: false,
          builder: (context) => _PurchaseItemMobileDialog(initialItem: newItem),
        );

    if (!mounted || result == null) {
      // Kaydetmeden/iptalle kapattıysa satırı geri al
      ref.read(purchaseFormProvider.notifier).removeItem(newItem.uiId);
      ref.read(purchaseItemsProvider.notifier).removeRowControllers(newItem.uiId);
      return;
    }

    if (result.delete) {
      ref.read(purchaseFormProvider.notifier).removeItem(newItem.uiId);
      ref.read(purchaseItemsProvider.notifier).removeRowControllers(newItem.uiId);
      return;
    }

    // Güncellenmiş satırı kaydet
    ref
        .read(purchaseFormProvider.notifier)
        .updateItem(newItem.uiId, result.item);
  }

  Future<void> _openItemDialogForExisting(PurchaseItemState item) async {
    final result = await showDialog<_DialogResult>(
          context: context,
          barrierDismissible: false,
          builder: (context) => _PurchaseItemMobileDialog(initialItem: item),
        );

    if (!mounted || result == null) {
      // Değişiklik yapılmadan kapatıldı, hiçbir şey yapma
      return;
    }

    if (result.delete) {
      ref.read(purchaseFormProvider.notifier).removeItem(item.uiId);
      ref.read(purchaseItemsProvider.notifier).removeRowControllers(item.uiId);
      return;
    }

    // Güncellenmiş satırı kaydet
    ref
        .read(purchaseFormProvider.notifier)
        .updateItem(item.uiId, result.item);
  }

  @override
  Widget build(BuildContext context) {
    final purchaseState = ref.watch(purchaseFormProvider);
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
              "Fatura Kalemleri",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Ürün arama + Yeni İlaç
            Autocomplete<Map<String, dynamic>>(
              optionsBuilder: (textEditingValue) {
                return _searchCombinedProducts(
                  textEditingValue.text,
                  localProducts,
                );
              },
              displayStringForOption: (option) => option['name'],
              onSelected: (selection) async {
                final alreadyExists = purchaseState.items.any(
                  (item) =>
                      item.productId.toString() ==
                      selection['id'].toString(),
                );
                if (alreadyExists) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Bu ürün zaten faturada mevcut."),
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
                    labelText: "Barkod okutun veya Ürün Adı yazın...",
                    prefixIcon: const Icon(
                      Icons.search,
                      color: AppColors.primary,
                    ),
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
                    filled: true,
                    fillColor: AppColors.background,
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
                          final isLocal = option['source'] == 'local';
                          final imgUrl = option['image_url']?.toString();

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
                                        imageUrl: imgUrl,
                                        fit: BoxFit.cover,
                                        placeholder: (c, u) => const Icon(
                                          Icons.image,
                                          size: 20,
                                          color: Colors.grey,
                                        ),
                                        errorWidget: (c, u, e) =>
                                            const Icon(
                                          Icons.broken_image,
                                          size: 20,
                                          color: Colors.grey,
                                        ),
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
                                    option['name'],
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
                label: const Text("Yeni İlaç Tanımla"),
              ),
            ),

            const SizedBox(height: 16),

            // Eklenmiş ürün listesi (kartlar)
            if (purchaseState.items.isEmpty)
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
                      "Faturaya henüz ürün eklenmedi.",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: purchaseState.items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final item = purchaseState.items[index];
                  return InkWell(
                    onTap: () => _openItemDialogForExisting(item),
                    child: _buildItemCard(item),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemCard(PurchaseItemState item) {
    final total = item.lineTotal;

    // Debug: satır kartında kullanılan imageUrl'i logla
    // ignore: avoid_print
    print('[MOBILE ITEMS] Build item card: '
        'productId=${item.productId}, imageUrl=${item.imageUrl}');
    final dateStr = item.expirationDate != null
        ? DateFormat('dd.MM.yyyy').format(item.expirationDate!)
        : 'SKT Seçilmedi';

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
                  "Parti: ${item.batchNo.isEmpty ? '-' : item.batchNo}  •  SKT: $dateStr",
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Miktar: ${item.quantity}  •  Mal Fazlası: ${item.freeQuantity}",
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
                _currency.format(total),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 4),
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

// --- SATIR DÜZENLEME DİALOGU ---

class _PurchaseItemMobileDialog extends StatefulWidget {
  final PurchaseItemState initialItem;

  const _PurchaseItemMobileDialog({required this.initialItem});

  @override
  State<_PurchaseItemMobileDialog> createState() =>
      _PurchaseItemMobileDialogState();
}

class _PurchaseItemMobileDialogState extends State<_PurchaseItemMobileDialog> {
  late TextEditingController _batchCtrl;
  late TextEditingController _qtyCtrl;
  late TextEditingController _freeQtyCtrl;
  late TextEditingController _buyCtrl;
  late TextEditingController _sellCtrl;
  late TextEditingController _disc1Ctrl;
  late TextEditingController _disc2Ctrl;
  late TextEditingController _disc3Ctrl;
  late TextEditingController _taxCtrl;

  late DateTime? _expirationDate;
  late PurchaseItemState _previewItem;

  final _currency = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');

  @override
  void initState() {
    super.initState();
    final i = widget.initialItem;
    _batchCtrl = TextEditingController(text: i.batchNo);
    // Miktar alanları UI'da integer görünsün (1 yerine 1.0 gösterme)
    _qtyCtrl = TextEditingController(text: i.quantity.toStringAsFixed(0));
    _freeQtyCtrl =
        TextEditingController(text: i.freeQuantity.toStringAsFixed(0));
    _buyCtrl = TextEditingController(text: i.unitPrice.toString());
    _sellCtrl = TextEditingController(text: i.sellingPrice.toString());
    _disc1Ctrl = TextEditingController(text: i.discount1.toString());
    _disc2Ctrl = TextEditingController(text: i.discount2.toString());
    _disc3Ctrl = TextEditingController(text: i.discount3.toString());
    _taxCtrl = TextEditingController(text: i.taxRate.toString());
    _expirationDate = i.expirationDate;
    _previewItem = i;
  }

  @override
  void dispose() {
    _batchCtrl.dispose();
    _qtyCtrl.dispose();
    _freeQtyCtrl.dispose();
    _buyCtrl.dispose();
    _sellCtrl.dispose();
    _disc1Ctrl.dispose();
    _disc2Ctrl.dispose();
    _disc3Ctrl.dispose();
    _taxCtrl.dispose();
    super.dispose();
  }

  void _rebuildPreview() {
    final i = widget.initialItem;
    setState(() {
      _previewItem = i.copyWith(
        batchNo: _batchCtrl.text,
        quantity: double.tryParse(_qtyCtrl.text) ?? 0,
        freeQuantity: double.tryParse(_freeQtyCtrl.text) ?? 0,
        unitPrice: double.tryParse(_buyCtrl.text) ?? 0,
        sellingPrice: double.tryParse(_sellCtrl.text) ?? 0,
        discount1: double.tryParse(_disc1Ctrl.text) ?? 0,
        discount2: double.tryParse(_disc2Ctrl.text) ?? 0,
        discount3: double.tryParse(_disc3Ctrl.text) ?? 0,
        taxRate: double.tryParse(_taxCtrl.text) ?? 0,
      ).copyWith(expirationDate: _expirationDate);
    });
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _expirationDate ?? now,
      firstDate: now,
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
    _freeQtyCtrl.text = '0';
    _buyCtrl.text = i.unitPrice.toString();
    _sellCtrl.text = i.sellingPrice.toString();
    _disc1Ctrl.text = '0';
    _disc2Ctrl.text = '0';
    _disc3Ctrl.text = '0';
    _taxCtrl.text = i.taxRate.toString();
    _expirationDate = i.expirationDate;
    _rebuildPreview();
  }

  @override
  Widget build(BuildContext context) {
    final i = widget.initialItem;
    final dateStr = _expirationDate != null
        ? DateFormat('dd.MM.yyyy').format(_expirationDate!)
        : 'SKT Seç';

    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      contentPadding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Başlık çubuğu
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
                    // Ürün bilgisi
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

                    // Parti + SKT
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

                    // Miktar & Mal Fazlası
                    _buildCard(
                      children: [
                        const Text(
                          "Miktar & Mal Fazlası",
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
                                controller: _qtyCtrl,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: "Miktar",
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: (_) => _rebuildPreview(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                controller: _freeQtyCtrl,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: "Mal Fazlası",
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

                    // Alış & Satış fiyatı
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

                    // İskontolar
                    _buildCard(
                      children: [
                        const Text(
                          "İskontolar (%)",
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
                                controller: _disc1Ctrl,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: "İsk1%",
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: (_) => _rebuildPreview(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                controller: _disc2Ctrl,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: "İsk2%",
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: (_) => _rebuildPreview(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                controller: _disc3Ctrl,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: "İsk3%",
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

                    // KDV
                    _buildCard(
                      children: [
                        const Text(
                          "KDV",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _taxCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: "KDV (%)",
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (_) => _rebuildPreview(),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Net Toplam
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
                            "Net Toplam",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _currency.format(_previewItem.lineTotal),
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

            // Alt butonlar
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(
                children: [
                  IconButton(
                    tooltip: "Satırı Sil",
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => Navigator.of(context).pop(_DialogResult(
                          delete: true,
                          item: _previewItem,
                        )),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: _resetFields,
                    child: const Text("Temizle"),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(_DialogResult(
                        delete: false,
                        item: _previewItem,
                      ));
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

class _DialogResult {
  final bool delete;
  final PurchaseItemState item;

  _DialogResult({required this.delete, required this.item});
}

