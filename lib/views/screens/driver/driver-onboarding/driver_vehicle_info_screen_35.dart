import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/navigation/app_navigator.dart';
import '../../../../services/auth_service.dart';
import '../../../../services/driver_service.dart';
import '../driver-main/driver_home_dashboard_screen_83.dart';
import '../driver-main/driver_my_ride_screen_30.dart';

class DriverVehicleInfoScreen extends StatefulWidget {
  final String role;
  final Map<String, dynamic>? driverData;
  final bool redirectToPostRide;

  const DriverVehicleInfoScreen({
    super.key,
    this.role = 'Driver',
    this.driverData,
    this.redirectToPostRide = false,
  });

  @override
  State<DriverVehicleInfoScreen> createState() => _DriverVehicleInfoScreenState();
}

class _DriverVehicleInfoScreenState extends State<DriverVehicleInfoScreen> {
  final _vehicleTypeController = TextEditingController();
  final _makeController = TextEditingController();
  final _modelController = TextEditingController();
  final _vehicleNumberController = TextEditingController();
  String? _selectedYear;

  bool _isLoading = false;

  @override
  void dispose() {
    _vehicleTypeController.dispose();
    _makeController.dispose();
    _modelController.dispose();
    _vehicleNumberController.dispose();
    super.dispose();
  }

  /// Indian registration plates: e.g. AP39AB1234, TS 09 EA 1234, DL-1C-AB-1234, and the BH series (22BH1234AA).
  static final RegExp _plateRegex = RegExp(r'^([A-Z]{2}\d{1,2}[A-Z]{0,3}\d{4}|\d{2}BH\d{4}[A-Z]{1,2})$');

  String? _validateVehicle({
    required String type,
    required String make,
    required String model,
    required String plate,
    required String year,
    bool optionalIfEmpty = false,
  }) {
    // During registration vehicle details are optional: leaving everything empty is fine.
    // Once the driver starts filling them in (or when posting a ride) they must be complete.
    final allEmpty = [type, make, model, plate, year].every((v) => v.isEmpty);
    if (optionalIfEmpty && allEmpty) return null;

    if (type.isEmpty) return 'Please enter your vehicle type (for example Sedan or SUV).';
    if (make.isEmpty) return 'Please enter the vehicle make (for example Toyota).';
    if (model.isEmpty) return 'Please enter the vehicle model (for example Innova).';
    if (year.isEmpty) return 'Please select the vehicle year.';
    if (plate.isEmpty) return 'Please enter the vehicle number plate.';
    final compactPlate = plate.replaceAll(RegExp(r'[\s-]'), '');
    if (!_plateRegex.hasMatch(compactPlate)) {
      return 'Please enter a valid number plate, for example AP39AB1234.';
    }
    return null;
  }

  /// "Skip for now": register without vehicle details (they are asked for again when posting a ride).
  void _skipVehicle() {
    setState(() {
      _vehicleTypeController.clear();
      _makeController.clear();
      _modelController.clear();
      _vehicleNumberController.clear();
      _selectedYear = null;
    });
    _submitApplication();
  }

