import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import './widgets/camera_controls_widget.dart';
import './widgets/camera_header_widget.dart';
import './widgets/camera_preview_widget.dart';
import './widgets/connection_status_widget.dart';

class CameraControlScreen extends StatefulWidget {
  const CameraControlScreen({super.key});

  @override
  State<CameraControlScreen> createState() => _CameraControlScreenState();
}

class _CameraControlScreenState extends State<CameraControlScreen>
    with WidgetsBindingObserver {
  // Camera related variables
  List<CameraDescription> _cameras = [];
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isLoading = true;
  bool _isFrontCamera = false;
  bool _isCapturing = false;
  bool _isContinuousMode = false;

  // Connection related variables
  bool _isConnected = true;
  int _signalStrength = 4;
  int _latency = 45;
  String _quality = 'HD';
  String _deviceName = 'Perangkat Anak - Samsung A54';

  // Timer for connection simulation and auto-disconnect
  Timer? _connectionTimer;
  Timer? _autoDisconnectTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
    _startConnectionSimulation();
    _startAutoDisconnectTimer();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    _connectionTimer?.cancel();
    _autoDisconnectTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _cameraController;

    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<bool> _requestCameraPermission() async {
    if (kIsWeb) return true;

    final status = await Permission.camera.request();
    return status.isGranted;
  }

  Future<void> _initializeCamera() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final hasPermission = await _requestCameraPermission();
      if (!hasPermission) {
        _showPermissionDialog();
        return;
      }

      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final camera = kIsWeb
          ? _cameras.firstWhere(
              (c) => c.lensDirection == CameraLensDirection.front,
              orElse: () => _cameras.first,
            )
          : _cameras.firstWhere(
              (c) => c.lensDirection == CameraLensDirection.back,
              orElse: () => _cameras.first,
            );

      _cameraController = CameraController(
        camera,
        kIsWeb ? ResolutionPreset.medium : ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      await _applySettings();

      setState(() {
        _isCameraInitialized = true;
        _isLoading = false;
        _isFrontCamera = camera.lensDirection == CameraLensDirection.front;
      });

      HapticFeedback.lightImpact();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isCameraInitialized = false;
      });
      _showErrorSnackBar('Gagal menginisialisasi kamera');
    }
  }

  Future<void> _applySettings() async {
    if (_cameraController == null) return;

    try {
      await _cameraController!.setFocusMode(FocusMode.auto);
      if (!kIsWeb) {
        try {
          await _cameraController!.setFlashMode(FlashMode.off);
        } catch (e) {
          // Flash not supported, ignore
        }
      }
    } catch (e) {
      // Settings not supported, ignore
    }
  }

  void _switchCamera() async {
    if (_cameras.length < 2) return;

    try {
      setState(() {
        _isLoading = true;
      });

      await _cameraController?.dispose();

      final newCamera = _isFrontCamera
          ? _cameras.firstWhere(
              (c) => c.lensDirection == CameraLensDirection.back,
              orElse: () => _cameras.first,
            )
          : _cameras.firstWhere(
              (c) => c.lensDirection == CameraLensDirection.front,
              orElse: () => _cameras.first,
            );

      _cameraController = CameraController(
        newCamera,
        kIsWeb ? ResolutionPreset.medium : ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      await _applySettings();

      setState(() {
        _isFrontCamera = newCamera.lensDirection == CameraLensDirection.front;
        _isLoading = false;
      });

      HapticFeedback.mediumImpact();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Gagal mengganti kamera');
    }
  }

  void _capturePhoto() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    try {
      setState(() {
        _isCapturing = true;
      });

      HapticFeedback.heavyImpact();
      final XFile photo = await _cameraController!.takePicture();

      // Simulate processing time
      await Future.delayed(const Duration(milliseconds: 500));

      _showSuccessSnackBar('Foto berhasil diambil');

      setState(() {
        _isCapturing = false;
      });
    } catch (e) {
      setState(() {
        _isCapturing = false;
      });
      _showErrorSnackBar('Gagal mengambil foto');
    }
  }

  void _openGallery() {
    HapticFeedback.lightImpact();
    _showInfoSnackBar('Membuka galeri perangkat...');
  }

  void _openSettings() {
    HapticFeedback.lightImpact();
    _showSettingsBottomSheet();
  }

  void _emergencyDisconnect() {
    HapticFeedback.heavyImpact();
    _showDisconnectDialog();
  }

  void _onDoubleTap() {
    HapticFeedback.mediumImpact();
    _switchCamera();
  }

  void _startConnectionSimulation() {
    _connectionTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        setState(() {
          // Simulate varying connection quality
          _signalStrength = 2 + (DateTime.now().millisecond % 3);
          _latency = 30 + (DateTime.now().millisecond % 70);

          if (_signalStrength >= 3) {
            _quality = 'HD';
          } else if (_signalStrength >= 2) {
            _quality = 'SD';
          } else {
            _quality = 'LOW';
          }
        });
      }
    });
  }

  void _startAutoDisconnectTimer() {
    _autoDisconnectTimer = Timer(const Duration(minutes: 5), () {
      if (mounted) {
        _showAutoDisconnectDialog();
      }
    });
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          'Izin Kamera Diperlukan',
          style: AppTheme.lightTheme.textTheme.titleMedium,
        ),
        content: Text(
          'Aplikasi memerlukan akses kamera untuk dapat menampilkan preview dari perangkat anak.',
          style: AppTheme.lightTheme.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings();
            },
            child: Text('Buka Pengaturan'),
          ),
        ],
      ),
    );
  }

  void _showDisconnectDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Putus Koneksi Darurat',
          style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
            color: AppTheme.lightTheme.colorScheme.error,
          ),
        ),
        content: Text(
          'Apakah Anda yakin ingin memutus koneksi kamera secara darurat? Tindakan ini akan menghentikan semua aktivitas monitoring.',
          style: AppTheme.lightTheme.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.lightTheme.colorScheme.error,
            ),
            child: Text('Putus Koneksi'),
          ),
        ],
      ),
    );
  }

  void _showAutoDisconnectDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          'Sesi Berakhir',
          style: AppTheme.lightTheme.textTheme.titleMedium,
        ),
        content: Text(
          'Sesi monitoring kamera telah berakhir setelah 5 menit untuk melindungi privasi. Anda akan dikembalikan ke dashboard.',
          style: AppTheme.lightTheme.textTheme.bodyMedium,
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: Text('Kembali ke Dashboard'),
          ),
        ],
      ),
    );
  }

  void _showSettingsBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: EdgeInsets.all(4.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pengaturan Kamera',
              style: AppTheme.lightTheme.textTheme.titleMedium,
            ),
            SizedBox(height: 3.h),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'high_quality',
                color: AppTheme.lightTheme.colorScheme.primary,
                size: 6.w,
              ),
              title: Text('Kualitas Video'),
              subtitle: Text(_quality),
              trailing: CustomIconWidget(
                iconName: 'arrow_forward_ios',
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                size: 4.w,
              ),
              onTap: () {
                Navigator.pop(context);
                _showInfoSnackBar(
                    'Kualitas disesuaikan otomatis berdasarkan koneksi');
              },
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'network_check',
                color: AppTheme.lightTheme.colorScheme.primary,
                size: 6.w,
              ),
              title: Text('Status Koneksi'),
              subtitle:
                  Text('Sinyal: $_signalStrength/4, Latensi: ${_latency}ms'),
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'info',
                color: AppTheme.lightTheme.colorScheme.primary,
                size: 6.w,
              ),
              title: Text('Tentang'),
              subtitle: Text('Kontrol Kamera Jarak Jauh v1.0'),
              onTap: () {
                Navigator.pop(context);
                _showInfoSnackBar(
                    'Parent Control Hub - Kontrol Kamera Jarak Jauh');
              },
            ),
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.lightTheme.colorScheme.tertiary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.lightTheme.colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showInfoSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.lightTheme.colorScheme.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Column(
            children: [
              CameraHeaderWidget(
                deviceName: _deviceName,
                isConnected: _isConnected,
                isFrontCamera: _isFrontCamera,
                onCameraSwitch: _switchCamera,
                onBack: () => Navigator.of(context).pop(),
              ),
              CameraPreviewWidget(
                cameraController: _cameraController,
                isLoading: _isLoading,
                isConnected: _isConnected,
                onDoubleTap: _onDoubleTap,
              ),
              CameraControlsWidget(
                onCapture: _capturePhoto,
                onGallery: _openGallery,
                onSettings: _openSettings,
                onEmergencyDisconnect: _emergencyDisconnect,
                isCapturing: _isCapturing,
                isContinuousMode: _isContinuousMode,
              ),
            ],
          ),
          ConnectionStatusWidget(
            isConnected: _isConnected,
            signalStrength: _signalStrength,
            latency: _latency,
            quality: _quality,
          ),
        ],
      ),
    );
  }
}
