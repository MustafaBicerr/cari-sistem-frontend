import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/api/api_client.dart';
import '../../data/product_repository.dart';
import '../../domain/models/product.dart';

// final productRepositoryProvider = Provider((ref) => ProductRepository());
final productRepositoryProvider = Provider((ref) {
  final apiClient = ref.read(apiClientProvider);
  return ProductRepository(apiClient);
});

// UI'ın dinleyeceği asıl liste sağlayıcısı
final productListProvider = FutureProvider.autoDispose<List<Product>>((
  ref,
) async {
  debugPrint('[PRODUCT DEBUG][PROVIDER] Loading product list');
  final repo = ref.read(productRepositoryProvider);
  final products = await repo.getProducts();
  debugPrint(
    '[PRODUCT DEBUG][PROVIDER] Repository returned\n'
    'Item count: ${products.length}',
  );
  return products;
});
