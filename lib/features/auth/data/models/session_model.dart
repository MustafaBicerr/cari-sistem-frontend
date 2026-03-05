import '../../domain/entities/session.dart';

class SessionModel extends Session {
  const SessionModel({
    required String id,
    required String deviceName,
    required String ipAddress,
    required String userAgent,
    required DateTime createdAt,
    required DateTime lastUsedAt,
  }) : super(
          id: id,
          deviceName: deviceName,
          ipAddress: ipAddress,
          userAgent: userAgent,
          createdAt: createdAt,
          lastUsedAt: lastUsedAt,
        );

  factory SessionModel.fromJson(Map<String, dynamic> json) {
    return SessionModel(
      id: json['id']?.toString() ?? '',
      deviceName: json['device_name']?.toString() ?? '',
      ipAddress: json['ip_address']?.toString() ?? '',
      userAgent: json['user_agent']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      lastUsedAt: DateTime.tryParse(json['last_used_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'device_name': deviceName,
      'ip_address': ipAddress,
      'user_agent': userAgent,
      'created_at': createdAt.toIso8601String(),
      'last_used_at': lastUsedAt.toIso8601String(),
    };
  }

  factory SessionModel.fromEntity(Session entity) {
    return SessionModel(
      id: entity.id,
      deviceName: entity.deviceName,
      ipAddress: entity.ipAddress,
      userAgent: entity.userAgent,
      createdAt: entity.createdAt,
      lastUsedAt: entity.lastUsedAt,
    );
  }
}
