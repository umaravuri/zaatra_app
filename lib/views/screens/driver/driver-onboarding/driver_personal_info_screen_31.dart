import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../services/auth_service.dart';
import '../../../../services/driver_service.dart';
import 'driver_document_upload_screen_33.dart';

class DriverPersonalInfoScreen extends StatefulWidget {
  final String role;
  final Map<String, dynamic>? initialData;

  const DriverPersonalInfoScreen({
    super.key,
    this.role = 'Driver',
    this.initialData,
  });

  @override
  State<DriverPersonalInfoScreen> createState() => _DriverPersonalInfoScreenState();
}

class _DriverPersonalInfoScreenState extends State<DriverPersonalInfoScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initPrefilledData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _initPrefilledData() async {
    // 1. First priority: Check passed initialData from Registration / OTP
    if (widget.initialData != null && widget.initialData!.isNotEmpty) {
      final initName = widget.initialData!['fullName'] ?? widget.initialData!['name'] ?? '';
      final initEmail = widget.initialData!['email'] ?? '';
      final initPhone = widget.initialData!['phone'] ?? '';
      final initLocation = widget.initialData!['location'] ??
          widget.initialData!['city'] ??
          '';

      final cleanInitName = initName.toString().trim();
      if (cleanInitName.isNotEmpty && cleanInitName.toLowerCase() != 'user') {
        _nameController.text = cleanInitName;
      }
      if (initEmail.toString().trim().isNotEmpty) {
        _emailController.text = initEmail.toString().trim();
      }
      if (initPhone.toString().trim().isNotEmpty) {
        final d = initPhone.toString().replaceAll(RegExp(r'[^0-9]'), '');
        final tenDigits = d.length >= 10 ? d.substring(d.length - 10) : d;
        _phoneController.text = tenDigits;
      }
      if (initLocation.toString().trim().isNotEmpty) {
        _locationController.text = initLocation.toString().trim();
      }
    }

    // 2. Second priority / Fallback: Check local storage and backend profile
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentPhone = prefs.getString('currentPhone') ?? '';
      final cleanDigits = currentPhone.replaceAll(RegExp(r'[^0-9]'), '');
      final tenDigits = cleanDigits.length >= 10 ? cleanDigits.substring(cleanDigits.length - 10) : cleanDigits;

      if (_nameController.text.isEmpty) {
        final savedName = prefs.getString('user_name_$cleanDigits') ??
            prefs.getString('currentUserName') ??
            '';
        if (savedName.isNotEmpty && savedName.toLowerCase() != 'user') {
          _nameController.text = savedName;
        }
      }

      if (_phoneController.text.isEmpty && tenDigits.isNotEmpty) {
        _phoneController.text = tenDigits;
      }

      if (_emailController.text.isEmpty) {
        final savedEmail = prefs.getString('user_email_$cleanDigits') ??
            prefs.getString('currentUserEmail') ??
            '';
        if (savedEmail.isNotEmpty) _emailController.text = savedEmail;
      }

      if (_locationController.text.isEmpty) {
        final savedLoc = prefs.getString('user_city_$cleanDigits') ??
            prefs.getString('currentUserCity') ??
            '';
        if (savedLoc.isNotEmpty) _locationController.text = savedLoc;
      }

      // If still missing, check AuthService user profile
      if (_nameController.text.isEmpty || _emailController.text.isEmpty) {
        final user = await AuthService.getCurrentUser();
        if (user != null) {
          if (_nameController.text.isEmpty && user['name'] != null) {
            final uName = user['name'].toString().trim();
            if (uName.isNotEmpty && uName.toLowerCase() != 'user') {
              _nameController.text = uName;
            }
          }
          if (_emailController.text.isEmpty && user['email'] != null) {
            _emailController.text = user['email'].toString().trim();
          }
        }
      }

