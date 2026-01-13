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

  // Geriye oluşturulan ürünü döndürüyoruz ki ID'sini alıp stok ekleyebilelim
  Future<Product> createProduct(
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

      final response = await _dio.post(
        ApiConstants.products,
        data: formData,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      // Backend response: { message: "...", product: {...} }
      return Product.fromJson(response.data['product']);
    } catch (e) {
      throw Exception("Ürün eklenirken hata oluştu: ${e.toString()}");
    }
  }

  // YENİ: Stok Ekleme Metodu
  Future<void> addStock({
    required String productId,
    required double quantity,
    required DateTime expirationDate,
    String? batchNo,
  }) async {
    try {
      final token = await _storage.read(key: 'auth_token');

      await _dio.post(
        '${ApiConstants.products}/$productId/stocks',
        data: {
          "quantity": quantity,
          "expiration_date": expirationDate.toIso8601String(),
          "batch_no": batchNo,
          "location": "Depo 1", // Varsayılan konum
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
    } catch (e) {
      throw Exception("Stok eklenirken hata: $e");
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

  // --- VETILAC & STOK EKSTRALARI ---

  // İlaç Arama (Autocomplete için)
  Future<List<Map<String, dynamic>>> searchVetilac(String query) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      final response = await _dio.get(
        '${ApiConstants.baseUrl}/vetilac/search',
        queryParameters: {'q': query},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      return []; // Hata durumunda boş liste dön, akışı bozma
    }
  }

  // İlaç Detayı Getir
  Future<Map<String, dynamic>?> getVetilacDetails(String id) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      final response = await _dio.get(
        '${ApiConstants.baseUrl}/vetilac/$id',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } catch (e) {
      return null;
    }
  }

  // Ürünün Stok Geçmişini Getir
  Future<List<dynamic>> getProductStocks(String productId) async {
    final token = await _storage.read(key: 'auth_token');
    final response = await _dio.get(
      '${ApiConstants.products}/$productId/stocks',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return response.data;
  }
}
