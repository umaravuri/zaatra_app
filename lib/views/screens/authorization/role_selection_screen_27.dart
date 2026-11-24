import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/navigation/app_navigator.dart';
import '../../../services/auth_service.dart';
import '../../../services/driver_service.dart';
import '../customer/customer-stay/customer_home_screen_38.dart';
import '../driver/driver-main/driver_home_dashboard_screen_83.dart';
import '../driver/driver-onboarding/driver_personal_info_screen_31.dart';
import '../host_updated/host_dashboard_screen.dart';

class RoleSelectionScreen extends StatefulWidget {
  static const String routeName = AppRoutes.roleSelection;
  final String? phoneNumber;
  final String userName;
  final bool isExistingUser;
  final Map<String, dynamic>? roles;

  const RoleSelectionScreen({
    super.key,
    this.phoneNumber,
    this.userName = '',
    this.isExistingUser = false,
    this.roles,
  });

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  // Default selected role is 'customer' matching 27.png
  String _selectedRole = 'customer';
  bool _isLoading = false;
  String? _loadingRole;

  void _showAccountNotFoundDialog({
    required String title,
    required String message,
    required String buttonText,
    required VoidCallback onRegister,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.info_outline_rounded, color: Color(0xFF5A36A8), size: 26),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1D1B20)),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(fontSize: 14, color: Color(0xFF625B71), height: 1.4),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              onRegister();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5A36A8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: Text(buttonText, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleRoleSelection(String role) async {
    if (_isLoading) return;

    setState(() {
      _selectedRole = role;
      _isLoading = true;
      _loadingRole = role;
    });

    final phone = widget.phoneNumber ?? '';
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final tenDigit = cleanPhone.length >= 10 ? cleanPhone.substring(cleanPhone.length - 10) : cleanPhone;

    // Call Backend API 3: POST /api/auth/mobile/select-role?soft=true
    Map<String, dynamic> selectResult = {};
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('currentUserRole', role);
      if (cleanPhone.isNotEmpty) {
        await prefs.setString('user_role_$cleanPhone', role);
        await prefs.setString('user_role_$tenDigit', role);
      }
      selectResult = await AuthService.selectRoleMobile(phone: phone, role: role.toLowerCase());
    } catch (_) {}

    // Check if the backend or OTP step gave a definitive answer
    // 1. First priority: selectResult from POST /api/auth/mobile/select-role
    // 2. Second priority: widget.roles from POST /api/auth/mobile/verify-otp
    bool? backendCanLogin = selectResult.isNotEmpty && selectResult['canLogin'] != null
        ? (selectResult['canLogin'] == true)
        : null;

    if (backendCanLogin == null && widget.roles != null && widget.roles is Map) {
      final roleObj = widget.roles![role.toLowerCase()];
      if (roleObj is Map && roleObj['canLogin'] != null) {
        backendCanLogin = roleObj['canLogin'] == true;
      }
    }

    // 1. SCENARIO A: Customer Selection -> Always dynamic registration / direct access
    if (role.toLowerCase() == 'customer') {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadingRole = null;
      });

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          settings: const RouteSettings(name: AppRoutes.customerHome),
          builder: (context) => const CustomerHomeScreen(),
        ),
        (route) => false,
      );
      return;
    }

    // 2. SCENARIO B: Host Selection -> straight to the host side (dashboard)
    if (role.toLowerCase() == 'host') {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadingRole = null;
      });

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          settings: const RouteSettings(name: AppRoutes.hostHome),
          builder: (context) => const HostDashboardScreen(),
        ),
        (route) => false,
      );
      return;
    }

    // 3. SCENARIO C: Driver Selection
    if (role.toLowerCase() == 'driver') {
      bool isDriverExisting = false;

      if (backendCanLogin != null) {
        isDriverExisting = backendCanLogin;
      } else {
        // Fallback check if backend unreachable
        isDriverExisting = await DriverService.isOldDriver(phone);
      }

      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadingRole = null;
      });

      if (isDriverExisting) {
        // Case C1: Existing Driver -> Driver Dashboard Screen 83
        final prefs = await SharedPreferences.getInstance();
        final rawUser = selectResult['user'] is Map ? (selectResult['user'] as Map<String, dynamic>) : null;
        String? backendName;
        if (rawUser != null) {
          backendName = (rawUser['name'] ?? rawUser['fullName'])?.toString();
        }

        final resolvedName = backendName ??
            prefs.getString('user_name_$cleanPhone') ??
            prefs.getString('user_name_$tenDigit') ??
            (widget.userName.isNotEmpty && widget.userName.toLowerCase() != 'user' ? widget.userName : null);

        if (resolvedName != null && resolvedName.isNotEmpty) {
          await prefs.setString('driverName', resolvedName);
          await prefs.setString('currentUserName', resolvedName);
        }

        // Establish 30-day persistent session if token returned
        final token = selectResult['token']?.toString() ?? selectResult['data']?['token']?.toString();
        final userId = rawUser?['id']?.toString() ?? rawUser?['_id']?.toString() ?? rawUser?['userId']?.toString();
        if (token != null && token.isNotEmpty) {
          await AuthService.createSession(
            token: token,
            role: 'driver',
            phone: phone,
            userId: userId,
            driverId: userId,
            userProfile: rawUser,
          );
        }

        if (rawUser?['vehicle'] != null) {
          await prefs.setString('driver_vehicle_$cleanPhone', rawUser!['vehicle'].toString());
        }

        // Make sure the server session is in the driver role (needed to post rides); best effort.
        try {
          await AuthService.switchRole('driver');
        } catch (_) {}

        // A new login starts active.
        await DriverService.markOnlineAtLogin(phone);

        if (!mounted) return;

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            settings: const RouteSettings(name: AppRoutes.driverHome),
            builder: (context) => DriverHomeDashboardScreen83(
              driverName: resolvedName,
            ),
          ),
          (route) => false,
        );
      } else {
        // Case C2: Not registered as Driver -> Display Pop-up Alert Dialog
        final popup = selectResult['popup'] is Map ? selectResult['popup'] : null;
        final title = popup?['title']?.toString() ?? 'Driver Account Not Found';
        final message = selectResult['message']?.toString() ??
            popup?['message']?.toString() ??
            "You do not have any account in Zaatra, so please register.";
        final buttonText = popup?['buttonText']?.toString() ?? 'Register as Driver';

        final initVals = selectResult['initialValues'] is Map ? (selectResult['initialValues'] as Map) : null;
        final cleanName = widget.userName.trim();
        final effectiveName = (initVals?['fullName']?.toString().isNotEmpty == true)
            ? initVals!['fullName'].toString()
            : ((cleanName.isNotEmpty && cleanName.toLowerCase() != 'user') ? cleanName : '');
        final effectivePhone = (initVals?['phone']?.toString().isNotEmpty == true)
            ? initVals!['phone'].toString()
            : phone;
        final effectiveEmail = initVals?['email']?.toString() ?? '';
        final effectiveCity = initVals?['city']?.toString() ?? '';

        _showAccountNotFoundDialog(
          title: title,
          message: message,
          buttonText: buttonText,
          onRegister: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DriverPersonalInfoScreen(
                  role: 'Driver',
                  initialData: {
                    'fullName': effectiveName,
                    'name': effectiveName,
                    'phone': effectivePhone,
                    'email': effectiveEmail,
                    'city': effectiveCity,
                  },
                ),
              ),
            );
          },
        );
      }
      return;
    }

    setState(() {
      _isLoading = false;
      _loadingRole = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ✈️ Subtle Flight Path Background Graphic matching 27.png
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 260,
            child: IgnorePointer(
              child: CustomPaint(
                painter: _FlightPathPainter(),
              ),
            ),
          ),

          // Bottom City Skyline Watermark matching 27.png
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: IgnorePointer(
              child: Image.asset(
                'assets/images/image 31.png',
                fit: BoxFit.fitWidth,
                alignment: Alignment.bottomCenter,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),

                  // Minimalist Back Button matching 27.png
                  if (Navigator.canPop(context))
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF3EDF7),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 18,
                          color: Color(0xFF1D1B20),
                        ),
                      ),
                    )
                  else
                    const SizedBox(height: 40),

                  const SizedBox(height: 36),

                  // Header Typography matching 27.png
                  const Text(
                    'Choose your role',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1D1B20),
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Select a role to continue',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                      color: Color(0xFF79747E),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // 1. Customer Role Card matching 27.png
                  _buildRoleCard(
                    roleId: 'customer',
                    title: 'Customer',
                    subtitle: 'book a stay and rides',
                    iconAsset: 'assets/images/role_customer_icon.png',
                    isSelected: _selectedRole == 'customer',
                    isLoadingThis: _isLoading && _loadingRole == 'customer',
                    onTap: () {
                      setState(() {
                        _selectedRole = 'customer';
                      });
                    },
                  ),

                  const SizedBox(height: 16),

                  // 2. Host Role Card matching 27.png
                  _buildRoleCard(
                    roleId: 'host',
                    title: 'Host',
                    subtitle: 'List your properties',
                    iconAsset: 'assets/images/role_host_icon.png',
                    isSelected: _selectedRole == 'host',
                    isLoadingThis: _isLoading && _loadingRole == 'host',
                    onTap: () {
                      setState(() {
                        _selectedRole = 'host';
                      });
                    },
                  ),

                  const SizedBox(height: 16),

                  // 3. Driver Role Card matching 27.png
                  _buildRoleCard(
                    roleId: 'driver',
                    title: 'Driver',
                    subtitle: 'Offer rides and earns',
                    iconAsset: 'assets/images/role_driver_icon.png',
                    isSelected: _selectedRole == 'driver',
                    isLoadingThis: _isLoading && _loadingRole == 'driver',
                    onTap: () {
                      setState(() {
                        _selectedRole = 'driver';
                      });
                    },
                  ),

                  const SizedBox(height: 42),

                  // Action Button ("Confirm" / "Conform") matching 27.png
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : () => _handleRoleSelection(_selectedRole),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5A36A8),
                        disabledBackgroundColor: const Color(0xFF5A36A8).withValues(alpha: 0.6),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Confirm',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.2,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleCard({
    required String roleId,
    required String title,
    required String subtitle,
    required String iconAsset,
    required bool isSelected,
    required bool isLoadingThis,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: _isLoading ? null : onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF6F2FB),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Circular illustrated icon badge matching 27(1).png
            Image.asset(
              iconAsset,
              width: 54,
              height: 54,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Container(
                width: 54,
                height: 54,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: Color(0xFF5A36A8),
                  size: 26,
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Title & Subtitle matching 27(1).png
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1D1B20),
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.normal,
                      color: Color(0xFF625B71),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 10),

            // Selection Checkmark / Loading Indicator matching 27.png
            if (isLoadingThis)
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2E7D32)),
                ),
              )
            else if (isSelected)
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: Color(0xFF2E7D32),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 16,
                  color: Colors.white,
                ),
              )
            else
              const SizedBox(width: 24),
          ],
        ),
      ),
    );
  }
}

