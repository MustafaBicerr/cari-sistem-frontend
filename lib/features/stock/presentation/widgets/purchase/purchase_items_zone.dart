import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile/core/utils/image_utils.dart';
import '../../../../../core/constants/api_constants.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../products/domain/models/product.dart';
import '../../../../products/presentation/providers/product_controller.dart';
import '../../../../products/presentation/providers/product_provider.dart';
import '../../../../products/presentation/widgets/product_form_dialog.dart';
import '../../providers/purchase_form_provider.dart';
import 'purchase_table_row.dart';

class PurchaseItemsZone extends ConsumerStatefulWidget {
  const PurchaseItemsZone({super.key});

  @override
  ConsumerState<PurchaseItemsZone> createState() => _PurchaseItemsZoneState();
}

class _PurchaseItemsZoneState extends ConsumerState<PurchaseItemsZone> {
  TextEditingController? _searchController;
  bool _isSearching = false;

  // // ----------------------------------------------------------
  // // IMAGE URL BUILDER
  // // ----------------------------------------------------------
  // String? _getImageUrl(String? path, String? fullUrl) {
  //   if (fullUrl != null && fullUrl.isNotEmpty) return fullUrl;
  //   if (path != null && path.isNotEmpty) {
  //     if (path.startsWith('http')) return path;
  //     final baseUrl = ApiConstants.baseUrl.replaceAll('/api', '');
  //     final normalizedPath = path.startsWith('/') ? path : '/$path';
  //     return '$baseUrl$normalizedPath';
  //   }
  //   return null;
  // }

