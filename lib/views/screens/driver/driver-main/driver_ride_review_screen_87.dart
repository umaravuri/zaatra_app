import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../models/place_location_model.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/route_map_webview.dart';
import 'driver_customer_preferences_screen_93.dart';

/// Screen 87 — Ride Review
/// Displays a summary of the ride the driver is about to publish.
/// No Preference section — removed per design update.
class DriverRideReviewScreen extends StatelessWidget {
  final Map<String, dynamic>? rideDetails;

  const DriverRideReviewScreen({super.key, this.rideDetails});

  @override
  Widget build(BuildContext context) {
    final pickup = rideDetails?['pickupLocation'] ?? rideDetails?['from'] ?? 'Pickup';
    final dest = rideDetails?['destinationLocation'] ?? rideDetails?['to'] ?? 'Destination';
    final date = _formatDate(rideDetails?['departureDate'] ?? rideDetails?['departs']);
    final time = rideDetails?['departureTime'] ?? rideDetails?['time'] ?? '--:--';
    final seats = rideDetails?['seats']?.toString() ?? '4';
    final pricePerSeat = rideDetails?['pricePerSeat'] ?? rideDetails?['price'] ?? 850;
    final luggageCount = rideDetails?['luggage'] ?? rideDetails?['luggageCount'] ?? 1;
    final luggageSize = rideDetails?['luggageSize'] ?? 'Medium Bag';
    final duration = rideDetails?['duration'] ?? '';
    final distance = rideDetails?['distance'] ?? '';
    final polyline = rideDetails?['polyline'] ?? '';

    // Build LocationPoints for the map
    final pickupLat = (rideDetails?['pickupLat'] as num?)?.toDouble() ?? 0.0;
    final pickupLng = (rideDetails?['pickupLng'] as num?)?.toDouble() ?? 0.0;
    final destLat = (rideDetails?['destLat'] as num?)?.toDouble() ?? 0.0;
    final destLng = (rideDetails?['destLng'] as num?)?.toDouble() ?? 0.0;

    final pickupPoint = LocationPoint(
      name: pickup,
      formattedAddress: rideDetails?['from'] ?? pickup,
      latitude: pickupLat,
      longitude: pickupLng,
    );
    final destPoint = LocationPoint(
      name: dest,
      formattedAddress: rideDetails?['to'] ?? dest,
      latitude: destLat,
      longitude: destLng,
    );

    CandidateRoute? candidate;
    if (polyline.isNotEmpty) {
      candidate = CandidateRoute(
        routeIndex: 0,
        summary: '',
        name: 'Route',
        distanceText: distance,
        distanceMeters: 0,
        durationText: duration,
        durationSeconds: 0,
        overviewPolyline: polyline,
        isRecommended: true,
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Ride',
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
                  // Pickup
                  _buildLocationBox('Pickup location', pickup, const Color(0xFF4CAF50)),
                  const SizedBox(height: 12),
                  // Destination
                  _buildLocationBox('Destination', dest, const Color(0xFFE53935)),
                  const SizedBox(height: 16),

                  // Route Map
                  RouteMapWebView(
                    pickup: pickup,
                    destination: dest,
                    pickupPoint: pickupPoint,
                    destPoint: destPoint,
                    candidateRoutes: candidate != null ? [candidate] : const [],
                    height: 220,
                    borderRadius: 18,
                    interactive: false,
                    selectedRouteIndex: 0,
                    onRouteSelected: null,
                  ),

                  const SizedBox(height: 20),

                  // Ride Details Grid
                  Row(
                    children: [
                      Expanded(child: _buildDetailCard('Date', date, Icons.calendar_today_rounded)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildDetailCard('Time', time, Icons.access_time_rounded)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildDetailCard('Available Seats', '$seats Seats', Icons.people_alt_rounded)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildDetailCard('Paid for seat', '₹ $pricePerSeat', Icons.currency_rupee_rounded)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildDetailCard(
                    'Luggage',
                    '$luggageCount $luggageSize',
                    Icons.luggage_rounded,
                  ),

                  const SizedBox(height: 32),

                  CustomButton(
                    text: 'Next',
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DriverCustomerPreferencesScreen(
                            rideDetails: rideDetails,
                          ),
                        ),
                      );

                      if (result is Map && result['action'] == 'change_date') {
                        if (context.mounted) {
                          // Pop back past review screen directly to the date/calendar screen
                          Navigator.pop(context, result);
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(dynamic raw) {
    if (raw == null) return '--';
    final s = raw.toString();
    // Try ISO format: 2024-05-20T...
    final dt = DateTime.tryParse(s);
    if (dt != null) {
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    }
    // Already formatted (e.g. "20 - 5 - 2024")
    return s.replaceAll(RegExp(r'\s*-\s*'), ' ');
  }

  Widget _buildLocationBox(String label, String address, Color iconColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.location_on_rounded, color: iconColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 2),
                Text(
                  address,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
