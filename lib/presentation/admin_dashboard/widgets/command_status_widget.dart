import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../models/command_history.dart';

class CommandStatusWidget extends StatelessWidget {
  final CommandHistory commandHistory;

  const CommandStatusWidget({
    Key? key,
    required this.commandHistory,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 0.5.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          // Header Row
          Row(
            children: [
              // Command Icon
              Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: _getCommandColor().withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: CustomIconWidget(
                  iconName: _getCommandIcon(),
                  color: _getCommandColor(),
                  size: 5.w,
                ),
              ),
              SizedBox(width: 3.w),

              // Command Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          commandHistory.commandTypeDisplay,
                          style: AppTheme.lightTheme.textTheme.titleMedium
                              ?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 2.w),
                        // Status Badge
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 2.w, vertical: 0.5.h),
                          decoration: BoxDecoration(
                            color: _getStatusColor().withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            commandHistory.statusDisplay,
                            style: AppTheme.lightTheme.textTheme.bodySmall
                                ?.copyWith(
                              color: _getStatusColor(),
                              fontWeight: FontWeight.w600,
                              fontSize: 8.sp,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      commandHistory.deviceName,
                      style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              // Status Icon
              CustomIconWidget(
                iconName: _getStatusIcon(),
                color: _getStatusColor(),
                size: 5.w,
              ),
            ],
          ),

          SizedBox(height: 2.h),

          // Details Row
          Row(
            children: [
              // Execution Time
              Expanded(
                child: Row(
                  children: [
                    CustomIconWidget(
                      iconName: 'timer',
                      color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      size: 3.w,
                    ),
                    SizedBox(width: 1.w),
                    Text(
                      commandHistory.executionTimeDisplay,
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // Timestamp
              Row(
                children: [
                  CustomIconWidget(
                    iconName: 'access_time',
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    size: 3.w,
                  ),
                  SizedBox(width: 1.w),
                  Text(
                    _formatTimestamp(commandHistory.createdAt),
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Error Details (if any)
          if (commandHistory.errorDetails != null) ...[
            SizedBox(height: 1.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.error
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  CustomIconWidget(
                    iconName: 'error_outline',
                    color: AppTheme.lightTheme.colorScheme.error,
                    size: 3.w,
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      commandHistory.errorDetails!,
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Loading indicator for executing commands
          if (commandHistory.isExecuting) ...[
            SizedBox(height: 1.h),
            LinearProgressIndicator(
              backgroundColor: AppTheme.lightTheme.colorScheme.primary
                  .withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(
                AppTheme.lightTheme.colorScheme.primary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getCommandColor() {
    switch (commandHistory.commandType) {
      case 'flash':
        return AppTheme.lightTheme.colorScheme.tertiary;
      case 'camera':
        return AppTheme.lightTheme.colorScheme.primary;
      case 'audio':
        return AppTheme.lightTheme.colorScheme.secondary;
      case 'wallpaper':
        return const Color(0xFF8B5CF6);
      case 'system':
        return AppTheme.lightTheme.colorScheme.onSurface;
      default:
        return AppTheme.lightTheme.colorScheme.primary;
    }
  }

  String _getCommandIcon() {
    switch (commandHistory.commandType) {
      case 'flash':
        return 'flashlight_on';
      case 'camera':
        return 'camera_alt';
      case 'audio':
        return 'volume_up';
      case 'wallpaper':
        return 'wallpaper';
      case 'system':
        return 'settings';
      default:
        return 'smartphone';
    }
  }

  Color _getStatusColor() {
    switch (commandHistory.status) {
      case 'success':
        return AppTheme.lightTheme.colorScheme.tertiary;
      case 'failed':
        return AppTheme.lightTheme.colorScheme.error;
      case 'executing':
        return AppTheme.lightTheme.colorScheme.primary;
      case 'pending':
        return AppTheme.lightTheme.colorScheme.secondary;
      case 'timeout':
        return AppTheme.lightTheme.colorScheme.error;
      default:
        return AppTheme.lightTheme.colorScheme.onSurface;
    }
  }

  String _getStatusIcon() {
    switch (commandHistory.status) {
      case 'success':
        return 'check_circle';
      case 'failed':
        return 'error';
      case 'executing':
        return 'hourglass_empty';
      case 'pending':
        return 'schedule';
      case 'timeout':
        return 'timer_off';
      default:
        return 'help_outline';
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Baru saja';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}j';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}h';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}
