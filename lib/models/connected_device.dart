class ConnectedDevice {
  final String id;
  final String userId;
  final String deviceId;
  final String childName;
  final String deviceModel;
  final String status;
  final DateTime lastActivity;
  final int? batteryLevel;
  final String? location;
  final String? pairingCode;
  final String connectionStatus;
  final String? appVersion;
  final bool isPaired;
  final DateTime? pairedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ConnectedDevice({
    required this.id,
    required this.userId,
    required this.deviceId,
    required this.childName,
    required this.deviceModel,
    required this.status,
    required this.lastActivity,
    this.batteryLevel,
    this.location,
    this.pairingCode,
    required this.connectionStatus,
    this.appVersion,
    required this.isPaired,
    this.pairedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ConnectedDevice.fromJson(Map<String, dynamic> json) {
    return ConnectedDevice(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      deviceId: json['device_id'] as String,
      childName: json['child_name'] as String,
      deviceModel: json['device_model'] as String,
      status: json['status'] as String,
      lastActivity: DateTime.parse(json['last_activity'] as String),
      batteryLevel: json['battery_level'] as int?,
      location: json['location'] as String?,
      pairingCode: json['pairing_code'] as String?,
      connectionStatus: json['connection_status'] as String,
      appVersion: json['app_version'] as String?,
      isPaired: json['is_paired'] as bool? ?? false,
      pairedAt: json['paired_at'] != null
          ? DateTime.parse(json['paired_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'device_id': deviceId,
      'child_name': childName,
      'device_model': deviceModel,
      'status': status,
      'last_activity': lastActivity.toIso8601String(),
      'battery_level': batteryLevel,
      'location': location,
      'pairing_code': pairingCode,
      'connection_status': connectionStatus,
      'app_version': appVersion,
      'is_paired': isPaired,
      'paired_at': pairedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  ConnectedDevice copyWith({
    String? status,
    DateTime? lastActivity,
    int? batteryLevel,
    String? location,
    String? connectionStatus,
  }) {
    return ConnectedDevice(
      id: id,
      userId: userId,
      deviceId: deviceId,
      childName: childName,
      deviceModel: deviceModel,
      status: status ?? this.status,
      lastActivity: lastActivity ?? this.lastActivity,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      location: location ?? this.location,
      pairingCode: pairingCode,
      connectionStatus: connectionStatus ?? this.connectionStatus,
      appVersion: appVersion,
      isPaired: isPaired,
      pairedAt: pairedAt,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  bool get isOnline => status == 'online';
  bool get isOffline => status == 'offline';
  bool get isSecureConnection => connectionStatus == 'secure';

  String get lastActivityText {
    final now = DateTime.now();
    final difference = now.difference(lastActivity);

    if (difference.inMinutes < 1) {
      return 'Baru saja';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} menit lalu';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} jam lalu';
    } else {
      return '${difference.inDays} hari lalu';
    }
  }
}
