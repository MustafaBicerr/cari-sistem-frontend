import '../constants/api_constants.dart';

/// Production'da görsellerin servis edildiği sabit base (panel değil, API).
/// Nginx/ASSET_BASE_URL karışıklığında bile çıktıyı buna zorlamak için kullanılır.
const String _imageBaseAuthority = 'https://api.vetapp.com.tr';

class ImageUtils {
  /// Bozuk URL'deki /.vetapp.com.tr/ veya /vetapp.com.tr/ segmentini kaldırır.
  static String _stripVetappDomainSegment(String urlOrPath) {
    return urlOrPath
        .replaceAll('/.vetapp.com.tr/', '/')
        .replaceAll('/vetapp.com.tr/', '/');
  }

  /// Dönen URL panel host'u veya yinelenen domain segmenti içeriyorsa
  /// her zaman _imageBaseAuthority + path ile düzeltir (production için kesin çözüm).
  static String _normalizeOutputUrl(String url) {
    if (!url.contains('vetapp.com.tr')) return url;
    final needsFix = url.contains('panel.vetapp.com.tr') ||
        url.contains('/.vetapp.com.tr/') ||
        url.contains('/vetapp.com.tr/');
    if (!needsFix) return url;
    final stripped = _stripVetappDomainSegment(url);
    final uri = Uri.tryParse(stripped);
    if (uri == null) return url;
    String path = uri.path;
    if (path.isEmpty) path = '/';
    if (!path.startsWith('/')) path = '/$path';
    return '$_imageBaseAuthority$path';
  }

  /// Ürün görsel URL oluşturur.
  /// Production panel'de path bazen ".vetapp.com.tr/public/..." veya tam URL
  /// "https://panel.../.vetapp.com.tr/public/..." şeklinde bozuk geliyor; bu düzeltilir.
  /// Backend artık her zaman api.vetapp.com.tr ile full_image_url döndürüyor; önce onu kullan.
  static String? getImageUrl(String? path, String? fullUrl) {
    // Backend doğru tam URL gönderdiyse (api.vetapp.com.tr) direkt kullan – Docker/build farkına takılmayalım
    final trimmedFull = fullUrl?.trim();
    if (trimmedFull != null &&
        trimmedFull.isNotEmpty &&
        trimmedFull.startsWith('http') &&
        trimmedFull.contains('api.vetapp.com.tr') &&
        !trimmedFull.contains('/.vetapp.com.tr/') &&
        !trimmedFull.contains('/vetapp.com.tr/')) {
      return trimmedFull;
    }

    String? candidate = path?.trim();
    if (candidate == null || candidate.isEmpty) {
      if (trimmedFull != null && trimmedFull.isNotEmpty) {
        candidate = trimmedFull;
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
        return _normalizeOutputUrl('${ApiConstants.baseUrlImage}$pathOnly');
      }
      return _normalizeOutputUrl(candidate);
    }

    // Relative path: başta domain benzeri segment varsa kırp (.vetapp.com.tr/ vb.)
    candidate = candidate.replaceFirst(RegExp(r'^[^/]+/'), '');
    if (!candidate.startsWith('/')) {
      candidate = '/$candidate';
    }

    final baseUrl = ApiConstants.baseUrlImage;
    return _normalizeOutputUrl('$baseUrl$candidate');
  }
}
