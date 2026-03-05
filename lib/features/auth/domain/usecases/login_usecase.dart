import '../repositories/auth_repository.dart';
import '../entities/auth_tokens.dart';
import '../entities/user.dart';

class LoginUseCase {
  final AuthRepository repository;
  LoginUseCase(this.repository);

  Future<(User, AuthTokens)> call({
    required String identifier,
    required String password,
    required String deviceName,
  }) {
    return repository.login(
      identifier: identifier,
      password: password,
      deviceName: deviceName,
    );
  }
}
