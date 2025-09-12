import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../models/connected_device.dart';

class DeviceCardWidget extends StatelessWidget {
  final ConnectedDevice device;
  final VoidCallback? onTap;
  final VoidCallback? onQuickFlash;
  final VoidCallback? onQuickCamera;
  final VoidCallback? onQuickAudio;

  const DeviceCardWidget({
    Key? key,
    required this.device,
    this.onTap,
    this.onQuickFlash,
    this.onQuickCamera,
    this.onQuickAudio,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Device Header
            Row(
              children: [
                // Device Icon
                Container(
                  padding: EdgeInsets.all(3.w),
                  decoration: BoxDecoration(
                    color: device.isOnline
                        ? AppTheme.lightTheme.colorScheme.primary
                            .withValues(alpha: 0.1)
                        : AppTheme.lightTheme.colorScheme.outline
                            .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: CustomIconWidget(
                    iconName: 'smartphone',
                    color: device.isOnline
                        ? AppTheme.lightTheme.colorScheme.primary
                        : AppTheme.lightTheme.colorScheme.outline,
                    size: 6.w,
                  ),
                ),
                SizedBox(width: 3.w),

                // Device Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        device.childName,
                        style:
                            AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        device.deviceModel,
                        style:
                            AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                          color:
                              AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),

                // Status Badge
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                  decoration: BoxDecoration(
                    color: device.isOnline
                        ? AppTheme.lightTheme.colorScheme.tertiary
                            .withValues(alpha: 0.2)
                        : AppTheme.lightTheme.colorScheme.error
                            .withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    device.isOnline ? 'Online' : 'Offline',
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: device.isOnline
                          ? AppTheme.lightTheme.colorScheme.tertiary
                          : AppTheme.lightTheme.colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 2.h),

            // Device Details
            Row(
              children: [
                // Battery Level
                Expanded(
                  child: Row(
                    children: [
                      CustomIconWidget(
                        iconName: device.batteryLevel != null &&
                                device.batteryLevel! > 20
                            ? 'battery_full'
                            : 'battery_alert',
                        color: device.batteryLevel != null &&
                                device.batteryLevel! > 20
                            ? AppTheme.lightTheme.colorScheme.tertiary
                            : AppTheme.lightTheme.colorScheme.error,
                        size: 4.w,
                      ),
                      SizedBox(width: 1.w),
                      Text(
                        '${device.batteryLevel ?? 0}%',
                        style:
                            AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                // Location
                Expanded(
                  child: Row(
                    children: [
                      CustomIconWidget(
                        iconName: 'location_on',
                        color: AppTheme.lightTheme.colorScheme.primary,
                        size: 4.w,
                      ),
                      SizedBox(width: 1.w),
                      Expanded(
                        child: Text(
                          device.location ?? '-',
                          style: AppTheme.lightTheme.textTheme.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                // Connection Security
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                  decoration: BoxDecoration(
                    color: device.isSecureConnection
                        ? AppTheme.lightTheme.colorScheme.tertiary
                            .withValues(alpha: 0.1)
                        : AppTheme.lightTheme.colorScheme.error
                            .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CustomIconWidget(
                        iconName:
                            device.isSecureConnection ? 'lock' : 'lock_open',
                        color: device.isSecureConnection
                            ? AppTheme.lightTheme.colorScheme.tertiary
                            : AppTheme.lightTheme.colorScheme.error,
                        size: 3.w,
                      ),
                      SizedBox(width: 0.5.w),
                      Text(
                        device.isSecureConnection ? 'Aman' : 'Tidak Aman',
                        style:
                            AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                          color: device.isSecureConnection
                              ? AppTheme.lightTheme.colorScheme.tertiary
                              : AppTheme.lightTheme.colorScheme.error,
                          fontSize: 8.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: 1.h),

            // Last Activity
            Row(
              children: [
                CustomIconWidget(
                  iconName: 'access_time',
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  size: 3.w,
                ),
                SizedBox(width: 1.w),
                Text(
                  'Terakhir aktif: ${device.lastActivityText}',
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),

            SizedBox(height: 2.h),

            // Quick Actions
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionButton(
                    icon: 'flashlight_on',
                    label: 'Flash',
                    color: AppTheme.lightTheme.colorScheme.tertiary,
                    onTap: onQuickFlash,
                    enabled: device.isOnline,
                  ),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: _buildQuickActionButton(
                    icon: 'camera_alt',
                    label: 'Kamera',
                    color: AppTheme.lightTheme.colorScheme.primary,
                    onTap: onQuickCamera,
                    enabled: device.isOnline,
                  ),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: _buildQuickActionButton(
                    icon: 'volume_up',
                    label: 'Audio',
                    color: AppTheme.lightTheme.colorScheme.secondary,
                    onTap: onQuickAudio,
                    enabled: device.isOnline,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton({
    required String icon,
    required String label,
    required Color color,
    required VoidCallback? onTap,
    required bool enabled,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 1.5.h, horizontal: 2.w),
        decoration: BoxDecoration(
          color: enabled
              ? color.withValues(alpha: 0.1)
              : AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            CustomIconWidget(
              iconName: icon,
              color: enabled ? color : AppTheme.lightTheme.colorScheme.outline,
              size: 4.w,
            ),
            SizedBox(height: 0.5.h),
            Text(
              label,
              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                color:
                    enabled ? color : AppTheme.lightTheme.colorScheme.outline,
                fontWeight: FontWeight.w500,
                fontSize: 8.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
