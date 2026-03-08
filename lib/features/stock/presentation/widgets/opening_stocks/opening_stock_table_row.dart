import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile/core/services/item_zone_table_view.dart';
import 'package:mobile/core/utils/image_utils.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mobile/features/stock/domain/entities/opening_stock_item_entity.dart';
import 'package:mobile/features/stock/presentation/providers/opening_stock_items_provider.dart';

/// Optimized row component with fixed height (60px) to avoid layout calculations
class OpeningStockTableRow extends ConsumerWidget {
  final int rowIndex;
  final OpeningStockItemEntity item;
  final Function(OpeningStockItemEntity) onChanged;
  final VoidCallback onDelete;
  final DateTime? expirationDate;
  final Function(DateTime) onDateChanged;

  static const double rowHeight = 64.0;

  const OpeningStockTableRow({
    super.key,
    required this.rowIndex,
    required this.item,
    required this.onChanged,
    required this.onDelete,
    required this.expirationDate,
    required this.onDateChanged,
  });

  void _updateItem(WidgetRef ref) {
    final rowData = ref
        .read(openingStockItemsProvider.notifier)
        .parseRowData(rowIndex);

    final updated = item.copyWith(
      batchNo: rowData['batchNo'],
      quantity: rowData['quantity'],
      buyingPrice: rowData['buyingPrice'],
      sellingPrice: rowData['sellingPrice'],
      vatRate: rowData['vatRate'],
      location: rowData['location'],
    );

    onChanged(updated);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctrls = ref
        .read(openingStockItemsProvider.notifier)
        .getRowControllers(rowIndex, item);

    final bgColor =
        rowIndex % 2 == 0 ? Colors.white : Color.fromARGB(40, 250, 250, 250);

    final dateStr = DateFormat(
      'dd.MM.yyyy',
    ).format(expirationDate ?? item.expirationDate);

    return Container(
      height: rowHeight,
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Photo
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
                    item.imageUrl != null
                        ? ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: CachedNetworkImage(
                            imageUrl: item.imageUrl!,
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

          // Product Name
          _buildCell(
            width: 190,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 8.0,
                horizontal: 4.0,
              ),
              child: Text(
                item.productName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),

          // Batch No
          _buildCell(
            width: 120,
            child: Center(
              child: _buildCompactInput(
                ctrls.batchCtrl,
                'Parti',
                onChanged: (_) => _updateItem(ref),
              ),
            ),
          ),

          // Expiration Date (SKT)
          _buildCell(
            width: 120,
            child: Center(
              child: _buildDateSelector(context, dateStr, () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: expirationDate ?? item.expirationDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 3650)),
                );
                if (date != null) onDateChanged(date);
              }),
            ),
          ),

          // Quantity
          _buildCell(
            width: 70,
            child: Center(
              child: _buildCompactInput(
                ctrls.qtyCtrl,
                'Adet',
                onChanged: (_) => _updateItem(ref),
                keyboardType: TextInputType.number,
              ),
            ),
          ),

          // Buying Price
          _buildCell(
            width: 90,
            child: Center(
              child: _buildCompactInput(
                ctrls.priceCtrl,
                '₺',
                onChanged: (_) => _updateItem(ref),
                keyboardType: TextInputType.number,
              ),
            ),
          ),

          // Selling Price
          _buildCell(
            width: 90,
            child: Center(
              child: _buildCompactInput(
                ctrls.sellPriceCtrl,
                '₺',
                onChanged: (_) => _updateItem(ref),
                keyboardType: TextInputType.number,
              ),
            ),
          ),

          // VAT Rate
          _buildCell(
            width: 70,
            child: Center(
              child: _buildCompactInput(
                ctrls.vatCtrl,
                '%',
                onChanged: (_) => _updateItem(ref),
                keyboardType: TextInputType.number,
              ),
            ),
          ),

          // Location
          _buildCell(
            width: 90,
            child: Center(
              child: _buildCompactInput(
                ctrls.locationCtrl,
                'Konum',
                onChanged: (_) => _updateItem(ref),
              ),
            ),
          ),

          // Delete Button
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
                onPressed: () {
                  ref
                      .read(openingStockItemsProvider.notifier)
                      .removeRowControllers(rowIndex);
                  onDelete();
                },
                tooltip: 'Satırı Sil',
              ),
            ),
          ),
        ],
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
    TextEditingController controller,
    String hint, {
    required Function(String) onChanged,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return CompactInput(
      controller: controller,
      hint: hint,
      onChanged: onChanged,
      keyboardType: keyboardType,
    );
  }

  Widget _buildDateSelector(
    BuildContext context,
    String dateStr,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
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
