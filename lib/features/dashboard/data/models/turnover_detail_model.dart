class TurnoverDetailModel {
  final String id;
  final double amount;
  final String paymentMethod;
  final String category;
  final String description;
  final String timeStr;
  final String customerName;
  final String createdByUser;
  final double transactionTotalAmount;
  final List<TurnoverItem> items;

  TurnoverDetailModel({
    required this.id,
    required this.amount,
    required this.paymentMethod,
    required this.category,
    required this.description,
    required this.timeStr,
    required this.customerName,
    required this.createdByUser,
    required this.transactionTotalAmount,
    required this.items,
  });

  factory TurnoverDetailModel.fromJson(Map<String, dynamic> json) {
    return TurnoverDetailModel(
      id: json['id']?.toString() ?? '',
      // 🔥 GÜVENLİ PARSE: Null gelirse 0.0 yapar, hata vermez.
      amount: _safeDouble(json['amount']),
      paymentMethod: json['payment_method'] ?? 'UNKNOWN',
      category: json['category'] ?? 'OTHER',
      description: json['description'] ?? '',
      timeStr: json['time_str'] ?? '',
      customerName: json['customer_name'] ?? 'Misafir',
      createdByUser: json['created_by_user'] ?? 'Sistem',
      transactionTotalAmount: _safeDouble(json['transaction_total_amount']),
      items:
          (json['items'] as List?)
              ?.map((item) => TurnoverItem.fromJson(item))
              .toList() ??
          [],
    );
  }
}

class TurnoverItem {
  final String productName;
  final double quantity;
  final double unitPrice; // Listede görünen (Dinamik) fiyat
  final double total;
  final String paymentStatus;

  // Enflasyon hesaplaması için kritik alanlar
  final double snapshotPrice; // Satış anındaki
  final double currentPrice; // Şu anki
  final List<PriceHistoryItem> priceHistory;

  TurnoverItem({
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.total,
    required this.paymentStatus,
    required this.snapshotPrice,
    required this.currentPrice,
    required this.priceHistory,
  });

  factory TurnoverItem.fromJson(Map<String, dynamic> json) {
    return TurnoverItem(
      productName: json['product_name'] ?? 'Ürün',
      quantity: _safeDouble(json['quantity']),
      unitPrice: _safeDouble(json['unit_price']),
      total: _safeDouble(json['total']),
      paymentStatus: json['payment_status'] ?? 'UNPAID',

      // 🔥 Backend restart edilmezse bunlar null gelir, burada 0'a çevirip kurtarıyoruz.
      snapshotPrice: _safeDouble(json['snapshot_price']),
      currentPrice: _safeDouble(json['current_price']),

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
      date: json['date'] ?? '',
      oldPrice: _safeDouble(json['old_price']),
      newPrice: _safeDouble(json['new_price']),
    );
  }
}

// 👇 HAYAT KURTARAN FONKSİYON
// Veritabanından string "180.00" de gelse, null da gelse, int 180 de gelse double yapar.
double _safeDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) {
    return double.tryParse(value) ?? 0.0;
  }
  return 0.0;
}
