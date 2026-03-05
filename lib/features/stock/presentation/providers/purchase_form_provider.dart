import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:mobile/core/api/api_client.dart';
import 'package:uuid/uuid.dart';
import '../../data/stock_repository.dart';

final stockRepositoryProvider = Provider((ref) {
  final apiClient = ref.read(apiClientProvider);
  return StockRepository(apiClient);
});

// 1. SATIR MODELİ
class PurchaseItemState {
  final String uiId;
  final String productId;
  final String productName;
  final String productSource; //'local' veya 'global'
  final String? imageUrl;
  final String batchNo;
  final DateTime? expirationDate;
  final double quantity;
  final double freeQuantity;
  final double unitPrice;
  final double sellingPrice; //YENİ: Satış Fiyatı
  final double discount1;
  final double discount2;
  final double discount3;
  final double taxRate;

  PurchaseItemState({
    required this.uiId,
    required this.productId,
    required this.productName,
    required this.productSource,
    this.imageUrl,
    this.batchNo = '',
    this.expirationDate,
    this.quantity = 1,
    this.freeQuantity = 0,
    this.unitPrice = 0,
    this.sellingPrice = 0,
    this.discount1 = 0,
    this.discount2 = 0,
    this.discount3 = 0,
    this.taxRate = 0,
  });

  PurchaseItemState copyWith({
    String? batchNo,
    DateTime? expirationDate,
    double? quantity,
    double? freeQuantity,
    double? unitPrice,
    double? sellingPrice,
    double? discount1,
    double? discount2,
    double? discount3,
    double? taxRate,
  }) {
    return PurchaseItemState(
      uiId: uiId,
      productId: productId,
      productName: productName,
      productSource: productSource,
      imageUrl: imageUrl,
      batchNo: batchNo ?? this.batchNo,
      expirationDate: expirationDate ?? this.expirationDate,
      quantity: quantity ?? this.quantity,
      freeQuantity: freeQuantity ?? this.freeQuantity,
      unitPrice: unitPrice ?? this.unitPrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      discount1: discount1 ?? this.discount1,
      discount2: discount2 ?? this.discount2,
      discount3: discount3 ?? this.discount3,
      taxRate: taxRate ?? this.taxRate,
    );
  }

  double get grossTotal => quantity * unitPrice;
  double get netTotal {
    double current = grossTotal;
    current = current * (1 - (discount1 / 100));
    current = current * (1 - (discount2 / 100));
    current = current * (1 - (discount3 / 100));
    return current;
  }

  double get rowDiscountAmount => grossTotal - netTotal;
  double get taxAmount => netTotal * (taxRate / 100);
  double get lineTotal => netTotal + taxAmount;
}

// 2. FORM MODELİ
class PurchaseFormState {
  final String? supplierId;
  final String? supplierName;
  final String supplierSource; //'local' veya 'global'
  final Map<String, dynamic>? supplierData;
  final String invoiceNo;
  final DateTime invoiceDate;
  final DateTime? dueDate;
  final String note;
  final List<PurchaseItemState> items;
  final double generalDiscountAmount;
  final double paidAmount;
  final bool isLoading;
  final String? error;
  final bool isSupplierLoading;

  PurchaseFormState({
    this.supplierId,
    this.supplierName,
    this.supplierSource = 'local',
    this.supplierData,
    this.invoiceNo = '',
    required this.invoiceDate,
    this.dueDate,
    this.note = '',
    this.items = const [],
    this.generalDiscountAmount = 0,
    this.paidAmount = 0,
    this.isLoading = false,
    this.error,
    this.isSupplierLoading = false,
  });

