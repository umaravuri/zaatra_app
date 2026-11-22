import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../views/screens/customer/customer-stay/customer_home_screen_38.dart';
import '../../views/screens/driver/driver-main/driver_home_dashboard_screen_83.dart';

class AppRoutes {
  static const String splash = '/splash';
  static const String customerHome = '/customer_home';
  static const String driverHome = '/driver_home';
  static const String hostHome = '/host_home';
  static const String login = '/login';
  static const String roleSelection = '/role_selection';
}

class AppNavigator {
  static DateTime? _lastBackPressTime;

  /// Deterministically returns to an existing CustomerHomeScreen on the stack.
  /// If not found, cleanly installs CustomerHomeScreen as the new authenticated root.
  static void returnToCustomerHome(BuildContext context) {
    bool found = false;
    Navigator.of(context).popUntil((route) {
      if (route.settings.name == AppRoutes.customerHome) {
        found = true;
        return true;
      }
      return route.isFirst;
    });

    if (!found) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          settings: const RouteSettings(name: AppRoutes.customerHome),
          builder: (_) => const CustomerHomeScreen(),
        ),
        (route) => false,
      );
    }
  }

  /// Deterministically returns to an existing DriverHomeDashboardScreen83 on the stack.
  /// If not found, cleanly installs DriverHomeDashboardScreen83 as the new authenticated root.
  static void returnToDriverHome(BuildContext context) {
    bool found = false;
    Navigator.of(context).popUntil((route) {
      if (route.settings.name == AppRoutes.driverHome) {
        found = true;
        return true;
      }
      return route.isFirst;
    });

    if (!found) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          settings: const RouteSettings(name: AppRoutes.driverHome),
          builder: (_) => const DriverHomeDashboardScreen83(),
        ),
        (route) => false,
      );
    }
  }

  /// Platform-aware root exit guard for primary dashboards (Customer, Driver, Host).
  /// Allows child dialogs/modals to pop first, and handles Web vs. Android/iOS exit cleanly.
  static Widget buildRootExitGuard({
    required BuildContext context,
    required Widget child,
    String homeName = 'Home',
  }) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        // 1. If a bottom sheet, dialog, or overlay can pop, let it pop first
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
          return;
        }

        // 2. On Web: Avoid SystemNavigator.pop() which browsers block
        if (kIsWeb) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('You are on the $homeName screen.'),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }

        // 3. On Mobile (Android/iOS): Double-tap within 2s to exit cleanly
        final now = DateTime.now();
        if (_lastBackPressTime == null || now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
          _lastBackPressTime = now;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Press back again to exit Zaatra'),
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          SystemNavigator.pop();
        }
      },
      child: child,
    );
  }
}
