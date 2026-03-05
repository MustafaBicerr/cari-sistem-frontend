import '../repositories/auth_repository.dart';
import '../entities/session.dart';

class GetSessionsUseCase {
  final AuthRepository repository;
  GetSessionsUseCase(this.repository);

  Future<List<Session>> call() {
    return repository.getSessions();
  }
}
