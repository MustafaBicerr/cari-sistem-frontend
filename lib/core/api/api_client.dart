import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/api_constants.dart';

// 👇 İŞTE BU EKSİKTİ: ApiClient'ı uygulamaya sunan Provider
final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

class ApiClient {
  final Dio _dio;
  final FlutterSecureStorage _storage;

  /// Called when refresh token fails (e.g. expired). App should clear auth state and redirect to login.
  void Function()? onSessionExpired;

  /// Lock so only one refresh runs when multiple requests get 401.
  Future<bool>? _refreshFuture;

  ApiClient()
    : _dio = Dio(
        BaseOptions(
          baseUrl: ApiConstants.baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          headers: {'Content-Type': 'application/json'},
        ),
      ),
      _storage = const FlutterSecureStorage() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: 'access_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          if (e.response?.statusCode != 401) {
            return handler.next(e);
          }

          final refreshToken = await _storage.read(key: 'refresh_token');
          if (refreshToken == null || refreshToken.isEmpty) {
            await _clearTokens();
            onSessionExpired?.call();
            return handler.next(e);
          }

          try {
            final ok = await _refreshToken(refreshToken);
            if (ok) {
              final opts = e.requestOptions;
              opts.headers['Authorization'] =
                  'Bearer ${await _storage.read(key: 'access_token')}';
              final response = await _dio.fetch(opts);
              return handler.resolve(response);
            }
          } catch (_) {}

          await _clearTokens();
          onSessionExpired?.call();
          return handler.next(e);
        },
      ),
    );
  }

  Future<bool> _refreshToken(String refreshToken) async {
    if (_refreshFuture != null) {
      return _refreshFuture!;
    }
    _refreshFuture = _doRefresh(refreshToken);
    try {
      final result = await _refreshFuture!;
      return result;
    } finally {
      _refreshFuture = null;
    }
  }

  Future<bool> _doRefresh(String refreshToken) async {
    final dio = Dio(BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ));
    final response = await dio.post<Map<String, dynamic>>(
      ApiConstants.refresh,
      data: {'refresh_token': refreshToken},
    );
    if (response.statusCode != 200 || response.data == null) {
      return false;
    }
    final access = response.data!['access_token']?.toString();
    final refresh = response.data!['refresh_token']?.toString();
    if (access == null || refresh == null) {
      return false;
    }
    await _storage.write(key: 'access_token', value: access);
    await _storage.write(key: 'refresh_token', value: refresh);
    return true;
  }

  Future<void> _clearTokens() async {
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
  }

  Dio get dio => _dio;
  FlutterSecureStorage get storage => _storage;
}
