import 'package:flutter/material.dart';

/// One stop on the shared trip card.
class TripShareStop {
  final String time;
  final String name;
  const TripShareStop({required this.time, required this.name});
}

/// One seat tile on the shared trip card.
class TripShareSeat {
  final int number; // 1-based
  final bool isBooked;
  const TripShareSeat({required this.number, required this.isBooked});
}

/// Everything the shared "Trip Shared" card shows. Empty strings / empty lists
/// mean "unknown" and the matching line is simply left out (never invented).
class TripShareCardData {
  final String driverName;
  final String vehicleLine; // e.g. "White Swift Dzire · TS 09 AB 1234"
  final String rating; // e.g. "4.8"
  final List<TripShareStop> stops;
  final String estimatedArrival;
  final String statusLabel; // "On The Way", "Completed", ...
  final Color statusColor;
  final List<TripShareSeat> seats;

  const TripShareCardData({
    required this.driverName,
    this.vehicleLine = '',
    this.rating = '',
    this.stops = const [],
    this.estimatedArrival = '',
    required this.statusLabel,
    this.statusColor = const Color(0xFF1B7F2A),
    this.seats = const [],
  });
}

/// The purple "ticket" trip card (Figma node 31:19313) that is exported as a PNG
/// when the driver shares a trip. Fixed logical width so the image looks the same
/// on every device.
class TripShareCard extends StatelessWidget {
  static const double cardWidth = 340;
  static const String logoAsset = 'assets/images/zaatra_logo_badge.png';

  static const Color _purpleTop = Color(0xFF6103BC);
  static const Color _purpleBottom = Color(0xFF5A03B4);
  static const Color _lavender = Color(0xFFE9E2FE);
  static const Color _seatAvailable = Color(0xFFE6DEFD);
  static const Color _seatBooked = Color(0xFFBACAB8);
  static const Color _ink = Color(0xFF1E1B1E);
  static const Color _muted = Color(0xFF6B7280);
  static const double _notch = 9;
  static const Color _edge = Color(0xFFE4DDF4);

  final TripShareCardData data;

  const TripShareCard({super.key, required this.data});