  PurchaseFormState copyWith({
    String? supplierId,
    String? supplierName,
    String? supplierSource,
    Map<String, dynamic>? supplierData,
    String? invoiceNo,
    DateTime? invoiceDate,
    DateTime? dueDate,
    String? note,
    List<PurchaseItemState>? items,
    double? generalDiscountAmount,
    double? paidAmount,
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool? isSupplierLoading,
    bool clearSupplier = false,
  }) {
    return PurchaseFormState(
      // clearSupplier true ise null yap, değilse yeni değeri al, o da yoksa eskiyi koru
      supplierId: clearSupplier ? null : (supplierId ?? this.supplierId),
      supplierName: clearSupplier ? null : (supplierName ?? this.supplierName),
      supplierData: clearSupplier ? null : (supplierData ?? this.supplierData),
      supplierSource:
          clearSupplier ? 'local' : (supplierSource ?? this.supplierSource),

      invoiceNo: invoiceNo ?? this.invoiceNo,
      invoiceDate: invoiceDate ?? this.invoiceDate,
      dueDate: dueDate ?? this.dueDate,
      note: note ?? this.note,
      items: items ?? this.items,
      generalDiscountAmount:
          generalDiscountAmount ?? this.generalDiscountAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      isSupplierLoading: isSupplierLoading ?? this.isSupplierLoading,
    );
  }

  double get totalGross => items.fold(0, (sum, item) => sum + item.grossTotal);
  double get totalRowDiscount =>
      items.fold(0, (sum, item) => sum + item.rowDiscountAmount);
  // double get totalTax => items.fold(0, (sum, item) => sum + item.taxAmount);
  double get totalTax => recalculatedTotalTax;
  double get totalNetBeforeGeneralDiscount =>
      items.fold(0, (sum, item) => sum + item.netTotal);
  double get adjustedNetTotal {
    final result = totalNetBeforeGeneralDiscount - generalDiscountAmount;
    return result > 0 ? result : 0;
  }

  double get recalculatedTotalTax {
    return items.fold(0, (sum, item) {
      final ratio =
          totalNetBeforeGeneralDiscount == 0
              ? 0
              : item.netTotal / totalNetBeforeGeneralDiscount;

      final itemGeneralDiscount = generalDiscountAmount * ratio;
      final adjustedItemNet = item.netTotal - itemGeneralDiscount;

      return sum + (adjustedItemNet * (item.taxRate / 100));
    });
  }

  double get subTotal => items.fold(0, (sum, item) => sum + item.lineTotal);
  double get grandTotal {
    return adjustedNetTotal + recalculatedTotalTax;
  }
  // double get grandTotal {
  //   final result = subTotal - generalDiscountAmount;
  //   return result > 0 ? result : 0;
  // }

  double get remainingDebt {
    final result = grandTotal - paidAmount;
    return result > 0 ? result : 0;
  }
}

// 3. NOTIFIER
class PurchaseFormNotifier extends StateNotifier<PurchaseFormState> {
  final StockRepository _repo;

  PurchaseFormNotifier(this._repo)
    : super(PurchaseFormState(invoiceDate: DateTime.now()));

  // Çarpıya basıldığında çağrılacak temizleme metodu
  void clearSupplier() {
    state = state.copyWith(clearSupplier: true);
  }

  //Pre-flight Creation Mantığı
  Future<void> selectSupplier(Map<String, dynamic> selection) async {
    final source = selection['source'];

    // 1. Zaten yerel bir tedarikçiyse
    if (source == 'local') {
      state = state.copyWith(
        supplierId: selection['id'],
        supplierName: selection['name'],
        supplierSource: 'local',
        supplierData: selection, // 🔥 Veriyi sakla
      );
      return;
    }

    // 2. Global ise oluştur
    state = state.copyWith(isSupplierLoading: true, clearError: true);

    try {
      final payload = {
        "name": selection['name'],
        "tax_number": selection['tax_number'] ?? '',
        "tax_office": selection['tax_office'] ?? '',
        "city": selection['city'] ?? '',
        "district": selection['district'] ?? '',
        "address": selection['address'] ?? '',
        "warehouse_type": selection['warehouse_type'] ?? '',
      };

      final newSupplier = await _repo.createSupplier(payload);

      state = state.copyWith(
        supplierId: newSupplier['id'],
        supplierName: newSupplier['name'],
        supplierSource: 'local',
        supplierData: newSupplier, // 🔥 Oluşan yeni veriyi sakla
        isSupplierLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isSupplierLoading: false,
        error: "Tedarikçi sisteme kaydedilemedi: ${e.toString()}",
      );
    }
  }

