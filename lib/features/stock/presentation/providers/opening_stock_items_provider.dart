import 'package:flutter/scheduler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../domain/entities/opening_stock_item_entity.dart';

/// Provider for managing row controllers and debouncing updates
final openingStockItemsProvider =
    StateNotifierProvider<OpeningStockItemsNotifier, OpeningStockItemsState>(
      (ref) => OpeningStockItemsNotifier(),
    );

class OpeningStockItemsState {
  final Map<int, _RowControllers> controllers;
  final Set<int> dirtyRows; // Track which rows have unsaved changes

  const OpeningStockItemsState({
    required this.controllers,
    required this.dirtyRows,
  });

  OpeningStockItemsState copyWith({
    Map<int, _RowControllers>? controllers,
    Set<int>? dirtyRows,
  }) {
    return OpeningStockItemsState(
      controllers: controllers ?? this.controllers,
      dirtyRows: dirtyRows ?? this.dirtyRows,
    );
  }
}

/// Model to hold all controllers for a single row
class _RowControllers {
  final TextEditingController batchCtrl;
  final TextEditingController qtyCtrl;
  final TextEditingController priceCtrl;
  final TextEditingController sellPriceCtrl;
  final TextEditingController vatCtrl;
  final TextEditingController locationCtrl;

  _RowControllers({
    required this.batchCtrl,
    required this.qtyCtrl,
    required this.priceCtrl,
    required this.sellPriceCtrl,
    required this.vatCtrl,
    required this.locationCtrl,
  });

  void dispose() {
    batchCtrl.dispose();
    qtyCtrl.dispose();
    priceCtrl.dispose();
    sellPriceCtrl.dispose();
    vatCtrl.dispose();
    locationCtrl.dispose();
  }
}

class OpeningStockItemsNotifier extends StateNotifier<OpeningStockItemsState> {
  OpeningStockItemsNotifier()
    : super(const OpeningStockItemsState(controllers: {}, dirtyRows: {}));

  /// Pending controllers created during build; moved to state after frame.
  final Map<int, _RowControllers> _pendingControllers = {};

  /// Get or create controllers for a row. New controllers are registered
  /// in state after the current frame to avoid "setState during build".
  _RowControllers getRowControllers(int rowIndex, OpeningStockItemEntity item) {
    if (state.controllers.containsKey(rowIndex)) {
      return state.controllers[rowIndex]!;
    }
    if (_pendingControllers.containsKey(rowIndex)) {
      return _pendingControllers[rowIndex]!;
    }

    final ctrls = _RowControllers(
      batchCtrl: TextEditingController(text: item.batchNo ?? ''),
      qtyCtrl: TextEditingController(text: item.quantity.toString()),
      priceCtrl: TextEditingController(text: item.buyingPrice.toString()),
      sellPriceCtrl: TextEditingController(text: item.sellingPrice.toString()),
      vatCtrl: TextEditingController(text: item.vatRate.toString()),
      locationCtrl: TextEditingController(text: item.location ?? ''),
    );

    _pendingControllers[rowIndex] = ctrls;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _pendingControllers.remove(rowIndex);
      if (!state.controllers.containsKey(rowIndex)) {
        state = state.copyWith(
          controllers: {...state.controllers, rowIndex: ctrls},
        );
      }
    });

    return ctrls;
  }

  /// Mark a row as dirty (has unsaved changes)
  void markRowDirty(int rowIndex) {
    if (!state.dirtyRows.contains(rowIndex)) {
      state = state.copyWith(dirtyRows: {...state.dirtyRows, rowIndex});
    }
  }

  /// Clear dirty flag for a row
  void clearRowDirty(int rowIndex) {
    if (state.dirtyRows.contains(rowIndex)) {
      state = state.copyWith(
        dirtyRows: state.dirtyRows.where((i) => i != rowIndex).toSet(),
      );
    }
  }

  /// Remove controllers for a deleted row
  void removeRowControllers(int rowIndex) {
    state.controllers[rowIndex]?.dispose();
    final newControllers = Map<int, _RowControllers>.from(state.controllers)
      ..remove(rowIndex);
    final newDirtyRows = state.dirtyRows.where((i) => i != rowIndex).toSet();

    state = state.copyWith(
      controllers: newControllers,
      dirtyRows: newDirtyRows,
    );
  }

  /// Parse and validate row data
  Map<String, dynamic> parseRowData(int rowIndex) {
    final ctrls = state.controllers[rowIndex];
    if (ctrls == null) {
      throw Exception('Row $rowIndex not found');
    }

    return {
      'batchNo': ctrls.batchCtrl.text,
      'quantity': double.tryParse(ctrls.qtyCtrl.text) ?? 0.0,
      'buyingPrice': double.tryParse(ctrls.priceCtrl.text) ?? 0.0,
      'sellingPrice': double.tryParse(ctrls.sellPriceCtrl.text) ?? 0.0,
      'vatRate': int.tryParse(ctrls.vatCtrl.text) ?? 0,
      'location': ctrls.locationCtrl.text,
    };
  }

  /// Cleanup all controllers
  void dispose() {
    for (var ctrls in state.controllers.values) {
      ctrls.dispose();
    }
  }
}
