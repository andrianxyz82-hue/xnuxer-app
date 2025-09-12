import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import './widgets/upload_progress_widget.dart';
import './widgets/wallpaper_gallery_widget.dart';
import './widgets/wallpaper_preview_widget.dart';
import './widgets/wallpaper_source_card.dart';

class WallpaperControlScreen extends StatefulWidget {
  const WallpaperControlScreen({Key? key}) : super(key: key);

  @override
  State<WallpaperControlScreen> createState() => _WallpaperControlScreenState();
}

class _WallpaperControlScreenState extends State<WallpaperControlScreen>
    with TickerProviderStateMixin {
  final ImagePicker _imagePicker = ImagePicker();
  List<CameraDescription> _cameras = [];
  CameraController? _cameraController;

  String _currentView = 'main'; // main, gallery, camera, preview
  String? _selectedImagePath;
  String? _selectedImageUrl;
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String _uploadMessage = '';
  bool _isCameraInitialized = false;
  XFile? _capturedImage;

  // Mock device data
  final Map<String, dynamic> _deviceInfo = {
    "deviceName": "Samsung Galaxy A54",
    "deviceId": "SM-A546B",
    "lastSeen": "2 menit yang lalu",
    "status": "online",
    "batteryLevel": 78,
  };

  // Mock wallpaper history
  final List<Map<String, dynamic>> _wallpaperHistory = [
    {
      "id": "1",
      "url":
          "https://images.pexels.com/photos/1366919/pexels-photo-1366919.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1",
      "appliedAt": "2025-01-12 18:30:00",
      "type": "preset"
    },
    {
      "id": "2",
      "url":
          "https://images.pexels.com/photos/1323550/pexels-photo-1323550.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1",
      "appliedAt": "2025-01-12 15:45:00",
      "type": "gallery"
    },
  ];

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    try {
      if (!kIsWeb) {
        final cameras = await availableCameras();
        if (cameras.isNotEmpty) {
          setState(() {
            _cameras = cameras;
          });
        }
      }
    } catch (e) {
      debugPrint('Error initializing camera: \$e');
    }
  }

  Future<bool> _requestCameraPermission() async {
    if (kIsWeb) return true;

    final status = await Permission.camera.request();
    return status.isGranted;
  }

  Future<bool> _requestStoragePermission() async {
    if (kIsWeb) return true;

    final status = await Permission.storage.request();
    return status.isGranted;
  }

  Future<void> _setupCameraController() async {
    if (_cameras.isEmpty || _cameraController != null) return;

    try {
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

      if (!kIsWeb) {
        try {
          await _cameraController!.setFocusMode(FocusMode.auto);
          await _cameraController!.setFlashMode(FlashMode.auto);
        } catch (e) {
          debugPrint('Error setting camera modes: \$e');
        }
      }

      setState(() {
        _isCameraInitialized = true;
      });
    } catch (e) {
      debugPrint('Error setting up camera: \$e');
      _showErrorToast('Gagal mengakses kamera');
    }
  }

  Future<void> _capturePhoto() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    try {
      final XFile photo = await _cameraController!.takePicture();
      setState(() {
        _capturedImage = photo;
        _selectedImagePath = photo.path;
        _currentView = 'preview';
      });
    } catch (e) {
      debugPrint('Error capturing photo: \$e');
      _showErrorToast('Gagal mengambil foto');
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      if (!await _requestStoragePermission()) {
        _showErrorToast('Izin akses galeri diperlukan');
        return;
      }

      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImagePath = image.path;
          _selectedImageUrl = null;
          _currentView = 'preview';
        });
      }
    } catch (e) {
      debugPrint('Error picking from gallery: \$e');
      _showErrorToast('Gagal memilih gambar dari galeri');
    }
  }

  Future<void> _openCamera() async {
    try {
      if (!await _requestCameraPermission()) {
        _showErrorToast('Izin akses kamera diperlukan');
        return;
      }

      await _setupCameraController();

      if (_isCameraInitialized) {
        setState(() {
          _currentView = 'camera';
        });
      } else {
        _showErrorToast('Gagal menginisialisasi kamera');
      }
    } catch (e) {
      debugPrint('Error opening camera: \$e');
      _showErrorToast('Gagal membuka kamera');
    }
  }

  void _openPresetGallery() {
    setState(() {
      _currentView = 'gallery';
    });
  }

  void _onImageSelected(String imageUrl) {
    setState(() {
      _selectedImageUrl = imageUrl;
      _selectedImagePath = null;
      _currentView = 'preview';
    });
  }

  Future<void> _setWallpaper() async {
    if (_selectedImagePath == null && _selectedImageUrl == null) {
      _showErrorToast('Tidak ada gambar yang dipilih');
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
      _uploadMessage = 'Memproses gambar...';
    });

    try {
      // Simulate upload progress
      for (int i = 0; i <= 100; i += 10) {
        await Future.delayed(Duration(milliseconds: 200));
        setState(() {
          _uploadProgress = i.toDouble();
          if (i < 30) {
            _uploadMessage = 'Mengompres gambar...';
          } else if (i < 70) {
            _uploadMessage = 'Mengunggah ke perangkat...';
          } else if (i < 100) {
            _uploadMessage = 'Menerapkan wallpaper...';
          } else {
            _uploadMessage = 'Wallpaper berhasil diterapkan!';
          }
        });
      }

      // Simulate successful wallpaper application
      await Future.delayed(Duration(milliseconds: 500));

      _showSuccessToast(
          'Wallpaper berhasil diterapkan pada ${_deviceInfo["deviceName"]}');

      // Add to history
      final newHistoryItem = {
        "id": DateTime.now().millisecondsSinceEpoch.toString(),
        "url": _selectedImageUrl ?? _selectedImagePath ?? "",
        "appliedAt": DateTime.now().toString(),
        "type": _selectedImageUrl != null ? "preset" : "custom"
      };

      setState(() {
        _wallpaperHistory.insert(0, newHistoryItem);
        _isUploading = false;
        _currentView = 'main';
        _selectedImagePath = null;
        _selectedImageUrl = null;
      });
    } catch (e) {
      debugPrint('Error setting wallpaper: \$e');
      setState(() {
        _isUploading = false;
      });
      _showErrorToast('Gagal menerapkan wallpaper');
    }
  }

  void _showErrorToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: AppTheme.lightTheme.colorScheme.error,
      textColor: Colors.white,
    );
  }

  void _showSuccessToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: AppTheme.lightTheme.colorScheme.tertiary,
      textColor: Colors.white,
    );
  }

  void _goBack() {
    if (_currentView == 'camera' && _cameraController != null) {
      _cameraController!.dispose();
      _cameraController = null;
      setState(() {
        _isCameraInitialized = false;
      });
    }

    setState(() {
      _currentView = 'main';
      _selectedImagePath = null;
      _selectedImageUrl = null;
      _capturedImage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      body: SafeArea(
        child: _isUploading ? _buildUploadingView() : _buildCurrentView(),
      ),
    );
  }

  Widget _buildUploadingView() {
    return Center(
      child: UploadProgressWidget(
        progress: _uploadProgress,
        message: _uploadMessage,
        isCompleted: _uploadProgress >= 100,
        onCancel: _uploadProgress < 100
            ? () {
                setState(() {
                  _isUploading = false;
                  _uploadProgress = 0.0;
                });
              }
            : null,
      ),
    );
  }

  Widget _buildCurrentView() {
    switch (_currentView) {
      case 'gallery':
        return WallpaperGalleryWidget(
          onImageSelected: _onImageSelected,
          onBack: _goBack,
        );
      case 'camera':
        return _buildCameraView();
      case 'preview':
        return WallpaperPreviewWidget(
          imagePath: _selectedImagePath,
          imageUrl: _selectedImageUrl,
          onClose: _goBack,
          onSetWallpaper: _setWallpaper,
        );
      default:
        return _buildMainView();
    }
  }

  Widget _buildMainView() {
    return Column(
      children: [
        _buildHeader(),
        _buildDeviceInfo(),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(4.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSourceOptions(),
                SizedBox(height: 4.h),
                _buildWallpaperHistory(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: CustomIconWidget(
              iconName: 'arrow_back',
              color: AppTheme.lightTheme.colorScheme.onSurface,
              size: 6.w,
            ),
          ),
          Expanded(
            child: Text(
              'Ubah Wallpaper',
              style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(width: 12.w),
        ],
      ),
    );
  }

  Widget _buildDeviceInfo() {
    return Container(
      margin: EdgeInsets.all(4.w),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: CustomIconWidget(
              iconName: 'smartphone',
              color: AppTheme.lightTheme.primaryColor,
              size: 6.w,
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _deviceInfo["deviceName"],
                  style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 0.5.h),
                Row(
                  children: [
                    Container(
                      width: 2.w,
                      height: 2.w,
                      decoration: BoxDecoration(
                        color: AppTheme.lightTheme.colorScheme.tertiary,
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      _deviceInfo["status"] == "online" ? "Online" : "Offline",
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.tertiary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      "• ${_deviceInfo["lastSeen"]}",
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.h),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.surface,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomIconWidget(
                  iconName: 'battery_std',
                  color: AppTheme.lightTheme.colorScheme.tertiary,
                  size: 4.w,
                ),
                SizedBox(width: 1.w),
                Text(
                  "${_deviceInfo["batteryLevel"]}%",
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSourceOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pilih Sumber Wallpaper',
          style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 2.h),
        GridView.count(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 3.w,
          mainAxisSpacing: 3.w,
          childAspectRatio: 1.1,
          children: [
            WallpaperSourceCard(
              title: 'Galeri Foto',
              description: 'Pilih dari galeri perangkat',
              iconName: 'photo_library',
              onTap: _pickFromGallery,
            ),
            WallpaperSourceCard(
              title: 'Ambil Foto',
              description: 'Gunakan kamera untuk mengambil foto',
              iconName: 'camera_alt',
              onTap: _openCamera,
            ),
            WallpaperSourceCard(
              title: 'Koleksi Preset',
              description: 'Pilih dari koleksi wallpaper',
              iconName: 'collections',
              onTap: _openPresetGallery,
            ),
            WallpaperSourceCard(
              title: 'Riwayat',
              description: 'Gunakan wallpaper sebelumnya',
              iconName: 'history',
              onTap: () {
                if (_wallpaperHistory.isNotEmpty) {
                  _onImageSelected(_wallpaperHistory.first["url"]);
                } else {
                  _showErrorToast('Tidak ada riwayat wallpaper');
                }
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWallpaperHistory() {
    if (_wallpaperHistory.isEmpty) {
      return SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Riwayat Wallpaper',
          style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 2.h),
        SizedBox(
          height: 25.h,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount:
                _wallpaperHistory.length > 5 ? 5 : _wallpaperHistory.length,
            separatorBuilder: (context, index) => SizedBox(width: 3.w),
            itemBuilder: (context, index) {
              final wallpaper = _wallpaperHistory[index];
              return _buildHistoryItem(wallpaper);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryItem(Map<String, dynamic> wallpaper) {
    return GestureDetector(
      onTap: () => _onImageSelected(wallpaper["url"]),
      child: Container(
        width: 35.w,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CustomImageWidget(
                imageUrl: wallpaper["url"],
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.7),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 2.w,
                left: 2.w,
                right: 2.w,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      wallpaper["type"] == "preset" ? "Preset" : "Kustom",
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                    Text(
                      DateTime.parse(wallpaper["appliedAt"]).day.toString() +
                          "/" +
                          DateTime.parse(wallpaper["appliedAt"])
                              .month
                              .toString(),
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCameraView() {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
          color: Colors.black,
          child: Row(
            children: [
              IconButton(
                onPressed: _goBack,
                icon: CustomIconWidget(
                  iconName: 'close',
                  color: Colors.white,
                  size: 6.w,
                ),
              ),
              Expanded(
                child: Text(
                  'Ambil Foto',
                  style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(width: 12.w),
            ],
          ),
        ),
        Expanded(
          child: _isCameraInitialized && _cameraController != null
              ? CameraPreview(_cameraController!)
              : Container(
                  color: Colors.black,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          color: Colors.white,
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          'Menginisialisasi kamera...',
                          style: AppTheme.lightTheme.textTheme.bodyMedium
                              ?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
        Container(
          padding: EdgeInsets.all(4.w),
          color: Colors.black,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                onPressed: _pickFromGallery,
                icon: CustomIconWidget(
                  iconName: 'photo_library',
                  color: Colors.white,
                  size: 8.w,
                ),
              ),
              GestureDetector(
                onTap: _isCameraInitialized ? _capturePhoto : null,
                child: Container(
                  width: 18.w,
                  height: 18.w,
                  decoration: BoxDecoration(
                    color: _isCameraInitialized ? Colors.white : Colors.grey,
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(
                      color: Colors.white,
                      width: 3,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8.w),
            ],
          ),
        ),
      ],
    );
  }
}