  void updateSupplier(String id, String name, String source) {
    state = state.copyWith(
      supplierId: id,
      supplierName: name,
      supplierSource: source,
    );
  }

  void updateInvoiceNo(String no) => state = state.copyWith(invoiceNo: no);
  void updateInvoiceDate(DateTime date) =>
      state = state.copyWith(invoiceDate: date);
  void updateDueDate(DateTime date) => state = state.copyWith(dueDate: date);
  void updateNote(String note) => state = state.copyWith(note: note);

  void addItem(
    String productId,
    String productName,
    double price,
    double sellPrice,
    double taxRate,
    String source,
    String? imageUrl,
  ) {
    final newItem = PurchaseItemState(
      uiId: const Uuid().v4(),
      productId: productId,
      productName: productName,
      productSource: source, // 'local' veya 'global'
      imageUrl: imageUrl,
      unitPrice: price,
      sellingPrice: sellPrice, //Yeni Satış Fiyatı
      taxRate: taxRate,
    );
    state = state.copyWith(items: [...state.items, newItem]);
  }

  void updateItem(String uiId, PurchaseItemState updatedItem) {
    state = state.copyWith(
      items: state.items.map((i) => i.uiId == uiId ? updatedItem : i).toList(),
    );
  }

  void removeItem(String uiId) {
    state = state.copyWith(
      items: state.items.where((i) => i.uiId != uiId).toList(),
    );
  }

  void updateGeneralDiscount(double amount) =>
      state = state.copyWith(generalDiscountAmount: amount);
  void updatePaidAmount(double amount) =>
      state = state.copyWith(paidAmount: amount);

  Future<bool> saveInvoice() async {
    if (state.supplierId == null) {
      state = state.copyWith(error: "Lütfen bir tedarikçi seçin.");
      return false;
    }
    if (state.items.isEmpty) {
      state = state.copyWith(error: "Faturaya en az bir ürün eklemelisiniz.");
      return false;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final payload = {
        "supplier_id": state.supplierId,
        "supplier_source": state.supplierSource,
        "supplier_name":
            state.supplierName, // DB'de yeni kayıt açarken lazım olacak
        "invoice_no": state.invoiceNo.trim(),
        "invoice_date": state.invoiceDate.toIso8601String(),
        "due_date": state.dueDate?.toIso8601String(),
        "note": state.note,
        "paid_amount": state.paidAmount,
        "general_discount_amount": state.generalDiscountAmount,
        "items":
            state.items
                .map(
                  (item) => {
                    "product_id": item.productId,
                    "product_source": item.productSource,
                    "quantity": item.quantity,
                    "free_quantity": item.freeQuantity,
                    "unit_price": item.unitPrice,
                    "selling_price": item.sellingPrice, // 🔥 Payload'a eklendi
                    "discount_rate": item.discount1,
                    "discount_rate_2": item.discount2,
                    "discount_rate_3": item.discount3,
                    "tax_rate": item.taxRate,
                    "batch_no": item.batchNo.trim(),
                    "expiration_date": item.expirationDate?.toIso8601String(),
                  },
                )
                .toList(),
      };

      await _repo.createPurchaseInvoice(payload);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  void resetForm() => state = PurchaseFormState(invoiceDate: DateTime.now());
}

final purchaseFormProvider =
    StateNotifierProvider.autoDispose<PurchaseFormNotifier, PurchaseFormState>((
      ref,
    ) {
      final repo = ref.read(stockRepositoryProvider);
      return PurchaseFormNotifier(repo);
    });
