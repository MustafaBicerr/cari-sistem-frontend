import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/image_utils.dart';
import '../../domain/models/product.dart';
import 'product_form_dialog.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final bool isPosMode; // 🔥 YENİ: Satış ekranında mı?
  final VoidCallback? onAddToCart; // 🔥 YENİ: Sepete ekleme aksiyonu

  const ProductCard({
    super.key,
    required this.product,
    this.isPosMode = false,
    this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    debugPrint(
      '[PRODUCT DEBUG][CARD] ProductCard rendering\n'
      'Product: ${product.name}\n'
      'ID: ${product.id}\n'
      'Price: ${product.sellingPrice}',
    );

    final imageUrl = ImageUtils.getImageUrl(
      product.customImagePath,
      product.fullImageUrl,
    );

    return RepaintBoundary(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                isPosMode
                    ? AppColors.primary.withOpacity(
                      0.3,
                    ) // POS modunda çerçeve daha belirgin
                    : const Color(0x1A9E9E9E),
            width: isPosMode ? 1.5 : 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x08000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. RESİM ALANI (Tıklanınca aksiyon)
            Expanded(
              flex: 3,
              child: InkWell(
                onTap:
                    isPosMode
                        ? onAddToCart
                        : null, // POS'ta resme tıklayınca da ekle
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child:
                        imageUrl != null
                            ? CachedNetworkImage(
                              imageUrl: imageUrl,
                              fit: BoxFit.cover,
                              memCacheHeight: 300,
                              memCacheWidth: 300,
                              placeholder:
                                  (context, url) => Shimmer.fromColors(
                                    baseColor: const Color(0xFFE0E0E0),
                                    highlightColor: const Color(0xFFF5F5F5),
                                    child: Container(color: Colors.white),
                                  ),
                              errorWidget:
                                  (context, url, error) => const Center(
                                    child: Icon(
                                      Icons.image_not_supported_outlined,
                                      color: Color(0x4D2196F3),
                                    ),
                                  ),
                            )
                            : const Center(
                              child: Icon(
                                Icons.inventory_2_outlined,
                                size: 48,
                                color: Color(0x4D2196F3),
                              ),
                            ),
                  ),
                ),
              ),
            ),

            // 2. BİLGİ ALANI
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Stok Durumu
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color:
                                product.stockQuantity <
                                        product.criticalStockLevel
                                    ? AppColors.error.withOpacity(0.1)
                                    : AppColors.success.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            "Stok: ${product.stockQuantity.toInt()}",
                            style: TextStyle(
                              fontSize: 10,
                              color:
                                  product.stockQuantity <
                                          product.criticalStockLevel
                                      ? AppColors.error
                                      : AppColors.success,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "₺${product.sellingPrice}",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppColors.primary,
                          ),
                        ),
                        // 🔥 MODA GÖRE BUTON DEĞİŞİMİ
                        InkWell(
                          onTap:
                              isPosMode
                                  ? onAddToCart
                                  : () {
                                    showDialog(
                                      context: context,
                                      builder:
                                          (context) => ProductFormDialog(
                                            product: product,
                                          ),
                                    );
                                  },
                          child: Container(
                            padding: const EdgeInsets.all(
                              8,
                            ), // Dokunma alanı büyüdü
                            decoration: BoxDecoration(
                              color:
                                  isPosMode
                                      ? AppColors.success
                                      : const Color(0x1A2196F3),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isPosMode
                                  ? Icons.add_shopping_cart
                                  : Icons.edit, // İkon değişti
                              color:
                                  isPosMode ? Colors.white : AppColors.primary,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
