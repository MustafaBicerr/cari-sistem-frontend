class Product {
  final String id;
  final String name;
  final String? barcode;
  final double sellPrice;
  final String? normalizedName;
  final double buyPrice;
  final double currentStock;
  final int lowStockLimit;
  final int taxRate;
  final String unitType;
  final String? imageUrl;

  Product({
    required this.id,
    required this.name,
    this.barcode,
    this.normalizedName,
    required this.sellPrice,
    required this.buyPrice,
    required this.currentStock,
    required this.lowStockLimit,
    this.taxRate = 0,
    this.unitType = 'PIECE',
    this.imageUrl,
  });

  // JSON'dan Nesneye Çevirme (Factory Constructor)
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] ?? '',
      name: json['name'] ?? 'İsimsiz Ürün',
      normalizedName: json['normalized_name'],
      barcode: json['barcode'],
      // Backend sayıları bazen String bazen Number gönderebilir, garantiye alalım:
      sellPrice: double.tryParse(json['sell_price'].toString()) ?? 0.0,
      buyPrice: double.tryParse(json['buy_price'].toString()) ?? 0.0,
      currentStock: double.tryParse(json['current_stock'].toString()) ?? 0.0,
      lowStockLimit: int.tryParse(json['low_stock_limit'].toString()) ?? 10,
      taxRate: int.tryParse(json['tax_rate'].toString()) ?? 0,
      unitType: json['unit_type'] ?? 'PIECE',
      imageUrl: json['full_image_url'] ?? json['image_url'],
    );
  }
}
