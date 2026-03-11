import '../constants/api_constants.dart';

class ImageUtils {
  /// Ürün görsel URL oluşturur
  static String? getImageUrl(String? path, String? fullUrl) {
    // 1) Önce relative path'e göre URL üretelim.
    // Böylece backend'in döndürdüğü full_url'de "localhost" olsa bile
    // Android emülatörde doğru host (10.0.2.2) kullanılabilir.
    if (path != null && path.isNotEmpty) {
      if (path.startsWith('http')) {
        return path;
      }

      final baseUrl = ApiConstants.baseUrlImage;
      final normalizedPath = path.startsWith('/') ? path : '/$path';

      return '$baseUrl$normalizedPath';
    }

    // 2) Path yoksa, fullUrl'i olduğu gibi dön.
    if (fullUrl != null && fullUrl.isNotEmpty) {
      return fullUrl;
    }

    return null;
  }
}
