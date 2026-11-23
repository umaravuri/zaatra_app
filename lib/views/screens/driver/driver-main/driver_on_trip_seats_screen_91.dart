import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../services/ride_service.dart';
import '../../../widgets/custom_button.dart';
import 'driver_trip_shared_screen_94.dart';

class DriverOnTripSeatsScreen extends StatefulWidget {
  final String rideId;
  final String origin;
  final String destination;
  final String departureTime;
  final String arrivalTime;
  final String duration;
  final int totalSeats;
  final int bookedSeats;
  final List<dynamic>? passengerList;
  final List<dynamic>? routeTimeline;

  const DriverOnTripSeatsScreen({
    super.key,
    this.rideId = '',
    this.origin = '-',
    this.destination = '-',
    this.departureTime = '-',
    this.arrivalTime = '-',
    this.duration = '-',
    this.totalSeats = 4,
    this.bookedSeats = 3,
    this.passengerList,
    this.routeTimeline,
  });

  @override
  State<DriverOnTripSeatsScreen> createState() => _DriverOnTripSeatsScreenState();
}

class _DriverOnTripSeatsScreenState extends State<DriverOnTripSeatsScreen> {
  bool _hasStartedNavigation = false;
  bool _isNavigating = false;

  void _openShareTrip() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DriverTripSharedScreen(
          stage: 'during_ride',
          rideId: widget.rideId,
          routeTimeline: widget.routeTimeline,
          tripData: {
            'origin': widget.origin != '-' ? widget.origin : null,
            'destination': widget.destination != '-' ? widget.destination : null,
            'time': widget.departureTime != '-' ? widget.departureTime : null,
            'arrivalTime': widget.arrivalTime != '-' ? widget.arrivalTime : null,
            'duration': widget.duration != '-' ? widget.duration : null,
          },
        ),
      ),
    );
  }

  Future<void> _launchNavigation() async {
    setState(() => _isNavigating = true);

    try {
      // 1. Call backend startNavigation API if rideId available
      if (widget.rideId.isNotEmpty) {
        await RideService.startNavigation(
          rideId: widget.rideId,
          origin: widget.origin,
          destination: widget.destination,
        );
      }
    } catch (_) {}

    // 2. Launch Google Maps navigation
    final navIntentUrl = 'google.navigation:q=${Uri.encodeComponent(widget.destination)}&mode=d';
    final webUrl = 'https://www.google.com/maps/dir/?api=1&origin=${Uri.encodeComponent(widget.origin)}&destination=${Uri.encodeComponent(widget.destination)}&travelmode=driving';

    try {
      final nativeUri = Uri.parse(navIntentUrl);
      final webUri = Uri.parse(webUrl);

      bool launched = false;
      try {
        launched = await launchUrl(nativeUri, mode: LaunchMode.externalApplication);
      } catch (_) {}

      if (!launched) {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open Google Maps: $e')),
        );
      }
    }

    if (mounted) {
      setState(() {
        _isNavigating = false;
        _hasStartedNavigation = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'On Trip',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        actions: [
          IconButton(
            tooltip: 'Share Trip Card',
            icon: const Icon(Icons.share_rounded, color: AppColors.textPrimary, size: 22),
            onPressed: _openShareTrip,
          ),
        ],
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Main Live Route Card matching 91.png
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F5FE),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                widget.origin,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                widget.duration,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                widget.destination,
                                textAlign: TextAlign.end,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(widget.departureTime, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                            const Text('• • • • • • •', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                            Text(widget.arrivalTime, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Map Container inside Card matching 91.png
                        Container(
                          height: 220,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8DEF8),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                              child: const Icon(Icons.directions_car_filled_rounded, color: AppColors.primary, size: 24),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // ETA & Distance Left Row matching 91.png
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Text(
                              'ETA  ${widget.duration != '-' ? widget.duration : '02h 45 Mins'}',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            ),
                            const Text(
                              'Distance Left  -- Km',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Seats Available Section matching 91.png
                  const Text(
                    'Seats Available',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 12),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F5FE),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: _buildSeatBoxes(),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Start Navigation / Resume Navigation Button
                  CustomButton(
                    text: _isNavigating
                        ? 'Launching Navigation...'
                        : (_hasStartedNavigation ? 'Resume Navigation 🗺️' : 'Start Navigation 🗺️'),
                    backgroundColor: _hasStartedNavigation ? const Color(0xFF0288D1) : AppColors.primary,
                    textColor: Colors.white,
                    onPressed: _isNavigating ? () {} : _launchNavigation,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildSeatBoxes() {
    final total = widget.totalSeats > 0 ? widget.totalSeats : 4;
    final booked = widget.bookedSeats.clamp(0, total);
    List<Widget> boxes = [];
    for (int i = 1; i <= total; i++) {
      final isBooked = i <= booked;
      final label = isBooked ? 'S-$i Booked' : 'Available';
      boxes.add(_buildSeatBox(label, isBooked: isBooked));
    }
    return boxes;
  }

  Widget _buildSeatBox(String label, {required bool isBooked}) {
    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isBooked ? const Color(0xFFE8DEF8) : const Color(0xFFC4D5C5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Icon(
              isBooked ? Icons.person_rounded : Icons.check_box_outline_blank_rounded,
              color: isBooked ? AppColors.primary : Colors.transparent,
              size: 22,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        ),
      ],
    );
  }
}
