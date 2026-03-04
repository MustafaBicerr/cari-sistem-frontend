import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/features/stock/presentation/providers/purchase_form_provider.dart';
import 'package:mobile/features/stock/presentation/providers/purchase_items_provider.dart';

/// Optimized row component with fixed height (100px) to avoid layout calculations
/// Designed for purchase items with complex discounts and calculations
class PurchaseTableRow extends ConsumerWidget {
  final PurchaseItemState item;
  final Function(PurchaseItemState) onChanged;
  final VoidCallback onDelete;

  // Fixed row height to avoid IntrinsicHeight calculations
  static const double rowHeight = 100.0;

  const PurchaseTableRow({
    super.key,
    required this.item,
    required this.onChanged,
    required this.onDelete,
  });

  void _updateItem(WidgetRef ref) {
    final rowData = ref
        .read(purchaseItemsProvider.notifier)
        .parseRowData(item.uiId);

    final updated = item.copyWith(
      batchNo: rowData['batchNo'],
      quantity: rowData['quantity'],
      freeQuantity: rowData['freeQuantity'],
      unitPrice: rowData['unitPrice'],
      sellingPrice: rowData['sellingPrice'],
      discount1: rowData['discount1'],
      discount2: rowData['discount2'],
      discount3: rowData['discount3'],
      taxRate: rowData['taxRate'],
    );

    onChanged(updated);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctrls = ref
        .read(purchaseItemsProvider.notifier)
        .getRowControllers(item.uiId, item);

    final bgColor =
        item.uiId.hashCode % 2 == 0
            ? Colors.white
            : Color.fromARGB(40, 250, 250, 250);

    final dateStr =
        item.expirationDate != null
            ? DateFormat('dd.MM.yyyy').format(item.expirationDate!)
            : 'SKT Seç';

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
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),

          // Batch No & Expiration Date (Stacked, fixed height control)
          _buildCell(
            width: 120,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: _buildCompactInput(
                      ctrls.batchCtrl,
                      'Parti',
                      onChanged: (_) => _updateItem(ref),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Flexible(
                    child: _buildDateSelector(context, dateStr, () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: item.expirationDate ?? DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(
                          const Duration(days: 3650),
                        ),
                      );
                      if (date != null) {
                        onChanged(item.copyWith(expirationDate: date));
                      }
                    }),
                  ),
                ],
              ),
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

          // Free Quantity
          _buildCell(
            width: 70,
            child: Center(
              child: _buildCompactInput(
                ctrls.freeQtyCtrl,
                'Bedava',
                onChanged: (_) => _updateItem(ref),
                keyboardType: TextInputType.number,
              ),
            ),
          ),

          // Unit Price
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

          // Selling Price (Highlighted)
          _buildCell(
            width: 90,
            child: Center(
              child: _buildCompactInput(
                ctrls.sellPriceCtrl,
                '₺',
                onChanged: (_) => _updateItem(ref),
                keyboardType: TextInputType.number,
                isHighlight: true,
              ),
            ),
          ),

          // Discounts (Stacked: 3 fields vertically)
          _buildCell(
            width: 90,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: _buildCompactInput(
                      ctrls.disc1Ctrl,
                      'İsk1%',
                      onChanged: (_) => _updateItem(ref),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Flexible(
                    child: _buildCompactInput(
                      ctrls.disc2Ctrl,
                      'İsk2%',
                      onChanged: (_) => _updateItem(ref),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Flexible(
                    child: _buildCompactInput(
                      ctrls.disc3Ctrl,
                      'İsk3%',
                      onChanged: (_) => _updateItem(ref),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Tax Rate
          _buildCell(
            width: 70,
            child: Center(
              child: _buildCompactInput(
                ctrls.taxCtrl,
                '%',
                onChanged: (_) => _updateItem(ref),
                keyboardType: TextInputType.number,
              ),
            ),
          ),

          // Net Total (Display Only)
          _buildCell(
            width: 110,
            child: Center(
              child: Text(
                '₺${item.lineTotal.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppColors.primary,
                ),
                textAlign: TextAlign.right,
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
                      .read(purchaseItemsProvider.notifier)
                      .removeRowControllers(item.uiId);
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
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        border:
            showBorder
                ? Border(right: BorderSide(color: Colors.grey.shade300))
                : null,
      ),
      child: child,
    );
  }

  Widget _buildCompactInput(
    TextEditingController controller,
    String hint, {
    required Function(String) onChanged,
    TextInputType keyboardType = TextInputType.text,
    bool isHighlight = false,
  }) {
    return SizedBox(
      height: 28,
      child: TextFormField(
        controller: controller,
        onChanged: onChanged,
        textAlign: TextAlign.center,
        keyboardType: keyboardType,
        style: TextStyle(
          fontSize: 12,
          color: isHighlight ? Colors.deepOrange : Colors.black87,
          fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 10, color: Colors.grey),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 4,
            vertical: 0,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: BorderSide(
              color:
                  isHighlight
                      ? Colors.deepOrange.shade200
                      : Colors.grey.shade400,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: BorderSide(
              color:
                  isHighlight
                      ? Colors.deepOrange.shade300
                      : Colors.grey.shade300,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: BorderSide(
              color: isHighlight ? Colors.deepOrange : AppColors.primary,
              width: 1.5,
            ),
          ),
        ),
      ),
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
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color:
              item.expirationDate == null ? Colors.red.shade50 : Colors.white,
          border: Border.all(
            color:
                item.expirationDate == null
                    ? Colors.red.shade200
                    : Colors.grey.shade300,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          dateStr,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: item.expirationDate == null ? Colors.red : Colors.black87,
          ),
        ),
      ),
    );
  }
}
