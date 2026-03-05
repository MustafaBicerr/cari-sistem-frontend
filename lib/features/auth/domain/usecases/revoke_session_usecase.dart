import '../repositories/auth_repository.dart';

class RevokeSessionUseCase {
  final AuthRepository repository;
  RevokeSessionUseCase(this.repository);

  Future<void> call(String sessionId) {
    return repository.revokeSession(sessionId);
  }
}
