import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../models/customer_booking_model.dart';
import '../customer-ride/live_ride_tracking_screen_106.dart';
import '../customer-ride/ride_chat_screen.dart';

/// Customer-side "Active" ride card (Figma frame 88246764).
///
/// The ride has already started, so there is intentionally no Cancel action.
/// Actions: Call driver, Message driver, Track ride.
class ActiveRideCard extends StatelessWidget {
  final CustomerBookingItem booking;

  /// Opens the ride's detail screen (PIN, route, booking info).
  final VoidCallback? onViewDetails;

  const ActiveRideCard({super.key, required this.booking, this.onViewDetails});

  static const Color _ink = Color(0xFF1E1B1E);
  static const Color _grey = Color(0xFF757575);
  static const Color _line = Color(0xFFEDE7F6);

  // ---- data helpers -------------------------------------------------------

  Map<String, dynamic> get _driver => booking.driverInfo ?? const {};

  String _firstNonEmpty(List<dynamic> values, String fallback) {
    for (final v in values) {
      final s = v?.toString().trim() ?? '';
      if (s.isNotEmpty) return s;
    }
    return fallback;
  }

  String get _driverName => _firstNonEmpty([_driver['name'], _driver['fullName']], 'Driver');
  String get _driverPhone => _firstNonEmpty([_driver['phone'], _driver['phoneNumber']], '');
  String get _driverAvatar => _firstNonEmpty([_driver['avatar'], _driver['photo']], '');
  String get _rating => _firstNonEmpty([_driver['rating']], '');

  String get _driverDetails {
    final parts = <String>[];
    final car = _firstNonEmpty([_driver['carModel'], _driver['vehicleModel']], '');
    final trips = _firstNonEmpty([_driver['tripsCount'], _driver['trips']], '');
    final plate = _firstNonEmpty([_driver['vehicleNumber'], _driver['numberPlate']], '');
    if (car.isNotEmpty) parts.add(car);
    if (trips.isNotEmpty && trips != '0') parts.add('$trips Trips');
    if (plate.isNotEmpty) parts.add(plate);
    return parts.join(', ');
  }

  String get _destination => booking.destinationLocation.isNotEmpty
      ? booking.destinationLocation.split(',').first.trim()
      : 'Destination';

  String get _pickup => booking.pickupLocation.isNotEmpty
      ? booking.pickupLocation.split(',').first.trim()
      : '';

  /// Live stops come from the API (`stops`/`route`) when present, otherwise
  /// we fall back to pickup -> destination.
  List<MapEntry<String, String>> get _stops {
    final raw = booking.rawJson['stops'] ?? booking.rawJson['route'];
    final out = <MapEntry<String, String>>[];
    if (raw is List) {
      for (final s in raw) {
        if (s is Map) {
          final name = _firstNonEmpty([s['name'], s['location'], s['city']], '');
          final time = _firstNonEmpty([s['time'], s['eta'], s['arrival']], '');
          if (name.isNotEmpty) out.add(MapEntry(time, name));
        }
      }
    }
    if (out.isEmpty) {
      if (_pickup.isNotEmpty) out.add(MapEntry(booking.departureTime, _pickup));
      out.add(MapEntry('', _destination));
    }
    return out;
  }

  // ---- actions ------------------------------------------------------------

