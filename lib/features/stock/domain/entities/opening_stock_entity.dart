import 'opening_stock_item_entity.dart';

class OpeningStockEntity {
  final DateTime entryDate;
  final String? note;
  final List<OpeningStockItemEntity> items;

  const OpeningStockEntity({
    required this.entryDate,
    this.note,
    required this.items,
  });

  Map<String, dynamic> toJson() {
    // Format: YYYY-MM-DD
    final dateStr =
        "${entryDate.year.toString().padLeft(4, '0')}-${entryDate.month.toString().padLeft(2, '0')}-${entryDate.day.toString().padLeft(2, '0')}";

    return {
      "entry_date": dateStr,
      "note": note,
      "items": items.map((e) => e.toJson()).toList(),
    };
  }
}
