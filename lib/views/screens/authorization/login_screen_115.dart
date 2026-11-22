import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/navigation/app_navigator.dart';
import '../../../services/auth_service.dart';
import '../../widgets/custom_button.dart';
import 'otp_verification_screen_26.dart';
import '../customer/customer-stay/customer_home_screen_38.dart';

class LoginScreen extends StatefulWidget {
  static const String routeName = AppRoutes.login;
  final bool isExistingUser;
  final String? initialPhone;

  const LoginScreen({
    super.key,
    this.isExistingUser = true,
    this.initialPhone,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  bool _agreeToTerms = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialPhone != null && widget.initialPhone!.isNotEmpty) {
      final clean = widget.initialPhone!.replaceAll(RegExp(r'[^0-9]'), '');
      final tenDigits = clean.length >= 10 ? clean.substring(clean.length - 10) : clean;
      _phoneController.text = tenDigits;
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    final phone = _phoneController.text.trim();

    if (phone.isEmpty || phone.length != 10 || !RegExp(r'^[6-9][0-9]{9}$').hasMatch(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid 10-digit mobile number starting with 9, 8, 7, or 6.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please agree to the Terms & Conditions & Privacy Policy to continue.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final formattedPhone = phone.startsWith('+91') ? phone : '+91 $phone';

    // Flush previous user session if switching to a different phone number
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentStoredPhone = prefs.getString('currentPhone') ?? '';
      final currentClean = currentStoredPhone.replaceAll(RegExp(r'[^0-9]'), '');
      final newClean = phone.replaceAll(RegExp(r'[^0-9]'), '');
      if (currentClean.isNotEmpty &&
          currentClean != newClean &&
          !currentClean.endsWith(newClean) &&
          !newClean.endsWith(currentClean)) {
        await AuthService.logout();
      }
    } catch (_) {}

    String matchedPhone = formattedPhone;
    String otp = '123456';
    String userName = 'User';

    // Request 6-digit OTP from backend (or fallback to instant OTP)
    try {
      final result = await AuthService.loginInitMobile(
        phone: formattedPhone,
      );

      if (result['success'] == true) {
        matchedPhone = result['matchedPhone']?.toString() ?? formattedPhone;
        otp = (result['otp'] ?? (result['data'] is Map ? result['data']['otp'] : null))?.toString() ?? '123456';
        final rawUser = result['user'] ?? (result['data'] is Map ? result['data']['user'] : null);
        if (rawUser is Map) {
          userName = (rawUser['name'] ?? rawUser['fullName'] ?? 'User').toString();
        }
      }
    } catch (_) {
      // Backend unreachable or offline; continue with OTP flow
    }

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.mark_email_read_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'OTP Sent to $matchedPhone: $otp',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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

    // 🚀 Navigate to OTP Verification Screen matching Screen 26
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OtpVerificationScreen(
          phoneNumber: matchedPhone,
          expectedOtp: otp,
          isExistingUser: true,
          isRegistrationFlow: false,
          userName: userName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.opaque,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ✈️ Subtle Flight Path Background Graphic matching Screen 115
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 280,
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _FlightPathPainter(),
                ),
              ),
            ),

            // Bottom City Skyline Watermark matching 115.png
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
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: mediaQuery.size.height - mediaQuery.padding.top - mediaQuery.padding.bottom,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 12),

