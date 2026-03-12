import '../constants/api_constants.dart';

class ImageUtils {
  /// Bozuk URL'deki /.vetapp.com.tr/ veya /vetapp.com.tr/ segmentini kaldırır.
  static String _stripVetappDomainSegment(String urlOrPath) {
    return urlOrPath
        .replaceAll('/.vetapp.com.tr/', '/')
        .replaceAll('/vetapp.com.tr/', '/');
  }

  /// Ürün görsel URL oluşturur.
  /// Production panel'de path bazen ".vetapp.com.tr/public/..." veya tam URL
  /// "https://panel.../.vetapp.com.tr/public/..." şeklinde bozuk geliyor; bu düzeltilir.
  static String? getImageUrl(String? path, String? fullUrl) {
    String? candidate = path?.trim();
    if (candidate == null || candidate.isEmpty) {
      if (fullUrl != null && fullUrl.isNotEmpty) {
        candidate = fullUrl.trim();
      } else {
        return null;
      }
    }

    // Tam URL (http/https) gelmişse
    if (candidate.startsWith('http://') || candidate.startsWith('https://')) {
      if (candidate.contains('/.vetapp.com.tr/') ||
          candidate.contains('/vetapp.com.tr/')) {
        candidate = _stripVetappDomainSegment(candidate);
        final uri = Uri.parse(candidate);
        final pathOnly = uri.path.startsWith('/') ? uri.path : '/${uri.path}';
        return '${ApiConstants.baseUrlImage}$pathOnly';
      }
      return candidate;
    }

    // Relative path: başta domain benzeri segment varsa kırp (.vetapp.com.tr/ vb.)
    candidate = candidate.replaceFirst(RegExp(r'^[^/]+/'), '');
    if (!candidate.startsWith('/')) {
      candidate = '/$candidate';
    }

    final baseUrl = ApiConstants.baseUrlImage;
    return '$baseUrl$candidate';
  }
}
