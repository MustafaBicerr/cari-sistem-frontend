import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:mobile/features/auth/presentation/providers/auth_controller.dart';
import '../../domain/entities/session.dart';
import '../../domain/usecases/get_sessions_usecase.dart';
import '../../domain/usecases/revoke_session_usecase.dart';

final getSessionsUseCaseProvider = Provider(
  (ref) => GetSessionsUseCase(ref.read(authRepositoryProvider)),
);
final revokeSessionUseCaseProvider = Provider(
  (ref) => RevokeSessionUseCase(ref.read(authRepositoryProvider)),
);

final sessionControllerProvider =
    StateNotifierProvider<SessionController, AsyncValue<List<Session>>>((ref) {
      return SessionController(
        ref.read(getSessionsUseCaseProvider),
        ref.read(revokeSessionUseCaseProvider),
      );
    });

class SessionController extends StateNotifier<AsyncValue<List<Session>>> {
  final GetSessionsUseCase _getSessions;
  final RevokeSessionUseCase _revoke;

  SessionController(this._getSessions, this._revoke)
    : super(const AsyncValue.data([]));

  Future<void> loadSessions() async {
    state = const AsyncValue.loading();
    try {
      final list = await _getSessions.call();
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> revoke(String sessionId) async {
    state = const AsyncValue.loading();
    try {
      await _revoke.call(sessionId);
      await loadSessions();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
