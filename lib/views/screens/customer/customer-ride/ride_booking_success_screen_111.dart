import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../models/ride_booking_model.dart';
import '../../../../services/ride_service.dart';
import '../../../../services/customer_location_tracking_service.dart';
import '../../../widgets/custom_button.dart';
import '../customer-stay/customer_home_screen_38.dart';
import 'live_ride_tracking_screen_106.dart';
import 'ride_confirmed_detail_screen_112.dart';

class RideBookingSuccessScreen extends StatefulWidget {
  final RideBookingSession? session;
  final String? bookingId;
  final RideConfirmationModal? confirmationModal;

  const RideBookingSuccessScreen({
    super.key,
    this.session,
    this.bookingId,
    this.confirmationModal,
  });

  @override
  State<RideBookingSuccessScreen> createState() => _RideBookingSuccessScreenState();
}

class _RideBookingSuccessScreenState extends State<RideBookingSuccessScreen> {
  RideConfirmationModal? _modal;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _modal = widget.confirmationModal;
    final session = widget.session;
    final id = widget.bookingId ?? session?.bookingId ?? '';
    if (session != null && id.isNotEmpty) {
      CustomerLocationTrackingService.instance.setActiveBookingFromStrings(
        bookingId: id,
        dateStr: session.date,
        timeStr: session.time,
        driverName: session.driver.name,
        pickupAddress: session.pickup,
      );
    }
    if (_modal == null) {
      _fetchConfirmationModal();
    }
  }

  Future<void> _fetchConfirmationModal() async {
    final effectiveId = widget.bookingId ?? widget.session?.bookingId ?? '';
    if (effectiveId.isEmpty) return;

    setState(() => _isLoading = true);
    final res = await RideService.getRideConfirmation(effectiveId);
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (res['success'] == true) {
          _modal = RideConfirmationModal.fromJson(res);
          final data = res['data'] is Map ? res['data'] as Map : res;
          final active = _activeSession;
          final dateStr = (data['date'] ?? data['departureDate'] ?? active.date).toString();
          final timeStr = (data['time'] ?? data['departureTime'] ?? active.time).toString();
          final pickupAddr = (data['pickupLocation'] ?? data['pickup'] ?? active.pickup).toString();
          CustomerLocationTrackingService.instance.setActiveBookingFromStrings(
            bookingId: effectiveId,
            dateStr: dateStr,
            timeStr: timeStr,
            driverName: _modal!.driverName.isNotEmpty ? _modal!.driverName : active.driver.name,
            pickupAddress: pickupAddr,
          );
        }
      });
    }
  }

  RideBookingSession get _activeSession => widget.session ?? const RideBookingSession();

  @override
  Widget build(BuildContext context) {
    final active = _activeSession;
    final m = _modal;

    final title = m?.title.isNotEmpty == true ? m!.title : 'Ride Accepted & Confirmed!';
    final subtitle = m?.subtitle.isNotEmpty == true
        ? m!.subtitle
        : 'Your ride with ${active.driver.name.isNotEmpty ? active.driver.name : (m?.driverName.isNotEmpty == true ? m!.driverName : "the driver")} has\nbeen accepted and confirmed successfully';
    
    final pin = m?.boardingPin.isNotEmpty == true
        ? m!.boardingPin
        : active.boardingPin;
    // Never show an invented PIN: if none has been issued yet, say so.
    final pinLabel = pin.isNotEmpty ? pin : 'Pending';

    final vehicleModel = active.driver.carModel.isNotEmpty
        ? active.driver.carModel
        : (m?.vehicle ?? '');
    final vehiclePlate = active.driver.vehicleNumber.isNotEmpty
        ? active.driver.vehicleNumber
        : (m?.vehicleNumberPlate ?? '');
    final carPlateJoined = [vehicleModel, vehiclePlate].where((s) => s.isNotEmpty).join(' • ');
    final carPlate = m?.carAndPlate.isNotEmpty == true
        ? m!.carAndPlate
        : (carPlateJoined.isNotEmpty ? carPlateJoined : 'Details pending');
    
    final payAmount = m?.payToDriver.isNotEmpty == true
        ? m!.payToDriver
        : (active.totalAmount > 0
            ? '₹${active.totalAmount.toStringAsFixed(0)} (Cash/UPI)'
            : (m?.amountFormatted.isNotEmpty == true ? '${m!.amountFormatted} (Cash/UPI)' : 'Cash/UPI'));

    return Scaffold(
      backgroundColor: Colors.white,
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
            if (_isLoading)
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: LinearProgressIndicator(
                  color: AppColors.primary,
                  backgroundColor: Color(0xFFF3EDF7),
                  minHeight: 3,
                ),
              ),
            LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Spacer(),
                            const SizedBox(height: 16),

                            // Celebration Checkmark Circle matching Screen 111
                            Container(
                              width: 120,
                              height: 120,
                              decoration: const BoxDecoration(
                                color: Color(0xFFE8F5E9),
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: Icon(Icons.check_circle_rounded, color: Color(0xFF4CAF50), size: 80),
                              ),
                            ),

                            const SizedBox(height: 28),

                            // Title Header matching Screen 111
                            Text(
                              title,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),

                            const SizedBox(height: 10),

                            Text(
                              subtitle,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 15,
                                color: AppColors.textSecondary,
                                height: 1.4,
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Security Boarding PIN & Booking Card
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF7F4FB),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          m?.pinLabel.isNotEmpty == true ? m!.pinLabel : 'Boarding 4-Digit PIN:',
                                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          pinLabel,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            letterSpacing: 2,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  const Divider(color: AppColors.border),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          m?.carAndPlateLabel.isNotEmpty == true ? m!.carAndPlateLabel : 'Car & Plate:',
                                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          carPlate,
                                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.end,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          m?.payToDriverLabel.isNotEmpty == true ? m!.payToDriverLabel : 'Pay to Driver:',
                                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        payAmount,
                                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF2E7D32)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            const Spacer(),
                            const SizedBox(height: 16),

                            // Primary CTA: View Trip Details (Screen 112)
                            CustomButton(
                              text: 'View Trip Details',
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => RideConfirmedDetailScreen112(
                                      session: active,
                                      bookingId: widget.bookingId ?? active.bookingId,
                                    ),
                                  ),
                                );
                              },
                            ),

                            const SizedBox(height: 10),

                            // Secondary CTA: Show Route Map (Screen 106)
                            OutlinedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => LiveRideTrackingScreen(session: active),
                                  ),
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 50),
                                side: const BorderSide(color: AppColors.primary, width: 1.5),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.map_rounded, color: AppColors.primary, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'Show Route Map',
                                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primary),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 8),

                            // Tertiary CTA: Go To Dashboard (Screen 38)
                            TextButton(
                              onPressed: () {
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(builder: (context) => const CustomerHomeScreen()),
                                  (route) => false,
                                );
                              },
                              child: const Text(
                                'Go To Dashboard',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                              ),
                            ),

                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}