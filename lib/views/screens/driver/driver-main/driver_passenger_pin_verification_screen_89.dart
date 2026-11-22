import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../models/ride_booking_model.dart';
import '../../../../services/ride_service.dart';
import '../../../widgets/custom_button.dart';
import 'driver_wrong_pin_screen_90.dart';

class DriverPassengerPinVerificationScreen extends StatefulWidget {
  final String rideId;
  final String? bookingId;
  final String passengerName;
  final String pickupLocation;
  final String dropoffLocation;
  final String? expectedPin;
  final int totalSeats;
  final List<int> bookedSeats;
  final int boardingSeat;

  const DriverPassengerPinVerificationScreen({
    super.key,
    this.rideId = 'RIDE-8902',
    this.bookingId,
    this.passengerName = 'Passenger',
    this.pickupLocation = 'Madhapur',
    this.dropoffLocation = 'Secunderabad',
    this.expectedPin = '8492',
    this.totalSeats = 4,
    this.bookedSeats = const [1, 2, 3],
    this.boardingSeat = 2,
  });

  @override
  State<DriverPassengerPinVerificationScreen> createState() => _DriverPassengerPinVerificationScreenState();
}

class _DriverPassengerPinVerificationScreenState extends State<DriverPassengerPinVerificationScreen> {
  final List<TextEditingController> _controllers = List.generate(4, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (index) => FocusNode());
  bool _isLoading = false;
  PassengerBoardingVerifyDetails? _verifyDetails;

  @override
  void initState() {
    super.initState();
    _loadVerifyDetails();
  }

