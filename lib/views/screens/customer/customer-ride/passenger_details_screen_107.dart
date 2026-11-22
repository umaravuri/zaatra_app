import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../models/ride_booking_model.dart';
import '../../../../services/auth_service.dart';
import '../../../../services/ride_service.dart';
import '../../../widgets/custom_button.dart';
import 'ride_awaiting_confirmation_screen.dart';
import 'ride_booking_success_screen_111.dart';

/// ============================================================================
/// SCREEN DATA ARCHITECTURE & API DEPENDENCY SPECIFICATION
/// ============================================================================
/// 
/// 1. APIS CALLED ON THIS SCREEN:
/// ----------------------------------------------------------------------------
/// A) [API 1: Customer Profile Prefill]
///    - Invoked: In `initState()` via `AuthService.getCurrentUser()`
///    - Source / Endpoint: Local Auth / Session Token Cache or `/api/auth/profile`
///    - Data Received:
///        • `name` (String) -> Split into First Name & Last Name controllers
///        • `phone` (String) -> Populates Phone Number controller
///        • `email` (String) -> Populates Email ID controller
///    - Usage: Pre-populates customer input fields if empty so the user doesn't
///      need to retype their profile information.
///
/// B) [API 2: Ride Booking Creation]
///    - Invoked: On "Book Ride" tap via `RideService.createBooking(...)`
///    - Endpoint: `POST /api/rides/book`
///    - Payload Dispatched (Frontend -> Backend):
///        • `rideId`: Driver's published ride ID (from session)
///        • `fullName`: Merged first + last name from text fields
///        • `phoneNumber`: Full phone with prefix `+91 ...`
///        • `emailID`: Customer email address
///        • `numberOfSeats`: Selected count from dropdown (1..4)
///        • `boardingPoint` / `pickup`: Selected boarding/pickup location
///        • `destination`: Ride drop-off point
///        • `paymentMethod`: "PAY_TO_DRIVER" (cash/UPI directly to driver)
///        • `doorstepPickupRequested`: Boolean flag (true if doorstep selected)
///        • `extraPickupCharge`: Detour fee amount
///        • `pricePerSeat`: Price per seat defined on driver ride
///        • `totalAmount`: Total computed fare (seats * price + detour charge)
///        • `luggage`: Selected luggage type (e.g. "1 Medium Bag")
///    - Response Received (Backend -> Frontend):
///        • `bookingId` / `id` / `_id`: Unique booking identifier created in DB
///        • `success`: Boolean status flag
///    - Usage: Transitions to [RideAwaitingConfirmationScreen] waiting for driver approval.
///
/// ----------------------------------------------------------------------------
/// 2. FIELD CLASSIFICATION (DYNAMIC vs STATIC):
/// ----------------------------------------------------------------------------
/// • DYNAMIC / API & SESSION DRIVEN:
///    - First Name & Last Name: Pre-filled via `AuthService`, editable by user.
///    - Phone Number: Pre-filled via `AuthService`, editable by user (10 digits).
///    - Email ID: Pre-filled via `AuthService`, editable by user.
///    - Number of Seats: Dynamically inherited from customer search session (`session.seatsCount`).
///    - Seat Fare: `session.driver.pricePerSeat * session.seatsCount` (Driver API).
///    - Doorstep Detour Fee: `session.detourCharge` (Google Maps Distance Matrix API).
///    - Total Payable: Live calculation `(pricePerSeat * seats) + detourCharge`.
///
/// • STATIC / UI-ONLY:
///    - Screen title: "Passenger Details"
///    - Field labels: "full name", "Last name", "Phone Number", "Email ID",
///      "Number Of Seats", "Fare Summary", "Total Payable".
///    - Phone prefix badge: "+91 "
///    - Bottom background illustration: `assets/images/image 31.png`
///    - Button CTA: "Book Ride"
/// ============================================================================
class PassengerDetailsScreen extends StatefulWidget {
  final RideBookingSession? session;

  const PassengerDetailsScreen({
    super.key,
    this.session,
  });

  @override
  State<PassengerDetailsScreen> createState() => _PassengerDetailsScreenState();
}

class _PassengerDetailsScreenState extends State<PassengerDetailsScreen> {
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;

  RideBookingSession get _activeSession => widget.session ?? const RideBookingSession();
  int get _seatsCount => _activeSession.seatsCount > 0 ? _activeSession.seatsCount : 1;

  static bool _isPlaceholderName(String? name) {
    if (name == null) return true;
    final clean = name.trim().toLowerCase();
    if (clean.isEmpty) return true;
    if (clean == 'customer' ||
        clean == 'user' ||
        clean.startsWith('customer ') ||
        clean.startsWith('customer_') ||
        clean.startsWith('user ') ||
        clean.startsWith('user_')) {
      return true;
    }
    // Pure numeric like "8888" or phone digits
    if (RegExp(r'^\d+$').hasMatch(clean)) return true;
    return false;
  }

