import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/services/secure_storage_service.dart';
import '../../domain/usecases/refresh_token_usecase.dart';
import '../../data/datasources/auth_local_datasource.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../providers/auth_state_provider.dart';
import '../../domain/entities/user.dart';
import '../../data/models/auth_tokens_model.dart';

/// Registers session-expired callback on ApiClient so 401+refresh failure logs user out.
/// Read once at app start (e.g. in MyApp.build).
final registerAuthSessionExpiredProvider = Provider<void>((ref) {
  final api = ref.read(apiClientProvider);
  final auth = ref.read(authControllerProvider.notifier);
  api.onSessionExpired = () => auth.setUnauthenticated();
});

// datasources/providers
final authRemoteDatasourceProvider = Provider(
  (ref) => AuthRemoteDatasource(ref.read(apiClientProvider)),
);
final authLocalDatasourceProvider = Provider(
  (ref) => AuthLocalDatasource(SecureStorageService()),
);

// repo provider
final authRepositoryProvider = Provider(
  (ref) => AuthRepositoryImpl(
    ref.read(authRemoteDatasourceProvider),
    ref.read(authLocalDatasourceProvider),
  ),
);

// usecase provider
final refreshTokenUseCaseProvider = Provider(
  (ref) => RefreshTokenUseCase(ref.read(authRepositoryProvider)),
);

// controller provider
final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) {
    return AuthController(
      ref.read(refreshTokenUseCaseProvider),
      ref.read(authLocalDatasourceProvider),
    );
  },
);

class AuthController extends StateNotifier<AuthState> {
  final RefreshTokenUseCase _refresh;
  final AuthLocalDatasource _local;

  AuthController(this._refresh, this._local) : super(const AuthState()) {
    _init();
  }

  Future<void> _init() async {
    final tokens = await _local.getTokens();
    if (tokens == null) {
      state = const AuthState(status: AuthStatus.unauthenticated);
      return;
    }
    try {
      final newTokens = await _refresh.call(tokens.refreshToken);
      await _local.saveTokens(AuthTokensModel.fromEntity(newTokens));
      state = const AuthState(status: AuthStatus.authenticated);
    } catch (_) {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  void setAuthenticated(User user) {
    state = AuthState(status: AuthStatus.authenticated, user: user);
  }

  void setUnauthenticated() {
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  void markMustChangePassword(User user) {
    state = AuthState(status: AuthStatus.mustChangePassword, user: user);
  }
}
