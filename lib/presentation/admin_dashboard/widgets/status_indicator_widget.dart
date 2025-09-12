import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class StatusIndicatorWidget extends StatelessWidget {
  final bool isSecure;
  final int connectedDevices;
  final bool isLoading;
  final Map<String, dynamic> stats;

  const StatusIndicatorWidget({
    Key? key,
    required this.isSecure,
    required this.connectedDevices,
    required this.isLoading,
    this.stats = const {},
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.lightTheme.colorScheme.primary,
            AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color:
                AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header Row
          Row(
            children: [
              // Security Status
              Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: CustomIconWidget(
                  iconName: isSecure ? 'shield' : 'warning',
                  color: Colors.white,
                  size: 6.w,
                ),
              ),
              SizedBox(width: 3.w),

              // Status Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isSecure ? 'Koneksi Aman' : 'Koneksi Tidak Aman',
                      style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Status Sistem Parent Control Hub',
                      style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),

              // Loading/Status indicator
              if (isLoading)
                Container(
                  width: 6.w,
                  height: 6.w,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    strokeWidth: 2,
                  ),
                )
              else
                Container(
                  padding: EdgeInsets.all(1.w),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Container(
                    width: 3.w,
                    height: 3.w,
                    decoration: BoxDecoration(
                      color: isSecure ? Colors.green : Colors.orange,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),

          SizedBox(height: 3.h),

          // Stats Row
          Row(
            children: [
              // Total Devices
              Expanded(
                child: _buildStatItem(
                  icon: 'devices',
                  value: stats['total_devices']?.toString() ??
                      connectedDevices.toString(),
                  label: 'Total Perangkat',
                ),
              ),

              Container(
                width: 1,
                height: 6.h,
                color: Colors.white.withValues(alpha: 0.3),
              ),

              // Online Devices
              Expanded(
                child: _buildStatItem(
                  icon: 'wifi',
                  value: stats['online_devices']?.toString() ?? '0',
                  label: 'Perangkat Online',
                ),
              ),

              Container(
                width: 1,
                height: 6.h,
                color: Colors.white.withValues(alpha: 0.3),
              ),

              // Today's Commands
              Expanded(
                child: _buildStatItem(
                  icon: 'flash_on',
                  value: stats['today_commands']?.toString() ?? '0',
                  label: 'Perintah Hari Ini',
                ),
              ),
            ],
          ),

          // Success Rate (if available)
          if (stats['success_rate'] != null) ...[
            SizedBox(height: 2.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  CustomIconWidget(
                    iconName: 'analytics',
                    color: Colors.white,
                    size: 4.w,
                  ),
                  SizedBox(width: 2.w),
                  Text(
                    'Tingkat Keberhasilan: ${(stats['success_rate'] as double).toStringAsFixed(1)}%',
                    style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Spacer(),
                  Container(
                    width: 20.w,
                    height: 0.5.h,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: (stats['success_rate'] as double) / 100,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        CustomIconWidget(
          iconName: icon,
          color: Colors.white,
          size: 8.w,
        ),
        SizedBox(height: 1.h),
        Text(
          value,
          style: AppTheme.lightTheme.textTheme.headlineMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 9.sp,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
