import 'package:flutter/material.dart';
import '../views/widgets/trip_share_card.dart';
import 'native_share_service.dart';

/// Builds and shares the purple "Trip Shared" card as an image. Used by every
/// screen that has a share button for a trip, so they all share the same card.
class TripCardShare {
  TripCardShare._();

  /// Placeholder ride id used by screens when none was passed; never a real ride.
  static const String _placeholderRideId = 'RIDE-20124568';

  /// Tracking link for a ride, or '' when there is no real ride id.
  static String urlFor(String? rideId) {
    final id = (rideId ?? '').trim();
    if (id.isEmpty || id == '--' || id == _placeholderRideId) return '';
    return 'https://zaatra.app/track/$id';
  }

  static String _shortPlace(dynamic v) => (v ?? '').toString().split(',').first.trim();

  /// Maps the loose timeline / seat maps the driver screens hold into card data.
  /// Anything unknown stays empty so the card leaves it out.
  static TripShareCardData buildData({
    required String driverName,
    String vehicleLine = '',
    String rating = '',
    List<Map<String, dynamic>> timeline = const [],
    List<Map<String, dynamic>> seats = const [],
    String estimatedArrival = '',
    required String statusLabel,
    required Color statusColor,
  }) {
    final stops = <TripShareStop>[];
    for (final item in timeline) {
      final name = _shortPlace(item['location'] ?? item['station']);
      if (name.isEmpty) continue;
      stops.add(TripShareStop(time: (item['time'] ?? '').toString(), name: name));
    }

    var eta = estimatedArrival.trim();
    if (eta.isEmpty && timeline.isNotEmpty) {
      eta = (timeline.last['timeRaw'] ?? timeline.last['time'] ?? '').toString().trim();
    }

    final seatList = <TripShareSeat>[];
    for (var i = 0; i < seats.length; i++) {
      final seat = seats[i];
      final n = int.tryParse((seat['seatNumber'] ?? '').toString().replaceAll(RegExp(r'[^0-9]'), '')) ?? (i + 1);
      seatList.add(TripShareSeat(number: n, isBooked: seat['isBooked'] == true));
    }

    return TripShareCardData(
      driverName: driverName == 'Driver' ? '' : driverName,
      vehicleLine: vehicleLine,
      rating: rating,
      stops: stops,
      estimatedArrival: eta,
      statusLabel: statusLabel,
      statusColor: statusColor,
      seats: seatList,
    );
  }

  /// Status text/colour shown on the card for a trip stage.
  static ({String label, Color color}) statusForStage(String stage) {
    switch (stage) {
      case 'during_ride':
        return (label: 'On The Way', color: const Color(0xFF1B7F2A));
      case 'summary':
        return (label: 'Completed', color: const Color(0xFF475569));
      default:
        return (label: 'Scheduled', color: const Color(0xFFB45309));
    }
  }

  static String buildText(TripShareCardData d, String url) {
    final first = d.stops.isNotEmpty ? d.stops.first.name : '';
    final last = d.stops.length > 1 ? d.stops.last.name : '';
    final route = (first.isNotEmpty && last.isNotEmpty) ? ' from $first to $last' : '';
    final by = d.driverName.isNotEmpty ? ' with ${d.driverName}' : '';
    final eta = d.estimatedArrival.isNotEmpty ? ' ETA: ${d.estimatedArrival}.' : '';
    final link = url.isNotEmpty ? ' Live link: $url' : '';
    return 'Track my Zaatra ride$route$by. Status: ${d.statusLabel}.$eta$link';
  }

  /// Renders [data] as the trip card off-screen and hands the PNG to the share
  /// sheet. Returns the same result map as [NativeShareService.captureAndShareWidget]
  /// (`success`, optional `isWeb`, `message`).
  static Future<Map<String, dynamic>> captureAndShare(
    BuildContext context, {
    required TripShareCardData data,
    required String text,
    String fallbackUrl = '',
  }) async {
    // Everything that needs the context happens before the first await.
    final overlay = Overlay.of(context);
    final precache = precacheImage(const AssetImage(TripShareCard.logoAsset), context);
    final key = GlobalKey();
    OverlayEntry? entry;
    try {
      try {
        await precache;
      } catch (_) {}

      entry = OverlayEntry(
        builder: (_) => Positioned(
          left: -5000,
          top: 0,
          child: RepaintBoundary(key: key, child: TripShareCard(data: data)),
        ),
      );
      overlay.insert(entry);
      await WidgetsBinding.instance.endOfFrame;
      await Future<void>.delayed(const Duration(milliseconds: 150));
      return await NativeShareService.captureAndShareWidget(
        key: key,
        text: text,
        fallbackShareUrl: fallbackUrl,
      );
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    } finally {
      entry?.remove();
    }
  }
}