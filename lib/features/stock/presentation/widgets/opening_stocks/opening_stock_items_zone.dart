import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile/core/theme/app_colors.dart';

import 'package:mobile/core/utils/image_utils.dart';
import 'package:mobile/core/services/item_zone_table_view.dart';
import 'package:mobile/features/stock/domain/entities/opening_stock_item_entity.dart';
import '../../../../products/presentation/providers/product_provider.dart';
import '../../../../products/presentation/providers/product_controller.dart';
import '../../providers/opening_stock_provider.dart';
import 'package:mobile/core/services/product_search_service.dart';

class OpeningStockItemsZone extends ConsumerStatefulWidget {
  const OpeningStockItemsZone({super.key});

  @override
  ConsumerState<OpeningStockItemsZone> createState() =>
      _OpeningStockItemsZoneState();
}

class _OpeningStockItemsZoneState extends ConsumerState<OpeningStockItemsZone> {
  TextEditingController? _searchController;
  bool _isSearching = false;

  Future<List<Map<String, dynamic>>> _searchCombinedProducts(
    String query,
    List<dynamic> localProducts,
  ) async {
    if (query.trim().isEmpty) return [];

    setState(() => _isSearching = true);

    // 1️⃣ LOCAL MATCHES
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
              },
            )
            .toList();

    // LOCAL NAME SET (NORMALIZED)
    final localNameSet =
        localProducts.map((p) => p.name.toLowerCase().trim()).toSet();

    // 2️⃣ GLOBAL (VETILAC) SEARCH
    final vetilacController = ref.read(productControllerProvider);
    final vetilacRes = await vetilacController.searchVetilac(query);

    final vetilacMatches =
        vetilacRes
            .where((v) {
              final globalName = v['raw_name'].toString().toLowerCase().trim();
              final existsLocally = localNameSet.contains(globalName);
              return !existsLocally;
            })
            .map((v) {
              return {
                'id': v['id'],
                'name': v['raw_name'],
                'image_url': ImageUtils.getImageUrl(
                  v['image_path'],
                  v['full_image_url'],
                ),
                'source': 'global',
              };
            })
            .toList();

    setState(() => _isSearching = false);

    return [...localMatches, ...vetilacMatches];
  }

  @override
  Widget build(BuildContext context) {
    final openingState = ref.watch(openingStockProvider);
    final openingNotifier = ref.read(openingStockProvider.notifier);

    final productListState = ref.watch(productListProvider);
    final localProducts = productListState.value ?? [];

    return Card(
      elevation: 0,
      color: Colors.blue.shade100.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.black12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Ürünler",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: Autocomplete<Map<String, dynamic>>(
                    optionsBuilder: (textEditingValue) {
                      return _searchCombinedProducts(
                        textEditingValue.text,
                        localProducts,
                      );
                    },
                    displayStringForOption: (option) => option['name'] ?? '',
                    onSelected: (selection) {
                      final alreadyExists = openingState.items.any(
                        (item) =>
                            item.productId.toString() ==
                            selection['id'].toString(),
                      );
                      if (alreadyExists) return;

                      print("DEBUG: Creating new item with selection:");
                      print(
                        "  - id: ${selection['id']} (type: ${selection['id'].runtimeType})",
                      );
                      print(
                        "  - name: ${selection['name']} (type: ${selection['name'].runtimeType})",
                      );
                      print(
                        "  - source: ${selection['source']} (type: ${selection['source'].runtimeType})",
                      );

                      final newItem = OpeningStockItemEntity(
                        productId: selection['id'].toString(),
                        productName: selection['name'] ?? '',
                        imageUrl: selection['image_url'],
                        productSource: selection['source'] ?? 'local',
                        quantity: 1.0,
                        expirationDate: DateTime.now(),
                        batchNo: '',
                        location: '',
                        buyingPrice: 0.0,
                        sellingPrice: 0.0,
                        vatRate: 0,
                      );

                      print("DEBUG: New item created successfully");
                      openingNotifier.addItem(newItem);
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
                          labelText: "Barkod okutun veya ürün adı...",
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon:
                              _isSearching
                                  ? const Padding(
                                    padding: EdgeInsets.all(12),
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : null,
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
                            width: 600,
                            constraints: const BoxConstraints(maxHeight: 350),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: ListView.separated(
                              padding: EdgeInsets.zero,
                              itemCount: options.length,
                              separatorBuilder:
                                  (c, i) =>
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
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                    child:
                                        imgUrl != null
                                            ? ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              child: CachedNetworkImage(
                                                imageUrl: imgUrl,
                                                fit: BoxFit.cover,
                                                placeholder:
                                                    (c, u) => const Icon(
                                                      Icons.image,
                                                      size: 20,
                                                      color: Colors.grey,
                                                    ),
                                                errorWidget:
                                                    (c, u, e) => const Icon(
                                                      Icons.broken_image,
                                                      size: 20,
                                                      color: Colors.grey,
                                                    ),
                                              ),
                                            )
                                            : const Icon(
                                              Icons.medication,
                                              color: Colors.grey,
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
                                        color:
                                            isLocal
                                                ? Colors.green
                                                : Colors.blue,
                                      ),
                                    ],
                                  ),
                                  subtitle: Text(
                                    isLocal
                                        ? "Klinikte Kayıtlı"
                                        : "Vetilac'tan Bulundu",
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
                ),
              ],
            ),

            const SizedBox(height: 24),

            if (openingState.items.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
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
                      "Henüz ürün eklenmedi.",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: 1100,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(11),
                            ),
                            border: Border(
                              bottom: BorderSide(color: Colors.grey.shade300),
                            ),
                          ),
                          child: const Row(
                            children: [
                              _HeaderCell("Fotoğraf", width: 70),
                              _HeaderCell("Ürün Adı", width: 190),
                              _HeaderCell("Parti No", width: 120),
                              _HeaderCell("SKT", width: 120),
                              _HeaderCell("Adet", width: 70),
                              _HeaderCell("Alış Fiyatı (₺)", width: 90),
                              _HeaderCell("Satış Fiyatı (₺)", width: 90),
                              _HeaderCell("KDV (%)", width: 70),
                              _HeaderCell("Konum", width: 90),
                              _HeaderCell("", width: 50),
                            ],
                          ),
                        ),
                        ...openingState.items.asMap().entries.map((entry) {
                          final index = entry.key;
                          final item = entry.value;
                          return _OpeningRow(
                            key: ValueKey(item.productId + index.toString()),
                            item: item,
                            index: index,
                            onChanged:
                                (updated) =>
                                    openingNotifier.updateItem(index, updated),
                            onDelete: () => openingNotifier.removeItem(index),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String title;
  final double width;
  final TextAlign align;
  final Color? color;

  const _HeaderCell(
    this.title, {
    required this.width,
    this.align = TextAlign.center,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return HeaderCell(title, width: width, align: align, color: color);
  }
}

class _OpeningRow extends StatefulWidget {
  final OpeningStockItemEntity item;
  final int index;
  final Function(OpeningStockItemEntity) onChanged;
  final VoidCallback onDelete;

  const _OpeningRow({
    super.key,
    required this.item,
    required this.index,
    required this.onChanged,
    required this.onDelete,
  });

  @override
  State<_OpeningRow> createState() => _OpeningRowState();
}

class _OpeningRowState extends State<_OpeningRow> {
  late TextEditingController _batchCtrl;
  late TextEditingController _qtyCtrl;
  late TextEditingController _priceCtrl;
  late TextEditingController _sellPriceCtrl;
  late TextEditingController _vatCtrl;
  late TextEditingController _locationCtrl;

  @override
  void initState() {
    super.initState();
    _batchCtrl = TextEditingController(text: widget.item.batchNo);
    _qtyCtrl = TextEditingController(text: widget.item.quantity.toString());
    _priceCtrl = TextEditingController(
      text: widget.item.buyingPrice.toString(),
    );
    _sellPriceCtrl = TextEditingController(
      text: widget.item.sellingPrice.toString(),
    );
    _vatCtrl = TextEditingController(text: widget.item.vatRate.toString());
    _locationCtrl = TextEditingController(text: widget.item.location ?? '');
  }

  void _updateItem() {
    print("DEBUG _updateItem: Current values");
    print("  - batchNo: ${_batchCtrl.text}");
    print(
      "  - quantity: ${_qtyCtrl.text} -> ${double.tryParse(_qtyCtrl.text) ?? 0}",
    );
    print(
      "  - buyingPrice: ${_priceCtrl.text} -> ${double.tryParse(_priceCtrl.text) ?? 0}",
    );
    print(
      "  - sellingPrice: ${_sellPriceCtrl.text} -> ${double.tryParse(_sellPriceCtrl.text) ?? 0}",
    );
    print(
      "  - vatRate (raw): ${_vatCtrl.text} (type: ${_vatCtrl.text.runtimeType})",
    );
    final parsedVat = int.tryParse(_vatCtrl.text) ?? 0;
    print("  - vatRate (parsed): $parsedVat (type: ${parsedVat.runtimeType})");
    print("  - location: ${_locationCtrl.text}");

    final updated = widget.item.copyWith(
      batchNo: _batchCtrl.text,
      quantity: double.tryParse(_qtyCtrl.text) ?? 0.0,
      buyingPrice: double.tryParse(_priceCtrl.text) ?? 0.0,
      sellingPrice: double.tryParse(_sellPriceCtrl.text) ?? 0.0,
      vatRate: parsedVat,
      location: _locationCtrl.text,
    );
    print("DEBUG: Item updated successfully");
    widget.onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    final bgColor =
        widget.index % 2 == 0
            ? Colors.white
            : Color.fromARGB(40, 250, 250, 250);
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildCell(
              width: 70,
              child: Center(
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child:
                      widget.item.imageUrl != null
                          ? ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: CachedNetworkImage(
                              imageUrl: widget.item.imageUrl!,
                              fit: BoxFit.cover,
                              placeholder:
                                  (c, u) => const Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                              errorWidget:
                                  (c, u, e) => const Icon(
                                    Icons.broken_image,
                                    size: 16,
                                    color: Colors.grey,
                                  ),
                            ),
                          )
                          : const Icon(
                            Icons.medication,
                            size: 20,
                            color: Colors.grey,
                          ),
                ),
              ),
            ),
            _buildCell(
              width: 190,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 8.0,
                  horizontal: 4.0,
                ),
                child: Text(
                  widget.item.productName,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            _buildCell(
              width: 120,
              child: Center(child: _buildCompactInput(_batchCtrl, "Parti")),
            ),
            _buildCell(
              width: 120,
              child: Center(child: _buildDateSelector(context)),
            ),
            _buildCell(
              width: 70,
              child: Center(child: _buildCompactInput(_qtyCtrl, "Adet")),
            ),
            _buildCell(
              width: 90,
              child: Center(child: _buildCompactInput(_priceCtrl, "₺")),
            ),
            _buildCell(
              width: 90,
              child: Center(child: _buildCompactInput(_sellPriceCtrl, "₺")),
            ),
            _buildCell(
              width: 70,
              child: Center(child: _buildCompactInput(_vatCtrl, "%")),
            ),
            _buildCell(
              width: 90,
              child: Center(child: _buildCompactInput(_locationCtrl, "")),
            ),
            _buildCell(
              width: 50,
              showBorder: false,
              child: Center(
                child: IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                    size: 20,
                  ),
                  onPressed: widget.onDelete,
                  tooltip: "Satırı Sil",
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCell({
    required double width,
    required Widget child,
    bool showBorder = true,
  }) {
    return ItemTableCell(width: width, child: child, showBorder: showBorder);
  }

  Widget _buildCompactInput(
    TextEditingController ctrl,
    String hint, {
    bool isHighlight = false,
  }) {
    return CompactInput(
      controller: ctrl,
      hint: hint,
      onChanged: (_) => _updateItem(),
      highlight: isHighlight,
    );
  }

  Widget _buildDateSelector(BuildContext context) {
    final dateStr = DateFormat('dd.MM.yyyy').format(widget.item.expirationDate);
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: widget.item.expirationDate,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 3650)),
        );
        if (date != null)
          widget.onChanged(widget.item.copyWith(expirationDate: date));
      },
      child: Container(
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          dateStr,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }
}
