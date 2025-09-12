import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../theme/app_theme.dart';
import './widgets/app_header_widget.dart';
import './widgets/login_link_widget.dart';
import './widgets/role_card_widget.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({Key? key}) : super(key: key);

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: 2.h),
              // Dismissible header with app logo and title
              const AppHeaderWidget(),
              SizedBox(height: 4.h),
              // Main content with role selection cards
              _buildRoleSelectionCards(),
              SizedBox(height: 6.h),
              // Bottom area with login link
              const LoginLinkWidget(),
              SizedBox(height: 2.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleSelectionCards() {
    return Column(
      children: [
        // Admin (Parent) Card
        RoleCardWidget(
          title: 'Orang Tua (Admin)',
          description:
              'Pantau dan kontrol perangkat anak Anda dengan fitur monitoring lengkap dan kontrol jarak jauh',
          iconName: 'admin_panel_settings',
          isAdmin: true,
          onTap: () {
            _navigateToAdminFlow();
          },
        ),
        SizedBox(height: 6.w),
        // User (Child) Card
        RoleCardWidget(
          title: 'Anak (User)',
          description:
              'Akses generator nickname Free Fire yang keren dan unik untuk meningkatkan pengalaman gaming Anda',
          iconName: 'sports_esports',
          isAdmin: false,
          onTap: () {
            _navigateToUserFlow();
          },
        ),
      ],
    );
  }

  void _navigateToAdminFlow() {
    // Navigate to admin dashboard or admin registration
    Navigator.pushNamed(context, '/admin-dashboard');
  }

  void _navigateToUserFlow() {
    // Navigate to Free Fire nickname generator
    Navigator.pushNamed(context, '/free-fire-nickname-generator');
  }
}
