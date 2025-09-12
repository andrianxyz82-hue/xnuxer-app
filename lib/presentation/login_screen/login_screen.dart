import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/app_export.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import './widgets/app_logo_widget.dart';
import './widgets/login_form_widget.dart';
import './widgets/role_selector_widget.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  String _selectedRole = 'Admin';
  bool _isLoading = false;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final AuthService _authService = AuthService();
  final DatabaseService _databaseService = DatabaseService();

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    // Start animations
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _handleRoleChange(String role) {
    if (_selectedRole != role && !_isLoading) {
      setState(() {
        _selectedRole = role;
      });

      // Restart animations for role change
      _slideController.reset();
      _slideController.forward();
    }
  }

  Future<void> _handleLogin(String email, String password) async {
    // Dismiss keyboard
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
    });

    try {
      // Authenticate with Supabase
      final response = await _authService.signInWithEmail(email, password);

      if (response.user != null) {
        // Update last login time
        await _authService.updateLastLogin();

        // Get user profile to determine role
        final userProfile = await _databaseService.getCurrentUserProfile();

        // Success - trigger haptic feedback
        HapticFeedback.heavyImpact();

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  CustomIconWidget(
                    iconName: 'check_circle',
                    color: Colors.white,
                    size: 5.w,
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Text(
                      'Login berhasil! Selamat datang ${userProfile?.fullName ?? 'User'}',
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              backgroundColor: AppTheme.lightTheme.colorScheme.primary,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        }

        // Navigate to appropriate screen based on role
        await Future.delayed(const Duration(milliseconds: 500));

        if (mounted) {
          if (userProfile?.isAdmin == true) {
            Navigator.pushReplacementNamed(context, '/admin-dashboard');
          } else {
            Navigator.pushReplacementNamed(
                context, '/free-fire-nickname-generator');
          }
        }
      } else {
        _showErrorSnackBar('Login gagal!', 'Respons tidak valid dari server.');
      }
    } catch (e) {
      // Handle authentication errors
      HapticFeedback.mediumImpact();

      String errorMessage = 'Login gagal!';
      String errorDetails = 'Terjadi kesalahan yang tidak diketahui.';

      if (e.toString().contains('Invalid login credentials')) {
        errorDetails = 'Email atau password salah.';
      } else if (e.toString().contains('Email not confirmed')) {
        errorDetails = 'Silakan verifikasi email Anda terlebih dahulu.';
      } else if (e.toString().contains('Network')) {
        errorMessage = 'Masalah Koneksi';
        errorDetails = 'Periksa koneksi internet Anda.';
      } else {
        errorDetails = 'Periksa kredensial Anda dan coba lagi.';
      }

      _showErrorSnackBar(errorMessage, errorDetails);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String title, String details) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              CustomIconWidget(
                iconName: 'error',
                color: Colors.white,
                size: 5.w,
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      details,
                      style: GoogleFonts.inter(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: AppTheme.lightTheme.colorScheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(
                horizontal: 6.w,
                vertical: 2.h,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height -
                      MediaQuery.of(context).padding.top -
                      MediaQuery.of(context).padding.bottom -
                      4.h,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: 4.h),

                      // App Logo with Role Indicator
                      AppLogoWidget(selectedRole: _selectedRole),

                      SizedBox(height: 6.h),

                      // Role Selector
                      RoleSelectorWidget(
                        selectedRole: _selectedRole,
                        onRoleChanged: _handleRoleChange,
                        isEnabled: !_isLoading,
                      ),

                      SizedBox(height: 4.h),

                      // Login Form
                      LoginFormWidget(
                        selectedRole: _selectedRole,
                        onLogin: _handleLogin,
                        isLoading: _isLoading,
                      ),

                      const Spacer(),

                      SizedBox(height: 4.h),

                      // Footer with demo credentials info
                      Container(
                        padding: EdgeInsets.all(4.w),
                        decoration: BoxDecoration(
                          color: AppTheme
                              .lightTheme.colorScheme.primaryContainer
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.lightTheme.colorScheme.primary
                                .withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                CustomIconWidget(
                                  iconName: 'info',
                                  color:
                                      AppTheme.lightTheme.colorScheme.primary,
                                  size: 4.w,
                                ),
                                SizedBox(width: 2.w),
                                Text(
                                  'Kredensial Demo',
                                  style: GoogleFonts.inter(
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.w600,
                                    color:
                                        AppTheme.lightTheme.colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 1.h),
                            Text(
                              'Admin: admin@parentcontrol.com / admin123\nUser: user@freefire.com / user123',
                              style: GoogleFonts.inter(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w400,
                                color: AppTheme
                                    .lightTheme.colorScheme.onSurfaceVariant,
                                height: 1.4,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 2.h),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
