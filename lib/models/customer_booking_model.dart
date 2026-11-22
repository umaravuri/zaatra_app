import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

/// Lifecycle state of a booking, derived once from the raw API `status`.
/// Denied / declined / rejected bookings are folded into [cancelled].
enum BookingState { upcoming, pending, active, completed, cancelled, unknown }

/// Classifies a raw backend status string using whole-word tokens, so that
/// e.g. "inactive", "not_started", "incomplete" or "delivered" are not
/// mistaken for active / started / complete / live.
BookingState classifyBookingStatus(String raw) {
  final tokens = raw
      .toLowerCase()
      .split(RegExp(r'[^a-z]+'))
      .where((t) => t.isNotEmpty)
      .toSet();
  bool has(List<String> words) => words.any(tokens.contains);

  if (has(['cancel', 'cancelled', 'canceled', 'denied', 'declined', 'decline', 'rejected', 'reject'])) {
    return BookingState.cancelled;
  }
  if (has(['completed', 'complete', 'finished', 'ended', 'done'])) {
    return BookingState.completed;
  }
  if (tokens.contains('not') || tokens.contains('yet')) {
    return BookingState.upcoming; // e.g. not_started
  }
  if (has(['active', 'ongoing', 'started', 'boarding', 'live']) ||
      (tokens.contains('in') && tokens.contains('progress')) ||
      tokens.contains('inprogress')) {
    return BookingState.active;
  }
  if (has(['pending', 'requested', 'awaiting', 'waiting', 'accepted', 'new'])) {
    return BookingState.pending;
  }
  if (has(['confirmed', 'conformed', 'confirm', 'scheduled', 'schedule', 'booked', 'upcoming'])) {
    return BookingState.upcoming;
  }
  return BookingState.unknown;
}

class CustomerBookingItem {
  final BookingState state;
  final String id;
  final String bookingId;
  final String category; // 'Stay' | 'Ride' | 'Heritage Sites' | 'Banquet Halls'
  final String type; // 'HOTEL STAY', 'RIDE BOOKING', 'HERITAGE TOUR', 'BANQUET VENUE'
  final String title;
  final String subtitle;
  final String price;
  final String status;
  final IconData icon;
  final Color statusColor;
  final DateTime? date;
  final bool isWholeCar;
  final String rideBookingCategory;
  final Map<String, dynamic>? statusBadge;
  final Map<String, dynamic> rawJson;
  final int seats;
  final String seatNumber;
  final List<String> seatNumbers;
  final String boardingPin;
  final Map<String, dynamic> driverPreferences;
  final Map<String, dynamic> customerPreferences;
  final List<Map<String, dynamic>> rideFeatures;
  final String tag;
  final String departureTime;
  final String pickupLocation;
  final String destinationLocation;
  final Map<String, dynamic>? driverInfo;

  /// Canonical id for every API call (pass, track, cancel, rate): the
  /// `:bookingId` the backend endpoints are documented with, falling back to `id`.
  String get refId => bookingId.isNotEmpty ? bookingId : id;

  CustomerBookingItem({
    this.state = BookingState.unknown,
    required this.id,
    required this.bookingId,
    required this.category,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.price,
    required this.status,
    required this.icon,
    required this.statusColor,
    this.date,
    this.isWholeCar = false,
    this.rideBookingCategory = '',
    this.statusBadge,
    this.rawJson = const {},
    this.seats = 1,
    this.seatNumber = '',
    this.seatNumbers = const [],
    this.boardingPin = '',
    this.driverPreferences = const {},
    this.customerPreferences = const {},
    this.rideFeatures = const [],
    this.tag = '',
    this.departureTime = '',
    this.pickupLocation = '',
    this.destinationLocation = '',
    this.driverInfo,
  });