  static bool _isPlaceholderEmail(String? email) {
    if (email == null) return true;
    final clean = email.trim().toLowerCase();
    if (clean.isEmpty) return true;
    if (clean.endsWith('@zaatra.com') ||
        clean.startsWith('customer_') ||
        clean.startsWith('user_') ||
        clean.contains('placeholder')) {
      return true;
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    String initName = _activeSession.passengerName.trim();
    if (_isPlaceholderName(initName)) initName = '';
    final nameParts = initName.split(' ');
    final rawFirst = nameParts.isNotEmpty ? nameParts.first : '';
    final rawLast = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
    _firstNameController = TextEditingController(text: !_isPlaceholderName(rawFirst) ? rawFirst : '');
    _lastNameController = TextEditingController(text: !_isPlaceholderName(rawLast) ? rawLast : '');

    // Phone number comes automatically
    String initPhone = _activeSession.passengerPhone.replaceAll(RegExp(r'^\+91\s*'), '').trim();
    _phoneController = TextEditingController(text: initPhone);

    // Email is optional and should be empty if user didn't fill it
    String initEmail = _activeSession.passengerEmail.trim();
    if (_isPlaceholderEmail(initEmail)) initEmail = '';
    _emailController = TextEditingController(text: initEmail);

    _prefillFromAuth();
  }

  Future<void> _prefillFromAuth() async {
    final user = await AuthService.getCurrentUser();
    final prefsPhone = await AuthService.getCurrentUserPhone();
    if (!mounted) return;

    setState(() {
      // 1. Phone number comes automatically
      if (_phoneController.text.isEmpty) {
        String p = user != null ? (user['phone']?.toString() ?? '') : '';
        if (p.isEmpty) p = prefsPhone;
        final digits = p.replaceAll(RegExp(r'[^0-9]'), '');
        final tenDigits = digits.length >= 10 ? digits.substring(digits.length - 10) : digits;
        if (tenDigits.isNotEmpty) _phoneController.text = tenDigits;
      }

      // 2. Name: Only prefill if user actually entered a real name, NOT a placeholder
      if (_firstNameController.text.isEmpty && _lastNameController.text.isEmpty && user != null) {
        final n = user['name']?.toString() ?? '';
        if (!_isPlaceholderName(n)) {
          final parts = n.trim().split(' ');
          final first = parts.isNotEmpty ? parts.first : '';
          final last = parts.length > 1 ? parts.sublist(1).join(' ') : '';
          if (!_isPlaceholderName(first)) _firstNameController.text = first;
          if (!_isPlaceholderName(last)) _lastNameController.text = last;
        }
      }

      // 3. Email: Optional, never prefill placeholders
      if (_emailController.text.isEmpty && user != null) {
        final e = user['email']?.toString() ?? '';
        if (!_isPlaceholderEmail(e)) {
          _emailController.text = e;
        }
      }
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  bool _isSubmitting = false;

  Future<void> _handleBookRide(RideBookingSession session, double totalFare) async {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final fullName = '$firstName $lastName'.trim();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();

    // Only name field is mandatory
    if (firstName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your first name.'), backgroundColor: Colors.red),
      );
      return;
    }

    // Phone number must be valid
    if (phone.isEmpty || phone.length < 10 || !RegExp(r'^[6-9][0-9]{9}$').hasMatch(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid 10-digit mobile number starting with 6, 7, 8 or 9.'), backgroundColor: Colors.red),
      );
      return;
    }

    // Email is optional: only validate format if user entered something
    if (email.isNotEmpty && !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]{2,}$').hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email address or leave it empty.'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final isAutoApproved = session.driver.preferences.autoApproval ||
        (session.rideDetailData?.driver.preferences.autoApproval ?? false);

    final isWholeCar = session.driver.isWholeCarOnly ||
        session.driver.rideType == 'door_to_door' ||
        session.isDoorstepPickup;
    final totalSeats = session.driver.totalSeats > 0 ? session.driver.totalSeats : 4;
    final bookingSeats = isWholeCar ? totalSeats : _seatsCount;

    final rideId = session.rideId.isNotEmpty ? session.rideId : session.driver.id;
    // Single payload builder; only the quote id differs between the first attempt and the retry.
    Future<Map<String, dynamic>> submitBooking(String? quoteId) => RideService.createBooking(
          rideId: rideId,
          quoteId: quoteId,
          passengerDetailsList: [
            {
              'name': fullName,
              'phone': '+91 $phone',
              'email': email,
            }
          ],
          fullName: fullName,
          lastName: lastName.isNotEmpty ? lastName : firstName,
          phoneNumber: '+91 $phone',
          emailID: email,
          numberOfSeats: bookingSeats,
          boardingPoint: session.boardingPoint.isNotEmpty ? session.boardingPoint : session.pickup,
          destination: session.destination,
          pickup: session.pickup.isNotEmpty ? session.pickup : session.boardingPoint,
          customerPickupAddress: session.customerPickupAddress.isNotEmpty ? session.customerPickupAddress : session.boardingPoint,
          customerDropAddress: session.customerDropAddress.isNotEmpty ? session.customerDropAddress : session.destination,
          customerPickupPincode: session.customerPickupPincode,
          customerPickupLandmark: session.customerPickupLandmark,
          custPickupLandmark: session.customerPickupLandmark,
          customerDropLandmark: session.customerDropAddress.isNotEmpty ? session.customerDropAddress : null,
          doorstepPickupRequested: session.isDoorstepPickup,
          isWholeCar: isWholeCar,
          extraPickupCharge: session.detourCharge,
          pricePerSeat: session.driver.pricePerSeat,
          totalAmount: totalFare,
          paymentMethod: 'PAY_TO_DRIVER',
          luggage: session.luggage.isNotEmpty ? session.luggage : "1 Medium Bag",
          status: isAutoApproved ? 'confirmed' : 'pending',
        );

    Map<String, dynamic> res;
    try {
      res = await submitBooking(session.quoteId.isNotEmpty ? session.quoteId : null);

      // If the first attempt failed with a quote error, retry once without the stale quote id.
      if (res['success'] != true && (res['message']?.toString().toLowerCase().contains('quote') ?? false)) {
        res = await submitBooking(null);
      }
    } catch (_) {
      // Network/timeouts must never leave the button spinning.
      res = {
        'success': false,
        'message': 'Could not create the booking. Please check your connection and try again.',
      };
    }

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (res['success'] != true) {
      String msg = res['message']?.toString() ?? 'Failed to create booking. Please try again.';
      if (msg.contains('/api/') || msg.toLowerCase().contains('quote-fare') || msg.toLowerCase().contains('post ')) {
        msg = 'Unable to lock fare quote. Please try again.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final bookingId = res['bookingId']?.toString() ??
        res['id']?.toString() ??
        (res['data'] is Map
            ? (res['data']['bookingId'] ?? res['data']['id'] ?? res['data']['_id'])?.toString() ?? ''
            : '');

    final boardingPin = res['boardingPin']?.toString() ??
        res['otp']?.toString() ??
        (res['data'] is Map ? (res['data']['boardingPin'] ?? res['data']['otp'])?.toString() ?? '' : '');

    final finalSession = session.copyWith(
      rideId: rideId,
      bookingId: bookingId,
      boardingPin: boardingPin.isNotEmpty ? boardingPin : session.boardingPin,
      passengerName: fullName,
      passengerPhone: '+91 $phone',
      passengerEmail: email,
      seatsCount: _seatsCount,
      totalAmount: totalFare,
      paymentMethod: 'PAY_TO_DRIVER',
    );

    final rawBookingStatus = (res['status'] ??
            res['bookingStatus'] ??
            (res['data'] is Map ? res['data']['status'] : null) ??
            (res['booking'] is Map ? res['booking']['status'] : null) ??
            '')
        .toString()
        .toLowerCase()
        .trim();

    final isConfirmed = isAutoApproved ||
        rawBookingStatus == 'confirmed' ||
        rawBookingStatus == 'accepted';

    if (isConfirmed) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => RideBookingSuccessScreen(
            session: finalSession,
            bookingId: bookingId,
          ),
        ),
      );
    } else {
      // Replace (not push) so back from the awaiting screen cannot land on this filled form
      // and create a duplicate booking.
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => RideAwaitingConfirmationScreen(
            session: finalSession,
            bookingId: bookingId,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = _activeSession;
    final isDoorToDoor = session.isDoorstepPickup ||
        session.driver.rideType.toLowerCase() == 'door_to_door' ||
        session.driver.isWholeCarOnly;
    final totalVehicleSeats = session.driver.totalSeats > 0 ? session.driver.totalSeats : 4;
    final chargedSeats = isDoorToDoor ? totalVehicleSeats : _seatsCount;
    final carPrice = (session.driver.wholeCarPrice > (session.driver.pricePerSeat * 1.5))
        ? session.driver.wholeCarPrice
        : (session.driver.pricePerSeat * totalVehicleSeats);
    final seatFare = isDoorToDoor ? carPrice : (session.driver.pricePerSeat * _seatsCount);
    final totalFare = seatFare + session.detourCharge;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Passenger Details',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 18),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
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
            Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Full Name', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                        const SizedBox(height: 8),
                        _buildInputField(
                          controller: _firstNameController,
                          hintText: 'Enter full name',
                          prefixIcon: const Icon(Icons.person_outline_rounded, color: AppColors.textSecondary),
                        ),

                        const SizedBox(height: 16),

                        const Text('Last name (Optional)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                        const SizedBox(height: 8),
                        _buildInputField(
                          controller: _lastNameController,
                          hintText: 'Enter last name (optional)',
                          prefixIcon: const Icon(Icons.person_outline_rounded, color: AppColors.textSecondary),
                        ),

                        const SizedBox(height: 16),

                        const Text('Phone Number', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                        const SizedBox(height: 8),
                        _buildInputField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          hintText: '9876543210',
                          maxLength: 10,
                          prefixWidget: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                            child: Text(
                              '+91 ',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            ),
                          ),
                          inputFormatters: [
                            _IndianMobileInputFormatter(),
                          ],
                        ),

                        const SizedBox(height: 16),

                        const Text('Email ID (Optional)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                        const SizedBox(height: 8),
                        _buildInputField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          hintText: 'name@example.com (optional)',
                          prefixIcon: const Icon(Icons.email_outlined, color: AppColors.textSecondary),
                        ),

                        const SizedBox(height: 20),

                        const Text('Number Of Seats', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                        const SizedBox(height: 8),

                        // Dynamic Read-Only Seat Badge inherited from Search Session
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFAFAFA),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.airline_seat_recline_normal_rounded, color: AppColors.primary, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  isDoorToDoor
                                      ? 'Whole Car ($chargedSeats Seats)'
                                      : '$_seatsCount ${_seatsCount == 1 ? 'Seat' : 'Seats'}',
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Driver Preferences & Luggage Policy Card
                        Builder(
                          builder: (context) {
                            final prefs = session.driver.preferences;
                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF9F9FB),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.shield_outlined, size: 16, color: AppColors.primary),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'Driver Policy & Luggage',
                                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                      ),
                                      const Spacer(),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: prefs.autoApproval ? const Color(0xFFE8F5E9) : const Color(0xFFFFF8E1),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          prefs.autoApproval ? 'Auto Confirm' : 'Manual Approval',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: prefs.autoApproval ? const Color(0xFF2E7D32) : const Color(0xFFE65100),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.luggage_outlined, size: 14, color: AppColors.textSecondary),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          'Luggage Limit: Max ${prefs.luggageCount} Large & ${prefs.mediumBagCount} Medium bag(s) per seat.',
                                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (prefs.driverPreferences.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 4,
                                      children: [
                                        for (final rule in prefs.driverPreferences)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: const Color(0xFFE0E0E0)),
                                            ),
                                            child: Text(
                                              '• $rule',
                                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 20),

                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7F4FB),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Fare Summary', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                              const SizedBox(height: 12),
                              _buildFareRow(
                                isDoorToDoor
                                    ? 'Entire Vehicle Booking (${chargedSeats} Seats Reserved)'
                                    : 'Seat Fare (${_seatsCount}x ₹${session.driver.pricePerSeat.toStringAsFixed(0)})',
                                '₹${seatFare.toStringAsFixed(0)}',
                              ),
                              if (isDoorToDoor) ...[
                                const SizedBox(height: 8),
                                _buildFareRow('Booking Mode', 'Private / Door-to-Door Vehicle'),
                              ],
                              const SizedBox(height: 10),
                              const Divider(color: AppColors.border),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Total Payable', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                                  Text(
                                    '₹${totalFare.toStringAsFixed(0)}',
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primary),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: CustomButton(
                    text: 'Book Ride',
                    isLoading: _isSubmitting,
                    onPressed: _isSubmitting ? null : () => _handleBookRide(session, totalFare),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFareRow(String label, String amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Text(amount, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      ],
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    String? hintText,
    Widget? prefixIcon,
    Widget? prefixWidget,
    int? maxLength,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLength: maxLength,
      inputFormatters: inputFormatters,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hintText,
        counterText: '',
        prefixIcon: prefixWidget ?? prefixIcon,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        fillColor: Colors.white,
        filled: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
      ),
    );
  }
}

/// Keeps digits only, drops a pasted +91 / 91 / 0 prefix and limits the value to 10 digits.
class _IndianMobileInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length > 10 && digits.startsWith('91')) digits = digits.substring(2);
    if (digits.length > 10 && digits.startsWith('0')) digits = digits.substring(1);
    if (digits.length > 10) digits = digits.substring(0, 10);
    return TextEditingValue(
      text: digits,
      selection: TextSelection.collapsed(offset: digits.length),
    );
  }
}