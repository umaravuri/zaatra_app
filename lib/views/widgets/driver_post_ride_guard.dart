import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../services/driver_service.dart';
import '../screens/driver/driver-main/driver_my_ride_screen_30.dart';
import '../screens/driver/driver-onboarding/driver_vehicle_info_screen_35.dart';

/// Shared guard that verifies driver vehicle registration before opening DriverMyRideScreen,
/// regardless of whether the driver is online or offline.
class DriverPostRideGuard {
  static Future<void> openPostRideScreen(
    BuildContext context, {
    VoidCallback? onReturned,
  }) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );

    Map<String, dynamic> verifyRes;
    bool verifyFailed = false;
    try {
      verifyRes = await DriverService.verifyPostRideEligibility();
    } catch (_) {
      verifyRes = {};
      verifyFailed = true;
    }

    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop();

    if (verifyFailed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not verify your vehicle details. Please check your connection and try again.',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final canPostRide = verifyRes['canPostRide'] == true;
    if (canPostRide) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const DriverMyRideScreen()),
      );
      onReturned?.call();
      return;
    }

    final popup = verifyRes['popup'] is Map
        ? Map<String, dynamic>.from(verifyRes['popup'] as Map)
        : null;
    _showRegisterVehiclePopup(context, popup);
  }

  static void _showRegisterVehiclePopup(
    BuildContext context, [
    Map<String, dynamic>? popup,
  ]) {
    final title = popup?['title']?.toString() ?? 'Vehicle Not Registered';
    final description = popup?['description']?.toString() ??
        'You need to register your vehicle before you can post a ride.';
    final buttonText = popup?['buttonText']?.toString() ?? 'Register Vehicle';
    final cancelText = popup?['cancelText']?.toString() ?? 'Cancel';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(
                color: Color(0xFFF3EDF7),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.directions_car_rounded,
                color: AppColors.primary,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E1E2D),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF7A7A8C),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DriverVehicleInfoScreen(
                        redirectToPostRide: true,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  buttonText,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                cancelText,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF7A7A8C),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
