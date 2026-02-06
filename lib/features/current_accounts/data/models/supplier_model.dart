class SupplierModel {
  final String id;
  final String name;
  final String? contactPerson;
  final String? phone;
  final String? email;
  final String? taxNumber;
  final String? taxOffice;
  final String? address;
  final String? iban;
  final String? city;
  final String? district;
  final String? licenseNo;
  final String? manager;
  final String? warehouseType;
  final double currentBalance;

  SupplierModel({
    required this.id,
    required this.name,
    this.contactPerson,
    this.phone,
    this.email,
    this.taxNumber,
    this.taxOffice,
    this.address,
    this.iban,
    this.city,
    this.district,
    this.licenseNo,
    this.manager,
    this.warehouseType,
    required this.currentBalance,
  });

  factory SupplierModel.fromJson(Map<String, dynamic> json) {
    return SupplierModel(
      id: json['id'],
      name: json['name'] ?? 'İsimsiz Tedarikçi',
      contactPerson: json['contact_person'],
      phone: json['phone'],
      email: json['email'],
      taxNumber: json['tax_number'],
      taxOffice: json['tax_office'],
      address: json['address'],
      iban: json['iban'],
      city: json['city'],
      district: json['district'],
      licenseNo: json['license_no'],
      manager: json['manager'],
      warehouseType: json['warehouse_type'],
      currentBalance: _safeDouble(json['current_balance']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'contact_person': contactPerson,
      'phone': phone,
      'email': email,
      'tax_number': taxNumber,
      'tax_office': taxOffice,
      'address': address,
      'iban': iban,
      'city': city,
      'district': district,
      'license_no': licenseNo,
      'manager': manager,
      'warehouse_type': warehouseType,
    };
  }
}

// ---------------------------------------------------------
// DETAY SAYFASI İÇİN MODEL (Profil + Geçmiş)
// Backend, supplier objesi içine 'history' array'i ekleyip yolluyor.
// ---------------------------------------------------------
class SupplierDetailResponse {
  final SupplierModel profile;
  final List<SupplierHistoryItem> history;

  SupplierDetailResponse({required this.profile, required this.history});

  factory SupplierDetailResponse.fromJson(Map<String, dynamic> json) {
    return SupplierDetailResponse(
      // Profil verisi ana objenin kendisi
      profile: SupplierModel.fromJson(json),
      history:
          (json['history'] as List?)
              ?.map((e) => SupplierHistoryItem.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class SupplierHistoryItem {
  final String id;
  final double initialAmount;
  final double remainingAmount;
  final String status;
  final String date;
  final String dueDate;
  final String type; // 'DEBT'
  final String description; // Fatura No veya Manuel Kayıt

  SupplierHistoryItem({
    required this.id,
    required this.initialAmount,
    required this.remainingAmount,
    required this.status,
    required this.date,
    required this.dueDate,
    required this.type,
    required this.description,
  });

  factory SupplierHistoryItem.fromJson(Map<String, dynamic> json) {
    return SupplierHistoryItem(
      id: json['debt_id'],
      initialAmount: _safeDouble(json['initial_amount']),
      remainingAmount: _safeDouble(json['remaining_amount']),
      status: json['status'] ?? '',
      date: json['created_at'] ?? '',
      dueDate: json['due_date'] ?? '',
      type: json['type'] ?? '',
      description: json['description'] ?? '',
    );
  }
}

double _safeDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is int) return value.toDouble();
  if (value is double) return value;
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}
