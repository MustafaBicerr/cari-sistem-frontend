import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/api_constants.dart';
import '../domain/models/product.dart';

class ProductRepository {
  final Dio _dio = Dio(BaseOptions(baseUrl: ApiConstants.baseUrl));
  final _storage = const FlutterSecureStorage();

  Future<List<Product>> getProducts() async {
    try {
      final token = await _storage.read(key: 'auth_token');

      final response = await _dio.get(
        ApiConstants.products,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      // Gelen liste verisini tek tek Product modeline çeviriyoruz
      final List data = response.data;
      return data.map((e) => Product.fromJson(e)).toList();
    } catch (e) {
      throw Exception("Ürünler yüklenemedi: $e");
    }
  }

  // ... getProducts fonksiyonunun altı ...

  Future<void> createProduct(
    Map<String, dynamic> productData, {
    XFile? imageFile,
  }) async {
    try {
      final token = await _storage.read(key: 'auth_token');

      final dataMap = Map<String, dynamic>.from(productData);

      if (imageFile != null) {
        final bytes = await imageFile.readAsBytes();
        dataMap['image'] = MultipartFile.fromBytes(
          bytes,
          filename: imageFile.name,
        );
      }

      final formData = FormData.fromMap(dataMap);

      await _dio.post(
        ApiConstants.products,
        data: formData,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      // Başarılı olursa void döner, hata varsa catch yakalar.
    } catch (e) {
      throw Exception("Ürün eklenirken hata oluştu: ${e.toString()}");
    }
  }

  Future<void> deleteProduct(String id) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      await _dio.delete(
        '${ApiConstants.products}/$id',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
    } catch (e) {
      throw Exception("Ürün silinirken hata oluştu: $e");
    }
  }

  Future<void> updateProduct({
    required String id,
    required Map<String, dynamic> updates,
    XFile? imageFile,
  }) async {
    try {
      final token = await _storage.read(key: 'auth_token');

      final dataMap = Map<String, dynamic>.from(updates);

      if (imageFile != null) {
        final bytes = await imageFile.readAsBytes();
        dataMap['image'] = MultipartFile.fromBytes(
          bytes,
          filename: imageFile.name,
        );
      }

      final formData = FormData.fromMap(dataMap);

      await _dio.put(
        '${ApiConstants.products}/$id',
        data: formData,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
    } catch (e) {
      throw Exception("Ürün güncellenirken hata oluştu: $e");
    }
  }
}
