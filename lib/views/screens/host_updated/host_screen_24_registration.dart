import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/host_updated_property_draft_model.dart';
import '../../../services/host_service.dart';
import '../../../services/host_api_service.dart';
import 'host_dashboard_screen.dart';
import 'widgets/host_components.dart';

/// Figma: frame 1228744498 (node 1:790)
/// Figma: frame 1228744499 (node 1:840)
class HostScreen24Registration extends StatefulWidget {
  final HostUpdatedPropertyDraft draft;

  const HostScreen24Registration({
    super.key,
    required this.draft,
  });

  @override
  State<HostScreen24Registration> createState() => _HostScreen24RegistrationState();
}

class _HostScreen24RegistrationState extends State<HostScreen24Registration> {
  late HostUpdatedPropertyDraft _draft;

  final String _goalDashboard = 'Manage your property from dashboard';
  final String _goalBookings = 'Get Booking and make money from guests browser our site';
  final String _goalCalendar = 'Saying your calender';

  late String _selectedGoal;
  bool _certifiedLegitimate = false;
  bool _agreedTerms = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _draft = widget.draft;
    _selectedGoal = _draft.registrationGoal.isNotEmpty
        ? (_draft.registrationGoal == 'dashboard'
            ? _goalDashboard
            : (_draft.registrationGoal == 'calendar' ? _goalCalendar : _goalBookings))
        : _goalBookings; // 9.png wireframe has second option selected
    _certifiedLegitimate = _draft.isLegitimateCertified;
    _agreedTerms = _draft.acceptedTerms;
  }

  Future<void> _submitRegistration({bool openLater = false}) async {
    if (!_agreedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept the terms & conditions to proceed.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (!_certifiedLegitimate) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please certify that this is a legitimate business to proceed.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final updated = _draft.copyWith(
        registrationGoal: _selectedGoal == _goalDashboard
            ? 'dashboard'
            : (_selectedGoal == _goalCalendar ? 'calendar' : 'bookings'),
        isLegitimateCertified: _certifiedLegitimate,
        acceptedTerms: _agreedTerms,
      );

      final firstUnit = updated.units.isNotEmpty ? updated.units.first : <String, dynamic>{};
      final bedrooms = int.tryParse(firstUnit['beds']?.toString() ?? '1') ?? 1;
      final bathrooms = int.tryParse(firstUnit['bathrooms']?.toString() ?? '1') ?? 1;
      final guests = int.tryParse(firstUnit['guests']?.toString() ?? '2') ?? 2;
      final price = double.tryParse(firstUnit['basePrice']?.toString() ?? '2500') ?? 2500.0;

      // STATIC: skip the legacy network registration while running on static data.
      if (!HostApiService.useStaticData) {
        // Submit property payload via legacy service
        await HostService.registerProperty(
          propertyType: updated.propertyType.isNotEmpty ? updated.propertyType : 'Hotel',
          propertyName: updated.propertyName.isNotEmpty ? updated.propertyName : 'The Blue Hotel & Suites',
          title: updated.propertyName.isNotEmpty ? updated.propertyName : 'The Blue Hotel & Suites',
          type: updated.propertyType.isNotEmpty ? updated.propertyType : 'Hotel',
          location: updated.city.isNotEmpty ? '${updated.city}, ${updated.country}' : 'Hyderabad, INDIA',
          city: updated.city.isNotEmpty ? updated.city : 'Hyderabad',
          country: updated.country.isNotEmpty ? updated.country : 'INDIA',
          latitude: updated.latitude,
          longitude: updated.longitude,
          bedrooms: bedrooms,
          bathrooms: bathrooms,
          guests: guests,
          pricePerNight: price,
          description: 'Complete listing published with all 3 steps verified.',
          amenities: updated.facilities,
        );
      }

      // Publish property listing via API 8
      final publishRes = await HostApiService.publishProperty(
        propertyId: updated.propertyId,
        price: price,
      );

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      if (publishRes['success'] != true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(publishRes['message']?.toString() ?? 'Could not publish the listing. Please try again.'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      if (openLater) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Listing draft saved. You can open it later from Dashboard.')),
        );
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HostDashboardScreen()),
          (route) => false,
        );
      } else {
        _showSuccessDialog();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Registration failed: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (ctx) => const _CongratulationsDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            const HostBackgroundGraphic(),
            Column(
          children: [
            HostTopBar(
              title: 'Registration',
              onBack: () => Navigator.pop(context, _draft),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Finish your registration',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E1E24),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Radio 1: Dashboard
                    _buildGoalRadio(
                      text: _goalDashboard,
                      isSelected: _selectedGoal == _goalDashboard,
                      onTap: () => setState(() => _selectedGoal = _goalDashboard),
                    ),
                    const SizedBox(height: 16),

                    // Radio 2: Bookings (Selected in wireframe 9.png)
                    _buildGoalRadio(
                      text: _goalBookings,
                      isSelected: _selectedGoal == _goalBookings,
                      onTap: () => setState(() => _selectedGoal = _goalBookings),
                    ),
                    const SizedBox(height: 16),

                    // Radio 3: Calendar
                    _buildGoalRadio(
                      text: _goalCalendar,
                      isSelected: _selectedGoal == _goalCalendar,
                      onTap: () => setState(() => _selectedGoal = _goalCalendar),
                    ),
                    const SizedBox(height: 24),

                    // Divider matching 9.png
                    const Divider(color: Color(0xFFE2E2EC), thickness: 1),
                    const SizedBox(height: 20),

                    // Checkbox 1: Certified Legitimate
                    _buildCheckbox(
                      text:
                          'I certified that this is a legitimate business with all necessary and performance. which can be shown upon first request.zatara.com',
                      value: _certifiedLegitimate,
                      onChanged: (val) => setState(() => _certifiedLegitimate = val ?? false),
                    ),
                    const SizedBox(height: 18),

                    // Checkbox 2: Agreed Terms
                    _buildCheckbox(
                      text: 'i have read accepted and agreed to the terms & conditions.',
                      value: _agreedTerms,
                      onChanged: (val) => setState(() => _agreedTerms = val ?? false),
                    ),

                    const SizedBox(height: 36),

                    // Primary Complete Registration Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5E42C2),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _isSubmitting ? null : () => _submitRegistration(openLater: false),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2),
                              )
                            : Text(
                                'Complete Registratation',
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Secondary Action: Complete Registration & open later
                    Center(
                      child: TextButton(
                        onPressed: _isSubmitting ? null : () => _submitRegistration(openLater: true),
                        child: Text(
                          'Complete Registratation & open later',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF555566),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalRadio({
    required String text,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? const Color(0xFF1E1E24) : const Color(0xFFA0A0B2),
                width: isSelected ? 7.0 : 1.5,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF333340),
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckbox({
    required String text,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            margin: const EdgeInsets.only(top: 2.0),
            decoration: BoxDecoration(
              color: value ? Colors.transparent : Colors.white,
              borderRadius: BorderRadius.circular(5),
              border: Border.all(
                color: const Color(0xFF2E2E38),
                width: 1.8,
              ),
            ),
            child: value
                ? const Icon(
                    Icons.check_rounded,
                    size: 18,
                    color: Color(0xFF1E1E24),
                  )
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 13.5,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF555566),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Modal matching 10.png
class _CongratulationsDialog extends StatelessWidget {
  const _CongratulationsDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Confetti and Checkmark Banner
            SizedBox(
              height: 150,
              width: double.infinity,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(220, 150),
                    painter: _ConfettiPainter(),
                  ),
                  // Green circular checkmark with soft glowing ring
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2ECC71),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2ECC71).withValues(alpha: 0.35),
                          blurRadius: 20,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 44,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Congratulations Headline
            Text(
              'Congratulations your property is\nready for bookings',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E1E24),
                height: 1.35,
              ),
            ),
            const SizedBox(height: 28),

            // Go Home Button (matching 10.png)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5E42C2),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  // Close the dialog, clear the onboarding stack and open the Host Dashboard
                  final navigator = Navigator.of(context);
                  navigator.pop();
                  navigator.pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const HostDashboardScreen()),
                    (route) => false,
                  );
                },
                child: Text(
                  'Go Home',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom painter for festive confetti matching 10.png
class _ConfettiPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final cx = size.width / 2;
    final cy = size.height / 2;

    // Confetti particles matching 10.png wireframe (green, mint, emerald)
    final particles = [
      {'x': cx - 55, 'y': cy - 35, 'color': const Color(0xFF27AE60), 'type': 'rect', 'w': 5.0, 'h': 5.0, 'rot': 0.3},
      {'x': cx - 40, 'y': cy - 50, 'color': const Color(0xFF2ECC71), 'type': 'star', 'w': 4.0, 'h': 4.0, 'rot': 0.0},
      {'x': cx + 45, 'y': cy - 45, 'color': const Color(0xFF27AE60), 'type': 'rect', 'w': 5.0, 'h': 5.0, 'rot': -0.4},
      {'x': cx + 55, 'y': cy - 25, 'color': const Color(0xFF2ECC71), 'type': 'rect', 'w': 4.0, 'h': 4.0, 'rot': 0.6},
      {'x': cx - 50, 'y': cy + 30, 'color': const Color(0xFF27AE60), 'type': 'star', 'w': 4.0, 'h': 4.0, 'rot': 0.0},
      {'x': cx + 48, 'y': cy + 25, 'color': const Color(0xFF27AE60), 'type': 'rect', 'w': 4.0, 'h': 4.0, 'rot': 0.2},
      {'x': cx - 25, 'y': cy - 55, 'color': const Color(0xFF2ECC71), 'type': 'circle', 'w': 3.5, 'h': 3.5, 'rot': 0.0},
      {'x': cx + 18, 'y': cy - 58, 'color': const Color(0xFF27AE60), 'type': 'rect', 'w': 4.0, 'h': 4.0, 'rot': 0.1},
      {'x': cx - 25, 'y': cy + 50, 'color': const Color(0xFF2ECC71), 'type': 'circle', 'w': 3.0, 'h': 3.0, 'rot': 0.0},
      {'x': cx + 22, 'y': cy + 50, 'color': const Color(0xFF2ECC71), 'type': 'star', 'w': 3.5, 'h': 3.5, 'rot': 0.0},
    ];

    for (final p in particles) {
      paint.color = p['color'] as Color;
      final px = p['x'] as double;
      final py = p['y'] as double;
      final type = p['type'] as String;

      if (type == 'circle') {
        canvas.drawCircle(Offset(px, py), p['w'] as double, paint);
      } else if (type == 'rect') {
        canvas.save();
        canvas.translate(px, py);
        canvas.rotate(p['rot'] as double);
        canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: p['w'] as double, height: p['h'] as double), paint);
        canvas.restore();
      } else {
        canvas.drawCircle(Offset(px, py), 2.5, paint);
      }
    }

    // Festive ribbon swirls matching 10.png
    strokePaint.color = const Color(0xFF2ECC71);
    final path1 = Path();
    path1.moveTo(cx - 50, cy - 20);
    path1.cubicTo(cx - 58, cy - 15, cx - 48, cy - 10, cx - 55, cy - 5);
    canvas.drawPath(path1, strokePaint);

    final path2 = Path();
    path2.moveTo(cx + 50, cy - 20);
    path2.cubicTo(cx + 56, cy - 15, cx + 48, cy - 10, cx + 54, cy - 5);
    canvas.drawPath(path2, strokePaint);

    final path3 = Path();
    path3.moveTo(cx - 40, cy + 20);
    path3.cubicTo(cx - 45, cy + 28, cx - 35, cy + 32, cx - 40, cy + 38);
    canvas.drawPath(path3, strokePaint);

    final path4 = Path();
    path4.moveTo(cx + 42, cy + 20);
    path4.cubicTo(cx + 46, cy + 26, cx + 38, cy + 30, cx + 42, cy + 38);
    canvas.drawPath(path4, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