  void _submitApplication() async {
    final vehicleType = _vehicleTypeController.text.trim();
    final vehicleMake = _makeController.text.trim();
    final vehicleModel = _modelController.text.trim();
    final vehicleNumber = _vehicleNumberController.text.trim().toUpperCase();
    final vehicleYear = _selectedYear ?? '';

    final validationError = _validateVehicle(
      type: vehicleType,
      make: vehicleMake,
      model: vehicleModel,
      plate: vehicleNumber,
      year: vehicleYear,
      // Reached from "Post a ride" (redirectToPostRide): every field is mandatory there.
      optionalIfEmpty: !widget.redirectToPostRide,
    );
    if (validationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(validationError), backgroundColor: Colors.redAccent),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final phone = widget.driverData?['cleanPhone'] ??
          widget.driverData?['phone'] ??
          prefs.getString('currentPhone') ??
          prefs.getString('driverPhone') ??
          '';
      final cleanDigits = phone.toString().replaceAll(RegExp(r'[^0-9]'), '');
      final tenDigits = cleanDigits.length >= 10 ? cleanDigits.substring(cleanDigits.length - 10) : cleanDigits;

      // 1. Call API 2: POST /api/drivers/vehicle-info (Submit Vehicle Information)
      // Best-effort: registerStep3 below is the authoritative call and is checked.
      try {
        await DriverService.submitVehicleInfo(
          vehicleType: vehicleType,
          vehicleMake: vehicleMake,
          vehicleModel: vehicleModel,
          vehicleNumberPlate: vehicleNumber,
          vehicleYear: vehicleYear.isNotEmpty ? vehicleYear : null,
        );
      } catch (_) {}

      // Fallback sync via registerStep3
      Map<String, dynamic>? step3Response;
      try {
        step3Response = await DriverService.registerStep3(
          phone: tenDigits,
          vehicleType: vehicleType.isNotEmpty ? vehicleType : null,
          make: vehicleMake.isNotEmpty ? vehicleMake : null,
          model: vehicleModel.isNotEmpty ? vehicleModel : null,
          year: vehicleYear.isNotEmpty ? vehicleYear : null,
          vehicleNumberPlate: vehicleNumber.isNotEmpty ? vehicleNumber : null,
        );
      } catch (_) {}

      // Never mark the driver as onboarded or open the dashboard if the server rejected the registration.
      if (step3Response == null || step3Response['success'] != true) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              step3Response?['message']?.toString() ??
                  'Could not complete your registration. Please check your connection and try again.',
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      // Also sync via legacy updateVehicleInfo as safety net
      try {
        await DriverService.updateVehicleInfo(
          vehicleType: vehicleType.isNotEmpty ? vehicleType : null,
          vehicleMake: vehicleMake.isNotEmpty ? vehicleMake : null,
          vehicleModel: vehicleModel.isNotEmpty ? vehicleModel : null,
          vehicleYear: vehicleYear.isNotEmpty ? vehicleYear : null,
          vehicleNumberPlate: vehicleNumber.isNotEmpty ? vehicleNumber : null,
        );
      } catch (_) {}

      // 2. Extract returned auth token and driver profile
      final token = step3Response['token']?.toString() ?? step3Response['data']?['token']?.toString();
      final rawDriver = step3Response['driver'] is Map ? (step3Response['driver'] as Map<String, dynamic>) : null;
      final userId = rawDriver?['userId']?.toString() ??
          rawDriver?['id']?.toString() ??
          rawDriver?['_id']?.toString() ??
          widget.driverData?['userId']?.toString();
      final driverName = rawDriver?['fullName']?.toString() ??
          rawDriver?['name']?.toString() ??
          widget.driverData?['fullName']?.toString() ??
          widget.driverData?['name']?.toString() ??
          '';

      // 3. Save locally to SharedPreferences to mark driver as onboarded
      final plateVal = vehicleNumber;
      if (cleanDigits.isNotEmpty) {
        await prefs.setBool('is_old_driver_$cleanDigits', true);
        await prefs.setBool('is_old_driver_$tenDigits', true);
        await prefs.setBool('driver_onboarded_$cleanDigits', true);
        await prefs.setBool('driver_onboarded_$tenDigits', true);
        await prefs.setString('driver_vehicle_plate_$cleanDigits', plateVal);
        await prefs.setString('driver_vehicle_plate_$tenDigits', plateVal);
        await prefs.setString('driver_vehicle_type_$cleanDigits', vehicleType);
        await prefs.setString('driver_vehicle_make_$cleanDigits', vehicleMake);
        await prefs.setString('driver_vehicle_model_$cleanDigits', vehicleModel);
        await prefs.setString('driver_vehicle_year_$cleanDigits', vehicleYear);
      }
      await prefs.setString('driver_vehicle_plate', plateVal);
      await prefs.setBool('is_old_driver', true);
      await prefs.setString('lastActiveRole', 'Driver');
      await prefs.setString('currentUserRole', 'driver');
      await prefs.setString('selectedRole', 'driver');
      if (driverName.isNotEmpty) {
        await prefs.setString('driverName', driverName);
        await prefs.setString('currentUserName', driverName);
      }
      if (userId != null && userId.isNotEmpty) {
        await prefs.setString('driverId', userId);
        await prefs.setString('driver_user_id', userId);
      }

      if (!widget.redirectToPostRide && tenDigits.isNotEmpty) {
        // Newly registered drivers start active.
        await DriverService.markOnlineAtLogin('+91 $tenDigits');
      }

      // Establish 30-day persistent session if token returned
      if (token != null && token.isNotEmpty) {
        await AuthService.createSession(
          token: token,
          role: 'driver',
          phone: '+91 $tenDigits',
          userId: userId,
          driverId: userId,
          userProfile: rawDriver,
        );
      }

      if (!mounted) return;

      final successMsg = step3Response['message']?.toString() ?? 'Vehicle registered successfully!';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(successMsg),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 2),
        ),
      );

      // 4. Navigation: Either to Post Ride or Driver Dashboard
      if (widget.redirectToPostRide) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const DriverMyRideScreen(),
          ),
        );
      } else {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            settings: const RouteSettings(name: AppRoutes.driverHome),
            builder: (context) => DriverHomeDashboardScreen83(
              driverName: driverName.isNotEmpty ? driverName : null,
            ),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      // Stay on this screen so the driver can retry; do not open the dashboard on failure.
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Something went wrong while saving your vehicle. Please try again.'),
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

                  // Circular Back Button matching Screen 35
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

                  // Progress Bar: Step 3 of 3 (100% full line) matching Screen 35
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: const LinearProgressIndicator(
                      value: 1.0,
                      minHeight: 6,
                      backgroundColor: Color(0xFFE8DEF8),
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Title & Subtitle matching Screen 35
                  const Text(
                    'Vehicle Information',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E1E2D),
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Tell about our Vehicle (Optional)',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF7A7A8C),
                      fontWeight: FontWeight.w400,
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Field 1: Vehicle Type
                  _buildInputField(
                    label: 'Vehicle Type',
                    hint: 'e.g. Sedan, SUV, Hatchback',
                    controller: _vehicleTypeController,
                  ),

                  const SizedBox(height: 18),

                  // Field 2: Make
                  _buildInputField(
                    label: 'Make',
                    hint: 'e.g. Maruti Suzuki, Hyundai',
                    controller: _makeController,
                  ),

                  const SizedBox(height: 18),

                  // Field 3: Model
                  _buildInputField(
                    label: 'Model',
                    hint: 'e.g. Dzire, Swift, Creta',
                    controller: _modelController,
                  ),

                  const SizedBox(height: 18),

                  // Field 4: Vehicle Number (max 12 alphanumeric, uppercase)
                  _buildInputField(
                    label: 'Vehicle Number',
                    hint: 'e.g. TS09AB1234',
                    controller: _vehicleNumberController,
                    maxLength: 12,
                    textCapitalization: TextCapitalization.characters,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // Field 5: Year (Dropdown from 1990 up to next year)
                  _buildYearDropdown(),

                  const SizedBox(height: 36),

                  // Continue CTA Button matching Screen 35
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitApplication,
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
                              'Continue',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.2,
                              ),
                            ),
                    ),
                  ),

                  if (!widget.redirectToPostRide) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: TextButton(
                        onPressed: _isLoading ? null : _skipVehicle,
                        child: const Text(
                          'Skip for now',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.primary),
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Text(
                        'Vehicle details are optional now, but you will need to add them before you can post a ride.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ),
                  ],

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
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
    int? maxLength,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E1E2D),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E4E9)),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            textCapitalization: textCapitalization,
            maxLength: maxLength,
            inputFormatters: inputFormatters,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1E1E2D),
            ),
            decoration: InputDecoration(
              counterText: '',
              hintText: hint,
              hintStyle: const TextStyle(
                color: Color(0xFFA0A0B0),
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildYearDropdown() {
    final latestYear = DateTime.now().year + 1; // next-year models are already on sale
    final years = List<String>.generate(latestYear - 1990 + 1, (i) => (latestYear - i).toString());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Year',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E1E2D),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E4E9)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedYear,
              isExpanded: true,
              hint: const Text(
                'Select Year',
                style: TextStyle(
                  color: Color(0xFFA0A0B0),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF7A7A8C)),
              items: years.map((y) {
                return DropdownMenuItem<String>(
                  value: y,
                  child: Text(
                    y,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1E1E2D),
                    ),
                  ),
                );
              }).toList(),
              onChanged: (val) {
                setState(() {
                  _selectedYear = val;
                });
              },
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