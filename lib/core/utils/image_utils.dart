import '../constants/api_constants.dart';

class ImageUtils {
  /// Ürün görsel URL oluşturur
  static String? getImageUrl(String? path, String? fullUrl) {
    if (fullUrl != null && fullUrl.isNotEmpty) {
      return fullUrl;
    }

    if (path != null && path.isNotEmpty) {
      if (path.startsWith('http')) {
        return path;
      }

      final baseUrl = ApiConstants.baseUrlImage;
      final normalizedPath = path.startsWith('/') ? path : '/$path';

      return '$baseUrl$normalizedPath';
    }

    return null;
  }
}
