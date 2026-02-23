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

  // Gerekirse ileride buraya faturayı getirme (getHistory vs) eklenecek
}
