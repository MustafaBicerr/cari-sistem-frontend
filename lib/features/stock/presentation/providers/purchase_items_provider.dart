import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../presentation/providers/purchase_form_provider.dart';

/// Provider for managing row controllers in purchase items
final purchaseItemsProvider =
    StateNotifierProvider<PurchaseItemsNotifier, PurchaseItemsState>(
      (ref) => PurchaseItemsNotifier(),
    );

class PurchaseItemsState {
  final Map<String, _RowControllers> controllers; // Key: uiId

  const PurchaseItemsState({required this.controllers});

  PurchaseItemsState copyWith({Map<String, _RowControllers>? controllers}) {
    return PurchaseItemsState(controllers: controllers ?? this.controllers);
  }
}

/// Model to hold all controllers for a single purchase row
class _RowControllers {
  final TextEditingController batchCtrl;
  final TextEditingController qtyCtrl;
  final TextEditingController freeQtyCtrl;
  final TextEditingController priceCtrl;
  final TextEditingController sellPriceCtrl;
  final TextEditingController disc1Ctrl;
  final TextEditingController disc2Ctrl;
  final TextEditingController disc3Ctrl;
  final TextEditingController taxCtrl;

  _RowControllers({
    required this.batchCtrl,
    required this.qtyCtrl,
    required this.freeQtyCtrl,
    required this.priceCtrl,
    required this.sellPriceCtrl,
    required this.disc1Ctrl,
    required this.disc2Ctrl,
    required this.disc3Ctrl,
    required this.taxCtrl,
  });

  void dispose() {
    batchCtrl.dispose();
    qtyCtrl.dispose();
    freeQtyCtrl.dispose();
    priceCtrl.dispose();
    sellPriceCtrl.dispose();
    disc1Ctrl.dispose();
    disc2Ctrl.dispose();
    disc3Ctrl.dispose();
    taxCtrl.dispose();
  }
}

class PurchaseItemsNotifier extends StateNotifier<PurchaseItemsState> {
  PurchaseItemsNotifier() : super(const PurchaseItemsState(controllers: {}));

  /// Get or create controllers for a row
  _RowControllers getRowControllers(String uiId, PurchaseItemState item) {
    if (state.controllers.containsKey(uiId)) {
      return state.controllers[uiId]!;
    }

    final ctrls = _RowControllers(
      batchCtrl: TextEditingController(text: item.batchNo),
      qtyCtrl: TextEditingController(text: item.quantity.toString()),
      freeQtyCtrl: TextEditingController(text: item.freeQuantity.toString()),
      priceCtrl: TextEditingController(text: item.unitPrice.toString()),
      sellPriceCtrl: TextEditingController(text: item.sellingPrice.toString()),
      disc1Ctrl: TextEditingController(text: item.discount1.toString()),
      disc2Ctrl: TextEditingController(text: item.discount2.toString()),
      disc3Ctrl: TextEditingController(text: item.discount3.toString()),
      taxCtrl: TextEditingController(text: item.taxRate.toString()),
    );

    state = state.copyWith(controllers: {...state.controllers, uiId: ctrls});

    return ctrls;
  }

  /// Remove controllers for a deleted row
  void removeRowControllers(String uiId) {
    state.controllers[uiId]?.dispose();
    final newControllers = Map<String, _RowControllers>.from(state.controllers)
      ..remove(uiId);

    state = state.copyWith(controllers: newControllers);
  }

  /// Parse and validate row data
  Map<String, dynamic> parseRowData(String uiId) {
    final ctrls = state.controllers[uiId];
    if (ctrls == null) {
      throw Exception('Row $uiId not found');
    }

    return {
      'batchNo': ctrls.batchCtrl.text,
      'quantity': double.tryParse(ctrls.qtyCtrl.text) ?? 0.0,
      'freeQuantity': double.tryParse(ctrls.freeQtyCtrl.text) ?? 0.0,
      'unitPrice': double.tryParse(ctrls.priceCtrl.text) ?? 0.0,
      'sellingPrice': double.tryParse(ctrls.sellPriceCtrl.text) ?? 0.0,
      'discount1': double.tryParse(ctrls.disc1Ctrl.text) ?? 0.0,
      'discount2': double.tryParse(ctrls.disc2Ctrl.text) ?? 0.0,
      'discount3': double.tryParse(ctrls.disc3Ctrl.text) ?? 0.0,
      'taxRate': double.tryParse(ctrls.taxCtrl.text) ?? 0.0,
    };
  }

  /// Cleanup all controllers
  void dispose() {
    for (var ctrls in state.controllers.values) {
      ctrls.dispose();
    }
  }
}