/// Dotted curved flight path with airplane vector matching 27.png
class _FlightPathPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE8DEF8).withValues(alpha: 0.9)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;

    final path = Path();
    // Starts behind the role title and loops upward
    path.moveTo(size.width * 0.42, size.height * 0.88);
    path.cubicTo(
      size.width * 0.41,
      size.height * 0.66,
      size.width * 0.49,
      size.height * 0.52,
      size.width * 0.47,
      size.height * 0.64,
    );
    path.cubicTo(
      size.width * 0.45,
      size.height * 0.74,
      size.width * 0.38,
      size.height * 0.80,
      size.width * 0.52,
      size.height * 0.76,
    );
    path.cubicTo(
      size.width * 0.65,
      size.height * 0.72,
      size.width * 0.74,
      size.height * 0.48,
      size.width * 0.85,
      size.height * 0.38,
    );

    // Draw dashed path
    final dashPath = Path();
    double distance = 0.0;
    const dashLength = 4.0;
    const dashSpace = 4.0;

    for (final metric in path.computeMetrics()) {
      while (distance < metric.length) {
        dashPath.addPath(
          metric.extractPath(distance, distance + dashLength),
          Offset.zero,
        );
        distance += dashLength + dashSpace;
      }
    }
    canvas.drawPath(dashPath, paint);

    // Airplane vector silhouette matching 27.png
    final planePainter = TextPainter(
      text: const TextSpan(
        text: '✈',
        style: TextStyle(
          fontSize: 32,
          color: Color(0xFFE8DEF8),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    canvas.save();
    canvas.translate(size.width * 0.82, size.height * 0.28);
    canvas.rotate(-0.55);
    planePainter.paint(canvas, Offset.zero);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}



********************************************************************************
================================================================================