                        // Top Navigation Row matching Screen 115 (Back button + Indian flag badge)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
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
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              )
                            else
                              const SizedBox(width: 40),
                            _buildIndiaFlagBadge(),
                          ],
                        ),

                        const SizedBox(height: 40),

                        // Centered Zaatra Logo matching Screen 115
                        Center(
                          child: Image.asset(
                            'assets/images/zaatra_logo_badge.png',
                            height: 78,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => Image.asset(
                              'assets/images/WhatsApp_Image_2026-07-30_at_9.42.30_PM-removebg-preview 2.png',
                              height: 78,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const Column(
                                children: [
                                  Text(
                                    'Zaatra',
                                    style: TextStyle(
                                      fontSize: 34,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  Text(
                                    'STAY  |  RIDE  |  EXPLORE',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondary,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 50),

                        // "Mobile Number" Label matching Screen 115
                        const Text(
                          'Mobile Number',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Phone Input Field matching Screen 115 (+ 91 000-000-0000)
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE2E0E8)),
                          ),
                          child: TextField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.done,
                            maxLength: 10,
                            onSubmitted: (_) => _handleLogin(),
                            inputFormatters: [
                              IndianPhoneNumberFormatter(),
                            ],
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                              letterSpacing: 0.5,
                            ),
                            decoration: const InputDecoration(
                              hintText: '000-000-0000',
                              hintStyle: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.normal,
                                color: Color(0xFF9E9E9E),
                              ),
                              counterText: '',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              prefixIcon: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                child: Text(
                                  '+ 91',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              prefixIconConstraints: BoxConstraints(minWidth: 0, minHeight: 0),
                            ),
                          ),
                        ),

                        const SizedBox(height: 28),

                        // Primary "Login" CTA Button matching Screen 115
                        CustomButton(
                          text: 'Login',
                          isLoading: _isLoading,
                          onPressed: _handleLogin,
                        ),

                        const Spacer(),

                        // "Sign Up Later?" Text Button matching Screen 115
                        Center(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(builder: (context) => const CustomerHomeScreen(userName: '')),
                                (route) => false,
                              );
                            },
                            child: const Text(
                              'Sign Up Later?',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 18),

                        // "I Agree to Terms & Conditions & Privacy Policy" Checkbox matching Screen 115
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              height: 22,
                              width: 22,
                              child: Checkbox(
                                value: _agreeToTerms,
                                activeColor: AppColors.primary,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                onChanged: (val) {
                                  setState(() {
                                    _agreeToTerms = val ?? false;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: RichText(
                                text: TextSpan(
                                  text: 'I Agree to ',
                                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                  children: const [
                                    TextSpan(
                                      text: 'Terms & Conditions',
                                      style: TextStyle(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.bold,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                    TextSpan(text: ' & '),
                                    TextSpan(
                                      text: 'Privacy Policy',
                                      style: TextStyle(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.bold,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIndiaFlagBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8E8EC)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: SizedBox(
          width: 22,
          height: 15,
          child: Column(
            children: [
              Expanded(child: Container(color: const Color(0xFFFF9933))), // Saffron
              Expanded(
                child: Container(
                  color: Colors.white,
                  child: Center(
                    child: Container(
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF000080), // Navy Blue Chakra
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(child: Container(color: const Color(0xFF138808))), // Green
            ],
          ),
        ),
      ),
    );
  }
}

/// Custom painter for the dotted curved flight path matching Screen 115
class _FlightPathPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD1C4E9).withValues(alpha: 0.5)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(size.width * 0.05, size.height * 0.85);
    path.cubicTo(
      size.width * 0.35,
      size.height * 0.95,
      size.width * 0.55,
      size.height * 0.2,
      size.width * 0.95,
      size.height * 0.35,
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
    canvas.translate(size.width * 0.88, size.height * 0.28);
    canvas.rotate(0.3);
    planePainter.paint(canvas, Offset.zero);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Formatter that strictly allows only 10 digits starting with 9, 8, 7, or 6
class IndianPhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (text.isEmpty) {
      return newValue;
    }

    // Strip non-digits
    String digits = text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(text: '');
    }

    // If pasted with leading 91 (12 digits) or leading 0 (11 digits), strip country code/zero
    if (digits.length == 12 && digits.startsWith('91')) {
      digits = digits.substring(2);
    } else if (digits.length == 11 && digits.startsWith('0')) {
      digits = digits.substring(1);
    }

    // Reject if first digit is NOT 6, 7, 8, or 9
    if (digits.isNotEmpty) {
      final firstChar = digits[0];
      if (firstChar != '9' && firstChar != '8' && firstChar != '7' && firstChar != '6') {
        return oldValue;
      }
    }

    // Max 10 digits
    final truncated = digits.length > 10 ? digits.substring(0, 10) : digits;

    return TextEditingValue(
      text: truncated,
      selection: TextSelection.collapsed(offset: truncated.length),
    );
  }
}
