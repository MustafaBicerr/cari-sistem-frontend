class SupplierDebtSummaryModel {
  final double totalSupplierDebt;
  final int supplierCount;
  final int openInvoiceCount;
  final DateTime? nearestDueDate;

  SupplierDebtSummaryModel({
    required this.totalSupplierDebt,
    required this.supplierCount,
    required this.openInvoiceCount,
    required this.nearestDueDate,
  });

  factory SupplierDebtSummaryModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'];

    return SupplierDebtSummaryModel(
      totalSupplierDebt: double.parse(data['total_supplier_debt'].toString()),
      supplierCount: int.parse(data['supplier_count'].toString()),
      openInvoiceCount: int.parse(data['open_invoice_count'].toString()),
      nearestDueDate:
          data['nearest_due_date'] != null
              ? DateTime.parse(data['nearest_due_date'])
              : null,
    );
  }
}

class SupplierDebtMasterModel {
  final String id;
  final String supplierName;
  final String invoiceNo;
  final DateTime invoiceDate;
  final DateTime? dueDate;

  final double totalAmount;
  final double paidAmount;
  final double remainingAmount;

  final String createdBy;
  final DateTime createdAt;

  SupplierDebtMasterModel({
    required this.id,
    required this.supplierName,
    required this.invoiceNo,
    required this.invoiceDate,
    this.dueDate,
    required this.totalAmount,
    required this.paidAmount,
    required this.remainingAmount,
    required this.createdBy,
    required this.createdAt,
  });

  factory SupplierDebtMasterModel.fromJson(Map<String, dynamic> json) {
    return SupplierDebtMasterModel(
      id: json['id']?.toString() ?? '',
      supplierName: json['supplier_name'] ?? '',
      invoiceNo: json['invoice_no'] ?? '',
      invoiceDate: DateTime.parse(json['invoice_date']),
      dueDate:
          json['due_date'] != null ? DateTime.parse(json['due_date']) : null,
      totalAmount: double.parse(json['total_net_amount'].toString()),
      paidAmount: double.parse(json['paid_amount'].toString()),
      remainingAmount: double.parse(json['remaining_amount'].toString()),
      createdBy: json['created_by_user'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
