import '../repositories/auth_repository.dart';

class ResetPasswordUseCase {
  final AuthRepository repository;
  ResetPasswordUseCase(this.repository);

  Future<void> call({
    required String token,
    required String newPassword,
  }) {
    return repository.resetPassword(token: token, newPassword: newPassword);
  }
}