  int get _availableSeats => data.seats.where((s) => !s.isBooked).length;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: DefaultTextStyle.merge(
        style: const TextStyle(color: _ink, decoration: TextDecoration.none),
        child: Container(
          width: cardWidth,
          color: Colors.white,
          padding: const EdgeInsets.all(14),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF3B0A8C).withValues(alpha: 0.18),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _topSection(),
                _bottomSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---- purple top ---------------------------------------------------------

  Widget _topSection() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 22),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [_purpleTop, _purpleBottom],
            ),
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _header(),
              if (data.stops.isNotEmpty) ...[
                const SizedBox(height: 16),
                _timeline(),
              ],
            ],
          ),
        ),
        // Ticket notches: half circles biting into both sides at the join.
        Positioned(left: 0, bottom: -_notch, child: _notchHalf(isLeft: true)),
        Positioned(right: 0, bottom: -_notch, child: _notchHalf(isLeft: false)),
      ],
    );
  }

  Widget _notchHalf({required bool isLeft}) {
    return SizedBox(
      width: _notch,
      height: _notch * 2,
      child: ClipRect(
        child: Align(
          alignment: isLeft ? Alignment.centerRight : Alignment.centerLeft,
          widthFactor: 0.5,
          child: Container(
            width: _notch * 2,
            height: _notch * 2,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: _edge, width: 1),
            ),
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 78,
          height: 66,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Image.asset(
            logoAsset,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(Icons.directions_car_rounded, color: _purpleTop, size: 32),
          ),
        ),
        const SizedBox(width: 10),
        Container(width: 1.2, height: 60, color: Colors.white.withValues(alpha: 0.55)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Zaatra Go',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              if (data.vehicleLine.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  data.vehicleLine,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.85)),
                ),
              ],
              if (data.driverName.isNotEmpty) ...[
                const SizedBox(height: 3),
                RichText(
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  text: TextSpan(
                    style: const TextStyle(fontSize: 12, color: Colors.white, decoration: TextDecoration.none),
                    children: [
                      const TextSpan(text: 'Driver : '),
                      TextSpan(text: data.driverName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
              if (data.rating.isNotEmpty) ...[
                const SizedBox(height: 3),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded, color: Color(0xFFFFC107), size: 15),
                    const SizedBox(width: 3),
                    Text(
                      data.rating,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _timeline() {
    final stops = data.stops;
    return Column(
      children: [
        for (var i = 0; i < stops.length; i++)
          _stopRow(stops[i], isFirst: i == 0, isLast: i == stops.length - 1),
      ],
    );
  }

  Widget _stopRow(TripShareStop stop, {required bool isFirst, required bool isLast}) {
    final emphasised = isFirst || isLast;
    const double slot = 22; // height of the marker slot, matches the text line
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 64,
            // Align first: the row stretches its children, which would otherwise
            // override the fixed slot height and push the time off the marker line.
            child: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                height: slot,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    stop.time,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: emphasised ? FontWeight.bold : FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            width: 24,
            child: Stack(
              children: [
                if (!(isFirst && isLast))
                  Positioned(
                    left: 11.2,
                    width: 1.6,
                    top: isFirst ? slot / 2 : 0,
                    bottom: isLast ? null : 0,
                    height: isLast ? slot / 2 : null,
                    child: Container(color: Colors.white.withValues(alpha: 0.8)),
                  ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: slot,
                  child: Center(child: _marker(isLast: isLast)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: slot),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    stop.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: emphasised ? 15 : 13.5,
                      fontWeight: emphasised ? FontWeight.bold : FontWeight.w500,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _marker({required bool isLast}) {
    if (isLast) {
      return Container(
        width: 20,
        height: 20,
        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
        child: const Icon(Icons.location_on_rounded, color: Color(0xFF2E9E3E), size: 15),
      );
    }
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFD9C8FF), width: 3),
      ),
    );
  }

  // ---- white bottom -------------------------------------------------------

  Widget _bottomSection() {
    final hasEta = data.estimatedArrival.isNotEmpty;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(22)),
        border: Border(
          left: BorderSide(color: _edge),
          right: BorderSide(color: _edge),
          bottom: BorderSide(color: _edge),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: _lavender,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFD9CFFA)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (hasEta) ...[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Estimated arrival', style: TextStyle(fontSize: 11, color: _muted)),
                        const SizedBox(height: 3),
                        Text(
                          data.estimatedArrival,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _ink),
                        ),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 38, color: const Color(0xFFBDB2E8)),
                  const SizedBox(width: 14),
                ],
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Trip Status', style: TextStyle(fontSize: 11, color: _muted)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Color.alphaBlend(data.statusColor.withValues(alpha: 0.2), Colors.white),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        data.statusLabel,
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: data.statusColor),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (data.seats.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text('Seats Available', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: _ink)),
            const SizedBox(height: 12),
            if (data.seats.length <= 4)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [for (final s in data.seats) _seatTile(s)],
              )
            else
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                runAlignment: WrapAlignment.center,
                spacing: 4,
                runSpacing: 10,
                children: [for (final s in data.seats) _seatTile(s)],
              ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                '$_availableSeats ${_availableSeats == 1 ? 'seat' : 'seats'} available out of ${data.seats.length}',
                style: const TextStyle(fontSize: 11, color: _muted),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _seatTile(TripShareSeat seat) {
    return SizedBox(
      width: 62,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: seat.isBooked ? _seatBooked : _seatAvailable,
              borderRadius: BorderRadius.circular(8),
            ),
            child: seat.isBooked
                ? null
                : const Icon(Icons.account_circle_outlined, color: Color(0xFF5B21B6), size: 26),
          ),
          const SizedBox(height: 6),
          Text(
            seat.isBooked ? 'Booked' : 'S-${seat.number} Available',
            textAlign: TextAlign.center,
            maxLines: 2,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: _ink),
          ),
        ],
      ),
    );
  }
}