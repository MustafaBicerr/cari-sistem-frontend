class OpeningStockItemEntity {
  final String productId;
  final String productName;
  final String? imageUrl;
  final String productSource; // local | global
  final double quantity;
  final DateTime expirationDate;
  final String? batchNo;
  final String? location;
  final double buyingPrice;
  final double sellingPrice;
  final int vatRate;

  const OpeningStockItemEntity({
    required this.productId,
    required this.productName,
    this.imageUrl,
    required this.productSource,
    required this.quantity,
    required this.expirationDate,
    this.batchNo,
    this.location,
    required this.buyingPrice,
    required this.sellingPrice,
    required this.vatRate,
  });

  Map<String, dynamic> toJson() {
    print("DEBUG toJson - Item: $productName");
    print("  quantity: $quantity (type: ${quantity.runtimeType})");
    print("  buyingPrice: $buyingPrice (type: ${buyingPrice.runtimeType})");
    print("  sellingPrice: $sellingPrice (type: ${sellingPrice.runtimeType})");
    print("  vatRate: $vatRate (type: ${vatRate.runtimeType})");

    // Format expiration_date as YYYY-MM-DD
    final expirationDateStr =
        "${expirationDate.year.toString().padLeft(4, '0')}-${expirationDate.month.toString().padLeft(2, '0')}-${expirationDate.day.toString().padLeft(2, '0')}";

    return {
      "product_id": productId,
      "product_source": productSource,
      "quantity": quantity.toDouble(),
      "expiration_date": expirationDateStr,
    };
  }

  /// Returns a new instance with any provided fields replaced.
  OpeningStockItemEntity copyWith({
    String? productId,
    String? productName,
    String? imageUrl,
    String? productSource,
    double? quantity,
    DateTime? expirationDate,
    String? batchNo,
    String? location,
    double? buyingPrice,
    double? sellingPrice,
    int? vatRate,
  }) {
    // Ensure all double fields are actually doubles
    double finalQuantity = quantity ?? this.quantity;
    if (finalQuantity is! double) {
      print("DEBUG: Converting quantity to double: $finalQuantity");
      finalQuantity = double.tryParse(finalQuantity.toString()) ?? 0.0;
    }

    double finalBuyingPrice = buyingPrice ?? this.buyingPrice;
    if (finalBuyingPrice is! double) {
      print("DEBUG: Converting buyingPrice to double: $finalBuyingPrice");
      finalBuyingPrice = double.tryParse(finalBuyingPrice.toString()) ?? 0.0;
    }

    double finalSellingPrice = sellingPrice ?? this.sellingPrice;
    if (finalSellingPrice is! double) {
      print("DEBUG: Converting sellingPrice to double: $finalSellingPrice");
      finalSellingPrice = double.tryParse(finalSellingPrice.toString()) ?? 0.0;
    }

    // Ensure vatRate is always an int
    int finalVatRate = vatRate ?? this.vatRate;
    if (finalVatRate is! int) {
      print(
        "DEBUG: WARNING - vatRate is not int, it's ${finalVatRate.runtimeType}",
      );
      finalVatRate = int.tryParse(finalVatRate.toString()) ?? 0;
    }

    return OpeningStockItemEntity(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      imageUrl: imageUrl ?? this.imageUrl,
      productSource: productSource ?? this.productSource,
      quantity: finalQuantity,
      expirationDate: expirationDate ?? this.expirationDate,
      batchNo: batchNo ?? this.batchNo,
      location: location ?? this.location,
      buyingPrice: finalBuyingPrice,
      sellingPrice: finalSellingPrice,
      vatRate: finalVatRate,
    );
  }
}
