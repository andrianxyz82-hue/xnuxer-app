import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class CameraPreviewWidget extends StatefulWidget {
  final CameraController? cameraController;
  final bool isLoading;
  final bool isConnected;
  final VoidCallback onDoubleTap;

  const CameraPreviewWidget({
    super.key,
    required this.cameraController,
    required this.isLoading,
    required this.isConnected,
    required this.onDoubleTap,
  });

  @override
  State<CameraPreviewWidget> createState() => _CameraPreviewWidgetState();
}

class _CameraPreviewWidgetState extends State<CameraPreviewWidget> {
  double _currentZoom = 1.0;
  double _minZoom = 1.0;
  double _maxZoom = 8.0;

  @override
  void initState() {
    super.initState();
    _initializeZoomLevels();
  }

  void _initializeZoomLevels() async {
    if (widget.cameraController != null &&
        widget.cameraController!.value.isInitialized) {
      _minZoom = await widget.cameraController!.getMinZoomLevel();
      _maxZoom = await widget.cameraController!.getMaxZoomLevel();
      setState(() {});
    }
  }

  void _onScaleStart(ScaleStartDetails details) {
    // Store initial zoom level
  }

  void _onScaleUpdate(ScaleUpdateDetails details) async {
    if (widget.cameraController == null ||
        !widget.cameraController!.value.isInitialized) return;

    final double newZoom =
        (_currentZoom * details.scale).clamp(_minZoom, _maxZoom);
    await widget.cameraController!.setZoomLevel(newZoom);
  }

  void _onScaleEnd(ScaleEndDetails details) {
    // Update current zoom level
    if (widget.cameraController != null &&
        widget.cameraController!.value.isInitialized) {
      setState(() {
        // Keep the current zoom as is, since setZoomLevel was already called in _onScaleUpdate
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.symmetric(horizontal: 2.w),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(16),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: widget.isLoading
              ? _buildLoadingPreview()
              : !widget.isConnected
                  ? _buildDisconnectedPreview()
                  : widget.cameraController != null &&
                          widget.cameraController!.value.isInitialized
                      ? _buildCameraPreview()
                      : _buildErrorPreview(),
        ),
      ),
    );
  }

  Widget _buildLoadingPreview() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 12.w,
            height: 12.w,
            child: CircularProgressIndicator(
              color: AppTheme.lightTheme.colorScheme.primary,
              strokeWidth: 3,
            ),
          ),
          SizedBox(height: 3.h),
          Text(
            'Menghubungkan kamera...',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 1.h),
          Text(
            'Mohon tunggu sebentar',
            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDisconnectedPreview() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomIconWidget(
            iconName: 'signal_wifi_off',
            color: AppTheme.lightTheme.colorScheme.error,
            size: 16.w,
          ),
          SizedBox(height: 3.h),
          Text(
            'Koneksi Terputus',
            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 1.h),
          Text(
            'Periksa koneksi internet\ndan coba lagi',
            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorPreview() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomIconWidget(
            iconName: 'camera_alt',
            color: AppTheme.lightTheme.colorScheme.error,
            size: 16.w,
          ),
          SizedBox(height: 3.h),
          Text(
            'Kamera Tidak Tersedia',
            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 1.h),
          Text(
            'Pastikan perangkat memiliki\nizin akses kamera',
            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCameraPreview() {
    return GestureDetector(
      onDoubleTap: widget.onDoubleTap,
      onScaleStart: _onScaleStart,
      onScaleUpdate: _onScaleUpdate,
      onScaleEnd: _onScaleEnd,
      child: Stack(
        children: [
          SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: CameraPreview(widget.cameraController!),
          ),
          if (_currentZoom > 1.0)
            Positioned(
              top: 2.h,
              left: 4.w,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_currentZoom.toStringAsFixed(1)}x',
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          Positioned(
            bottom: 2.h,
            right: 4.w,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomIconWidget(
                    iconName: 'touch_app',
                    color: Colors.white,
                    size: 4.w,
                  ),
                  SizedBox(width: 1.w),
                  Text(
                    'Ketuk 2x untuk ganti mode',
                    style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}