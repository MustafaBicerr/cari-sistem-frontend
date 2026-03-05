import 'package:mobile/features/auth/domain/entities/user.dart';

enum AuthStatus {
  unknown,
  authenticated,
  unauthenticated,
  loading,
  mustChangePassword,
}

class AuthState {
  final AuthStatus status;
  final User? user;

  const AuthState({this.status = AuthStatus.unknown, this.user});

  AuthState copyWith({AuthStatus? status, User? user}) {
    return AuthState(status: status ?? this.status, user: user ?? this.user);
  }
}
