import '../../domain/entities/auth_tokens.dart';

class AuthTokensModel extends AuthTokens {
  const AuthTokensModel({
    required String accessToken,
    required String refreshToken,
  }) : super(accessToken: accessToken, refreshToken: refreshToken);

  factory AuthTokensModel.fromJson(Map<String, dynamic> json) {
    return AuthTokensModel(
      accessToken: json['access_token']?.toString() ?? '',
      refreshToken: json['refresh_token']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      'refresh_token': refreshToken,
    };
  }

  factory AuthTokensModel.fromEntity(AuthTokens entity) {
    return AuthTokensModel(
      accessToken: entity.accessToken,
      refreshToken: entity.refreshToken,
    );
  }
}
