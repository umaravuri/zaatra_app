import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../services/auth_service.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/custom_text_field.dart';
import '../../authorization/otp_verification_screen_26.dart';

/// Formatter strictly enforcing Indian mobile number rules:
/// 1. Only digits [0-9]
/// 2. First digit MUST be 6, 7, 8, or 9
/// 3. Maximum length strictly 10 digits
class IndianMobileInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (text.isEmpty) return newValue;

    // Reject non-numeric characters
    if (!RegExp(r'^[0-9]+$').hasMatch(text)) {
      return oldValue;
    }

    // First digit must strictly be 6, 7, 8, or 9
    if (!['6', '7', '8', '9'].contains(text[0])) {
      return oldValue;
    }

    // Max 10 digits
    if (text.length > 10) {
      return oldValue;
    }

    return newValue;
  }
}

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emergencyController = TextEditingController();

  String _initialPhone = '';
  bool _isPhoneVerified = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();

    _phoneController.addListener(() {
      final current = _phoneController.text.trim();
      if (current != _initialPhone) {
        if (_isPhoneVerified) {
          setState(() => _isPhoneVerified = false);
        }
      } else if (_initialPhone.isNotEmpty && !_isPhoneVerified) {
        setState(() => _isPhoneVerified = true);
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _emergencyController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    final user = await AuthService.getCurrentUser();
    if (user != null && mounted) {
      final p = user['phone']?.toString() ?? '';
      final digits = p.replaceAll(RegExp(r'[^0-9]'), '');
      final tenDigits = digits.length >= 10 ? digits.substring(digits.length - 10) : digits;

      setState(() {
        _nameController.text = user['name']?.toString() ?? '';
        _emailController.text = user['email']?.toString() ?? '';
        _phoneController.text = tenDigits;
        _initialPhone = tenDigits;
        _isPhoneVerified = tenDigits.isNotEmpty;
      });
    } else {
      final name = await AuthService.getUserName(defaultFallback: '');
      final phone = await AuthService.getCurrentUserPhone();
      final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
      final tenDigits = digits.length >= 10 ? digits.substring(digits.length - 10) : digits;

      if (mounted) {
        setState(() {
          if (name.isNotEmpty) _nameController.text = name;
          if (tenDigits.isNotEmpty) {
            _phoneController.text = tenDigits;
            _initialPhone = tenDigits;
            _isPhoneVerified = true;
          }
        });
      }
    }
  }

  void _saveProfile() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your full name.'), backgroundColor: Colors.red),
      );
      return;
    }

    if (phone.isNotEmpty && (phone.length < 10 || !RegExp(r'^[6-9][0-9]{9}$').hasMatch(phone))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid 10-digit mobile number starting with 9, 8, 7, or 6.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (email.isNotEmpty && (!email.contains('@') || !email.contains('.'))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email address.'), backgroundColor: Colors.red),
      );
      return;
    }

    // Check if phone number was modified
    final cleanInitial = _initialPhone.replaceAll(RegExp(r'[^0-9]'), '');
    final cleanCurrent = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final bool phoneHasChanged = cleanCurrent.isNotEmpty && cleanCurrent != cleanInitial;

    // If phone has changed and not yet verified, trigger OTP flow
    if (phoneHasChanged && !_isPhoneVerified) {
      setState(() => _isLoading = true);
      final formattedPhone = phone.startsWith('+91') ? phone : '+91 $phone';
      String otp = '';
      String matchedPhone = formattedPhone;
      bool otpRequested = false;

      try {
        final result = await AuthService.loginInitMobile(phone: formattedPhone);
        if (result['success'] == true) {
          otpRequested = true;
          matchedPhone = result['matchedPhone']?.toString() ?? formattedPhone;
          otp = (result['otp'] ?? (result['data'] is Map ? result['data']['otp'] : null))?.toString() ?? '';
        }
      } catch (_) {}

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (!otpRequested) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not send the verification code. Please try again.'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      // Show SMS OTP demonstration toast matching login screen
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.mark_email_read_rounded, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  otp.isNotEmpty ? 'OTP Sent to $matchedPhone: $otp' : 'OTP sent to $matchedPhone',
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

      // Open OTP Verification Screen
      final verified = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => OtpVerificationScreen(
            phoneNumber: matchedPhone,
            expectedOtp: otp,
            isPhoneUpdateFlow: true,
            userName: name,
          ),
        ),
      );

      if (verified == true && mounted) {
        setState(() {
          _isPhoneVerified = true;
          _initialPhone = cleanCurrent;
        });

        // Persist verified profile
        await _persistProfile(name: name, phone: phone, email: email);
      }
      return;
    }

    // Phone unchanged or already verified
    await _persistProfile(name: name, phone: phone, email: email);
  }

  Future<void> _persistProfile({
    required String name,
    required String phone,
    required String email,
  }) async {
    setState(() => _isLoading = true);

    try {
      if (name.isNotEmpty) {
        await AuthService.saveUserName(name, phone: phone);
      }

      if (phone.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        final clean = phone.replaceAll(RegExp(r'[^0-9]'), '');
        final ten = clean.length >= 10 ? clean.substring(clean.length - 10) : clean;
        await prefs.setString('currentPhone', '+91 $ten');
        await prefs.setString('last_phone_number', ten);
      }
    } catch (_) {}

    await Future.delayed(const Duration(milliseconds: 300));

    if (mounted) {
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully! 🎉'),
          backgroundColor: AppColors.success,
        ),
      );

      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Edit Profile'),
        elevation: 0,
      ),
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Bottom Background Graphic
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
            SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Avatar Camera Badge
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 46,
                          backgroundColor: AppColors.primaryBackground,
                          child: const Icon(Icons.person_rounded, size: 54, color: AppColors.primary),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  CustomTextField(
                    label: 'Full Name',
                    hint: 'Enter full name',
                    controller: _nameController,
                    prefixIcon: Icons.person_outline_rounded,
                  ),

                  const SizedBox(height: 20),

                  CustomTextField(
                    label: 'Email Address',
                    hint: 'Enter email address',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icons.email_outlined,
                  ),

                  const SizedBox(height: 20),

                  // Mobile Number Field Header with Verified Badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Mobile Number',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                      ),
                      if (_isPhoneVerified && _phoneController.text.trim().isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF81C784)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle_rounded, color: Color(0xFF2E7D32), size: 14),
                              SizedBox(width: 4),
                              Text(
                                'Verified',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2E7D32),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    maxLength: 10,
                    inputFormatters: [
                      IndianMobileInputFormatter(),
                    ],
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      hintText: '9876543210',
                      counterText: '',
                      prefixIcon: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        child: Text('+91 ', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      ),
                      suffixIcon: _isPhoneVerified && _phoneController.text.trim().isNotEmpty
                          ? const Icon(Icons.verified_rounded, color: Color(0xFF2E7D32), size: 20)
                          : null,
                      fillColor: AppColors.inputBackground,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  CustomTextField(
                    label: 'Emergency Contact',
                    hint: 'Enter emergency contact',
                    controller: _emergencyController,
                    prefixIcon: Icons.contact_phone_outlined,
                  ),

                  const SizedBox(height: 36),

                  CustomButton(
                    text: 'Save Changes',
                    isLoading: _isLoading,
                    onPressed: _saveProfile,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}