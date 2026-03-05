import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:mobile/core/api/api_client.dart';
import '../../data/stock_repository.dart';
import '../../domain/entities/opening_stock_entity.dart';
import '../../domain/entities/opening_stock_item_entity.dart';

final openingStockProvider =
    StateNotifierProvider<OpeningStockNotifier, OpeningStockState>((ref) {
      final apiClient = ref.read(apiClientProvider);
      final repository = StockRepository(apiClient);

      return OpeningStockNotifier(repository);
    });

class OpeningStockState {
  final DateTime entryDate;
  final String? note;
  final List<OpeningStockItemEntity> items;
  final bool isLoading;

  const OpeningStockState({
    required this.entryDate,
    this.note,
    required this.items,
    this.isLoading = false,
  });

  OpeningStockState copyWith({
    DateTime? entryDate,
    String? note,
    List<OpeningStockItemEntity>? items,
    bool? isLoading,
  }) {
    return OpeningStockState(
      entryDate: entryDate ?? this.entryDate,
      note: note ?? this.note,
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class OpeningStockNotifier extends StateNotifier<OpeningStockState> {
  final StockRepository _repository;
  OpeningStockNotifier(this._repository)
    : super(OpeningStockState(entryDate: DateTime.now(), items: const []));

  // final StockRepository _repository = StockRepository();

  void setEntryDate(DateTime date) {
    state = state.copyWith(entryDate: date);
  }

  void setNote(String note) {
    state = state.copyWith(note: note);
  }

  void addItem(OpeningStockItemEntity item) {
    state = state.copyWith(items: [...state.items, item]);
  }

  void updateItem(int index, OpeningStockItemEntity updatedItem) {
    final updated = [...state.items];
    if (index < 0 || index >= updated.length) return;
    updated[index] = updatedItem;
    state = state.copyWith(items: updated);
  }

  void removeItem(int index) {
    final updated = [...state.items]..removeAt(index);
    state = state.copyWith(items: updated);
  }

  Future<void> submitOpeningStock() async {
    if (state.items.isEmpty) {
      throw Exception("En az bir ürün eklenmelidir.");
    }

    state = state.copyWith(isLoading: true);

    try {
      print("DEBUG submitOpeningStock:");
      print("  - entryDate: ${state.entryDate}");
      print("  - note: ${state.note}");
      print("  - items count: ${state.items.length}");

      for (int i = 0; i < state.items.length; i++) {
        final item = state.items[i];
        print("  - Item $i:");
        print(
          "    - productId: ${item.productId} (type: ${item.productId.runtimeType})",
        );
        print(
          "    - vatRate: ${item.vatRate} (type: ${item.vatRate.runtimeType})",
        );
        print(
          "    - quantity: ${item.quantity} (type: ${item.quantity.runtimeType})",
        );
        print(
          "    - buyingPrice: ${item.buyingPrice} (type: ${item.buyingPrice.runtimeType})",
        );
        print(
          "    - sellingPrice: ${item.sellingPrice} (type: ${item.sellingPrice.runtimeType})",
        );
      }

      final entity = OpeningStockEntity(
        entryDate: state.entryDate,
        note: state.note,
        items: state.items,
      );

      print("DEBUG: Converting to JSON...");
      final json = entity.toJson();
      print("DEBUG: JSON created successfully");
      print("DEBUG: JSON: $json");

      await _repository.createOpeningStock(json);

      state = OpeningStockState(entryDate: DateTime.now(), items: const []);
    } catch (e, stackTrace) {
      print("DEBUG: Error in submitOpeningStock: $e");
      print("DEBUG: Error type: ${e.runtimeType}");
      print("DEBUG: Stack trace:\n$stackTrace");
      rethrow;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }
}
