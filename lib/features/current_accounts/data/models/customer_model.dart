class CustomerModel {
  final String id;
  final String fullName;
  final String? phone;
  final String? email;
  final String? taxNumber;
  final String? address;
  final String? city;
  final String? district;
  final double currentBalance; // Backend'den hesaplanmış geliyor

  CustomerModel({
    required this.id,
    required this.fullName,
    this.phone,
    this.email,
    this.taxNumber,
    this.address,
    this.city,
    this.district,
    required this.currentBalance,
  });

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      id: json['id'],
      fullName: json['full_name'] ?? 'İsimsiz Müşteri',
      phone: json['phone'],
      email: json['email'],
      taxNumber: json['tax_number'],
      address: json['address'],
      city: json['city'],
      district: json['district'],
      // safeDouble kullanımı: String veya Int gelse de Double'a çevirir
      currentBalance: _safeDouble(json['current_balance']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'full_name': fullName,
      'phone': phone,
      'email': email,
      'tax_number': taxNumber,
      'address': address,
      'city': city,
      'district': district,
    };
  }
}

// ---------------------------------------------------------
// DETAY SAYFASI İÇİN KOMPLE MODEL (Profil + Geçmiş)
// ---------------------------------------------------------
class CustomerDetailResponse {
  final CustomerModel profile;
  final List<CustomerTransactionItem> transactions;
  final List<CustomerPaymentItem> payments;

  CustomerDetailResponse({
    required this.profile,
    required this.transactions,
    required this.payments,
  });

  factory CustomerDetailResponse.fromJson(Map<String, dynamic> json) {
    return CustomerDetailResponse(
      profile: CustomerModel.fromJson(json['profile']),
      transactions:
          (json['transactions'] as List?)
              ?.map((e) => CustomerTransactionItem.fromJson(e))
              .toList() ??
          [],
      payments:
          (json['payments'] as List?)
              ?.map((e) => CustomerPaymentItem.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class CustomerTransactionItem {
  final String id;
  final String date;
  final double totalAmount;
  final double finalAmount;
  final String? note;
  // Items listesi karmaşık olduğu için şimdilik dynamic bırakabilir veya özel model yazabiliriz.
  // Basit gösterim için ürün adlarını birleştirip gösterebiliriz.
  final List<dynamic> items;

  CustomerTransactionItem({
    required this.id,
    required this.date,
    required this.totalAmount,
    required this.finalAmount,
    this.note,
    required this.items,
  });

  factory CustomerTransactionItem.fromJson(Map<String, dynamic> json) {
    return CustomerTransactionItem(
      id: json['transaction_id'],
      date: json['transaction_date'] ?? '',
      totalAmount: _safeDouble(json['total_amount']),
      finalAmount: _safeDouble(json['final_amount']),
      note: json['note'],
      items: json['items'] ?? [],
    );
  }
}

class CustomerPaymentItem {
  final double amount;
  final String paymentMethod;
  final String description;
  final String date;
  final String? transactionId;

  CustomerPaymentItem({
    required this.amount,
    required this.paymentMethod,
    required this.description,
    required this.date,
    this.transactionId,
  });

  factory CustomerPaymentItem.fromJson(Map<String, dynamic> json) {
    return CustomerPaymentItem(
      amount: _safeDouble(json['amount']),
      paymentMethod: json['payment_method'] ?? 'Nakit',
      description: json['description'] ?? '',
      date: json['processed_at'] ?? '',
      transactionId: json['transaction_id'],
    );
  }
}

// Yardımcı Fonksiyon
double _safeDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is int) return value.toDouble();
  if (value is double) return value;
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}
