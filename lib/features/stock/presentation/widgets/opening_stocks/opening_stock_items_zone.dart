import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mobile/core/services/item_zone_table_view.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/core/utils/image_utils.dart';
import 'package:mobile/features/stock/domain/entities/opening_stock_item_entity.dart';
import 'package:mobile/shared/widgets/barcode_scanner_sheet.dart';
import '../../../../products/presentation/providers/product_provider.dart';
import '../../../../products/presentation/providers/product_controller.dart';
import '../../providers/opening_stock_provider.dart';
import 'opening_stock_table_row.dart';

class OpeningStockItemsZone extends ConsumerStatefulWidget {
  final void Function(String barcode)? onBarcodeScanned;

  const OpeningStockItemsZone({super.key, this.onBarcodeScanned});

  @override
  ConsumerState<OpeningStockItemsZone> createState() =>
      _OpeningStockItemsZoneState();
}

class _OpeningStockItemsZoneState extends ConsumerState<OpeningStockItemsZone> {
  TextEditingController? _searchController;
  bool _isSearching = false;
  Timer? _debounceTimer;
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _searchCombinedProducts(
    String query,
    List<dynamic> localProducts,
  ) async {
    if (query.trim().isEmpty) return [];

    setState(() => _isSearching = true);

    try {
      // LOCAL MATCHES
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

      // GLOBAL (REFERANS KATALOĞU) ARAMA
      final productController = ref.read(productControllerProvider);
      final masterDrugsRes = await productController.searchMasterDrugs(query);

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
                    v['image_path']?.toString(),
                    v['full_image_url']?.toString(),
                  ),
                  'source': 'global',
                };
              })
              .toList();

      return [...localMatches, ...masterDrugsMatches];
    } finally {
      setState(() => _isSearching = false);
    }
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

            // SEARCH BAR
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

                      // openingNotifier.addItem(newItem);
                      Future.microtask(() {
                        openingNotifier.addItem(newItem);
                      });
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
                                  : (widget.onBarcodeScanned != null
                                      ? IconButton(
                                          icon: const Icon(Icons.qr_code_scanner, color: AppColors.primary),
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
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ITEMS TABLE OR EMPTY STATE
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
                // Fixed height container with ListView.builder for virtual scrolling
                constraints: const BoxConstraints(maxHeight: 600),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: 1100,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // TABLE HEADER (2 satırlık başlıklar tam görünsün)
                        Container(
                          constraints: const BoxConstraints(minHeight: 56),
                          padding: const EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 4,
                          ),
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

                        // TABLE ROWS (Virtualized with ListView.builder)
                        Flexible(
                          child: ListView.builder(
                            controller: _scrollController,
                            shrinkWrap: true,
                            physics: const ClampingScrollPhysics(),
                            itemCount: openingState.items.length,
                            itemBuilder: (context, index) {
                              final item = openingState.items[index];

                              return OpeningStockTableRow(
                                key: ValueKey(
                                  item.productId,
                                ), // Only use productId as key
                                rowIndex: index,
                                item: item,
                                expirationDate: item.expirationDate,
                                onChanged:
                                    (updated) => openingNotifier.updateItem(
                                      index,
                                      updated,
                                    ),
                                onDelete:
                                    () => openingNotifier.removeItem(index),
                                onDateChanged:
                                    (date) => openingNotifier.updateItem(
                                      index,
                                      item.copyWith(expirationDate: date),
                                    ),
                              );
                            },
                          ),
                        ),
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
