import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/command_history.dart';
import '../models/connected_device.dart';
import '../models/user_profile.dart';
import './supabase_service.dart';

class DatabaseService {
  final SupabaseClient _client = SupabaseService.instance.client;

  // User Profile Operations
  Future<UserProfile?> getCurrentUserProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    try {
      final response = await _client
          .from('user_profiles')
          .select()
          .eq('id', user.id)
          .single();
      return UserProfile.fromJson(response);
    } catch (e) {
      throw Exception('Error fetching user profile: $e');
    }
  }

  Future<UserProfile> createUserProfile(UserProfile profile) async {
    try {
      final response = await _client
          .from('user_profiles')
          .insert(profile.toJson())
          .select()
          .single();
      return UserProfile.fromJson(response);
    } catch (e) {
      throw Exception('Error creating user profile: $e');
    }
  }

  Future<UserProfile> updateUserProfile(UserProfile profile) async {
    try {
      final response = await _client
          .from('user_profiles')
          .update(profile.toJson())
          .eq('id', profile.id)
          .select()
          .single();
      return UserProfile.fromJson(response);
    } catch (e) {
      throw Exception('Error updating user profile: $e');
    }
  }

  // Connected Devices Operations
  Future<List<ConnectedDevice>> getConnectedDevices({String? userId}) async {
    try {
      var query = _client.from('connected_devices').select();

      if (userId != null) {
        query = query.eq('user_id', userId);
      }

      final response = await query.order('created_at', ascending: false);
      return response.map((json) => ConnectedDevice.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error fetching connected devices: $e');
    }
  }

  Future<ConnectedDevice?> getDeviceById(String deviceId) async {
    try {
      final response = await _client
          .from('connected_devices')
          .select()
          .eq('id', deviceId)
          .single();
      return ConnectedDevice.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  Future<ConnectedDevice> updateDeviceStatus(
    String deviceId,
    String status, {
    DateTime? lastActivity,
    int? batteryLevel,
    String? location,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (lastActivity != null) {
        updateData['last_activity'] = lastActivity.toIso8601String();
      }
      if (batteryLevel != null) {
        updateData['battery_level'] = batteryLevel;
      }
      if (location != null) {
        updateData['location'] = location;
      }

      final response = await _client
          .from('connected_devices')
          .update(updateData)
          .eq('id', deviceId)
          .select()
          .single();
      return ConnectedDevice.fromJson(response);
    } catch (e) {
      throw Exception('Error updating device status: $e');
    }
  }

  Future<void> deleteDevice(String deviceId) async {
    try {
      await _client.from('connected_devices').delete().eq('id', deviceId);
    } catch (e) {
      throw Exception('Error deleting device: $e');
    }
  }

  // Device Commands Operations
  Future<String> createDeviceCommand({
    required String deviceId,
    required String adminUserId,
    required String commandType,
    Map<String, dynamic>? commandData,
  }) async {
    try {
      final response = await _client
          .from('device_commands')
          .insert({
            'device_id': deviceId,
            'admin_user_id': adminUserId,
            'command_type': commandType,
            'command_data': commandData,
            'status': 'pending',
          })
          .select('id')
          .single();
      return response['id'] as String;
    } catch (e) {
      throw Exception('Error creating device command: $e');
    }
  }

  Future<void> updateCommandStatus({
    required String commandId,
    required String status,
    DateTime? executedAt,
    DateTime? completedAt,
    String? errorMessage,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (executedAt != null) {
        updateData['executed_at'] = executedAt.toIso8601String();
      }
      if (completedAt != null) {
        updateData['completed_at'] = completedAt.toIso8601String();
      }
      if (errorMessage != null) {
        updateData['error_message'] = errorMessage;
      }

      await _client
          .from('device_commands')
          .update(updateData)
          .eq('id', commandId);
    } catch (e) {
      throw Exception('Error updating command status: $e');
    }
  }

  // Command History Operations
  Future<List<CommandHistory>> getCommandHistory({
    String? deviceId,
    String? adminUserId,
    int limit = 50,
  }) async {
    try {
      var query = _client.from('command_history').select();

      if (deviceId != null) {
        query = query.eq('device_id', deviceId);
      }
      if (adminUserId != null) {
        query = query.eq('admin_user_id', adminUserId);
      }

      final response =
          await query.order('created_at', ascending: false).limit(limit);

      return response.map((json) => CommandHistory.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error fetching command history: $e');
    }
  }

  Future<void> addCommandToHistory({
    String? commandId,
    required String deviceId,
    required String adminUserId,
    required String commandType,
    required String status,
    required String deviceName,
    int? executionTime,
    String? errorDetails,
  }) async {
    try {
      await _client.from('command_history').insert({
        'command_id': commandId,
        'device_id': deviceId,
        'admin_user_id': adminUserId,
        'command_type': commandType,
        'status': status,
        'device_name': deviceName,
        'execution_time': executionTime,
        'error_details': errorDetails,
      });
    } catch (e) {
      throw Exception('Error adding command to history: $e');
    }
  }

  // Statistics
  Future<Map<String, dynamic>> getDashboardStats(String userId) async {
    try {
      // Get device count
      final deviceCount = await _client
          .from('connected_devices')
          .select()
          .eq('user_id', userId)
          .count();

      // Get online device count
      final onlineDeviceCount = await _client
          .from('connected_devices')
          .select()
          .eq('user_id', userId)
          .eq('status', 'online')
          .count();

      // Get today's command count
      final today = DateTime.now().toIso8601String().split('T')[0];
      final todayCommandCount = await _client
          .from('command_history')
          .select()
          .eq('admin_user_id', userId)
          .gte('created_at', '${today}T00:00:00.000Z')
          .count();

      // Get successful command count today
      final successfulCommandCount = await _client
          .from('command_history')
          .select()
          .eq('admin_user_id', userId)
          .eq('status', 'success')
          .gte('created_at', '${today}T00:00:00.000Z')
          .count();

      return {
        'total_devices': deviceCount.count ?? 0,
        'online_devices': onlineDeviceCount.count ?? 0,
        'today_commands': todayCommandCount.count ?? 0,
        'successful_commands': successfulCommandCount.count ?? 0,
        'success_rate': todayCommandCount.count > 0
            ? ((successfulCommandCount.count ?? 0) / todayCommandCount.count) *
                100
            : 0.0,
      };
    } catch (e) {
      throw Exception('Error fetching dashboard stats: $e');
    }
  }

  // Real-time subscriptions
  RealtimeChannel subscribeToDevices(
    String userId,
    Function(PostgresChangePayload payload) callback,
  ) {
    final channel = _client.channel('devices:$userId').onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'connected_devices',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: callback,
        );

    channel.subscribe();
    return channel;
  }

  RealtimeChannel subscribeToCommandHistory(
    String adminUserId,
    Function(PostgresChangePayload payload) callback,
  ) {
    final channel =
        _client.channel('command_history:$adminUserId').onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'command_history',
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'admin_user_id',
                value: adminUserId,
              ),
              callback: callback,
            );

    channel.subscribe();
    return channel;
  }
}
