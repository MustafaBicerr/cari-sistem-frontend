import '../repositories/auth_repository.dart';

class LogoutUseCase {
  final AuthRepository repository;
  LogoutUseCase(this.repository);

  Future<void> call(String refreshToken) {
    return repository.logout(refreshToken);
  }
}
