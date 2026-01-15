class TransactionMasterModel {
  final String id;
  final String createdAt;
  final String timeStr;
  final String description;
  final String paymentMethod;
  final String transactionStatus; // 'PAID', 'UNPAID', 'PARTIAL'

  // Para Hesapları
  final double totalAmount; // İndirimsiz
  final double discountAmount; // İndirim
  final double finalAmount; // Fatura Tutarı (Toplam Borçlanılan)
  final double remainingAmount; // Kalan Borç
  final double paidAmount; // Ödenen (Biz hesapladık backend'de)

  // Kişiler
  final String customerName;
  final String customerPhone;
  final String cashierName;

  // Ürünler
  final List<MasterItem> items;

  TransactionMasterModel({
    required this.id,
    required this.createdAt,
    required this.timeStr,
    required this.description,
    required this.paymentMethod,
    required this.transactionStatus,
    required this.totalAmount,
    required this.discountAmount,
    required this.finalAmount,
    required this.remainingAmount,
    required this.paidAmount,
    required this.customerName,
    required this.customerPhone,
    required this.cashierName,
    required this.items,
  });

  factory TransactionMasterModel.fromJson(Map<String, dynamic> json) {
    return TransactionMasterModel(
      id: json['id']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
      timeStr: json['time_str']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      paymentMethod: json['payment_method']?.toString() ?? 'UNKNOWN',
      transactionStatus: json['transaction_status']?.toString() ?? 'UNKNOWN',

      // Güvenli Double Çevirimi
      totalAmount: _safeDouble(json['total_amount']),
      discountAmount: _safeDouble(json['discount_amount']),
      finalAmount: _safeDouble(json['final_amount']),
      remainingAmount: _safeDouble(json['remaining_amount']),
      paidAmount: _safeDouble(json['paid_amount']),

      customerName: json['customer_name']?.toString() ?? 'Misafir',
      customerPhone: json['customer_phone']?.toString() ?? '',
      cashierName: json['cashier_name']?.toString() ?? 'Sistem',

      items:
          (json['items'] as List?)
              ?.map((e) => MasterItem.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class MasterItem {
  final String productName;
  final double quantity;

  // Fiyatlar
  final double snapshotPrice; // Satış Anı
  final double currentPrice; // Güncel Raf
  final double displayUnitPrice; // Listede görünecek (Mantıksal)
  final double displayTotalPrice; // Listede görünecek toplam

  final String paymentStatus; // Satır bazlı durum
  final List<PriceHistoryItem> priceHistory;

  MasterItem({
    required this.productName,
    required this.quantity,
    required this.snapshotPrice,
    required this.currentPrice,
    required this.displayUnitPrice,
    required this.displayTotalPrice,
    required this.paymentStatus,
    required this.priceHistory,
  });

  factory MasterItem.fromJson(Map<String, dynamic> json) {
    return MasterItem(
      productName: json['product_name']?.toString() ?? 'Ürün',
      quantity: _safeDouble(json['quantity']),

      snapshotPrice: _safeDouble(json['snapshot_price']),
      currentPrice: _safeDouble(json['current_price']),
      displayUnitPrice: _safeDouble(json['display_unit_price']),
      displayTotalPrice: _safeDouble(json['display_total_price']),

      paymentStatus: json['payment_status']?.toString() ?? 'UNPAID',
      priceHistory:
          (json['price_history'] as List?)
              ?.map((e) => PriceHistoryItem.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class PriceHistoryItem {
  final String date;
  final double oldPrice;
  final double newPrice;

  PriceHistoryItem({
    required this.date,
    required this.oldPrice,
    required this.newPrice,
  });

  factory PriceHistoryItem.fromJson(Map<String, dynamic> json) {
    return PriceHistoryItem(
      date: json['date']?.toString() ?? '',
      oldPrice: _safeDouble(json['old_price']),
      newPrice: _safeDouble(json['new_price']),
    );
  }
}

// 🛡️ Helper: Her türlü veriyi double yapar
double _safeDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}
