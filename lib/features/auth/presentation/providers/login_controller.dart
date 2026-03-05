import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../domain/usecases/login_usecase.dart';
import '../providers/auth_controller.dart';

final loginUseCaseProvider = Provider(
  (ref) => LoginUseCase(ref.read(authRepositoryProvider)),
);

final loginControllerProvider =
    StateNotifierProvider<LoginController, AsyncValue<void>>((ref) {
      return LoginController(ref.read(loginUseCaseProvider), ref);
    });

class LoginController extends StateNotifier<AsyncValue<void>> {
  final LoginUseCase _login;
  final Ref _ref;

  LoginController(this._login, this._ref) : super(const AsyncValue.data(null));

  Future<void> login({
    required String identifier,
    required String password,
    required String deviceName,
  }) async {
    state = const AsyncValue.loading();
    try {
      final (user, tokens) = await _login.call(
        identifier: identifier,
        password: password,
        deviceName: deviceName,
      );
      _ref.read(authControllerProvider.notifier).setAuthenticated(user);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
