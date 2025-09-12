import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class ConnectionStatusWidget extends StatefulWidget {
  final bool isConnected;
  final int signalStrength; // 0-4
  final int latency; // in milliseconds
  final String quality; // 'HD', 'SD', 'LOW'

  const ConnectionStatusWidget({
    super.key,
    required this.isConnected,
    required this.signalStrength,
    required this.latency,
    required this.quality,
  });

  @override
  State<ConnectionStatusWidget> createState() => _ConnectionStatusWidgetState();
}

class _ConnectionStatusWidgetState extends State<ConnectionStatusWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    if (widget.isConnected) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(ConnectionStatusWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isConnected && !oldWidget.isConnected) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.isConnected && oldWidget.isConnected) {
      _pulseController.stop();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Color _getSignalColor() {
    if (!widget.isConnected) return AppTheme.lightTheme.colorScheme.error;

    switch (widget.signalStrength) {
      case 4:
        return AppTheme.lightTheme.colorScheme.tertiary;
      case 3:
        return AppTheme.lightTheme.colorScheme.tertiary;
      case 2:
        return Colors.orange;
      case 1:
        return Colors.orange;
      default:
        return AppTheme.lightTheme.colorScheme.error;
    }
  }

  String _getQualityText() {
    switch (widget.quality) {
      case 'HD':
        return 'HD';
      case 'SD':
        return 'SD';
      case 'LOW':
        return 'Rendah';
      default:
        return 'Auto';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 12.h,
      right: 4.w,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.5.h),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Signal strength indicator
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: widget.isConnected ? _pulseAnimation.value : 1.0,
                      child: _buildSignalBars(),
                    );
                  },
                ),
                SizedBox(width: 2.w),
                Text(
                  '${widget.signalStrength}/4',
                  style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            SizedBox(height: 1.h),
            // Latency indicator
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomIconWidget(
                  iconName: 'access_time',
                  color: _getLatencyColor(),
                  size: 3.w,
                ),
                SizedBox(width: 1.w),
                Text(
                  '${widget.latency}ms',
                  style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            SizedBox(height: 1.h),
            // Quality indicator
            Container(
              padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
              decoration: BoxDecoration(
                color: _getQualityColor().withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: _getQualityColor(),
                  width: 1,
                ),
              ),
              child: Text(
                _getQualityText(),
                style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                  color: _getQualityColor(),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignalBars() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(4, (index) {
        final isActive = index < widget.signalStrength && widget.isConnected;
        return Container(
          width: 1.w,
          height: (index + 1) * 1.h,
          margin: EdgeInsets.only(right: index < 3 ? 0.5.w : 0),
          decoration: BoxDecoration(
            color: isActive
                ? _getSignalColor()
                : Colors.white.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(1),
          ),
        );
      }),
    );
  }

  Color _getLatencyColor() {
    if (widget.latency <= 50) return AppTheme.lightTheme.colorScheme.tertiary;
    if (widget.latency <= 100) return Colors.orange;
    return AppTheme.lightTheme.colorScheme.error;
  }

  Color _getQualityColor() {
    switch (widget.quality) {
      case 'HD':
        return AppTheme.lightTheme.colorScheme.tertiary;
      case 'SD':
        return Colors.orange;
      case 'LOW':
        return AppTheme.lightTheme.colorScheme.error;
      default:
        return Colors.white;
    }
  }
}
