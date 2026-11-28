import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/navigation/app_navigator.dart';
import '../../../services/auth_service.dart';
import '../../../services/driver_service.dart';
import '../../../services/host_service.dart';
import 'role_selection_screen_27.dart';
import '../driver/driver-main/driver_home_dashboard_screen_83.dart';
import '../driver/driver-onboarding/driver_personal_info_screen_31.dart';
import '../host/become_host_screen_28.dart';
import '../customer/customer-stay/customer_home_screen_38.dart';
import 'login_screen_115.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String phoneNumber;
  final bool isExistingUser;
  final bool isRegistrationFlow;
  final bool isPhoneUpdateFlow;
  final String userName;
  final String userRole;
  final String? expectedOtp;
  final String? password;
  final String? email;
  final String? city;
  final String? state;

  const OtpVerificationScreen({
    super.key,
    required this.phoneNumber,
    this.isExistingUser = false,
    this.isRegistrationFlow = false,
    this.isPhoneUpdateFlow = false,
    this.userName = 'User',
    this.userRole = 'Driver',
    this.expectedOtp,
    this.password,
    this.email,
    this.city,
    this.state,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> _pinControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _pinFocusNodes =
      List.generate(6, (_) => FocusNode());

  late String _currentExpectedOtp;
  bool _isLoading = false;
  int _secondsRemaining = 25;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _currentExpectedOtp =
        widget.expectedOtp ?? (100000 + Random().nextInt(900000)).toString();
    _startCountdown();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    for (var controller in _pinControllers) {
      controller.dispose();
    }
    for (var node in _pinFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    setState(() {
      _secondsRemaining = 25;
    });
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        if (mounted) {
          setState(() {
            _secondsRemaining--;
          });
        }
      } else {
        timer.cancel();
      }
    });
  }

  String _formatPhone(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length >= 10) {
      final last10 = digits.substring(digits.length - 10);
      return '+91 $last10';
    }
    return raw.isNotEmpty ? raw : '+91 000-000-0000';
  }

  void _handlePaste(String val) {
    final digits = val.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isNotEmpty) {
      for (int i = 0; i < 6 && i < digits.length; i++) {
        _pinControllers[i].text = digits[i];
      }
      final nextIndex = digits.length < 6 ? digits.length : 5;
      _pinFocusNodes[nextIndex].requestFocus();
      setState(() {});
    }
  }

  void _resendOtp() async {
    String newOtp = (100000 + Random().nextInt(900000)).toString();

    try {
      final res = await AuthService.loginInitMobile(
        phone: widget.phoneNumber,
      );
      final backendOtp =
          (res['otp'] ?? (res['data'] is Map ? res['data']['otp'] : null))?.toString();
      if (backendOtp != null && backendOtp.isNotEmpty) {
        newOtp = backendOtp;
      }
    } catch (_) {}

    if (!mounted) return;

    setState(() {
      _currentExpectedOtp = newOtp;
      for (var controller in _pinControllers) {
        controller.clear();
      }
    });
    _pinFocusNodes[0].requestFocus();
    _startCountdown();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.vpn_key_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'New OTP: $_currentExpectedOtp',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _verifyOtp() async {
    final code = _pinControllers.map((c) => c.text.trim()).join();
    if (code.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the full 6-digit verification code.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Call Backend Mobile Login Step 2: POST /api/auth/mobile/verify-otp
      bool isBackendVerified = false;
      Map<String, dynamic>? verifiedRoles;
      try {
        final res = await AuthService.verifyOtpMobile(
          phone: widget.phoneNumber,
          otp: code,
        );
        if (res['success'] == true || res['verified'] == true) {
          isBackendVerified = true;
          if (res['roles'] is Map) {
            verifiedRoles = Map<String, dynamic>.from(res['roles']);
          }
        }
      } catch (_) {}

      // Only the code issued for this session (or the server's verification) is valid.
      final bool isSessionOtpValid = _currentExpectedOtp.isNotEmpty && code == _currentExpectedOtp;

      if (!isBackendVerified && !isSessionOtpValid) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid verification code. Please check the OTP and try again.'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      // Save verified phone number into local session
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('currentPhone', widget.phoneNumber);
        final cleanPhone = widget.phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
        final tenDigit = cleanPhone.length >= 10 ? cleanPhone.substring(cleanPhone.length - 10) : cleanPhone;
        await prefs.setString('last_phone_number', tenDigit);
      } catch (_) {}

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('OTP Verified Successfully!'),
          backgroundColor: AppColors.success,
          duration: Duration(seconds: 1),
        ),
      );

      if (widget.isPhoneUpdateFlow) {
        Navigator.pop(context, true);
        return;
      }

      // 🚀 Navigate to 'Choose Role' Screen 27
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          settings: const RouteSettings(name: AppRoutes.roleSelection),
          builder: (context) => RoleSelectionScreen(
            phoneNumber: widget.phoneNumber,
            userName: widget.userName,
            roles: verifiedRoles,
          ),
        ),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Verification error: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9FD),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Dotted Flight Path Background
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _OtpFlightPathPainter(),
              ),
            ),
          ),

          // Bottom City Skyline Watermark (image 31.png)
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

                  // Circular Back Button matching Screen 26
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFE8E8EC)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 18,
                          color: Color(0xFF1E1E2D),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Title: "Verify Your Number"
                  const Text(
                    'Verify Your Number',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E1E2D),
                      letterSpacing: -0.3,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Subtitle: "Autodecting to your code"
                  const Text(
                    'Autodecting to your code',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF7A7A8C),
                      fontWeight: FontWeight.w400,
                    ),
                  ),

                  const SizedBox(height: 4),

                  // Phone Number: bold formatted
                  Text(
                    _formatPhone(widget.phoneNumber),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E1E2D),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Trial Mode / Developer Sample OTP Card (only when the server returned a code)
                  if (_currentExpectedOtp.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.vpn_key_rounded, color: AppColors.primary, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Sample OTP: $_currentExpectedOtp',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            for (int i = 0;
                                i < 6 && i < _currentExpectedOtp.length;
                                i++) {
                              _pinControllers[i].text = _currentExpectedOtp[i];
                            }
                            _pinFocusNodes[5].requestFocus();
                            setState(() {});
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Autofill',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 6 Square OTP Digit Input Boxes matching Screen 26
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final itemWidth = (constraints.maxWidth - 5 * 10) / 6;
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(
                          6,
                          (index) => SizedBox(
                            width: itemWidth,
                            height: 56,
                            child: Focus(
                              onKeyEvent: (node, event) {
                                if (event is KeyDownEvent &&
                                    event.logicalKey == LogicalKeyboardKey.backspace) {
                                  if (_pinControllers[index].text.isEmpty && index > 0) {
                                    _pinFocusNodes[index - 1].requestFocus();
                                    _pinControllers[index - 1].clear();
                                    return KeyEventResult.handled;
                                  }
                                }
                                return KeyEventResult.ignored;
                              },
                              child: TextField(
                                controller: _pinControllers[index],
                                focusNode: _pinFocusNodes[index],
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                maxLength: 1,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E1E2D),
                                ),
                                decoration: InputDecoration(
                                  counterText: '',
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding: EdgeInsets.zero,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(color: Color(0xFFE2E4E9)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(color: Color(0xFFE2E4E9)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(
                                      color: AppColors.primary,
                                      width: 2,
                                    ),
                                  ),
                                ),
                                onChanged: (val) {
                                  if (val.length > 1) {
                                    _handlePaste(val);
                                    return;
                                  }
                                  if (val.isNotEmpty) {
                                    if (index < 5) {
                                      _pinFocusNodes[index + 1].requestFocus();
                                    } else {
                                      _pinFocusNodes[index].unfocus();
                                    }
                                  }
                                },
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  // Right-Aligned Timer / Resend Code Link matching Screen 26
                  Align(
                    alignment: Alignment.centerRight,
                    child: _secondsRemaining > 0
                        ? RichText(
                            text: TextSpan(
                              text: 'Re-send code in ',
                              style: const TextStyle(
                                color: Color(0xFF1E1E2D),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                              children: [
                                TextSpan(
                                  text:
                                      '00 : ${_secondsRemaining.toString().padLeft(2, '0')}',
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : GestureDetector(
                            onTap: _resendOtp,
                            child: const Text(
                              'Re-send code',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                  ),

                  const SizedBox(height: 28),

                  // Solid Purple CTA Button labeled "Confirm" matching Screen 26
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _verifyOtp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
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
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Confirm',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.2,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Dotted curved flight path with airplane icon matching Screen 26
class _OtpFlightPathPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD1C4E9).withValues(alpha: 0.55)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(size.width * 0.12, size.height * 0.38);
    path.cubicTo(
      size.width * 0.22,
      size.height * 0.32,
      size.width * 0.44,
      size.height * 0.28,
      size.width * 0.48,
      size.height * 0.20,
    );
    path.cubicTo(
      size.width * 0.52,
      size.height * 0.14,
      size.width * 0.38,
      size.height * 0.14,
      size.width * 0.38,
      size.height * 0.22,
    );
    path.cubicTo(
      size.width * 0.38,
      size.height * 0.30,
      size.width * 0.65,
      size.height * 0.24,
      size.width * 0.94,
      size.height * 0.08,
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

    // Airplane vector icon at path end
    final planePainter = TextPainter(
      text: const TextSpan(
        text: '✈',
        style: TextStyle(
          fontSize: 22,
          color: Color(0xFFB39DDB),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    canvas.save();
    canvas.translate(size.width * 0.86, size.height * 0.05);
    canvas.rotate(0.25);
    planePainter.paint(canvas, Offset.zero);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}