import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/product_repository.dart';
import '../../domain/models/product.dart';

final productRepositoryProvider = Provider((ref) => ProductRepository());

// UI'ın dinleyeceği asıl liste sağlayıcısı
final productListProvider = FutureProvider.autoDispose<List<Product>>((
  ref,
) async {
  final repo = ref.read(productRepositoryProvider);
  return repo.getProducts();
});
