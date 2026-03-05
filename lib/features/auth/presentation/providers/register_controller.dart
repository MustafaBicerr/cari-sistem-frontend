import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../domain/usecases/register_usecase.dart';
import '../providers/auth_controller.dart';

final registerUseCaseProvider = Provider(
  (ref) => RegisterUseCase(ref.read(authRepositoryProvider)),
);

final registerControllerProvider =
    StateNotifierProvider<RegisterController, AsyncValue<void>>((ref) {
      return RegisterController(ref.read(registerUseCaseProvider), ref);
    });

class RegisterController extends StateNotifier<AsyncValue<void>> {
  final RegisterUseCase _register;
  final Ref _ref;

  RegisterController(this._register, this._ref)
    : super(const AsyncValue.data(null));

  Future<void> register({
    required String clinicName,
    required String fullName,
    required String phone,
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    try {
      final (user, tokens) = await _register.call(
        clinicName: clinicName,
        fullName: fullName,
        phone: phone,
        email: email,
        password: password,
      );
      _ref.read(authControllerProvider.notifier).setAuthenticated(user);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
