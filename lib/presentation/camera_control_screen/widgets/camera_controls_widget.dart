import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class CameraControlsWidget extends StatefulWidget {
  final VoidCallback onCapture;
  final VoidCallback onGallery;
  final VoidCallback onSettings;
  final VoidCallback onEmergencyDisconnect;
  final bool isCapturing;
  final bool isContinuousMode;

  const CameraControlsWidget({
    super.key,
    required this.onCapture,
    required this.onGallery,
    required this.onSettings,
    required this.onEmergencyDisconnect,
    this.isCapturing = false,
    this.isContinuousMode = false,
  });

  @override
  State<CameraControlsWidget> createState() => _CameraControlsWidgetState();
}

class _CameraControlsWidgetState extends State<CameraControlsWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isLongPressing = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.9,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onCaptureStart() {
    HapticFeedback.lightImpact();
    _animationController.forward();
    setState(() {
      _isLongPressing = true;
    });
  }

  void _onCaptureEnd() {
    _animationController.reverse();
    if (_isLongPressing) {
      widget.onCapture();
      HapticFeedback.mediumImpact();
    }
    setState(() {
      _isLongPressing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildControlButton(
              icon: 'photo_library',
              label: 'Galeri',
              onTap: widget.onGallery,
            ),
            _buildCaptureButton(),
            _buildControlButton(
              icon: 'settings',
              label: 'Pengaturan',
              onTap: widget.onSettings,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required String icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomIconWidget(
              iconName: icon,
              color: AppTheme.lightTheme.colorScheme.onSurface,
              size: 6.w,
            ),
            SizedBox(height: 1.h),
            Text(
              label,
              style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCaptureButton() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTapDown: (_) => _onCaptureStart(),
          onTapUp: (_) => _onCaptureEnd(),
          onTapCancel: () => _onCaptureEnd(),
          onLongPress: () {
            HapticFeedback.heavyImpact();
            // Enable continuous mode
          },
          child: AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Container(
                  width: 20.w,
                  height: 20.w,
                  decoration: BoxDecoration(
                    color: widget.isCapturing
                        ? AppTheme.lightTheme.colorScheme.error
                        : AppTheme.lightTheme.colorScheme.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (widget.isCapturing
                                ? AppTheme.lightTheme.colorScheme.error
                                : AppTheme.lightTheme.colorScheme.primary)
                            .withValues(alpha: 0.3),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: widget.isCapturing
                      ? SizedBox(
                          width: 8.w,
                          height: 8.w,
                          child: CircularProgressIndicator(
                            color: AppTheme.lightTheme.colorScheme.onError,
                            strokeWidth: 3,
                          ),
                        )
                      : CustomIconWidget(
                          iconName:
                              widget.isContinuousMode ? 'stop' : 'camera_alt',
                          color: AppTheme.lightTheme.colorScheme.onPrimary,
                          size: 8.w,
                        ),
                ),
              );
            },
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          widget.isCapturing
              ? 'Mengambil...'
              : widget.isContinuousMode
                  ? 'Tahan untuk berhenti'
                  : 'Tahan untuk mode beruntun',
          style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 2.h),
        GestureDetector(
          onTap: widget.onEmergencyDisconnect,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
            decoration: BoxDecoration(
              color:
                  AppTheme.lightTheme.colorScheme.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.lightTheme.colorScheme.error
                    .withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomIconWidget(
                  iconName: 'emergency',
                  color: AppTheme.lightTheme.colorScheme.error,
                  size: 4.w,
                ),
                SizedBox(width: 2.w),
                Text(
                  'Putus Darurat',
                  style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
