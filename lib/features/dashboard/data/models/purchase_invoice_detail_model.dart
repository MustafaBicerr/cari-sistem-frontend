double _parseDouble(dynamic v) {
  if (v == null) return 0.0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0.0;
}

/// Tek alım faturası detayı (e-fatura görünümü: header + kalemler + özet + tedarikçi borç)
class PurchaseInvoiceDetailModel {
  final String id;
  final String invoiceNo;
  final DateTime invoiceDate;
  final DateTime? dueDate;
  final String? note;
  final double totalGrossAmount;
  final double totalDiscountAmount;
  final double totalVatAmount;
  final double totalNetAmount;
  final double paidAmount;
  final double remainingAmount;
  final String paymentStatus;
  final double generalDiscountAmount;
  final String? discountType;
  final DateTime createdAt;
  final String supplierName;
  final String? supplierPhone;
  final String? supplierAddress;
  final String? createdByUser;
  final List<PurchaseInvoiceItemDetailModel> items;
  final double supplierTotalDebt;
  final List<SupplierDueDateModel> supplierDueDates;
  final List<PurchaseInvoicePaymentModel> payments;

  PurchaseInvoiceDetailModel({
    required this.id,
    required this.invoiceNo,
    required this.invoiceDate,
    this.dueDate,
    this.note,
    required this.totalGrossAmount,
    required this.totalDiscountAmount,
    required this.totalVatAmount,
    required this.totalNetAmount,
    required this.paidAmount,
    required this.remainingAmount,
    required this.paymentStatus,
    required this.generalDiscountAmount,
    this.discountType,
    required this.createdAt,
    required this.supplierName,
    this.supplierPhone,
    this.supplierAddress,
    this.createdByUser,
    required this.items,
    required this.supplierTotalDebt,
    required this.supplierDueDates,
    required this.payments,
  });

  factory PurchaseInvoiceDetailModel.fromJson(Map<String, dynamic> json) {
    final itemsList = json['items'] as List<dynamic>? ?? [];
    final dueList = json['supplier_due_dates'] as List<dynamic>? ?? [];
    final payList = json['payments'] as List<dynamic>? ?? [];
    return PurchaseInvoiceDetailModel(
      id: json['id']?.toString() ?? '',
      invoiceNo: json['invoice_no']?.toString() ?? '',
      invoiceDate: DateTime.parse(json['invoice_date'].toString()),
      dueDate:
          json['due_date'] != null
              ? DateTime.parse(json['due_date'].toString())
              : null,
      note: json['note']?.toString(),
      totalGrossAmount: _parseDouble(json['total_gross_amount']),
      totalDiscountAmount: _parseDouble(json['total_discount_amount']),
      totalVatAmount: _parseDouble(json['total_vat_amount']),
      totalNetAmount: _parseDouble(json['total_net_amount']),
      paidAmount: _parseDouble(json['paid_amount']),
      remainingAmount: _parseDouble(json['remaining_amount']),
      paymentStatus: json['payment_status']?.toString() ?? 'UNPAID',
      generalDiscountAmount: _parseDouble(json['general_discount_amount']),
      discountType: json['discount_type']?.toString(),
      createdAt: DateTime.parse(json['created_at'].toString()),
      supplierName: json['supplier_name']?.toString() ?? '',
      supplierPhone: json['supplier_phone']?.toString(),
      supplierAddress: json['supplier_address']?.toString(),
      createdByUser: json['created_by_user']?.toString(),
      items:
          itemsList
              .map(
                (e) => PurchaseInvoiceItemDetailModel.fromJson(
                  e as Map<String, dynamic>,
                ),
              )
              .toList(),
      supplierTotalDebt: _parseDouble(json['supplier_total_debt']),
      supplierDueDates:
          dueList
              .map(
                (e) => SupplierDueDateModel.fromJson(e as Map<String, dynamic>),
              )
              .toList(),
      payments:
          payList
              .map(
                (e) => PurchaseInvoicePaymentModel.fromJson(
                  e as Map<String, dynamic>,
                ),
              )
              .toList(),
    );
  }
}

class PurchaseInvoiceItemDetailModel {
  final String productName;
  final String? batchNo;
  final DateTime? expirationDate;
  final double quantity;
  final double freeQuantity;
  final double unitPrice;
  final double discountRate;
  final double discountRate2;
  final double discountRate3;
  final double taxRate;
  final double lineTotal;
  final double netUnitCost;
  final double sellingPrice;

  PurchaseInvoiceItemDetailModel({
    required this.productName,
    this.batchNo,
    this.expirationDate,
    required this.quantity,
    required this.freeQuantity,
    required this.unitPrice,
    required this.discountRate,
    required this.discountRate2,
    required this.discountRate3,
    required this.taxRate,
    required this.lineTotal,
    required this.netUnitCost,
    required this.sellingPrice,
  });

  factory PurchaseInvoiceItemDetailModel.fromJson(Map<String, dynamic> json) {
    return PurchaseInvoiceItemDetailModel(
      productName: json['product_name']?.toString() ?? '',
      batchNo: json['batch_no']?.toString(),
      expirationDate:
          json['expiration_date'] != null
              ? DateTime.parse(json['expiration_date'].toString())
              : null,
      quantity: _parseDouble(json['quantity']),
      freeQuantity: _parseDouble(json['free_quantity']),
      unitPrice: _parseDouble(json['unit_price']),
      discountRate: _parseDouble(json['discount_rate']),
      discountRate2: _parseDouble(json['discount_rate_2']),
      discountRate3: _parseDouble(json['discount_rate_3']),
      taxRate: _parseDouble(json['tax_rate']),
      lineTotal: _parseDouble(json['line_total']),
      netUnitCost: _parseDouble(json['net_unit_cost']),
      sellingPrice: _parseDouble(json['selling_price']),
    );
  }
}

class SupplierDueDateModel {
  final String invoiceNo;
  final DateTime? dueDate;
  final double remainingAmount;

  SupplierDueDateModel({
    required this.invoiceNo,
    this.dueDate,
    required this.remainingAmount,
  });

  factory SupplierDueDateModel.fromJson(Map<String, dynamic> json) {
    return SupplierDueDateModel(
      invoiceNo: json['invoice_no']?.toString() ?? '',
      dueDate:
          json['due_date'] != null
              ? DateTime.parse(json['due_date'].toString())
              : null,
      remainingAmount: _parseDouble(json['remaining_amount']),
    );
  }
}

class PurchaseInvoicePaymentModel {
  final double amount;
  final String paymentMethod;
  final String? description;
  final DateTime processedAt;

  PurchaseInvoicePaymentModel({
    required this.amount,
    required this.paymentMethod,
    this.description,
    required this.processedAt,
  });

  factory PurchaseInvoicePaymentModel.fromJson(Map<String, dynamic> json) {
    return PurchaseInvoicePaymentModel(
      amount: _parseDouble(json['amount']),
      paymentMethod: json['payment_method']?.toString() ?? '',
      description: json['description']?.toString(),
      processedAt: DateTime.parse(json['processed_at'].toString()),
    );
  }
}