  // ----------------------------------------------------------
  // COMBINED SEARCH (LOCAL + GLOBAL)
  // ----------------------------------------------------------
  Future<List<Map<String, dynamic>>> _searchCombinedProducts(
    String query,
    List<Product> localProducts,
  ) async {
    // print("=====================================");
    // print("🔍 SEARCH QUERY: $query");
    // print("LOCAL PRODUCTS COUNT: ${localProducts.length}");
    // print("=====================================");

    if (query.isEmpty) return [];

    setState(() => _isSearching = true);

    // ------------------------------------------------------
    // 1️⃣ LOCAL MATCHES
    // ------------------------------------------------------
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

    // print("🟢 LOCAL MATCHES (${localMatches.length})");
    // for (var p in localMatches) {
    //   print(
    //     "   → ${p['id']} | ${p['name']} | Buy:${p['buy_price']} | Sell:${p['sell_price']}",
    //   );
    // }

    // final localIds = localMatches.map((p) => p['id'].toString()).toSet();
    // ------------------------------------------------------
    // LOCAL NAME SET (NORMALIZED)
    // ------------------------------------------------------
    final localNameSet =
        localProducts.map((p) => p.name.toLowerCase().trim()).toSet();

    print("🧠 LOCAL NAME SET:");
    for (var name in localNameSet) {
      print("   → $name");
    }

    // ------------------------------------------------------
    // 2️⃣ GLOBAL (REFERANS KATALOĞU) ARAMA
    // ------------------------------------------------------
    final productController = ref.read(productControllerProvider);
    final masterDrugsRes = await productController.searchMasterDrugs(query);

    print("☁️ GLOBAL RAW RESULT (${masterDrugsRes.length})");

    final masterDrugsMatches =
        masterDrugsRes
            .where((v) {
              final globalName =
                  (v['name'] ?? '').toString().toLowerCase().trim();

              final existsLocally = localNameSet.contains(globalName);

              print("🔎 GLOBAL CHECK BY NAME:");
              print("   Global Name: $globalName");
              print("   Exists Local: $existsLocally");

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

  @override
  Widget build(BuildContext context) {
    final purchaseState = ref.watch(purchaseFormProvider);
    final purchaseNotifier = ref.read(purchaseFormProvider.notifier);

    // ----------------------------------------------------------
    // PRODUCT LIST PROVIDER (SADECE BUILD İÇİNDE WATCH)
    // ----------------------------------------------------------
    final productListState = ref.watch(productListProvider);

    print("=====================================");
    print("📦 BUILD → productListProvider");
    print("   isLoading: ${productListState.isLoading}");
    print("   hasValue: ${productListState.hasValue}");
    print("   hasError: ${productListState.hasError}");

    final localProducts = productListState.value ?? [];

    print("   TOTAL LOCAL PRODUCTS: ${localProducts.length}");
    for (var p in localProducts) {
      print("      → ${p.id} | ${p.name}");
    }
    print("=====================================");

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

            // ------------------------------------------------------
            // ÜRÜN ARAMA
            // ------------------------------------------------------
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
                    displayStringForOption: (option) => option['name'],
                    onSelected: (selection) {
                      final alreadyExists = purchaseState.items.any(
                        (item) =>
                            item.productId.toString() ==
                            selection['id'].toString(),
                      );

                      print("🧠 DUPLICATE CHECK: $alreadyExists");

                      if (alreadyExists) {
                        print("❌ Ürün zaten faturada mevcut!");
                        return;
                      }

                      print("=====================================");
                      print("🟡 PRODUCT SELECTED");
                      print("ID: ${selection['id']}");
                      print("Name: ${selection['name']}");
                      print("Source: ${selection['source']}");
                      print("Buy Price: ${selection['buy_price']}");
                      print("Sell Price: ${selection['sell_price']}");
                      print("Tax Rate: ${selection['tax_rate']}");
                      print("=====================================");

                      // purchaseNotifier.addItem(
                      //   selection['id'],
                      //   selection['name'],
                      //   selection['buy_price'],
                      //   selection['sell_price'],
                      //   selection['tax_rate'],
                      //   selection['source'],
                      //   selection['image_url'],
                      // );
                      Future.microtask(() {
                        purchaseNotifier.addItem(
                          selection['id'],
                          selection['name'],
                          selection['buy_price'],
                          selection['sell_price'],
                          selection['tax_rate'],
                          selection['source'],
                          selection['image_url'],
                        );
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
                          labelText: "Barkod okutun veya Ürün Adı yazın...",
                          prefixIcon: const Icon(
                            Icons.search,
                            color: AppColors.primary,
                          ),
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
                                final isLocal = option['source'] == 'local';
                                final imgUrl = option['image_url'];

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
                                        color:
                                            isLocal
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
                ),
                const SizedBox(width: 16),

                // ------------------------------------------------------
                // YENİ ÜRÜN BUTONU
                // ------------------------------------------------------
                SizedBox(
                  height: 55,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await showDialog(
                        context: context,
                        builder: (context) => const ProductFormDialog(),
                      );
                      ref.invalidate(productListProvider);
                    },
                    icon: const Icon(Icons.add_box),
                    label: const Text("Yeni İlaç Tanımla"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ------------------------------------------------------
            // TABLO (DEĞİŞMEDİ)
            // ------------------------------------------------------
            if (purchaseState.items.isEmpty)
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
                      "Faturaya henüz ürün eklenmedi.",
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
                    width: 1050,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
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
                              _HeaderCell("Parti\nSKT", width: 120),
                              _HeaderCell("Miktar", width: 70),
                              _HeaderCell("Mal Fazlası", width: 70),
                              _HeaderCell("Alış Fiyatı (₺)", width: 90),
                              _HeaderCell(
                                "Satış Fiyatı (₺)",
                                width: 90,
                                color: Colors.deepOrange,
                              ),
                              _HeaderCell(
                                "İskontolar (%) (1, 2, 3)",
                                width: 90,
                              ),
                              _HeaderCell("KDV (%)", width: 70),
                              _HeaderCell(
                                "Net Toplam",
                                width: 110,
                                align: TextAlign.right,
                              ),
                              _HeaderCell("", width: 50),
                            ],
                          ),
                        ),
                        Container(
                          height: 600,
                          child:
                              purchaseState.items.isEmpty
                                  ? Center(
                                    child: Text(
                                      'Ürün eklemek için yukarıdan ara ve seçin',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  )
                                  : ListView.builder(
                                    itemCount: purchaseState.items.length,
                                    itemBuilder: (context, index) {
                                      final item = purchaseState.items[index];
                                      return PurchaseTableRow(
                                        key: ValueKey(item.uiId),
                                        item: item,
                                        onChanged:
                                            (updatedItem) =>
                                                purchaseNotifier.updateItem(
                                                  item.uiId,
                                                  updatedItem,
                                                ),
                                        onDelete:
                                            () => purchaseNotifier.removeItem(
                                              item.uiId,
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

// BAŞLIK HÜCRESİ WIDGET'I
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
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        border: Border(right: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Text(
        title,
        textAlign: TextAlign.left,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13,
          color: color ?? Colors.black87,
        ),
      ),
    );
  }
}
