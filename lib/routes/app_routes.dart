import 'package:flutter/material.dart';
import '../presentation/wallpaper_control_screen/wallpaper_control_screen.dart';
import '../presentation/camera_control_screen/camera_control_screen.dart';
import '../presentation/login_screen/login_screen.dart';
import '../presentation/free_fire_nickname_generator/free_fire_nickname_generator.dart';
import '../presentation/role_selection_screen/role_selection_screen.dart';
import '../presentation/admin_dashboard/admin_dashboard.dart';
import '../presentation/register_screen/register_screen.dart';

class AppRoutes {
  // TODO: Add your routes here
  static const String initial = '/';
  static const String wallpaperControl = '/wallpaper-control-screen';
  static const String cameraControl = '/camera-control-screen';
  static const String login = '/login-screen';
  static const String register = '/register-screen';
  static const String freeFireNicknameGenerator =
      '/free-fire-nickname-generator';
  static const String roleSelection = '/role-selection-screen';
  static const String adminDashboard = '/admin-dashboard';

  static Map<String, WidgetBuilder> routes = {
    initial: (context) => const RegisterScreen(),
    wallpaperControl: (context) => const WallpaperControlScreen(),
    cameraControl: (context) => const CameraControlScreen(),
    login: (context) => const LoginScreen(),
    register: (context) => const RegisterScreen(),
    freeFireNicknameGenerator: (context) => const FreeFireNicknameGenerator(),
    roleSelection: (context) => const RoleSelectionScreen(),
    adminDashboard: (context) => const AdminDashboard(),
    // TODO: Add your other routes here
  };
}
