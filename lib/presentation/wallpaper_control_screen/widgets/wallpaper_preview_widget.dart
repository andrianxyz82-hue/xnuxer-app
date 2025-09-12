import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class WallpaperPreviewWidget extends StatefulWidget {
  final String? imagePath;
  final String? imageUrl;
  final VoidCallback? onClose;
  final VoidCallback? onSetWallpaper;
  final bool isLoading;

  const WallpaperPreviewWidget({
    Key? key,
    this.imagePath,
    this.imageUrl,
    this.onClose,
    this.onSetWallpaper,
    this.isLoading = false,
  }) : super(key: key);

  @override
  State<WallpaperPreviewWidget> createState() => _WallpaperPreviewWidgetState();
}

class _WallpaperPreviewWidgetState extends State<WallpaperPreviewWidget> {
  final TransformationController _transformationController =
      TransformationController();
  String _selectedTarget = 'both';

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _buildPreviewArea(),
            ),
            _buildBottomToolbar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      color: Colors.black.withValues(alpha: 0.8),
      child: Row(
        children: [
          IconButton(
            onPressed: widget.onClose,
            icon: CustomIconWidget(
              iconName: 'close',
              color: Colors.white,
              size: 6.w,
            ),
          ),
          Expanded(
            child: Text(
              'Pratinjau Wallpaper',
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
    );
  }

  Widget _buildPreviewArea() {
    return Container(
      width: double.infinity,
      child: InteractiveViewer(
        transformationController: _transformationController,
        minScale: 0.5,
        maxScale: 3.0,
        child: Center(
          child: Container(
            constraints: BoxConstraints(
              maxWidth: 80.w,
              maxHeight: 60.h,
            ),
            child: AspectRatio(
              aspectRatio: 9 / 16,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: widget.imageUrl != null
                    ? CustomImageWidget(
                        imageUrl: widget.imageUrl!,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                      )
                    : widget.imagePath != null
                        ? Image.asset(
                            widget.imagePath!,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            color: AppTheme.lightTheme.colorScheme.surface,
                            child: Center(
                              child: CustomIconWidget(
                                iconName: 'image',
                                color: AppTheme
                                    .lightTheme.colorScheme.onSurfaceVariant,
                                size: 12.w,
                              ),
                            ),
                          ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomToolbar() {
    return Container(
      padding: EdgeInsets.all(4.w),
      color: Colors.black.withValues(alpha: 0.8),
      child: Column(
        children: [
          _buildTargetOptions(),
          SizedBox(height: 2.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: widget.isLoading ? null : widget.onSetWallpaper,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.lightTheme.primaryColor,
                padding: EdgeInsets.symmetric(vertical: 2.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: widget.isLoading
                  ? SizedBox(
                      height: 5.w,
                      width: 5.w,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'Atur sebagai Wallpaper',
                      style:
                          AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTargetOptions() {
    return Row(
      children: [
        Text(
          'Terapkan ke:',
          style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
            color: Colors.white,
          ),
        ),
        SizedBox(width: 4.w),
        Expanded(
          child: Row(
            children: [
              _buildTargetOption('home', 'Layar Utama'),
              SizedBox(width: 4.w),
              _buildTargetOption('lock', 'Layar Kunci'),
              SizedBox(width: 4.w),
              _buildTargetOption('both', 'Keduanya'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTargetOption(String value, String label) {
    final isSelected = _selectedTarget == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTarget = value),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 1.h, horizontal: 2.w),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.lightTheme.primaryColor
                : Colors.transparent,
            border: Border.all(
              color: isSelected
                  ? AppTheme.lightTheme.primaryColor
                  : Colors.white.withValues(alpha: 0.3),
            ),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            label,
            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
              color: isSelected
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.8),
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}
