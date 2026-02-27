import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../products/presentation/providers/product_controller.dart';
import '../../../../products/presentation/providers/product_provider.dart';
import '../../providers/purchase_form_provider.dart';

class PurchaseItemsZone extends ConsumerStatefulWidget {
  const PurchaseItemsZone({super.key});

  @override
  ConsumerState<PurchaseItemsZone> createState() => _PurchaseItemsZoneState();
}

class _PurchaseItemsZoneState extends ConsumerState<PurchaseItemsZone> {
  TextEditingController? _searchController;
  bool _isSearching = false;

  // 🔥 HEM YEREL HEM VETILAC ARAMASI
  Future<List<Map<String, dynamic>>> _searchCombinedProducts(
    String query,
  ) async {
    if (query.isEmpty) return [];
    setState(() => _isSearching = true);

    // 1. Yerel Ürünler (Riverpod State'den)
    final localProducts = ref.read(productListProvider).value ?? [];
    final localMatches =
        localProducts
            .where(
              (p) =>
                  p.name.toLowerCase().contains(query.toLowerCase()) ||
                  (p.barcode?.contains(query) ?? false),
            )
            .map(
              (p) => {
                'id': p.id,
                'name': p.name,
                'buy_price': p.buyingPrice,
                'sell_price': p.sellingPrice,
                'tax_rate': p.vatRate,
                'source': 'local',
              },
            )
            .toList();

    // 2. Vetilac Ürünleri (API'den)
    final vetilacController = ref.read(productControllerProvider);
    final vetilacRes = await vetilacController.searchVetilac(query);
    final vetilacMatches =
        vetilacRes
            .map(
              (v) => {
                'id': v['id'],
                'name': v['raw_name'],
                'buy_price': 0.0,
                'sell_price': 0.0, // Yeni ekleneceği için satış fiyatı belirsiz
                'tax_rate': 20.0, // Varsayılan
                'source': 'global',
              },
            )
            .toList();

    setState(() => _isSearching = false);
    return [...localMatches, ...vetilacMatches];
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(purchaseFormProvider);
    final notifier = ref.read(purchaseFormProvider.notifier);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Fatura Kalemleri",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // ÜRÜN ARAMA KUTUSU
            Autocomplete<Map<String, dynamic>>(
              optionsBuilder:
                  (textEditingValue) =>
                      _searchCombinedProducts(textEditingValue.text),
              displayStringForOption: (option) => option['name'],
              onSelected: (selection) {
                // Tabloya Ekle (Source ve Sell Price ile beraber)
                notifier.addItem(
                  selection['id'],
                  selection['name'],
                  selection['buy_price'],
                  selection['sell_price'],
                  selection['tax_rate'],
                  selection['source'],
                );
                _searchController?.clear();
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
                    suffixIcon:
                        _isSearching
                            ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : null,
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
                    elevation: 4,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 600,
                      constraints: const BoxConstraints(maxHeight: 300),
                      child: ListView.separated(
                        padding: EdgeInsets.zero,
                        itemCount: options.length,
                        separatorBuilder: (c, i) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final option = options.elementAt(index);
                          final isLocal = option['source'] == 'local';
                          return ListTile(
                            leading: Icon(
                              isLocal ? Icons.verified : Icons.cloud_download,
                              color:
                                  isLocal
                                      ? AppColors.success
                                      : AppColors.primary,
                            ),
                            title: Text(
                              option['name'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              isLocal
                                  ? "Klinikte Kayıtlı"
                                  : "Vetilac'tan Bulundu (Seçince Kaydedilir)",
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

            const SizedBox(height: 24),

            // DİNAMİK TABLO
            if (state.items.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Column(
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 48,
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
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width:
                      1500, // Genişliği artırdık çünkü Satış Fiyatı kolonu geldi
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12),
                          ),
                        ),
                        child: const Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text(
                                "Ürün Adı",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                "Parti No",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                "SKT",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                "Miktar",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                "Bedava",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                "Birim Fiyat",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                "Satış F.",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepOrange,
                                ),
                              ),
                            ), // 🔥 YENİ
                            Expanded(
                              flex: 1,
                              child: Text(
                                "İsk 1",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                "İsk 2",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                "İsk 3",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                "KDV",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                "Net Toplam",
                                style: TextStyle(fontWeight: FontWeight.bold),
                                textAlign: TextAlign.right,
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text("", textAlign: TextAlign.center),
                            ),
                          ],
                        ),
                      ),
                      ...state.items
                          .map(
                            (item) => _PurchaseItemRow(
                              key: ValueKey(item.uiId),
                              item: item,
                              onChanged:
                                  (updatedItem) => notifier.updateItem(
                                    item.uiId,
                                    updatedItem,
                                  ),
                              onDelete: () => notifier.removeItem(item.uiId),
                            ),
                          )
                          .toList(),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PurchaseItemRow extends StatefulWidget {
  final PurchaseItemState item;
  final Function(PurchaseItemState) onChanged;
  final VoidCallback onDelete;

  const _PurchaseItemRow({
    super.key,
    required this.item,
    required this.onChanged,
    required this.onDelete,
  });

  @override
  State<_PurchaseItemRow> createState() => _PurchaseItemRowState();
}

class _PurchaseItemRowState extends State<_PurchaseItemRow> {
  late TextEditingController _batchCtrl;
  late TextEditingController _qtyCtrl;
  late TextEditingController _freeQtyCtrl;
  late TextEditingController _priceCtrl;
  late TextEditingController _sellPriceCtrl; // 🔥 YENİ
  late TextEditingController _disc1Ctrl;
  late TextEditingController _disc2Ctrl;
  late TextEditingController _disc3Ctrl;
  late TextEditingController _taxCtrl;

  @override
  void initState() {
    super.initState();
    _batchCtrl = TextEditingController(text: widget.item.batchNo);
    _qtyCtrl = TextEditingController(text: widget.item.quantity.toString());
    _freeQtyCtrl = TextEditingController(
      text: widget.item.freeQuantity.toString(),
    );
    _priceCtrl = TextEditingController(text: widget.item.unitPrice.toString());
    _sellPriceCtrl = TextEditingController(
      text: widget.item.sellingPrice.toString(),
    ); // 🔥 YENİ
    _disc1Ctrl = TextEditingController(text: widget.item.discount1.toString());
    _disc2Ctrl = TextEditingController(text: widget.item.discount2.toString());
    _disc3Ctrl = TextEditingController(text: widget.item.discount3.toString());
    _taxCtrl = TextEditingController(text: widget.item.taxRate.toString());
  }

  void _updateItem() {
    final updated = widget.item.copyWith(
      batchNo: _batchCtrl.text,
      quantity: double.tryParse(_qtyCtrl.text) ?? 0,
      freeQuantity: double.tryParse(_freeQtyCtrl.text) ?? 0,
      unitPrice: double.tryParse(_priceCtrl.text) ?? 0,
      sellingPrice: double.tryParse(_sellPriceCtrl.text) ?? 0, // 🔥 YENİ
      discount1: double.tryParse(_disc1Ctrl.text) ?? 0,
      discount2: double.tryParse(_disc2Ctrl.text) ?? 0,
      discount3: double.tryParse(_disc3Ctrl.text) ?? 0,
      taxRate: double.tryParse(_taxCtrl.text) ?? 0,
    );
    widget.onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              widget.item.productName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(flex: 2, child: _buildInput(_batchCtrl, "Parti")),
          Expanded(flex: 2, child: _buildDateSelector(context)),
          Expanded(flex: 1, child: _buildInput(_qtyCtrl, "Adet")),
          Expanded(flex: 1, child: _buildInput(_freeQtyCtrl, "Bedava")),
          Expanded(flex: 2, child: _buildInput(_priceCtrl, "Fiyat")),
          Expanded(
            flex: 2,
            child: _buildInput(_sellPriceCtrl, "Satış", isHighlight: true),
          ), // 🔥 YENİ
          Expanded(flex: 1, child: _buildInput(_disc1Ctrl, "%")),
          Expanded(flex: 1, child: _buildInput(_disc2Ctrl, "%")),
          Expanded(flex: 1, child: _buildInput(_disc3Ctrl, "%")),
          Expanded(flex: 1, child: _buildInput(_taxCtrl, "%")),
          Expanded(
            flex: 2,
            child: Text(
              "₺${widget.item.lineTotal.toStringAsFixed(2)}",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          Expanded(
            flex: 1,
            child: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: widget.onDelete,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInput(
    TextEditingController ctrl,
    String hint, {
    bool isHighlight = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: TextFormField(
        controller: ctrl,
        onChanged: (v) => _updateItem(),
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        style: TextStyle(
          color: isHighlight ? Colors.deepOrange : Colors.black,
          fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
        ),
        decoration: InputDecoration(
          hintText: hint,
          isDense: true,
          contentPadding: const EdgeInsets.all(8),
          border: OutlineInputBorder(
            borderSide:
                isHighlight
                    ? const BorderSide(color: Colors.deepOrange)
                    : const BorderSide(color: Colors.grey),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide:
                isHighlight
                    ? const BorderSide(color: Colors.deepOrange, width: 2)
                    : const BorderSide(color: AppColors.primary, width: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildDateSelector(BuildContext context) {
    final dateStr =
        widget.item.expirationDate != null
            ? DateFormat('dd.MM.yyyy').format(widget.item.expirationDate!)
            : "Seç";
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: InkWell(
        onTap: () async {
          final date = await showDatePicker(
            context: context,
            initialDate: DateTime.now().add(const Duration(days: 365)),
            firstDate: DateTime.now(),
            lastDate: DateTime.now().add(const Duration(days: 3650)),
          );
          if (date != null)
            widget.onChanged(widget.item.copyWith(expirationDate: date));
        },
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            dateStr,
            textAlign: TextAlign.center,
            style: TextStyle(
              color:
                  widget.item.expirationDate == null
                      ? Colors.red
                      : Colors.black,
            ),
          ),
        ),
      ),
    );
  }
}
