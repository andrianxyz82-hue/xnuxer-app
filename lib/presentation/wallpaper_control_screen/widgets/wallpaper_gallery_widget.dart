import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class WallpaperGalleryWidget extends StatefulWidget {
  final Function(String imageUrl) onImageSelected;
  final VoidCallback? onBack;

  const WallpaperGalleryWidget({
    Key? key,
    required this.onImageSelected,
    this.onBack,
  }) : super(key: key);

  @override
  State<WallpaperGalleryWidget> createState() => _WallpaperGalleryWidgetState();
}

class _WallpaperGalleryWidgetState extends State<WallpaperGalleryWidget> {
  String _selectedCategory = 'all';
  final ScrollController _scrollController = ScrollController();

  final List<Map<String, dynamic>> _wallpaperCategories = [
    {'id': 'all', 'name': 'Semua', 'icon': 'apps'},
    {'id': 'nature', 'name': 'Alam', 'icon': 'nature'},
    {'id': 'abstract', 'name': 'Abstrak', 'icon': 'auto_awesome'},
    {'id': 'minimal', 'name': 'Minimal', 'icon': 'crop_free'},
    {'id': 'gaming', 'name': 'Gaming', 'icon': 'sports_esports'},
  ];

  final List<Map<String, dynamic>> _wallpaperImages = [
    {
      'id': '1',
      'url':
          'https://images.pexels.com/photos/1366919/pexels-photo-1366919.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1',
      'category': 'nature',
      'title': 'Pegunungan Hijau'
    },
    {
      'id': '2',
      'url':
          'https://images.pexels.com/photos/1323550/pexels-photo-1323550.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1',
      'category': 'abstract',
      'title': 'Abstrak Biru'
    },
    {
      'id': '3',
      'url':
          'https://images.pexels.com/photos/1366957/pexels-photo-1366957.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1',
      'category': 'nature',
      'title': 'Pantai Tropis'
    },
    {
      'id': '4',
      'url':
          'https://images.pexels.com/photos/1323712/pexels-photo-1323712.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1',
      'category': 'minimal',
      'title': 'Minimal Putih'
    },
    {
      'id': '5',
      'url':
          'https://images.pexels.com/photos/1366630/pexels-photo-1366630.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1',
      'category': 'gaming',
      'title': 'Gaming Neon'
    },
    {
      'id': '6',
      'url':
          'https://images.pexels.com/photos/1323592/pexels-photo-1323592.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1',
      'category': 'abstract',
      'title': 'Gradien Ungu'
    },
    {
      'id': '7',
      'url':
          'https://images.pexels.com/photos/1366974/pexels-photo-1366974.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1',
      'category': 'nature',
      'title': 'Hutan Bambu'
    },
    {
      'id': '8',
      'url':
          'https://images.pexels.com/photos/1323206/pexels-photo-1323206.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1',
      'category': 'minimal',
      'title': 'Geometri Hitam'
    },
    {
      'id': '9',
      'url':
          'https://images.pexels.com/photos/1366909/pexels-photo-1366909.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1',
      'category': 'gaming',
      'title': 'Cyber Space'
    },
  ];

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredImages {
    if (_selectedCategory == 'all') {
      return _wallpaperImages;
    }
    return _wallpaperImages
        .where((image) => image['category'] == _selectedCategory)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        _buildCategoryFilter(),
        Expanded(
          child: _buildImageGrid(),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      child: Row(
        children: [
          IconButton(
            onPressed: widget.onBack,
            icon: CustomIconWidget(
              iconName: 'arrow_back',
              color: AppTheme.lightTheme.colorScheme.onSurface,
              size: 6.w,
            ),
          ),
          Expanded(
            child: Text(
              'Pilih Wallpaper',
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

  Widget _buildCategoryFilter() {
    return Container(
      height: 6.h,
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _wallpaperCategories.length,
        separatorBuilder: (context, index) => SizedBox(width: 2.w),
        itemBuilder: (context, index) {
          final category = _wallpaperCategories[index];
          final isSelected = _selectedCategory == category['id'];

          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = category['id']),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.lightTheme.primaryColor
                    : AppTheme.lightTheme.colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? AppTheme.lightTheme.primaryColor
                      : AppTheme.lightTheme.colorScheme.outline,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomIconWidget(
                    iconName: category['icon'],
                    color: isSelected
                        ? Colors.white
                        : AppTheme.lightTheme.colorScheme.onSurface,
                    size: 4.w,
                  ),
                  SizedBox(width: 2.w),
                  Text(
                    category['name'],
                    style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                      color: isSelected
                          ? Colors.white
                          : AppTheme.lightTheme.colorScheme.onSurface,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildImageGrid() {
    final filteredImages = _filteredImages;

    return Padding(
      padding: EdgeInsets.all(4.w),
      child: GridView.builder(
        controller: _scrollController,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 2.w,
          mainAxisSpacing: 2.w,
          childAspectRatio: 0.6,
        ),
        itemCount: filteredImages.length,
        itemBuilder: (context, index) {
          final image = filteredImages[index];
          return _buildImageTile(image);
        },
      ),
    );
  }

  Widget _buildImageTile(Map<String, dynamic> image) {
    return GestureDetector(
      onTap: () => widget.onImageSelected(image['url']),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CustomImageWidget(
                imageUrl: image['url'],
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
                child: Text(
                  image['title'],
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
