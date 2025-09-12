import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class HistoryTab extends StatefulWidget {
  const HistoryTab({Key? key}) : super(key: key);

  @override
  State<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<HistoryTab> {
  List<Map<String, dynamic>> _historyNicknames = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getStringList('nickname_history') ?? [];

      final history = historyJson.map((item) {
        final parts = item.split('|');
        return {
          'nickname': parts.isNotEmpty ? parts[0] : '',
          'timestamp':
              parts.length > 1 ? parts[1] : DateTime.now().toIso8601String(),
          'category': parts.length > 2 ? parts[2] : 'Cool',
        };
      }).toList();

      // Sort by timestamp (newest first)
      history.sort((a, b) => DateTime.parse(b['timestamp'] as String)
          .compareTo(DateTime.parse(a['timestamp'] as String)));

      setState(() {
        _historyNicknames = history;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _clearHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('nickname_history');
      setState(() {
        _historyNicknames.clear();
      });

      HapticFeedback.mediumImpact();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Riwayat berhasil dihapus',
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: Colors.white,
              ),
            ),
            backgroundColor: AppTheme.lightTheme.colorScheme.tertiary,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _copyToClipboard(String nickname) async {
    await Clipboard.setData(ClipboardData(text: nickname));
    HapticFeedback.lightImpact();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Nickname disalin ke clipboard!',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: Colors.white,
            ),
          ),
          backgroundColor: AppTheme.lightTheme.colorScheme.tertiary,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }

  Future<void> _addToFavorites(String nickname) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favorites = prefs.getStringList('favorite_nicknames') ?? [];

      if (!favorites.contains(nickname)) {
        favorites.add(nickname);
        await prefs.setStringList('favorite_nicknames', favorites);

        HapticFeedback.lightImpact();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Ditambahkan ke favorit!',
                style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                ),
              ),
              backgroundColor: AppTheme.lightTheme.colorScheme.tertiary,
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Sudah ada di favorit',
                style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                ),
              ),
              backgroundColor: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }
      }
    } catch (e) {
      // Handle error silently
    }
  }

  String _formatTimestamp(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inMinutes < 1) {
        return 'Baru saja';
      } else if (difference.inHours < 1) {
        return '${difference.inMinutes} menit lalu';
      } else if (difference.inDays < 1) {
        return '${difference.inHours} jam lalu';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} hari lalu';
      } else {
        return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
      }
    } catch (e) {
      return 'Tidak diketahui';
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Funny':
        return AppTheme.lightTheme.colorScheme.tertiary;
      case 'Pro Player':
        return AppTheme.lightTheme.colorScheme.primary;
      default:
        return AppTheme.lightTheme.colorScheme.secondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: AppTheme.lightTheme.colorScheme.tertiary,
        ),
      );
    }

    return Column(
      children: [
        // Header with clear button
        if (_historyNicknames.isNotEmpty)
          Container(
            padding: EdgeInsets.all(4.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Riwayat Generate (${_historyNicknames.length})',
                  style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(
                          'Hapus Riwayat',
                          style: AppTheme.lightTheme.textTheme.titleLarge,
                        ),
                        content: Text(
                          'Yakin ingin menghapus semua riwayat nickname?',
                          style: AppTheme.lightTheme.textTheme.bodyMedium,
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              'Batal',
                              style: AppTheme.lightTheme.textTheme.labelLarge
                                  ?.copyWith(
                                color: AppTheme
                                    .lightTheme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _clearHistory();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  AppTheme.lightTheme.colorScheme.error,
                            ),
                            child: Text(
                              'Hapus',
                              style: AppTheme.lightTheme.textTheme.labelLarge
                                  ?.copyWith(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  },
                  icon: CustomIconWidget(
                    iconName: 'delete_sweep',
                    color: AppTheme.lightTheme.colorScheme.error,
                    size: 5.w,
                  ),
                  label: Text(
                    'Hapus Semua',
                    style: AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.error,
                    ),
                  ),
                ),
              ],
            ),
          ),

        // History List
        Expanded(
          child: _historyNicknames.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CustomIconWidget(
                        iconName: 'history',
                        color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                        size: 20.w,
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        'Belum Ada Riwayat',
                        style: AppTheme.lightTheme.textTheme.headlineSmall
                            ?.copyWith(
                          color:
                              AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 1.h),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.w),
                        child: Text(
                          'Generate nickname di tab Generator untuk melihat riwayat di sini',
                          style: AppTheme.lightTheme.textTheme.bodyMedium
                              ?.copyWith(
                            color: AppTheme
                                .lightTheme.colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadHistory,
                  color: AppTheme.lightTheme.colorScheme.tertiary,
                  child: ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 4.w),
                    itemCount: _historyNicknames.length,
                    itemBuilder: (context, index) {
                      final item = _historyNicknames[index];
                      final nickname = item['nickname'] as String;
                      final timestamp = item['timestamp'] as String;
                      final category = item['category'] as String;

                      return Container(
                        margin: EdgeInsets.only(bottom: 2.h),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.lightTheme.colorScheme.surface,
                              AppTheme.lightTheme.colorScheme.surface
                                  .withValues(alpha: 0.8),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          border: Border.all(
                            color: AppTheme.lightTheme.colorScheme.outline
                                .withValues(alpha: 0.3),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.lightTheme.colorScheme.shadow,
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 4.w,
                            vertical: 1.h,
                          ),
                          leading: Container(
                            padding: EdgeInsets.all(2.w),
                            decoration: BoxDecoration(
                              color: _getCategoryColor(category)
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: CustomIconWidget(
                              iconName: 'history',
                              color: _getCategoryColor(category),
                              size: 6.w,
                            ),
                          ),
                          title: Text(
                            nickname,
                            style: AppTheme.lightTheme.textTheme.titleMedium
                                ?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _formatTimestamp(timestamp),
                                style: AppTheme.lightTheme.textTheme.bodySmall
                                    ?.copyWith(
                                  color: AppTheme
                                      .lightTheme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              Container(
                                margin: EdgeInsets.only(top: 0.5.h),
                                padding: EdgeInsets.symmetric(
                                  horizontal: 2.w,
                                  vertical: 0.5.h,
                                ),
                                decoration: BoxDecoration(
                                  color: _getCategoryColor(category)
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  category,
                                  style: AppTheme
                                      .lightTheme.textTheme.labelSmall
                                      ?.copyWith(
                                    color: _getCategoryColor(category),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          trailing: PopupMenuButton<String>(
                            icon: CustomIconWidget(
                              iconName: 'more_vert',
                              color: AppTheme
                                  .lightTheme.colorScheme.onSurfaceVariant,
                              size: 6.w,
                            ),
                            onSelected: (value) {
                              switch (value) {
                                case 'copy':
                                  _copyToClipboard(nickname);
                                  break;
                                case 'favorite':
                                  _addToFavorites(nickname);
                                  break;
                              }
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem<String>(
                                value: 'copy',
                                child: Row(
                                  children: [
                                    CustomIconWidget(
                                      iconName: 'content_copy',
                                      color: AppTheme
                                          .lightTheme.colorScheme.primary,
                                      size: 5.w,
                                    ),
                                    SizedBox(width: 2.w),
                                    Text(
                                      'Salin',
                                      style: AppTheme
                                          .lightTheme.textTheme.bodyMedium,
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuItem<String>(
                                value: 'favorite',
                                child: Row(
                                  children: [
                                    CustomIconWidget(
                                      iconName: 'favorite',
                                      color: AppTheme
                                          .lightTheme.colorScheme.tertiary,
                                      size: 5.w,
                                    ),
                                    SizedBox(width: 2.w),
                                    Text(
                                      'Tambah ke Favorit',
                                      style: AppTheme
                                          .lightTheme.textTheme.bodyMedium,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onTap: () => _copyToClipboard(nickname),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}
