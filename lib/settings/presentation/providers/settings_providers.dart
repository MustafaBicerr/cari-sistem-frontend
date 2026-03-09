import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:mobile/core/api/api_client.dart';
import 'package:mobile/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:mobile/features/auth/domain/entities/session.dart';
import 'package:mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:mobile/features/auth/presentation/providers/auth_controller.dart';
import 'package:mobile/settings/data/datasources/settings_remote_datasource.dart';
import 'package:mobile/settings/data/repositories/settings_repository_impl.dart';
import 'package:mobile/settings/domain/entities/managed_user.dart';
import 'package:mobile/settings/domain/repositories/settings_repository.dart';

enum SettingsMenuItem {
  account,
  password,
  inflationProtection,
  userCreate,
  userFreeze,
  backupPeriod,
  userHistory,
  themeMode,
  logout,
}

enum BackupPeriodOption { daily, every3Days, weekly, monthly }

enum ThemePreference { system, light, dark }

class SettingsState {
  final SettingsMenuItem selectedMenu;
  final bool inflationProtectionEnabled;
  final BackupPeriodOption backupPeriod;
  final ThemePreference themePreference;
  final bool isBusy;
  final List<ManagedUser> users;
  final List<Session> sessions;
  final String? errorMessage;
  final String? successMessage;

  const SettingsState({
    this.selectedMenu = SettingsMenuItem.account,
    this.inflationProtectionEnabled = true,
    this.backupPeriod = BackupPeriodOption.weekly,
    this.themePreference = ThemePreference.system,
    this.isBusy = false,
    this.users = const [],
    this.sessions = const [],
    this.errorMessage,
    this.successMessage,
  });

  SettingsState copyWith({
    SettingsMenuItem? selectedMenu,
    bool? inflationProtectionEnabled,
    BackupPeriodOption? backupPeriod,
    ThemePreference? themePreference,
    bool? isBusy,
    List<ManagedUser>? users,
    List<Session>? sessions,
    String? errorMessage,
    String? successMessage,
    bool clearMessages = false,
  }) {
    return SettingsState(
      selectedMenu: selectedMenu ?? this.selectedMenu,
      inflationProtectionEnabled:
          inflationProtectionEnabled ?? this.inflationProtectionEnabled,
      backupPeriod: backupPeriod ?? this.backupPeriod,
      themePreference: themePreference ?? this.themePreference,
      isBusy: isBusy ?? this.isBusy,
      users: users ?? this.users,
      sessions: sessions ?? this.sessions,
      errorMessage: clearMessages ? null : errorMessage ?? this.errorMessage,
      successMessage:
          clearMessages ? null : successMessage ?? this.successMessage,
    );
  }
}

final settingsRemoteDatasourceProvider = Provider<SettingsRemoteDatasource>(
  (ref) => SettingsRemoteDatasource(ref.read(apiClientProvider)),
);

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepositoryImpl(ref.read(settingsRemoteDatasourceProvider)),
);

final settingsControllerProvider =
    StateNotifierProvider<SettingsController, SettingsState>(
      (ref) => SettingsController(
        settingsRepository: ref.read(settingsRepositoryProvider),
        authRepository: ref.read(authRepositoryProvider),
        authLocalDatasource: ref.read(authLocalDatasourceProvider),
        ref: ref,
      ),
    );

class SettingsController extends StateNotifier<SettingsState> {
  final SettingsRepository _settingsRepository;
  final AuthRepository _authRepository;
  final AuthLocalDatasource _authLocalDatasource;
  final Ref _ref;

  SettingsController({
    required SettingsRepository settingsRepository,
    required AuthRepository authRepository,
    required AuthLocalDatasource authLocalDatasource,
    required Ref ref,
  }) : _settingsRepository = settingsRepository,
       _authRepository = authRepository,
       _authLocalDatasource = authLocalDatasource,
       _ref = ref,
       super(const SettingsState());

  void selectMenu(SettingsMenuItem item) {
    state = state.copyWith(selectedMenu: item, clearMessages: true);
  }

