import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_client.dart'; // ApiClient Provider'ı buradan alıyoruz
import '../../data/auth_repository.dart';
import 'login_state_provider.dart';

// 👇 DÜZELTME: Repository artık ApiClient'tan besleniyor
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthRepository(dio: apiClient.dio, storage: apiClient.storage);
});

final authControllerProvider = Provider((ref) {
  return AuthController(ref);
});

class AuthController {
  final Ref _ref;

  AuthController(this._ref);

  Future<void> login({
    required String username,
    required String password,
    required void Function() onSuccess,
    required void Function(String error) onError,
  }) async {
    _ref.read(isLoadingProvider.notifier).state = true;

    try {
      final repo = _ref.read(authRepositoryProvider);
      final success = await repo.login(username, password);

      if (success) {
        onSuccess();
      } else {
        onError("Giriş başarısız. Bilgileri kontrol edin.");
      }
    } catch (e) {
      onError(e.toString());
    } finally {
      _ref.read(isLoadingProvider.notifier).state = false;
    }
  }
}
