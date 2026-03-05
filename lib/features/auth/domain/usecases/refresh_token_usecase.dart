import '../repositories/auth_repository.dart';
import '../entities/auth_tokens.dart';

class RefreshTokenUseCase {
  final AuthRepository repository;
  RefreshTokenUseCase(this.repository);

  Future<AuthTokens> call(String refreshToken) {
    return repository.refreshToken(refreshToken);
  }
}
