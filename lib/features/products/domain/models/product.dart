class Product {
  final String id;
  final String name;
  final String? barcode;
  final String? normalizedName;
  final double sellingPrice; // sell_price -> selling_price
  final double buyingPrice; // buy_price -> buying_price
  final double stockQuantity; // current_stock -> stock_quantity
  final double criticalStockLevel; // low_stock_limit -> critical_stock_level
  final int vatRate; // tax_rate -> vat_rate
  final String currency; // YENİ
  final String unitType;
  final String? customImagePath; // image_url -> custom_image_path
  final String? fullImageUrl; // Backend'den gelen tam URL
  final Map<String, dynamic>? localDetails; // attributes -> local_details
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Product({
    required this.id,
    required this.name,
    this.barcode,
    this.normalizedName,
    required this.sellingPrice,
    required this.buyingPrice,
    required this.stockQuantity,
    required this.criticalStockLevel,
    this.vatRate = 20,
    this.currency = 'TRY',
    this.unitType = 'PIECE',
    this.customImagePath,
    this.fullImageUrl,
    this.localDetails,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  // Vetilac verilerine kolay erişim için getter'lar
  String? get prospectus => localDetails?['prospectus'];
  List<dynamic>? get relatedDrugs => localDetails?['related_drugs'];
  Map<String, dynamic>? get drugDetails => localDetails?['details'];

  // JSON'dan Nesneye Çevirme (Factory Constructor)
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] ?? '',
      name: json['name'] ?? 'İsimsiz Ürün',
      normalizedName: json['normalized_name'],
      barcode: json['barcode'],
      // Backend sayıları bazen String bazen Number gönderebilir, garantiye alalım:
      sellingPrice: double.tryParse(json['selling_price'].toString()) ?? 0.0,
      buyingPrice: double.tryParse(json['buying_price'].toString()) ?? 0.0,
      stockQuantity: double.tryParse(json['stock_quantity'].toString()) ?? 0.0,
      criticalStockLevel:
          double.tryParse(json['critical_stock_level'].toString()) ?? 10.0,
      vatRate: int.tryParse(json['vat_rate'].toString()) ?? 20,
      currency: json['currency'] ?? 'TRY',
      unitType: json['unit_type'] ?? 'PIECE',
      customImagePath: json['custom_image_path'],
      fullImageUrl: json['full_image_url'],
      localDetails:
          json['local_details'] != null
              ? Map<String, dynamic>.from(json['local_details'])
              : null,
      isActive: json['is_active'] ?? true,
      createdAt:
          json['created_at'] != null
              ? DateTime.tryParse(json['created_at'].toString())
              : null,
      updatedAt:
          json['updated_at'] != null
              ? DateTime.tryParse(json['updated_at'].toString())
              : null,
    );
  }
}