  Future<void> _launch(BuildContext context, String scheme, String label) async {
    final clean = _driverPhone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (clean.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Driver phone number is not available yet')),
      );
      return;
    }
    final uri = Uri.parse('$scheme:$clean');
    try {
      if (!await launchUrl(uri) && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open $label for $_driverPhone')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open $label for $_driverPhone')),
        );
      }
    }
  }

  void _openChat(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RideChatScreen(
          bookingId: booking.refId,
          driverName: _driverName,
          vehicleInfo: _driverDetails,
        ),
      ),
    );
  }

  void _track(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LiveRideTrackingScreen(
          bookingId: booking.refId,
        ),
      ),
    );
  }

  // ---- build --------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _line, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _mapStrip(context),
              const SizedBox(height: 14),
              _driverRow(),
              const SizedBox(height: 6),
              Text('Cost Per Seat ${booking.price}',
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: _ink)),
              const SizedBox(height: 12),
              _pinBanner(),
              const SizedBox(height: 12),
              _destinationRow(),
              const SizedBox(height: 16),
              _sectionTitle('Live stops'),
              const SizedBox(height: 4),
              _liveStops(),
              const SizedBox(height: 18),
              _actions(context),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(t, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: _ink)),
      );

  Widget _img(String asset, double w, double h, double r) => ClipRRect(
        borderRadius: BorderRadius.circular(r),
        child: Image.asset(asset,
            width: w,
            height: h,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(width: w, height: h, color: _line)),
      );

  // Map strip: static placeholder with a Track button (no map SDK in the app).
  Widget _mapStrip(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => _track(context),
        child: Container(
          width: double.infinity,
          height: 180,
          color: const Color(0xFFF1F8E9),
          child: Stack(
            children: [
              Center(child: Icon(Icons.map_rounded, size: 80, color: Colors.green.shade100)),
              const Positioned(top: 20, left: 40, child: Icon(Icons.location_on, color: AppColors.primary, size: 28)),
              const Positioned(bottom: 24, right: 40, child: Icon(Icons.location_on, color: Colors.redAccent, size: 28)),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(8)),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.my_location_rounded, color: Colors.white, size: 14),
                      SizedBox(width: 4),
                      Text('Track ride',
                          style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _driverRow() {
    final avatar = _driverAvatar;
    final Widget photo = avatar.startsWith('http')
        ? ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.network(avatar,
                width: 58,
                height: 58,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _img('assets/images/image 27.png', 58, 58, 14)),
          )
        : _img('assets/images/image 27.png', 58, 58, 14);

    return Row(
      children: [
        photo,
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_driverName,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: _ink)),
              if (_driverDetails.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(_driverDetails, style: const TextStyle(fontSize: 11, color: _grey)),
              ],
              if (_rating.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star_rounded, color: Color(0xFFFFB800), size: 16),
                    const SizedBox(width: 3),
                    Text(_rating,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _ink)),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _pinBanner() {
    if (booking.boardingPin.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 11),
      alignment: Alignment.center,
      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(12)),
      child: Text('PIN: ${booking.boardingPin}',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
    );
  }

  Widget _destinationRow() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Destination',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _ink)),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  children: List.generate(
                    14,
                    (_) => Expanded(
                      child: Container(
                        height: 1.5,
                        margin: const EdgeInsets.symmetric(horizontal: 1.5),
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const Text('ETA', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _ink)),
          ],
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                _destination,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: _grey),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              booking.departureTime.isNotEmpty ? 'Time: ${booking.departureTime}' : 'Time: --',
              style: const TextStyle(fontSize: 12, color: _grey),
            ),
          ],
        ),
      ],
    );
  }

  Widget _liveStops() {
    final stops = _stops;
    return Column(
      children: [
        for (var i = 0; i < stops.length; i++)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 64,
                child: Text(stops[i].key,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _ink)),
              ),
              Column(
                children: [
                  if (i == 0)
                    const Icon(Icons.directions_car_rounded, size: 16, color: AppColors.primary)
                  else
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(color: Color(0xFFBDBDBD), shape: BoxShape.circle),
                    ),
                  if (i != stops.length - 1) Container(width: 2, height: 24, color: const Color(0xFFE0E0E0)),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(stops[i].value,
                    style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: i == 0 ? FontWeight.bold : FontWeight.w500,
                        color: _ink)),
              ),
            ],
          ),
      ],
    );
  }

  Widget _actions(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _launch(context, 'tel', 'the phone app'),
                icon: const Icon(Icons.call_rounded, size: 18, color: AppColors.primary),
                label: const Text('Call To Driver',
                    style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _openChat(context),
                icon: const Icon(Icons.chat_bubble_rounded, size: 18, color: Colors.white),
                label: const Text('Message',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _track(context),
            icon: const Icon(Icons.my_location_rounded, size: 18, color: Colors.white),
            label: const Text('Track Ride',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryDark,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        if (onViewDetails != null) ...[
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: onViewDetails,
              child: const Text('View ride details',
                  style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
            ),
          ),
        ],
      ],
    );
  }

}