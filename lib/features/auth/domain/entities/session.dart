import 'package:equatable/equatable.dart';

class Session extends Equatable {
  final String id;
  final String deviceName;
  final String ipAddress;
  final String userAgent;
  final DateTime createdAt;
  final DateTime lastUsedAt;

  const Session({
    required this.id,
    required this.deviceName,
    required this.ipAddress,
    required this.userAgent,
    required this.createdAt,
    required this.lastUsedAt,
  });

  @override
  List<Object?> get props => [
        id,
        deviceName,
        ipAddress,
        userAgent,
        createdAt,
        lastUsedAt,
      ];
}
