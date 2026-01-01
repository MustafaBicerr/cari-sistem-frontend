import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/auth_repository.dart';
import 'login_state_provider.dart';

final authRepositoryProvider = Provider((ref) => AuthRepository());

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
    // 1. Loading başlat
    _ref.read(isLoadingProvider.notifier).state = true;

    try {
      final repo = _ref.read(authRepositoryProvider);
      final success = await repo.login(username, password);

      if (success) {
        onSuccess(); // Sayfayı değiştir
      } else {
        onError("Giriş başarısız. Bilgileri kontrol edin.");
      }
    } catch (e) {
      onError(e.toString());
    } finally {
      // 2. Loading durdur
      _ref.read(isLoadingProvider.notifier).state = false;
    }
  }
}
