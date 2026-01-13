import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart'; // PAKET EKLENDİ
import '../../../../core/constants/api_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/product.dart';
import 'product_form_dialog.dart';

class ProductCard extends StatelessWidget {
  final Product product;

  const ProductCard({super.key, required this.product});

  String _getImageUrl(String path) {
    if (path.startsWith('http')) return path;
    final baseUrl = ApiConstants.baseUrl
        .replaceAll('/api', '')
        .replaceAll(RegExp(r'/$'), '');
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return '$baseUrl$normalizedPath';
  }

  @override
  Widget build(BuildContext context) {
    // RepaintBoundary: GPU Cache (Aynen koruyoruz)
    return RepaintBoundary(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0x1A9E9E9E)),
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
            // 1. RESİM ALANI (Skeleton Burada Çalışacak)
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: AppColors.background, // Resim yokken zemin rengi
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child:
                      product.fullImageUrl != null
                          ? CachedNetworkImage(
                            imageUrl: _getImageUrl(product.fullImageUrl!),
                            fit: BoxFit.cover,
                            memCacheHeight: 300,
                            memCacheWidth: 300,
                            fadeInDuration: const Duration(
                              milliseconds: 200,
                            ), // Yumuşak geçiş
                            // İŞTE SİHİR BURADA: Placeholder (Yüklenirken Gösterilecek)
                            placeholder:
                                (context, url) => Shimmer.fromColors(
                                  baseColor: const Color(0xFFE0E0E0), // Gri
                                  highlightColor: const Color(
                                    0xFFF5F5F5,
                                  ), // Parlayan Beyaz
                                  child: Container(color: Colors.white),
                                ),

                            // Hata Durumu (İkon göster)
                            errorWidget:
                                (context, url, error) => const Center(
                                  child: Icon(
                                    Icons.image_not_supported_outlined,
                                    size: 32,
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

            // 2. BİLGİ ALANI (Metinler Anlık Gelir, Skeleton'a Gerek Yok)
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
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Stok: ${product.stockQuantity.toInt()}",
                          style: TextStyle(
                            fontSize: 12,
                            color:
                                product.stockQuantity <
                                        product.criticalStockLevel
                                    ? AppColors.error
                                    : AppColors.success,
                            fontWeight: FontWeight.w500,
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
                            fontSize: 18,
                            color: AppColors.primary,
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder:
                                  (context) =>
                                      ProductFormDialog(product: product),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Color(0x1A2196F3),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.edit,
                              color: AppColors.primary,
                              size: 20,
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
