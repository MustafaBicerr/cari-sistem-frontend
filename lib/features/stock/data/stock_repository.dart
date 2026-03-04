import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/constants/api_constants.dart';

class StockRepository {
  final Dio _dio = Dio(BaseOptions(baseUrl: ApiConstants.baseUrl));
  final _storage = const FlutterSecureStorage();

  // Fatura Kaydet (Mal Kabul)
  Future<Map<String, dynamic>> createPurchaseInvoice(
    Map<String, dynamic> payload,
  ) async {
    try {
      final token = await _storage.read(key: 'auth_token');

      final response = await _dio.post(
        '/stock/purchase', // Backend rotamız
        data: payload,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      return response.data; // { message: "...", invoice: {...} }
    } on DioException catch (e) {
      final errorMsg =
          e.response?.data?['error'] ??
          'Fatura kaydedilirken bağlantı hatası oluştu.';
      throw Exception(errorMsg);
    } catch (e) {
      throw Exception('Beklenmeyen bir hata oluştu: $e');
    }
  }

  // --- Yeni Tedarikçi Oluşturma (Pre-flight Creation) ---
  Future<Map<String, dynamic>> createSupplier(
    Map<String, dynamic> payload,
  ) async {
    try {
      final token = await _storage.read(key: 'auth_token');

      final response = await _dio.post(
        '/suppliers', // Backend'deki supplier route'umuz
        data: payload,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      return response
          .data; // Backend'in döndürdüğü yeni kayıtlı tedarikçi objesi
    } on DioException catch (e) {
      final errorMsg =
          e.response?.data?['error'] ?? 'Tedarikçi oluşturulurken hata oluştu.';
      throw Exception(errorMsg);
    } catch (e) {
      throw Exception('Beklenmeyen bir hata: $e');
    }
  }

  // Gerekirse ileride buraya faturayı getirme (getHistory vs) eklenecek

  // Opening Stock Oluştur (Klinik İlk Stok Girişi)
  Future<Map<String, dynamic>> createOpeningStock(
    Map<String, dynamic> payload,
  ) async {
    try {
      final token = await _storage.read(key: 'auth_token');

      print("DEBUG StockRepository: Sending POST to /stock/opening");
      try {
        print(
          "DEBUG StockRepository: Full URL: ${_dio.options.baseUrl}/stock/opening",
        );
      } catch (e) {
        // ignore
      }
      print("DEBUG StockRepository: Payload type: ${payload.runtimeType}");
      try {
        print("DEBUG StockRepository: Full payload: ${payload.toString()}");
      } catch (e) {
        print("DEBUG StockRepository: Failed to stringify payload: $e");
      }

      final response = await _dio.post(
        '/stock/opening', // Backend endpoint
        data: payload,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      print("DEBUG StockRepository: Response status: ${response.statusCode}");
      try {
        print(
          "DEBUG StockRepository: Response data type: ${response.data.runtimeType}",
        );
        print("DEBUG StockRepository: Response data: ${response.data}");
      } catch (e) {
        print("DEBUG StockRepository: Failed to print response data: $e");
      }

      return response.data; // { message: "...", entry: {...} }
    } on DioException catch (e) {
      // print("DEBUG StockRepository: DioException caught");
      // print("DEBUG StockRepository: Error status: ${e.response?.statusCode}");
      // print("DEBUG StockRepository: Error data: ${e.response?.data}");
      // print("DEBUG StockRepository: Error message: ${e.message}");

      final errorMsg =
          e.response?.data?['error'] ??
          'Opening stok oluşturulurken bağlantı hatası oluştu.';
      throw Exception(errorMsg);
    } catch (e) {
      print("DEBUG StockRepository: Unexpected error: $e");
      print("DEBUG StockRepository: Error type: ${e.runtimeType}");
      throw Exception('Beklenmeyen bir hata oluştu: $e');
    }
  }
}
