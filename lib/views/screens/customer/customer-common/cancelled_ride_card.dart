import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../models/customer_booking_model.dart';

/// Cancelled ride card for My Bookings > Cancelled (Figma 88246766):
/// optional red "Auto-Cancelled" label, driver photo + details + rating,
/// cost per seat, origin ---- destination with date and time, and View Details.
/// Every value comes from the booking; anything missing is simply left out.
class CancelledRideCard extends StatelessWidget {
  final CustomerBookingItem booking;
  final VoidCallback? onViewDetails;

  const CancelledRideCard({super.key, required this.booking, this.onViewDetails});

  static const Color _ink = Color(0xFF1E1B1E);
  static const Color _grey = Color(0xFF757575);

  Map<String, dynamic> get _driver => booking.driverInfo ?? const {};
  Map<String, dynamic> get _raw => booking.rawJson;

  String _first(Map<String, dynamic> m, List<String> keys) {
    for (final k in keys) {
      final v = m[k]?.toString().trim() ?? '';
      if (v.isNotEmpty) return v;
    }
    return '';
  }

  bool get _isAuto {
    final status = (_raw['status'] ?? '').toString().toLowerCase();
    return status.contains('auto') || _raw['autoCancelled'] == true;
  }

  String get _driverName => _first(_driver, ['name', 'fullName']);
  String get _avatar => _first(_driver, ['avatar', 'photo', 'profileImage']);
  String get _rating => _first(_driver, ['rating']);

  String get _driverDetails {
    final car = _first(_driver, ['carModel', 'vehicleModel']);
    final trips = _first(_driver, ['tripsCount', 'trips']);
    final plate = _first(_driver, ['vehicleNumber', 'numberPlate']);
    return [
      if (car.isNotEmpty) car,
      if (trips.isNotEmpty && trips != '0') '$trips Trips',
      if (plate.isNotEmpty) plate,
    ].join(' , ');
  }

  String _place(String v) => v.split(',').first.trim();

  String get _origin => _place(booking.pickupLocation.isNotEmpty ? booking.pickupLocation : _first(_raw, ['pickup', 'from']));
  String get _destination =>
      _place(booking.destinationLocation.isNotEmpty ? booking.destinationLocation : _first(_raw, ['destination', 'to']));

  DateTime? _parse(String v) => v.isEmpty ? null : DateTime.tryParse(v)?.toLocal();

  static const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

  String _date(String raw) {
    final dt = _parse(raw);
    if (dt == null) return raw; // already a readable date, or empty
    return '${dt.day} ${_months[dt.month - 1]} . ${dt.year}';
  }

  String _time(String raw) {
    final dt = _parse(raw);
    if (dt == null) return raw;
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    return '${h.toString().padLeft(2, '0')} : $m ${dt.hour >= 12 ? 'PM' : 'AM'}';
  }

  String get _departDate => _date(_first(_raw, ['departureDate', 'date', 'scheduleDate', 'scheduledDate']));
  String get _departTime {
    final t = booking.departureTime.isNotEmpty ? booking.departureTime : _first(_raw, ['departureTime', 'time']);
    return _time(t);
  }

  String get _arriveDate => _date(_first(_raw, ['arrivalDate', 'arrivalDateFormatted', 'dropDate']));
  String get _arriveTime => _time(_first(_raw, ['arrivalTime', 'dropTime']));

  @override
  Widget build(BuildContext context) {
    final hasDriver = _driverName.isNotEmpty || _driverDetails.isNotEmpty || _avatar.isNotEmpty;
    final hasRoute = _origin.isNotEmpty || _destination.isNotEmpty;
    final hasPrice = booking.price.isNotEmpty && booking.price != '—';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE9E7EF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isAuto) ...[
            const Text(
              'Auto-Cancelled',
              style: TextStyle(color: Color(0xFFE53935), fontWeight: FontWeight.w500, fontSize: 16),
            ),
            const SizedBox(height: 12),
          ],
          if (hasDriver) _driverRow(hasPrice),
          if (!hasDriver && hasPrice)
            Text('Cost Per Seat  ${booking.price}',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _ink)),
          if (hasRoute) ...[
            const SizedBox(height: 18),
            _routeRow(),
          ],
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton(
              onPressed: onViewDetails,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text(
                'View Details',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.primary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _driverRow(bool hasPrice) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _avatarImage(),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_driverName.isNotEmpty)
                Text(_driverName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _ink)),
              if (_driverDetails.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(_driverDetails, style: const TextStyle(fontSize: 12, color: _grey)),
              ],
              if (_rating.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1EC),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_rounded, size: 15, color: Color(0xFFFF7A00)),
                      const SizedBox(width: 4),
                      Text(_rating, style: const TextStyle(fontSize: 13, color: _ink)),
                    ],
                  ),
                ),
              ],
              if (hasPrice) ...[
                const SizedBox(height: 8),
                Text('Cost Per Seat  ${booking.price}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _ink)),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _avatarImage() {
    Widget placeholder() => Container(
          width: 66,
          height: 80,
          color: const Color(0xFFEDE7F6),
          child: const Icon(Icons.person_rounded, size: 34, color: AppColors.primary),
        );
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: _avatar.startsWith('http')
          ? Image.network(_avatar, width: 66, height: 80, fit: BoxFit.cover, errorBuilder: (_, __, ___) => placeholder())
          : placeholder(),
    );
  }

  Widget _routeRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _routeEnd(_origin, _departDate, _departTime, CrossAxisAlignment.start),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 12, left: 8, right: 8),
            child: LayoutBuilder(
              builder: (context, c) {
                final dashes = (c.maxWidth / 8).floor().clamp(3, 14);
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(
                    dashes,
                    (_) => Container(width: 4, height: 1.2, color: const Color(0xFFBDBDBD)),
                  ),
                );
              },
            ),
          ),
        ),
        _routeEnd(_destination, _arriveDate, _arriveTime, CrossAxisAlignment.start),
      ],
    );
  }

  Widget _routeEnd(String place, String date, String time, CrossAxisAlignment align) {
    return Column(
      crossAxisAlignment: align,
      children: [
        if (place.isNotEmpty)
          Text(place, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: _grey)),
        if (date.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(date, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF3A3A3A))),
        ],
        if (time.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(time, style: const TextStyle(fontSize: 12, color: Color(0xFF3A3A3A))),
        ],
      ],
    );
  }
}