import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class UploadProgressWidget extends StatelessWidget {
  final double progress;
  final String message;
  final bool isCompleted;
  final VoidCallback? onCancel;

  const UploadProgressWidget({
    Key? key,
    required this.progress,
    required this.message,
    this.isCompleted = false,
    this.onCancel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(4.w),
      padding: EdgeInsets.all(6.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildProgressIcon(),
          SizedBox(height: 3.h),
          _buildProgressBar(),
          SizedBox(height: 2.h),
          _buildProgressText(),
          if (!isCompleted && onCancel != null) ...[
            SizedBox(height: 3.h),
            _buildCancelButton(),
          ],
        ],
      ),
    );
  }

  Widget _buildProgressIcon() {
    return Container(
      width: 16.w,
      height: 16.w,
      decoration: BoxDecoration(
        color: isCompleted
            ? AppTheme.lightTheme.colorScheme.tertiary.withValues(alpha: 0.1)
            : AppTheme.lightTheme.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(50),
      ),
      child: isCompleted
          ? CustomIconWidget(
              iconName: 'check_circle',
              color: AppTheme.lightTheme.colorScheme.tertiary,
              size: 8.w,
            )
          : Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 10.w,
                  height: 10.w,
                  child: CircularProgressIndicator(
                    value: progress / 100,
                    backgroundColor: AppTheme.lightTheme.colorScheme.outline
                        .withValues(alpha: 0.3),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppTheme.lightTheme.primaryColor,
                    ),
                    strokeWidth: 3,
                  ),
                ),
                CustomIconWidget(
                  iconName: 'cloud_upload',
                  color: AppTheme.lightTheme.primaryColor,
                  size: 5.w,
                ),
              ],
            ),
    );
  }

  Widget _buildProgressBar() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              isCompleted ? 'Selesai' : 'Mengunggah...',
              style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${progress.toInt()}%',
              style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                color: AppTheme.lightTheme.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SizedBox(height: 1.h),
        LinearProgressIndicator(
          value: progress / 100,
          backgroundColor:
              AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.3),
          valueColor: AlwaysStoppedAnimation<Color>(
            isCompleted
                ? AppTheme.lightTheme.colorScheme.tertiary
                : AppTheme.lightTheme.primaryColor,
          ),
          minHeight: 1.h,
        ),
      ],
    );
  }

  Widget _buildProgressText() {
    return Text(
      message,
      style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
        color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
      ),
      textAlign: TextAlign.center,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildCancelButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onCancel,
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: AppTheme.lightTheme.colorScheme.error,
          ),
          padding: EdgeInsets.symmetric(vertical: 2.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          'Batalkan',
          style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
            color: AppTheme.lightTheme.colorScheme.error,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
