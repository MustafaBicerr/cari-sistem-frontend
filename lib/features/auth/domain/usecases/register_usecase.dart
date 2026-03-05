import '../repositories/auth_repository.dart';
import '../entities/auth_tokens.dart';
import '../entities/user.dart';

class RegisterUseCase {
  final AuthRepository repository;
  RegisterUseCase(this.repository);

  Future<(User, AuthTokens)> call({
    required String clinicName,
    required String fullName,
    required String phone,
    required String email,
    required String password,
  }) {
    return repository.register(
      clinicName: clinicName,
      fullName: fullName,
      phone: phone,
      email: email,
      password: password,
    );
  }
}
