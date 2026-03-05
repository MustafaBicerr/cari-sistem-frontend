import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../domain/models/product.dart';

class ProductRepository {
  final ApiClient _apiClient;

  ProductRepository(this._apiClient);

  Future<List<Product>> getProducts() async {
    try {
      debugPrint(
        '[PRODUCT DEBUG][REPOSITORY] Requesting products\n'
        'Endpoint: ${ApiConstants.products}\n'
        'Headers: Authorization: Bearer [token]\n'
        'Token type: JWT access_token',
      );

      final response = await _apiClient.dio.get(ApiConstants.products);

      debugPrint(
        '[PRODUCT DEBUG][REPOSITORY] Response received\n'
        'Status code: ${response.statusCode}\n'
        'Response type: ${response.data.runtimeType}\n'
        'Raw data length: ${(response.data as List?)?.length ?? 0}',
      );

      final List data = response.data;
      final products = data.map((e) => Product.fromJson(e)).toList();

      debugPrint(
        '[PRODUCT DEBUG][REPOSITORY] Parsing complete\n'
        'Parsed list length: ${products.length}',
      );

      return products;
    } catch (e) {
      debugPrint(
        '[PRODUCT DEBUG][REPOSITORY] ERROR\n'
        'Exception: $e',
      );
      throw Exception("Ürünler yüklenemedi: $e");
    }
  }

  Future<Product> createProduct(
    Map<String, dynamic> productData, {
    XFile? imageFile,
  }) async {
    try {
      debugPrint(
        '[PRODUCT DEBUG][REPOSITORY] createProduct called\n'
        'Product name: ${productData['name']}\n'
        'Barcode: ${productData['barcode']}\n'
        'Has image: ${imageFile != null}',
      );

      final dataMap = Map<String, dynamic>.from(productData);

      // 🔥 MUCİZE BURADA: Map olan local_details'i güvenli bir JSON String'e çeviriyoruz
      if (dataMap['local_details'] != null) {
        dataMap['local_details'] = jsonEncode(dataMap['local_details']);
      }

      if (imageFile != null) {
        final bytes = await imageFile.readAsBytes();
        dataMap['image'] = MultipartFile.fromBytes(
          bytes,
          filename: imageFile.name,
        );
      }

      final formData = FormData.fromMap(dataMap);

      final response = await _apiClient.dio.post(
        ApiConstants.products,
        data: formData,
      );

      debugPrint(
        '[PRODUCT DEBUG][REPOSITORY] createProduct response received\n'
        'Status: ${response.statusCode}\n'
        'Product created: ${response.data['product']?['id']}',
      );

      return Product.fromJson(response.data['product']);
    } catch (e) {
      debugPrint(
        '[PRODUCT DEBUG][REPOSITORY] createProduct ERROR\n'
        'Exception: $e',
      );
      throw Exception("Ürün eklenirken hata oluştu: ${e.toString()}");
    }
  }

  Future<void> addStock({
    required String productId,
    required double quantity,
    required DateTime expirationDate,
    String? batchNo,
  }) async {
    try {
      await _apiClient.dio.post(
        '${ApiConstants.products}/$productId/stocks',
        data: {
          "quantity": quantity,
          "expiration_date": expirationDate.toIso8601String(),
          "batch_no": batchNo,
          "location": "Depo 1",
        },
      );
    } catch (e) {
      throw Exception("Stok eklenirken hata: $e");
    }
  }

  Future<void> deleteProduct(String id) async {
    try {
      await _apiClient.dio.delete('${ApiConstants.products}/$id');
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
      debugPrint(
        '[PRODUCT DEBUG][REPOSITORY] updateProduct called\n'
        'Product ID: $id\n'
        'Updates: ${updates.keys.join(', ')}\n'
        'Has image: ${imageFile != null}',
      );

      final dataMap = Map<String, dynamic>.from(updates);

      // 🔥 AYNI ZIRH BURADA DA GEÇERLİ
      if (dataMap['local_details'] != null) {
        dataMap['local_details'] = jsonEncode(dataMap['local_details']);
      }

      if (imageFile != null) {
        final bytes = await imageFile.readAsBytes();
        dataMap['image'] = MultipartFile.fromBytes(
          bytes,
          filename: imageFile.name,
        );
      }

      final formData = FormData.fromMap(dataMap);

      await _apiClient.dio.put('${ApiConstants.products}/$id', data: formData);
    } catch (e) {
      throw Exception("Ürün güncellenirken hata oluştu: $e");
    }
  }

  // --- VETILAC & STOK EKSTRALARI ---

  // İlaç Arama (Autocomplete için)
  Future<List<Map<String, dynamic>>> searchVetilac(String query) async {
    try {
      final response = await _apiClient.dio.get(
        '/vetilac/search',
        queryParameters: {'q': query},
      );
      return List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      return []; // Hata durumunda boş liste dön, akışı bozma
    }
  }

  // İlaç Detayı Getir
  Future<Map<String, dynamic>?> getVetilacDetails(String id) async {
    try {
      final response = await _apiClient.dio.get('/vetilac/$id');
      return response.data;
    } catch (e) {
      return null;
    }
  }

  // Ürünün Stok Geçmişini Getir
  Future<List<dynamic>> getProductStocks(String productId) async {
    final response = await _apiClient.dio.get(
      '${ApiConstants.products}/$productId/stocks',
    );
    return response.data;
  }
}
