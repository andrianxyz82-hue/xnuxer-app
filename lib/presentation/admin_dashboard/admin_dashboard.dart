import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../models/command_history.dart';
import '../../models/connected_device.dart';
import '../../models/user_profile.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import './widgets/command_status_widget.dart';
import './widgets/control_button_widget.dart';
import './widgets/device_card_widget.dart';
import './widgets/status_indicator_widget.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  bool _isSecureConnection = true;
  String? _selectedDeviceId;

  final AuthService _authService = AuthService();
  final DatabaseService _databaseService = DatabaseService();

  UserProfile? _currentUser;
  List<ConnectedDevice> _connectedDevices = [];
  List<CommandHistory> _commandHistory = [];
  Map<String, dynamic> _dashboardStats = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    setState(() => _isLoading = true);

    try {
      // Load user profile
      _currentUser = await _databaseService.getCurrentUserProfile();

      if (_currentUser != null) {
        // Load connected devices
        _connectedDevices = await _databaseService.getConnectedDevices();

        // Load command history
        _commandHistory = await _databaseService.getCommandHistory(
          adminUserId: _currentUser!.id,
          limit: 20,
        );

        // Load dashboard stats
        _dashboardStats =
            await _databaseService.getDashboardStats(_currentUser!.id);

        setState(() {
          _isLoading = false;
          _isSecureConnection = true;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading data: $e'),
          backgroundColor: AppTheme.lightTheme.colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _refreshDevices() async {
    HapticFeedback.lightImpact();
    setState(() => _isLoading = true);

    try {
      // Refresh devices data
      _connectedDevices = await _databaseService.getConnectedDevices();

      // Refresh command history
      if (_currentUser != null) {
        _commandHistory = await _databaseService.getCommandHistory(
          adminUserId: _currentUser!.id,
          limit: 20,
        );

        // Refresh dashboard stats
        _dashboardStats =
            await _databaseService.getDashboardStats(_currentUser!.id);
      }

      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Status perangkat diperbarui'),
          backgroundColor: AppTheme.lightTheme.colorScheme.tertiary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error refreshing data: $e'),
          backgroundColor: AppTheme.lightTheme.colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _selectDevice(String deviceId) {
    setState(() => _selectedDeviceId = deviceId);
    HapticFeedback.selectionClick();
  }

  Future<void> _executeCommand(String commandType) async {
    if (_selectedDeviceId == null || _currentUser == null) {
      _showSelectDeviceDialog();
      return;
    }

    try {
      // Create command in database
      final commandId = await _databaseService.createDeviceCommand(
        deviceId: _selectedDeviceId!,
        adminUserId: _currentUser!.id,
        commandType: commandType,
      );

      // Update command status to executing
      await _databaseService.updateCommandStatus(
        commandId: commandId,
        status: 'executing',
        executedAt: DateTime.now(),
      );

      // Find selected device
      final selectedDevice = _connectedDevices.firstWhere(
        (device) => device.id == _selectedDeviceId,
      );

      // Add to command history immediately
      await _databaseService.addCommandToHistory(
        commandId: commandId,
        deviceId: _selectedDeviceId!,
        adminUserId: _currentUser!.id,
        commandType: commandType,
        status: 'executing',
        deviceName:
            '${selectedDevice.deviceModel} (${selectedDevice.childName})',
      );

      // Simulate command execution
      Future.delayed(Duration(seconds: 3), () async {
        try {
          final success =
              DateTime.now().millisecond % 4 != 0; // 75% success rate
          final newStatus = success ? 'success' : 'failed';
          final executionTime =
              success ? 1000 + DateTime.now().millisecond % 2000 : null;

          // Update command status
          await _databaseService.updateCommandStatus(
            commandId: commandId,
            status: newStatus,
            completedAt: DateTime.now(),
            errorMessage: success ? null : 'Device communication timeout',
          );

          // Update command history
          await _databaseService.addCommandToHistory(
            commandId: commandId,
            deviceId: _selectedDeviceId!,
            adminUserId: _currentUser!.id,
            commandType: commandType,
            status: newStatus,
            deviceName:
                '${selectedDevice.deviceModel} (${selectedDevice.childName})',
            executionTime: executionTime,
            errorDetails: success ? null : 'Device communication timeout',
          );

          // Refresh command history
          await _refreshDevices();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(success
                    ? 'Perintah berhasil dijalankan'
                    : 'Perintah gagal dijalankan'),
                backgroundColor: success
                    ? AppTheme.lightTheme.colorScheme.tertiary
                    : AppTheme.lightTheme.colorScheme.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        } catch (e) {
          print('Error updating command status: $e');
        }
      });

      // Refresh data immediately to show executing command
      await _refreshDevices();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error executing command: $e'),
          backgroundColor: AppTheme.lightTheme.colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _executeFlashCommand() {
    if (_selectedDeviceId == null) {
      _showSelectDeviceDialog();
      return;
    }

    HapticFeedback.mediumImpact();
    _showCommandDialog('Flash', 'flash');
  }

  void _executeCameraCommand() {
    if (_selectedDeviceId == null) {
      _showSelectDeviceDialog();
      return;
    }

    HapticFeedback.mediumImpact();
    Navigator.pushNamed(context, '/camera-control-screen');
  }

  void _executeAudioCommand() {
    if (_selectedDeviceId == null) {
      _showSelectDeviceDialog();
      return;
    }

    HapticFeedback.mediumImpact();
    _showCommandDialog('Audio', 'audio');
  }

  void _executeWallpaperCommand() {
    if (_selectedDeviceId == null) {
      _showSelectDeviceDialog();
      return;
    }

    HapticFeedback.mediumImpact();
    Navigator.pushNamed(context, '/wallpaper-control-screen');
  }

  void _showSelectDeviceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Pilih Perangkat'),
        content: Text(
            'Silakan pilih perangkat terlebih dahulu untuk menjalankan perintah.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showCommandDialog(String commandName, String commandType) {
    final selectedDevice = _connectedDevices.firstWhere(
      (device) => device.id == _selectedDeviceId,
      orElse: () => ConnectedDevice(
        id: '',
        userId: '',
        deviceId: '',
        childName: 'Unknown',
        deviceModel: 'Unknown',
        status: 'offline',
        lastActivity: DateTime.now(),
        connectionStatus: 'failed',
        isPaired: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Konfirmasi Perintah'),
        content: Text(
            'Apakah Anda yakin ingin menjalankan perintah $commandName pada perangkat ${selectedDevice.childName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _executeCommand(commandType);
            },
            child: Text('Jalankan'),
          ),
        ],
      ),
    );
  }

  void _showAdvancedOptions(String commandType) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(6.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12.w,
              height: 0.5.h,
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 3.h),
            Text(
              'Opsi Lanjutan - $commandType',
              style: AppTheme.lightTheme.textTheme.titleLarge,
            ),
            SizedBox(height: 3.h),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'schedule',
                color: AppTheme.lightTheme.colorScheme.primary,
                size: 6.w,
              ),
              title: Text('Jadwalkan Perintah'),
              subtitle: Text('Atur waktu eksekusi otomatis'),
              onTap: () {
                Navigator.pop(context);
                // Implement scheduling
              },
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'repeat',
                color: AppTheme.lightTheme.colorScheme.primary,
                size: 6.w,
              ),
              title: Text('Perintah Berulang'),
              subtitle: Text('Jalankan secara berkala'),
              onTap: () {
                Navigator.pop(context);
                // Implement recurring commands
              },
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'settings',
                color: AppTheme.lightTheme.colorScheme.primary,
                size: 6.w,
              ),
              title: Text('Pengaturan Khusus'),
              subtitle: Text('Konfigurasi parameter perintah'),
              onTap: () {
                Navigator.pop(context);
                // Implement custom settings
              },
            ),
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }

  void _addNewDevice() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Tambah Perangkat Baru'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Untuk menambahkan perangkat baru:'),
            SizedBox(height: 2.h),
            Text('1. Install aplikasi di perangkat anak'),
            Text('2. Masukkan kode pairing yang ditampilkan'),
            Text('3. Berikan izin yang diperlukan'),
            SizedBox(height: 2.h),
            Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.primary
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Kode Pairing: ABC123',
                style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.lightTheme.colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Tutup'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Implement device pairing
            },
            child: Text('Mulai Pairing'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Parent Control Hub'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _refreshDevices,
            icon: CustomIconWidget(
              iconName: 'refresh',
              color: AppTheme.lightTheme.colorScheme.onSurface,
              size: 6.w,
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              switch (value) {
                case 'settings':
                  // Navigate to settings
                  break;
                case 'logout':
                  try {
                    await _authService.signOut();
                    Navigator.pushReplacementNamed(
                        context, '/role-selection-screen');
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error signing out: $e'),
                        backgroundColor: AppTheme.lightTheme.colorScheme.error,
                      ),
                    );
                  }
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    CustomIconWidget(
                      iconName: 'settings',
                      color: AppTheme.lightTheme.colorScheme.onSurface,
                      size: 5.w,
                    ),
                    SizedBox(width: 3.w),
                    Text('Pengaturan'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    CustomIconWidget(
                      iconName: 'logout',
                      color: AppTheme.lightTheme.colorScheme.error,
                      size: 5.w,
                    ),
                    SizedBox(width: 3.w),
                    Text(
                      'Keluar',
                      style: TextStyle(
                          color: AppTheme.lightTheme.colorScheme.error),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: CustomIconWidget(
                iconName: 'dashboard',
                color: AppTheme.lightTheme.colorScheme.primary,
                size: 6.w,
              ),
              text: 'Dashboard',
            ),
            Tab(
              icon: CustomIconWidget(
                iconName: 'history',
                color: AppTheme.lightTheme.colorScheme.primary,
                size: 6.w,
              ),
              text: 'Riwayat',
            ),
            Tab(
              icon: CustomIconWidget(
                iconName: 'settings',
                color: AppTheme.lightTheme.colorScheme.primary,
                size: 6.w,
              ),
              text: 'Pengaturan',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Dashboard Tab
          RefreshIndicator(
            onRefresh: _refreshDevices,
            child: SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 2.h),

                  // Status Indicator
                  StatusIndicatorWidget(
                    isSecure: _isSecureConnection,
                    connectedDevices: _connectedDevices.length,
                    isLoading: _isLoading,
                    stats: _dashboardStats,
                  ),

                  SizedBox(height: 2.h),

                  // Connected Devices Section
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4.w),
                    child: Text(
                      'Perangkat Terhubung',
                      style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  SizedBox(height: 1.h),

                  // Device Cards
                  _connectedDevices.isEmpty
                      ? Center(
                          child: Padding(
                            padding: EdgeInsets.all(8.w),
                            child: Column(
                              children: [
                                CustomIconWidget(
                                  iconName: 'devices',
                                  color:
                                      AppTheme.lightTheme.colorScheme.outline,
                                  size: 15.w,
                                ),
                                SizedBox(height: 2.h),
                                Text(
                                  'Belum ada perangkat terhubung',
                                  style: AppTheme
                                      .lightTheme.textTheme.titleMedium
                                      ?.copyWith(
                                    color: AppTheme.lightTheme.colorScheme
                                        .onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: _connectedDevices.length,
                          itemBuilder: (context, index) {
                            final device = _connectedDevices[index];
                            final isSelected = _selectedDeviceId == device.id;

                            return Container(
                              decoration: isSelected
                                  ? BoxDecoration(
                                      border: Border.all(
                                        color: AppTheme
                                            .lightTheme.colorScheme.primary,
                                        width: 2,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      color: AppTheme
                                          .lightTheme.colorScheme.primary
                                          .withValues(alpha: 0.05),
                                    )
                                  : null,
                              child: DeviceCardWidget(
                                device: device,
                                onTap: () => _selectDevice(device.id),
                                onQuickFlash: () {
                                  _selectDevice(device.id);
                                  _executeFlashCommand();
                                },
                                onQuickCamera: () {
                                  _selectDevice(device.id);
                                  _executeCameraCommand();
                                },
                                onQuickAudio: () {
                                  _selectDevice(device.id);
                                  _executeAudioCommand();
                                },
                              ),
                            );
                          },
                        ),

                  SizedBox(height: 3.h),

                  // Control Section
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4.w),
                    child: Text(
                      'Kontrol Perangkat',
                      style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  SizedBox(height: 2.h),

                  // Control Buttons Grid
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4.w),
                    child: Wrap(
                      spacing: 4.w,
                      runSpacing: 2.h,
                      children: [
                        ControlButtonWidget(
                          title: 'Kontrol Flash',
                          iconName: 'flashlight_on',
                          backgroundColor:
                              AppTheme.lightTheme.colorScheme.tertiary,
                          onTap: _executeFlashCommand,
                          onLongPress: () => _showAdvancedOptions('Flash'),
                        ),
                        ControlButtonWidget(
                          title: 'Akses Kamera',
                          iconName: 'camera_alt',
                          backgroundColor:
                              AppTheme.lightTheme.colorScheme.primary,
                          onTap: _executeCameraCommand,
                          onLongPress: () => _showAdvancedOptions('Kamera'),
                        ),
                        ControlButtonWidget(
                          title: 'Upload Audio',
                          iconName: 'volume_up',
                          backgroundColor:
                              AppTheme.lightTheme.colorScheme.secondary,
                          onTap: _executeAudioCommand,
                          onLongPress: () => _showAdvancedOptions('Audio'),
                        ),
                        ControlButtonWidget(
                          title: 'Ubah Wallpaper',
                          iconName: 'wallpaper',
                          backgroundColor: Color(0xFF8B5CF6),
                          onTap: _executeWallpaperCommand,
                          onLongPress: () => _showAdvancedOptions('Wallpaper'),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 4.h),
                ],
              ),
            ),
          ),

          // History Tab
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 2.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                  child: Text(
                    'Riwayat Perintah',
                    style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(height: 2.h),
                _commandHistory.isEmpty
                    ? Center(
                        child: Padding(
                          padding: EdgeInsets.all(8.w),
                          child: Column(
                            children: [
                              CustomIconWidget(
                                iconName: 'history',
                                color: AppTheme.lightTheme.colorScheme.outline,
                                size: 15.w,
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                'Belum ada riwayat perintah',
                                style: AppTheme.lightTheme.textTheme.titleMedium
                                    ?.copyWith(
                                  color: AppTheme
                                      .lightTheme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: _commandHistory.length,
                        itemBuilder: (context, index) {
                          final command = _commandHistory[index];
                          return CommandStatusWidget(
                            commandHistory: command,
                          );
                        },
                      ),
                SizedBox(height: 4.h),
              ],
            ),
          ),

          // Settings Tab
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 2.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                  child: Text(
                    'Pengaturan',
                    style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(height: 2.h),

                // User Profile Section
                if (_currentUser != null)
                  Container(
                    margin:
                        EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                    padding: EdgeInsets.all(4.w),
                    decoration: BoxDecoration(
                      color: AppTheme.lightTheme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.lightTheme.colorScheme.outline
                            .withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(3.w),
                          decoration: BoxDecoration(
                            color: AppTheme.lightTheme.colorScheme.primary
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: CustomIconWidget(
                            iconName: 'person',
                            color: AppTheme.lightTheme.colorScheme.primary,
                            size: 8.w,
                          ),
                        ),
                        SizedBox(width: 4.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _currentUser!.fullName,
                                style: AppTheme.lightTheme.textTheme.titleMedium
                                    ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                _currentUser!.email,
                                style: AppTheme.lightTheme.textTheme.bodyMedium
                                    ?.copyWith(
                                  color: AppTheme
                                      .lightTheme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              Text(
                                'Role: ${_currentUser!.role.toUpperCase()}',
                                style: AppTheme.lightTheme.textTheme.bodySmall
                                    ?.copyWith(
                                  color:
                                      AppTheme.lightTheme.colorScheme.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                // Settings Options
                ListTile(
                  leading: CustomIconWidget(
                    iconName: 'notifications',
                    color: AppTheme.lightTheme.colorScheme.primary,
                    size: 6.w,
                  ),
                  title: Text('Notifikasi'),
                  subtitle: Text('Atur preferensi notifikasi'),
                  trailing: Switch(
                    value: true,
                    onChanged: (value) {
                      // Handle notification toggle
                    },
                  ),
                ),

                ListTile(
                  leading: CustomIconWidget(
                    iconName: 'security',
                    color: AppTheme.lightTheme.colorScheme.primary,
                    size: 6.w,
                  ),
                  title: Text('Keamanan'),
                  subtitle: Text('Pengaturan keamanan dan privasi'),
                  trailing: CustomIconWidget(
                    iconName: 'chevron_right',
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    size: 5.w,
                  ),
                  onTap: () {
                    // Navigate to security settings
                  },
                ),

                ListTile(
                  leading: CustomIconWidget(
                    iconName: 'schedule',
                    color: AppTheme.lightTheme.colorScheme.primary,
                    size: 6.w,
                  ),
                  title: Text('Jadwal Otomatis'),
                  subtitle: Text('Atur perintah otomatis'),
                  trailing: CustomIconWidget(
                    iconName: 'chevron_right',
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    size: 5.w,
                  ),
                  onTap: () {
                    // Navigate to scheduling settings
                  },
                ),

                ListTile(
                  leading: CustomIconWidget(
                    iconName: 'help',
                    color: AppTheme.lightTheme.colorScheme.primary,
                    size: 6.w,
                  ),
                  title: Text('Bantuan'),
                  subtitle: Text('FAQ dan panduan penggunaan'),
                  trailing: CustomIconWidget(
                    iconName: 'chevron_right',
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    size: 5.w,
                  ),
                  onTap: () {
                    // Navigate to help
                  },
                ),

                ListTile(
                  leading: CustomIconWidget(
                    iconName: 'info',
                    color: AppTheme.lightTheme.colorScheme.primary,
                    size: 6.w,
                  ),
                  title: Text('Tentang Aplikasi'),
                  subtitle: Text('Versi 1.0.0'),
                  trailing: CustomIconWidget(
                    iconName: 'chevron_right',
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    size: 5.w,
                  ),
                  onTap: () {
                    // Show about dialog
                  },
                ),

                SizedBox(height: 4.h),

                // Logout Button
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text('Keluar'),
                            content: Text(
                                'Apakah Anda yakin ingin keluar dari aplikasi?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text('Batal'),
                              ),
                              ElevatedButton(
                                onPressed: () async {
                                  Navigator.pop(context);
                                  try {
                                    await _authService.signOut();
                                    Navigator.pushReplacementNamed(
                                        context, '/role-selection-screen');
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Error signing out: $e'),
                                        backgroundColor: AppTheme
                                            .lightTheme.colorScheme.error,
                                      ),
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      AppTheme.lightTheme.colorScheme.error,
                                ),
                                child: Text('Keluar'),
                              ),
                            ],
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.lightTheme.colorScheme.error,
                        padding: EdgeInsets.symmetric(vertical: 2.h),
                      ),
                      child: Text(
                        'Keluar dari Aplikasi',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 4.h),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton.extended(
              onPressed: _addNewDevice,
              icon: CustomIconWidget(
                iconName: 'add',
                color: Colors.white,
                size: 6.w,
              ),
              label: Text(
                'Tambah Perangkat',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          : null,
    );
  }
}
