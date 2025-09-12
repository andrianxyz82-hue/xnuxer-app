import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import './widgets/background_service_listener.dart';
import './widgets/favorites_tab.dart';
import './widgets/history_tab.dart';
import './widgets/nickname_generator_tab.dart';

class FreeFireNicknameGenerator extends StatefulWidget {
  const FreeFireNicknameGenerator({Key? key}) : super(key: key);

  @override
  State<FreeFireNicknameGenerator> createState() =>
      _FreeFireNicknameGeneratorState();
}

class _FreeFireNicknameGeneratorState extends State<FreeFireNicknameGenerator>
    with TickerProviderStateMixin {
  late TabController _tabController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _currentIndex = _tabController.index;
      });
    });
    _saveNicknameToHistory('SampleNickname_123', 'Cool'); // Demo entry
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _saveNicknameToHistory(String nickname, String category) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final history = prefs.getStringList('nickname_history') ?? [];

      final entry = '$nickname|${DateTime.now().toIso8601String()}|$category';
      history.insert(0, entry); // Add to beginning

      // Keep only last 50 entries
      if (history.length > 50) {
        history.removeRange(50, history.length);
      }

      await prefs.setStringList('nickname_history', history);
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _onRefresh() async {
    HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 1000));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Aplikasi diperbarui!',
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

  @override
  Widget build(BuildContext context) {
    return BackgroundServiceListener(
      child: Scaffold(
        backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: _onRefresh,
            color: AppTheme.lightTheme.colorScheme.tertiary,
            child: Column(
              children: [
                // Free Fire Header
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    horizontal: 4.w,
                    vertical: 2.h,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.lightTheme.colorScheme.tertiary,
                        AppTheme.lightTheme.colorScheme.tertiary
                            .withValues(alpha: 0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.lightTheme.colorScheme.tertiary
                            .withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Free Fire Logo Placeholder
                      Container(
                        width: 12.w,
                        height: 12.w,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: CustomIconWidget(
                            iconName: 'local_fire_department',
                            color: AppTheme.lightTheme.colorScheme.tertiary,
                            size: 8.w,
                          ),
                        ),
                      ),
                      SizedBox(width: 3.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Free Fire',
                              style: AppTheme.lightTheme.textTheme.titleLarge
                                  ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'Nickname Generator',
                              style: AppTheme.lightTheme.textTheme.bodyMedium
                                  ?.copyWith(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Settings Button
                      IconButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          showModalBottomSheet(
                            context: context,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(16),
                              ),
                            ),
                            builder: (context) => Container(
                              padding: EdgeInsets.all(4.w),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 12.w,
                                    height: 0.5.h,
                                    decoration: BoxDecoration(
                                      color: AppTheme
                                          .lightTheme.colorScheme.outline,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  SizedBox(height: 2.h),
                                  Text(
                                    'Tentang Aplikasi',
                                    style: AppTheme
                                        .lightTheme.textTheme.titleLarge
                                        ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(height: 2.h),
                                  Text(
                                    'Free Fire Nickname Generator v1.0\n\nBuat nickname unik untuk karakter Free Fire kamu dengan mudah dan cepat!',
                                    style: AppTheme
                                        .lightTheme.textTheme.bodyMedium,
                                    textAlign: TextAlign.center,
                                  ),
                                  SizedBox(height: 3.h),
                                  ElevatedButton(
                                    onPressed: () => Navigator.pop(context),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme
                                          .lightTheme.colorScheme.tertiary,
                                      minimumSize: Size(double.infinity, 6.h),
                                    ),
                                    child: Text(
                                      'Tutup',
                                      style: AppTheme
                                          .lightTheme.textTheme.labelLarge
                                          ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        icon: CustomIconWidget(
                          iconName: 'settings',
                          color: Colors.white,
                          size: 6.w,
                        ),
                      ),
                    ],
                  ),
                ),

                // Tab Bar
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.lightTheme.colorScheme.surface,
                    border: Border(
                      bottom: BorderSide(
                        color: AppTheme.lightTheme.colorScheme.outline
                            .withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    labelColor: AppTheme.lightTheme.colorScheme.tertiary,
                    unselectedLabelColor:
                        AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    indicatorColor: AppTheme.lightTheme.colorScheme.tertiary,
                    indicatorWeight: 3,
                    labelStyle:
                        AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    unselectedLabelStyle:
                        AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w400,
                    ),
                    tabs: [
                      Tab(
                        icon: CustomIconWidget(
                          iconName: 'auto_awesome',
                          color: _currentIndex == 0
                              ? AppTheme.lightTheme.colorScheme.tertiary
                              : AppTheme
                                  .lightTheme.colorScheme.onSurfaceVariant,
                          size: 6.w,
                        ),
                        text: 'Generator',
                      ),
                      Tab(
                        icon: CustomIconWidget(
                          iconName: 'favorite',
                          color: _currentIndex == 1
                              ? AppTheme.lightTheme.colorScheme.tertiary
                              : AppTheme
                                  .lightTheme.colorScheme.onSurfaceVariant,
                          size: 6.w,
                        ),
                        text: 'Favorit',
                      ),
                      Tab(
                        icon: CustomIconWidget(
                          iconName: 'history',
                          color: _currentIndex == 2
                              ? AppTheme.lightTheme.colorScheme.tertiary
                              : AppTheme
                                  .lightTheme.colorScheme.onSurfaceVariant,
                          size: 6.w,
                        ),
                        text: 'Riwayat',
                      ),
                    ],
                  ),
                ),

                // Tab Bar View
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: const [
                      NicknameGeneratorTab(),
                      FavoritesTab(),
                      HistoryTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Floating Action Button for Quick Generate
        floatingActionButton: _currentIndex == 0
            ? FloatingActionButton.extended(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  // Quick random generation
                  final quickNicknames = [
                    'FireDragon_${DateTime.now().millisecond}',
                    'ShadowHunter_${DateTime.now().millisecond}',
                    'EliteSniper_${DateTime.now().millisecond}',
                    'ProGamer_${DateTime.now().millisecond}',
                    'DarkLord_${DateTime.now().millisecond}',
                  ];

                  final randomNickname = quickNicknames[
                      DateTime.now().millisecond % quickNicknames.length];

                  Clipboard.setData(ClipboardData(text: randomNickname));
                  _saveNicknameToHistory(randomNickname, 'Quick');

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Quick nickname: $randomNickname (disalin!)',
                        style:
                            AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                      backgroundColor: AppTheme.lightTheme.colorScheme.tertiary,
                      duration: const Duration(seconds: 3),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      action: SnackBarAction(
                        label: 'OK',
                        textColor: Colors.white,
                        onPressed: () {},
                      ),
                    ),
                  );
                },
                backgroundColor: AppTheme.lightTheme.colorScheme.tertiary,
                foregroundColor: Colors.white,
                icon: CustomIconWidget(
                  iconName: 'flash_on',
                  color: Colors.white,
                  size: 6.w,
                ),
                label: Text(
                  'Quick',
                  style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            : null,
      ),
    );
  }
}
