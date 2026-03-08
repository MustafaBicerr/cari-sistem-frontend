import 'package:mobile/core/api/api_client.dart';

class ProductSearchService {
  /// Local + Global ürünleri birlikte arar
  static Future<List<Map<String, dynamic>>> searchCombinedProducts({
    required String query,
    required List<dynamic> localProducts,
    required ApiClient apiClient,
  }) async {
    if (query.trim().isEmpty) return [];

    final lowerQuery = query.toLowerCase();

    // ---------------------------
    // LOCAL SEARCH
    // ---------------------------
    final localMatches =
        localProducts
            .where((p) {
              final name = (p.name ?? '').toString().toLowerCase();
              final barcode = (p.barcode ?? '').toString().toLowerCase();

              return name.contains(lowerQuery) || barcode.contains(lowerQuery);
            })
            .map((p) {
              return {
                "id": p.id,
                "name": p.name,
                "barcode": p.barcode,
                "source": "local",
                "product": p,
              };
            })
            .toList();

    // ---------------------------
    // GLOBAL SEARCH (API)
    // ---------------------------
    List<Map<String, dynamic>> globalMatches = [];

    try {
      final response = await apiClient.dio.get(
        "/products/global-search",
        queryParameters: {"q": query},
      );

      final data = response.data;

      if (data is List) {
        globalMatches =
            data.map<Map<String, dynamic>>((p) {
              return {
                "id": p["id"],
                "name": p["name"] ?? p["raw_name"],
                "barcode": p["barcode"],
                "source": "global",
                "product": p,
              };
            }).toList();
      }
    } catch (_) {
      // global search başarısız olsa bile local sonuçları döndür
    }

    // ---------------------------
    // MERGE
    // ---------------------------
    final results = [...localMatches, ...globalMatches];

    return results;
  }
}
