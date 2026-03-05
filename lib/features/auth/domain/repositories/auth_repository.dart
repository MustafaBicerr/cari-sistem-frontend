import '../entities/user.dart';
import '../entities/session.dart';
import '../entities/auth_tokens.dart';

abstract class AuthRepository {
  Future<(User, AuthTokens)> login({
    required String identifier,
    required String password,
    required String deviceName,
  });

  Future<(User, AuthTokens)> register({
    required String clinicName,
    required String fullName,
    required String phone,
    required String email,
    required String password,
  });

  Future<AuthTokens> refreshToken(String refreshToken);

  Future<void> logout(String refreshToken);

  Future<List<Session>> getSessions();

  Future<void> revokeSession(String sessionId);

  Future<void> forgotPassword(String identifier);

  Future<void> resetPassword({
    required String token,
    required String newPassword,
  });

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });
}
