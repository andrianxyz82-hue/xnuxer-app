class CommandHistory {
  final String id;
  final String? commandId;
  final String deviceId;
  final String adminUserId;
  final String commandType;
  final String status;
  final String deviceName;
  final int? executionTime;
  final String? errorDetails;
  final DateTime createdAt;

  const CommandHistory({
    required this.id,
    this.commandId,
    required this.deviceId,
    required this.adminUserId,
    required this.commandType,
    required this.status,
    required this.deviceName,
    this.executionTime,
    this.errorDetails,
    required this.createdAt,
  });

  factory CommandHistory.fromJson(Map<String, dynamic> json) {
    return CommandHistory(
      id: json['id'] as String,
      commandId: json['command_id'] as String?,
      deviceId: json['device_id'] as String,
      adminUserId: json['admin_user_id'] as String,
      commandType: json['command_type'] as String,
      status: json['status'] as String,
      deviceName: json['device_name'] as String,
      executionTime: json['execution_time'] as int?,
      errorDetails: json['error_details'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'command_id': commandId,
      'device_id': deviceId,
      'admin_user_id': adminUserId,
      'command_type': commandType,
      'status': status,
      'device_name': deviceName,
      'execution_time': executionTime,
      'error_details': errorDetails,
      'created_at': createdAt.toIso8601String(),
    };
  }

  bool get isSuccess => status == 'success';
  bool get isFailed => status == 'failed';
  bool get isExecuting => status == 'executing';
  bool get isPending => status == 'pending';

  String get commandTypeDisplay {
    switch (commandType) {
      case 'flash':
        return 'Flash';
      case 'camera':
        return 'Kamera';
      case 'audio':
        return 'Audio';
      case 'wallpaper':
        return 'Wallpaper';
      case 'system':
        return 'Sistem';
      default:
        return commandType;
    }
  }

  String get statusDisplay {
    switch (status) {
      case 'success':
        return 'Berhasil';
      case 'failed':
        return 'Gagal';
      case 'executing':
        return 'Menjalankan';
      case 'pending':
        return 'Menunggu';
      case 'timeout':
        return 'Timeout';
      default:
        return status;
    }
  }

  String get executionTimeDisplay {
    if (executionTime == null) return '-';
    if (executionTime! < 1000) {
      return '${executionTime}ms';
    } else {
      return '${(executionTime! / 1000).toStringAsFixed(1)}s';
    }
  }
}
