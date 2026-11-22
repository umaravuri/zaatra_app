import 'package:flutter/material.dart';
import 'core/config/app_env.dart';
import 'core/navigation/app_navigator.dart';
import 'core/theme/app_theme.dart';
import 'views/screens/authorization/login_screen_115.dart';
import 'views/screens/authorization/role_selection_screen_27.dart';
import 'views/screens/customer/customer-stay/customer_home_screen_38.dart';
import 'views/screens/driver/driver-main/driver_home_dashboard_screen_83.dart';
import 'views/screens/host_updated/host_screens_gallery_screen.dart';
import 'views/screens/splash/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppEnv.init();

  runApp(const ZaatraApp());
}

class ZaatraApp extends StatelessWidget {
  final Widget? initialScreen;
  const ZaatraApp({super.key, this.initialScreen});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Zaatra',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: initialScreen ?? const SplashScreen(),
      routes: {
        AppRoutes.splash: (context) => const SplashScreen(),
        AppRoutes.login: (context) => const LoginScreen(),
        AppRoutes.roleSelection: (context) => const RoleSelectionScreen(),
        AppRoutes.driverHome: (context) => const DriverHomeDashboardScreen83(),
        AppRoutes.customerHome: (context) => const CustomerHomeScreen(),
        '/driver_dashboard': (context) => const DriverHomeDashboardScreen83(),
        '/host_gallery': (context) => const HostScreensGalleryScreen(),
      },
    );
  }
}