  Future<void> _loadVerifyDetails() async {
    final bId = widget.bookingId ?? '';
    if (bId.isEmpty) return;

    final res = await RideService.getPassengerVerifyDetails(
      rideId: widget.rideId,
      bookingId: bId,
      passengerName: widget.passengerName,
    );

    if (mounted && res['success'] == true) {
      setState(() {
        _verifyDetails = PassengerBoardingVerifyDetails.fromJson(res);
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _currentEnteredPin => _controllers.map((c) => c.text.trim()).join();

  Future<void> _handleVerifyPin() async {
    final enteredPin = _currentEnteredPin;

    if (enteredPin.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the full 4-digit passenger boarding PIN.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final res = await RideService.verifyPassengerPin(
        rideId: widget.rideId,
        bookingId: widget.bookingId,
        pin: enteredPin,
        passengerName: _verifyDetails?.passengerName ?? widget.passengerName,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (res['success'] == true) {
        final pName = _verifyDetails?.passengerName ?? widget.passengerName;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$pName verified and boarded successfully! 🎉'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
          ),
        );

        Navigator.pop(context, true);
      } else {
        // Backend 2.4.0: Unlimited attempts with zero lockout
        final errMsg = res['message']?.toString() ??
            'Incorrect 4-digit PIN. Please ask the passenger for their Zaatra boarding code.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errMsg),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 3),
          ),
        );

        for (final c in _controllers) {
          c.clear();
        }
        if (_focusNodes.isNotEmpty) {
          _focusNodes[0].requestFocus();
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Verification error: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final pName = (_verifyDetails?.passengerName != null && _verifyDetails!.passengerName.isNotEmpty && _verifyDetails!.passengerName != 'Passenger')
        ? _verifyDetails!.passengerName
        : (widget.passengerName.isNotEmpty && widget.passengerName != 'Passenger'
            ? widget.passengerName
            : (_verifyDetails?.passengerName.isNotEmpty == true ? _verifyDetails!.passengerName : widget.passengerName));
    final fromLoc = _verifyDetails?.pickupLocation.isNotEmpty == true ? _verifyDetails!.pickupLocation : widget.pickupLocation;
    final toLoc = _verifyDetails?.dropoffLocation.isNotEmpty == true ? _verifyDetails!.dropoffLocation : widget.dropoffLocation;
    final rawSeat = (_verifyDetails?.seatNumber.isNotEmpty == true)
        ? _verifyDetails!.seatNumber
        : 'S-${widget.boardingSeat}';
    final normalizedSeat = rawSeat.replaceAll('Seat ', '').trim();
    final seatLabel = normalizedSeat.startsWith('S-')
        ? normalizedSeat
        : (normalizedSeat.startsWith('S') ? 'S-${normalizedSeat.substring(1)}' : 'S-$normalizedSeat');
    final seatGrid = _verifyDetails?.seatGrid ?? [];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context, false),
        ),
        title: const Text(
          'Verification',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
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
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  const SizedBox(height: 10),

                  // Smartphone Vector Illustration Graphic
                  Center(
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF3EDF7),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.phonelink_setup_rounded, color: AppColors.primary, size: 70),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Passenger Details Banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F5FE),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.primary.withAlpha(40)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: AppColors.primary.withAlpha(30),
                          child: const Icon(Icons.person, color: AppColors.primary, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                pName,
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$fromLoc → $toLoc',
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            seatLabel,
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 26),

                  // 4-Digit PIN Entry Fields Row
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final itemWidth = (constraints.maxWidth - 3 * 14) / 4;
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(4, (index) {
                          return SizedBox(
                            width: itemWidth,
                            height: 56,
                            child: TextField(
                              controller: _controllers[index],
                              focusNode: _focusNodes[index],
                              textAlign: TextAlign.center,
                              keyboardType: TextInputType.number,
                              maxLength: 1,
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                              decoration: InputDecoration(
                                counterText: '',
                                contentPadding: EdgeInsets.zero,
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(color: AppColors.border, width: 1.5),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(color: AppColors.primary, width: 2),
                                ),
                              ),
                              onChanged: (value) {
                                if (value.isNotEmpty && index < 3) {
                                  _focusNodes[index + 1].requestFocus();
                                } else if (value.isEmpty && index > 0) {
                                  _focusNodes[index - 1].requestFocus();
                                }
                                if (_currentEnteredPin.length == 4) {
                                  FocusScope.of(context).unfocus();
                                }
                              },
                            ),
                          );
                        }),
                      );
                    },
                  ),

                  const SizedBox(height: 28),

                  // Verify PIN Primary Button
                  CustomButton(
                    text: 'Verify PIN',
                    isLoading: _isLoading,
                    onPressed: _handleVerifyPin,
                  ),


                  const SizedBox(height: 28),

                  // Seats Layout Section with Visual Matrix
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Visual Seat Grid',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F5FE),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: seatGrid.isNotEmpty
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: seatGrid.map((item) {
                              final isCurrent = item.seat == seatLabel || item.isPassengerSeat;
                              final displayStatus = isCurrent ? 'Boarding' : (item.isBooked ? 'Booked' : 'Available');
                              return _buildSeatBox(
                                '${item.seat} $displayStatus',
                                isBooked: item.isBooked && !isCurrent,
                                isBoarding: isCurrent,
                                isAvailable: item.isAvailable && !isCurrent,
                              );
                            }).toList(),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: List.generate(widget.totalSeats, (index) {
                              final seatNum = index + 1;
                              final seatCode = 'S-$seatNum';
                              final isBoarding = seatNum == widget.boardingSeat || seatCode == seatLabel;
                              final isBooked = widget.bookedSeats.contains(seatNum);

                              String label;
                              if (isBoarding) {
                                label = '$seatCode Boarding';
                              } else if (isBooked) {
                                label = '$seatCode Booked';
                              } else {
                                label = '$seatCode Available';
                              }

                              return _buildSeatBox(
                                label,
                                isBooked: isBooked && !isBoarding,
                                isBoarding: isBoarding,
                                isAvailable: !isBooked && !isBoarding,
                              );
                            }),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeatBox(String label, {required bool isBooked, bool isBoarding = false, bool isAvailable = false}) {
    Color boxColor;
    Color iconColor;

    if (isBoarding) {
      boxColor = AppColors.primary;
      iconColor = Colors.white;
    } else if (isBooked) {
      boxColor = const Color(0xFFE8DEF8);
      iconColor = AppColors.primary;
    } else {
      boxColor = const Color(0xFFE8F5E9);
      iconColor = const Color(0xFF2E7D32);
    }

    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: boxColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isBoarding
                ? [
                    BoxShadow(
                      color: AppColors.primary.withAlpha(80),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Icon(
              isAvailable ? Icons.event_seat_outlined : (isBooked ? Icons.person_rounded : Icons.check_box_outline_blank_rounded),
              color: iconColor,
              size: 22,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isBoarding ? FontWeight.bold : FontWeight.w600,
            color: isBoarding ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