  factory CustomerBookingItem.fromJson(Map<String, dynamic> json, {String? defaultCategory}) {
    final id = json['id']?.toString() ?? json['_id']?.toString() ?? json['bookingId']?.toString() ?? '';
    final bookingId = json['bookingId']?.toString() ?? json['bookingCode']?.toString() ?? id;

    // Detect category if not provided
    String detectedCategory = defaultCategory ?? 'Ride';
    final rawCategory = json['category']?.toString().toLowerCase() ??
        json['type']?.toString().toLowerCase() ??
        json['bookingType']?.toString().toLowerCase() ??
        '';

    if (rawCategory.contains('stay') || rawCategory.contains('hotel') || rawCategory.contains('room')) {
      detectedCategory = 'Stay';
    } else if (rawCategory.contains('ride') || rawCategory.contains('cab') || rawCategory.contains('car')) {
      detectedCategory = 'Ride';
    } else if (rawCategory.contains('heritage') || rawCategory.contains('tour') || rawCategory.contains('monument')) {
      detectedCategory = 'Heritage Sites';
    } else if (rawCategory.contains('banquet') || rawCategory.contains('hall') || rawCategory.contains('event')) {
      detectedCategory = 'Banquet Halls';
    }

    // Determine type label and icon
    String typeLabel = 'BOOKING';
    IconData iconData = Icons.event_note_rounded;

    switch (detectedCategory) {
      case 'Stay':
        typeLabel = json['stayType']?.toString() ?? 'HOTEL STAY';
        iconData = Icons.apartment_rounded;
        break;
      case 'Ride':
        typeLabel = 'RIDE BOOKING';
        iconData = Icons.directions_car_rounded;
        break;
      case 'Heritage Sites':
        typeLabel = 'HERITAGE TOUR';
        iconData = Icons.account_balance_rounded;
        break;
      case 'Banquet Halls':
        typeLabel = 'BANQUET VENUE';
        iconData = Icons.celebration_rounded;
        break;
    }

    // Title & Subtitle
    String title = json['title']?.toString() ?? '';
    if (title.isEmpty) {
      if (detectedCategory == 'Ride') {
        final pickup = (json['pickup'] ?? json['pickupLocation'] ?? json['from'] ?? '').toString();
        final drop = (json['destination'] ?? json['dropoffLocation'] ?? json['to'] ?? '').toString();
        title = (pickup.isNotEmpty && drop.isNotEmpty)
            ? '$pickup ➔ $drop'
            : (drop.isNotEmpty ? drop : (pickup.isNotEmpty ? pickup : 'Ride booking'));
      } else if (detectedCategory == 'Stay') {
        title = (json['hotelName'] ?? json['propertyName'] ?? 'Stay booking').toString();
      } else if (detectedCategory == 'Heritage Sites') {
        title = (json['placeName'] ?? json['monumentName'] ?? 'Heritage tour').toString();
      } else {
        title = (json['hallName'] ?? json['venueName'] ?? 'Banquet booking').toString();
      }
    }

    String subtitle = json['subtitle']?.toString() ?? '';
    if (subtitle.isEmpty) {
      if (detectedCategory == 'Ride') {
        final rawDateStr = json['date'] ?? json['scheduleDate'] ?? json['createdAt'] ?? 'Today';
        final formattedDate = _formatBookingDate(rawDateStr);
        final driverName = json['driverName'] ?? (json['driver'] is Map ? json['driver']['name'] : null);
        subtitle = driverName != null ? '$formattedDate • Driver: $driverName' : '$formattedDate • Confirmed Ride';
      } else if (detectedCategory == 'Stay') {
        final checkIn = json['checkIn'] ?? json['checkInDate'];
        final checkOut = json['checkOut'] ?? json['checkOutDate'];
        subtitle = (checkIn != null && checkOut != null) ? '$checkIn - $checkOut' : 'Stay booking';
      } else if (detectedCategory == 'Heritage Sites') {
        final timeStr = json['time'];
        subtitle = timeStr != null ? 'Tour Timing: $timeStr' : 'Heritage tour';
      } else {
        final guests = json['guests'] ?? json['capacity'];
        subtitle = guests != null ? 'Event Reservation • $guests guests' : 'Event Reservation';
      }
    } else if (subtitle.contains('T') && subtitle.contains('Z')) {
      final isoRegex = RegExp(r'\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d+)?Z?');
      subtitle = subtitle.replaceAllMapped(isoRegex, (m) => _formatBookingDate(m.group(0)));
    }

    // Price
    String priceStr = json['priceFormatted']?.toString() ??
        json['price']?.toString() ??
        json['fare']?.toString() ??
        json['totalAmount']?.toString() ??
        '';
    if (priceStr.isNotEmpty && !priceStr.startsWith('₹') && !priceStr.startsWith('\$')) {
      final pNum = double.tryParse(priceStr);
      if (pNum != null) {
        priceStr = '₹${pNum.toStringAsFixed(0)}';
      } else {
        priceStr = '₹$priceStr';
      }
    }
    if (priceStr.isEmpty) {
      priceStr = '—'; // never invent a price
    }

    // Status & Color
    // No invented default: a booking without a status is "unknown", not "Confirmed".
    final rawStatus = json['status']?.toString() ?? '';
    final badgeText = json['statusBadge'] is Map ? (json['statusBadge'] as Map)['text']?.toString() ?? '' : '';
    var bookingState = classifyBookingStatus(rawStatus);
    if (bookingState == BookingState.unknown && badgeText.isNotEmpty) {
      bookingState = classifyBookingStatus(badgeText);
    }
    final lowerRaw = rawStatus.toLowerCase();
    Color statusColor = AppColors.success;
    String displayStatus = rawStatus.isEmpty ? 'Status unavailable' : rawStatus;

    switch (bookingState) {
      case BookingState.cancelled:
        final denied = lowerRaw.contains('denied') || lowerRaw.contains('decline') || lowerRaw.contains('reject');
        displayStatus = denied ? 'Denied ⛔' : 'Cancelled ❌';
        statusColor = denied ? const Color(0xFFD32F2F) : Colors.red;
        break;
      case BookingState.completed:
        displayStatus = 'Completed';
        statusColor = const Color(0xFF64748B);
        break;
      case BookingState.active:
        displayStatus = 'Ride Active 🚗';
        statusColor = AppColors.primary;
        break;
      case BookingState.pending:
        displayStatus = 'Pending ⏳';
        statusColor = const Color(0xFFF57C00); // Orange per API specification
        break;
      case BookingState.upcoming:
        if (lowerRaw.contains('schedule')) {
          displayStatus = 'Scheduled ⏳';
          statusColor = const Color(0xFFF57C00);
        } else {
          displayStatus = 'Confirmed ✅';
          statusColor = AppColors.success;
        }
        break;
      case BookingState.unknown:
        statusColor = const Color(0xFF64748B);
        break;
    }

    // Status badge parsing per API 6
    Map<String, dynamic>? statusBadgeMap;
    if (json['statusBadge'] is Map) {
      statusBadgeMap = Map<String, dynamic>.from(json['statusBadge']);
      if (statusBadgeMap['text'] != null && statusBadgeMap['text'].toString().isNotEmpty) {
        displayStatus = statusBadgeMap['text'].toString();
      }
      final colorStr = statusBadgeMap['color']?.toString().toLowerCase() ?? '';
      if (colorStr == 'orange') {
        statusColor = const Color(0xFFF57C00);
      } else if (colorStr == 'green') {
        statusColor = AppColors.success;
      } else if (colorStr == 'red') {
        statusColor = const Color(0xFFD32F2F);
      } else if (colorStr == 'grey' || colorStr == 'gray') {
        statusColor = const Color(0xFF64748B);
      } else if (colorStr == 'blue') {
        statusColor = const Color(0xFF1976D2);
      }
    }

    final isWholeCar = json['isWholeCar'] == true;
    final rideCat = json['rideBookingCategory']?.toString() ?? '';

    // Parse seats, pin, preferences, tag & features per new API
    final rawSeats = json['seats'];
    final seatsList = json['seatNumbers'] is List ? (json['seatNumbers'] as List).map((e) => e.toString()).toList() : <String>[];
    final int seatsCount = rawSeats is num
        ? rawSeats.toInt()
        : (int.tryParse(rawSeats?.toString() ?? '') ?? (seatsList.isNotEmpty ? seatsList.length : 1));
    final String seatNum = json['seatNumber']?.toString() ?? (seatsList.isNotEmpty ? seatsList.join(', ') : '');
    final String pin = json['boardingPin']?.toString() ?? '';
    final String bookingTag = json['tag']?.toString() ?? typeLabel;
    final String depTime = json['departureTime']?.toString() ?? json['timeWindow']?.toString() ?? '';
    final String pLoc = json['pickup']?.toString() ?? json['pickupLocation']?.toString() ?? '';
    final String dLoc = json['destination']?.toString() ?? json['destinationLocation']?.toString() ?? '';
    final Map<String, dynamic>? dInfo = json['driver'] is Map ? Map<String, dynamic>.from(json['driver'] as Map) : null;

    final Map<String, dynamic> dPrefs = json['driverPreferences'] is Map
        ? Map<String, dynamic>.from(json['driverPreferences'] as Map)
        : <String, dynamic>{};
    final Map<String, dynamic> cPrefs = json['customerPreferences'] is Map
        ? Map<String, dynamic>.from(json['customerPreferences'] as Map)
        : <String, dynamic>{};

    final List<Map<String, dynamic>> rFeatures = [];
    if (json['rideFeatures'] is List) {
      for (final f in json['rideFeatures'] as List) {
        if (f is Map) {
          rFeatures.add(Map<String, dynamic>.from(f));
        }
      }
    }

    return CustomerBookingItem(
      state: bookingState,
      id: id,
      bookingId: bookingId,
      category: detectedCategory,
      type: typeLabel,
      title: title,
      subtitle: subtitle,
      price: priceStr,
      status: displayStatus,
      icon: iconData,
      statusColor: statusColor,
      isWholeCar: isWholeCar,
      rideBookingCategory: rideCat,
      statusBadge: statusBadgeMap,
      rawJson: json,
      seats: seatsCount,
      seatNumber: seatNum,
      seatNumbers: seatsList,
      boardingPin: pin,
      driverPreferences: dPrefs,
      customerPreferences: cPrefs,
      rideFeatures: rFeatures,
      tag: bookingTag,
      departureTime: depTime,
      pickupLocation: pLoc,
      destinationLocation: dLoc,
      driverInfo: dInfo,
    );
  }

  static String _formatBookingDate(dynamic raw) {
    if (raw == null) return 'Today';
    final str = raw.toString().trim();
    if (str.isEmpty || str.toLowerCase() == 'today') return 'Today';
    try {
      final dt = DateTime.tryParse(str);
      if (dt != null) {
        final local = dt.toLocal();
        const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        final month = months[local.month - 1];
        final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
        final minute = local.minute.toString().padLeft(2, '0');
        final ampm = local.hour >= 12 ? 'PM' : 'AM';
        return '${local.day} $month ${local.year}, $hour:$minute $ampm';
      }
    } catch (_) {}
    return str;
  }
}