      if (mounted) setState(() {});
    } catch (_) {}
  }

  void _nextStep() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final location = _locationController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Full name is required. Please enter your name.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (name.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid full name (at least 2 letters).'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (!RegExp(r"^[a-zA-Z\s]+$").hasMatch(name)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Name must contain only alphabetic letters and spaces (no numbers or special characters).'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (phone.isEmpty || phone.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid 10-digit mobile number.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Email is optional, but if entered, validate simple format
    if (email.isNotEmpty && !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid email address, or leave it blank.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final formattedPhone = phone.startsWith('+91') ? phone : '+91 $phone';
    final cleanDigits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final tenDigits = cleanDigits.length >= 10 ? cleanDigits.substring(cleanDigits.length - 10) : cleanDigits;

    // Call API 2: POST /api/drivers/register/step-1
    Map<String, dynamic>? step1Response;
    try {
      step1Response = await DriverService.registerStep1(
        fullName: name,
        phone: tenDigits,
        email: email.isNotEmpty ? email : null,
        city: location.isNotEmpty ? location : null,
      );
    } catch (_) {}

    final rawDriver = step1Response?['driver'] is Map ? (step1Response!['driver'] as Map<String, dynamic>) : null;
    final userId = rawDriver?['userId'] ?? rawDriver?['id'] ?? rawDriver?['_id'];

    final driverData = {
      ...?widget.initialData,
      'fullName': name,
      'name': name,
      'email': email,
      'phone': formattedPhone,
      'cleanPhone': tenDigits,
      'city': location.isNotEmpty ? location : (rawDriver?['city'] ?? ''),
      'location': location.isNotEmpty ? location : 'India',
      'country': 'India',
      if (userId != null) 'userId': userId.toString(),
      if (step1Response != null) 'step1Response': step1Response,
    };

    // Save locally
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_name_$cleanDigits', name);
      await prefs.setString('user_name_$tenDigits', name);
      if (email.isNotEmpty) await prefs.setString('user_email_$cleanDigits', email);
      if (location.isNotEmpty) await prefs.setString('user_city_$cleanDigits', location);
      await prefs.setString('currentUserName', name);
      await prefs.setString('driverName', name);
      await prefs.setString('currentPhone', formattedPhone);
      if (userId != null) {
        await prefs.setString('driverId', userId.toString());
        await prefs.setString('driver_user_id', userId.toString());
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }

    if (!mounted) return;

    // Navigate to Screen 33 (Driver Document Upload Screen)
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DriverDocumentUploadScreen(
          role: widget.role,
          driverData: driverData,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9FD),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Dotted flight trail in background
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _OnboardingFlightPathPainter(),
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
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),

                  // Circular Back Button matching Screen 31
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

                  const SizedBox(height: 18),

                  // Progress Bar: Step 1 of 3 (33%) matching Screen 31
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: const LinearProgressIndicator(
                      value: 0.33,
                      minHeight: 6,
                      backgroundColor: Color(0xFFE8DEF8),
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Title & Subtitle matching Screen 31
                  const Text(
                    'Tell us About yourself',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E1E2D),
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Fill in your personal details',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF7A7A8C),
                      fontWeight: FontWeight.w400,
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Full Name Field (Compulsory, Alphabetic Letters Only)
                  _buildInputField(
                    label: 'Full Name',
                    hint: 'Enter your full name',
                    controller: _nameController,
                    prefixIcon: Icons.person_outline_rounded,
                    keyboardType: TextInputType.name,
                    isRequired: true,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r"[a-zA-Z\s]")),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // Email ID Field (Pre-filled from Registration if available)
                  _buildInputField(
                    label: 'Email ID (Optional)',
                    hint: 'Enter Here',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icons.email_outlined,
                  ),

                  const SizedBox(height: 18),

                  // Phone Number Field (Pre-filled from Registration / Verified - Uneditable)
                  _buildInputField(
                    label: 'Phone Number',
                    hint: '+91 000-000-0000',
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    prefixIcon: Icons.phone_outlined,
                    maxLength: 10,
                    readOnly: true,
                    enabled: false,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // Location / City Field (Optional)
                  _buildInputField(
                    label: 'City / Location (Optional)',
                    hint: 'Enter your city or area',
                    controller: _locationController,
                    prefixIcon: Icons.location_on_outlined,
                  ),

                  const SizedBox(height: 36),

                  // Continue CTA Button matching Screen 31
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _nextStep,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isLoading
                          ? const Center(
                              child: SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              ),
                            )
                          : const Text(
                              'Continue',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
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

  Widget _buildInputField({
    required String label,
    required String hint,
    required TextEditingController controller,
    IconData? prefixIcon,
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
    List<TextInputFormatter>? inputFormatters,
    bool readOnly = false,
    bool enabled = true,
    bool isRequired = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E1E2D),
              ),
            ),
            if (isRequired) ...[
              const SizedBox(width: 4),
              const Text(
                '*',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: enabled && !readOnly ? Colors.white : const Color(0xFFF5F5F7),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E4E9)),
          ),
          child: TextField(
            controller: controller,
            readOnly: readOnly,
            enabled: enabled,
            keyboardType: keyboardType,
            maxLength: maxLength,
            inputFormatters: inputFormatters,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: enabled && !readOnly ? const Color(0xFF1E1E2D) : const Color(0xFF6B7280),
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                color: Color(0xFFA0A0B0),
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
              counterText: '',
              prefixIcon: prefixIcon != null
                  ? Icon(prefixIcon, color: const Color(0xFF7A7A8C), size: 20)
                  : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }
}

/// Dotted flight path decoration matching the onboarding screens
class _OnboardingFlightPathPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD1C4E9).withValues(alpha: 0.5)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(size.width * 0.1, size.height * 0.35);
    path.cubicTo(
      size.width * 0.3, size.height * 0.28,
      size.width * 0.5, size.height * 0.22,
      size.width * 0.5, size.height * 0.14,
    );
    path.cubicTo(
      size.width * 0.5, size.height * 0.08,
      size.width * 0.38, size.height * 0.08,
      size.width * 0.38, size.height * 0.14,
    );
    path.cubicTo(
      size.width * 0.38, size.height * 0.22,
      size.width * 0.7, size.height * 0.18,
      size.width * 0.94, size.height * 0.06,
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
    canvas.translate(size.width * 0.86, size.height * 0.03);
    canvas.rotate(0.25);
    planePainter.paint(canvas, Offset.zero);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