  void setInflationProtection(bool value) {
    state = state.copyWith(
      inflationProtectionEnabled: value,
      successMessage:
          value
              ? 'Enflasyon korumasi acildi. Borclar fiyat degisiminden etkilenebilir.'
              : 'Enflasyon korumasi kapatildi. Mevcut borc tutarlari sabit kalir.',
      errorMessage: null,
    );
  }

  void setBackupPeriod(BackupPeriodOption value) {
    state = state.copyWith(
      backupPeriod: value,
      successMessage: 'Yedekleme periyodu guncellendi.',
      errorMessage: null,
    );
  }

  void setThemePreference(ThemePreference value) {
    state = state.copyWith(
      themePreference: value,
      successMessage: 'Tema tercihi kaydedildi (altyapi bekleniyor).',
      errorMessage: null,
    );
  }

  Future<void> loadUsers() async {
    state = state.copyWith(isBusy: true, clearMessages: true);
    try {
      final users = await _settingsRepository.listUsers();
      state = state.copyWith(isBusy: false, users: users);
    } catch (e) {
      state = state.copyWith(isBusy: false, errorMessage: e.toString());
    }
  }

  Future<void> createUser({
    required String branchId,
    required String fullName,
    required String phone,
    required String email,
    required String password,
    required String role,
  }) async {
    state = state.copyWith(isBusy: true, clearMessages: true);
    try {
      await _settingsRepository.createUser(
        branchId: branchId,
        fullName: fullName,
        phone: phone,
        email: email,
        password: password,
        role: role,
      );
      final users = await _settingsRepository.listUsers();
      state = state.copyWith(
        isBusy: false,
        users: users,
        successMessage: 'Kullanici basariyla olusturuldu.',
      );
    } catch (e) {
      state = state.copyWith(isBusy: false, errorMessage: e.toString());
    }
  }

  Future<void> deactivateUser(String userId) async {
    state = state.copyWith(isBusy: true, clearMessages: true);
    try {
      await _settingsRepository.deactivateUser(userId);
      final users = await _settingsRepository.listUsers();
      state = state.copyWith(
        isBusy: false,
        users: users,
        successMessage: 'Kullanici donduruldu.',
      );
    } catch (e) {
      state = state.copyWith(isBusy: false, errorMessage: e.toString());
    }
  }

  Future<void> loadSessions() async {
    state = state.copyWith(isBusy: true, clearMessages: true);
    try {
      final sessions = await _authRepository.getSessions();
      state = state.copyWith(isBusy: false, sessions: sessions);
    } catch (e) {
      state = state.copyWith(isBusy: false, errorMessage: e.toString());
    }
  }

  Future<void> revokeSession(String sessionId) async {
    state = state.copyWith(isBusy: true, clearMessages: true);
    try {
      await _authRepository.revokeSession(sessionId);
      final sessions = await _authRepository.getSessions();
      state = state.copyWith(
        isBusy: false,
        sessions: sessions,
        successMessage: 'Oturum sonlandirildi.',
      );
    } catch (e) {
      state = state.copyWith(isBusy: false, errorMessage: e.toString());
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    state = state.copyWith(isBusy: true, clearMessages: true);
    try {
      await _authRepository.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      state = state.copyWith(
        isBusy: false,
        successMessage: 'Sifre basariyla degistirildi.',
      );
    } catch (e) {
      state = state.copyWith(isBusy: false, errorMessage: e.toString());
    }
  }

  Future<void> logout() async {
    state = state.copyWith(isBusy: true, clearMessages: true);
    try {
      final tokens = await _authLocalDatasource.getTokens();
      if (tokens != null) {
        await _authRepository.logout(tokens.refreshToken);
      } else {
        await _authLocalDatasource.clearTokens();
      }
      _ref.read(authControllerProvider.notifier).setUnauthenticated();
      state = state.copyWith(
        isBusy: false,
        successMessage: 'Oturum kapatildi.',
      );
    } catch (e) {
      await _authLocalDatasource.clearTokens();
      _ref.read(authControllerProvider.notifier).setUnauthenticated();
      state = state.copyWith(
        isBusy: false,
        errorMessage: 'Cikis sirasinda hata alindi, yerel oturum kapatildi.',
      );
    }
  }
}
