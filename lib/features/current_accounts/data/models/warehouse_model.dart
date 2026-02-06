class WarehouseModel {
  final String name;
  final String? city;
  final String? district;
  final String? licenseNo;
  final String? manager;
  final String? address;
  final String? warehouseType;

  WarehouseModel({
    required this.name,
    this.city,
    this.district,
    this.licenseNo,
    this.manager,
    this.address,
    this.warehouseType,
  });

  factory WarehouseModel.fromJson(Map<String, dynamic> json) {
    return WarehouseModel(
      name: json['name'] ?? '',
      city: json['city'],
      district: json['district'],
      licenseNo: json['license_no'],
      manager: json['manager'],
      address: json['address'],
      warehouseType: json['warehouse_type'],
    );
  }
}
