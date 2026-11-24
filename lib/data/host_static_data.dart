// =============================================================================
// TEMPORARY - HOST MODULE STATIC DATA
// =============================================================================
// Everything the host screens would normally receive from the backend lives
// here, shaped exactly like the API responses.
//
// Screens must NOT import this file. They call HostApiService, which returns
// this data while `HostApiService.useStaticData` is true.
//
// When the APIs are integrated:
//   1. Set `HostApiService.useStaticData = false` (or delete the flag).
//   2. Delete this file.
//   3. `grep -rn "HostStaticData" lib` must then return nothing.
// =============================================================================

class HostStaticData {
  HostStaticData._();

  // ---------------------------------------------------------------------------
  // Dashboard (GET /hosts/dashboard)
  // ---------------------------------------------------------------------------
  static Map<String, dynamic> dashboard(String period) {
    return {
      'success': true,
      'message': 'Host dashboard data fetched successfully',
      'dashboard': {
        'host': {
          'hostId': 'H-101',
          'name': 'Manohar',
          'avatar': '/uploads/profiles/manohar.jpg',
          'greeting': 'Hello, Manohar 👋',
          'subGreeting': 'Good Morning !',
        },
        'kpis': {
          'totalEarnings': {
            'value': 124256,
            'formatted': '₹ 1,24,256',
            'growthBadge': '+12.9% This Month',
            'growthValue': 12.9,
          },
          'occupancy': {
            'percentage': 78,
            'formatted': '78%',
            'growthBadge': '+8% this month',
            'growthValue': 8.0,
          },
        },
        'recentUpdates': {
          'propertyCount': 6,
          'activeBookingsCount': 12,
          'upcomingBookingsCount': 5,
          'rating': 4.8,
          'reviewsCount': 24,
        },
        'revenueOverview': {
          'selectedPeriod': period == 'this_year'
              ? 'This Year'
              : (period == 'this_week' ? 'This Week' : 'This Month'),
          'chart': {
            'labels': ['1 May', '7 May', '14 May', '21 May', '31 May'],
            'data': [40000, 75000, 95000, 125000, 160000],
            'currency': '₹',
          },
        },
        'recentBookings': [
          {
            'bookingId': 'BK-1001',
            'type': 'stay',
            'title': 'See view Villa',
            'details': [
              'Check in /out : 15 Aug To 16 Aug',
              'Deluxe rooms : 2 rooms 4 adults , 4 children',
            ],
            'amount': 85200,
            'taxes': 4500,
            'currency': '₹',
            'status': 'Up Coming',
            'countdown': '7 Mins, 5 Sec',
          },
          {
            'bookingId': 'BK-1002',
            'type': 'event',
            'title': 'Convention Hall',
            'details': [
              'Event : Wedding , Date : 15 Sep 2026',
              'Time : 6:00AM-10:00AM',
              'Hall : Main 1, Guest 800, 2 AC Rooms',
            ],
            'amount': 85200,
            'taxes': 4500,
            'currency': '₹',
            'status': 'Up Coming',
          },
        ],
      },
    };
  }

  // ---------------------------------------------------------------------------
  // Listing wizard reference data (GET /hosts/properties/metadata)
  // ---------------------------------------------------------------------------
  static Map<String, dynamic> propertiesMetadata() {
    return {
      'categories': [
        {'id': 'hotel', 'name': 'Hotel'},
        {'id': 'villa', 'name': 'Villa'},
        {'id': 'flats', 'name': 'Flats'},
        {'id': 'room', 'name': 'Room'},
        {'id': 'apartments', 'name': 'Apartments'},
        {'id': 'farm_stay', 'name': 'Farm stay'},
        {'id': 'resort', 'name': 'Resort'},
        {'id': 'hall', 'name': 'Hall'},
        {'id': 'convention_center', 'name': 'Convention Center'},
        {'id': 'gardens_lawn', 'name': 'Gardens / Lawn'},
        {'id': 'function_hall', 'name': 'Function Hall'},
      ],
      'listingScopes': [
        {
          'key': 'SINGLE_UNIT',
          'title': 'One apartments / property with one or more rooms / venues for guests to book',
        },
        {
          'key': 'MULTIPLE_UNITS',
          'title': 'Multiple apartments / properties with one or more rooms / venues that guests book',
        },
      ],
      'starRatings': ['N/A', '1', '2', '3', '4', '5'],
      'facilities': [
        'Restaurant', 'Power Backup', 'Room Service', 'Lift', 'Wifi', 'Parking',
        'Bar', 'Security / CCTV', '24-hour front desk', 'Swimming Pool', 'Garden',
        'Decoration', 'Terrace', 'Airport Shuttle', 'AC', 'Laundry', 'Charging rooms',
        'Bonfire', 'Kitchen', 'BBQ', 'Sound System', 'DJ / Sounds', 'Stage', 'Catering',
        'Accommodation rooms',
      ],
      'provisionTypes': ['Included', 'Extra Charge', 'On Request'],
      'languages': [
        'Assamese', 'Bengali', 'Gujarati', 'Hindi', 'Kannada', 'Kashmiri',
        'Malayalam', 'Marathi', 'Malayali', 'Odia', 'Punjabi', 'Santali',
        'Tamil', 'Telugu', 'Urdu', 'English',
      ],
      'unitTypes': [
        'Single', 'Double', 'Twin', 'Twin / Double', 'Quadrapule', 'Suite',
        'Family', 'Studio', 'Apartment', 'Single room', 'Dormitry Room',
        'Bed in Dormitory', 'Flat',
      ],
    };
  }

  // ---------------------------------------------------------------------------
  // Host's property list (GET /hosts/properties)
  // ---------------------------------------------------------------------------
  static List<Map<String, dynamic>> properties() {
    return [
      {
        'propertyId': 'PROP-101',
        'title': 'The Blue Hotel & Suites',
        'type': 'Apartments',
        'city': 'Hyderabad',
        'price': 4500,
        'status': 'listed',
      },
      {
        'propertyId': 'PROP-102',
        'title': 'See View Villa',
        'type': 'Villa',
        'city': 'Goa',
        'price': 12000,
        'status': 'draft',
      },
    ];
  }

  // ---------------------------------------------------------------------------
  // Wizard responses
  // ---------------------------------------------------------------------------

  /// GET /hosts/properties/wizard/draft - no unfinished draft by default.
  static Map<String, dynamic> activeDraft() => {'success': true, 'hasDraft': false};

  /// POST /hosts/properties/wizard/step
  static Map<String, dynamic> wizardStep({required int step, String? propertyId}) {
    final id = (propertyId != null && propertyId.isNotEmpty) ? propertyId : 'PROP-1001';
    return {
      'success': true,
      'message': 'Step saved',
      'currentStep': step,
      'nextStep': step + 1,
      'property': {'propertyId': id, 'isDraft': true, 'status': 'draft'},
    };
  }

  /// POST /hosts/properties/metadata/facilities
  static Map<String, dynamic> customFacility({
    required String name,
    required String provisionType,
    required double extraCharge,
  }) {
    return {
      'success': true,
      'facility': {
        'name': name,
        'provisionType': provisionType,
        'extraCharge': extraCharge,
        'isCustom': true,
      },
    };
  }

  /// POST /hosts/properties/metadata/languages
  static Map<String, dynamic> customLanguage(String language) =>
      {'success': true, 'language': language};

  /// POST /hosts/properties/upload-photos
  static Map<String, dynamic> uploadedPhotos(int count) {
    final stamp = DateTime.now().millisecondsSinceEpoch;
    return {
      'success': true,
      'count': count,
      'photos': List.generate(count, (i) => '/uploads/properties/photos-${i + 1}.jpg'),
    };
  }

  /// POST /hosts/properties/publish
  static Map<String, dynamic> published({required String propertyId, required double price}) {
    return {
      'success': true,
      'message': 'Property published successfully',
      'property': {'propertyId': propertyId, 'status': 'listed', 'price': price},
    };
  }

  // ---------------------------------------------------------------------------
  // Bookings (in-memory store so status changes are visible while on static data)
  // ---------------------------------------------------------------------------

  /// The check-in / completion PIN accepted while running on static data.
  static const String testOtp = '1234';

  static int _idSeq = 2000;
  static int _txnSeq = 12456000;

  static final List<Map<String, dynamic>> _bookings = [
    _seed('BK-1001', '125487', 'stay', 'Sri meghana hotel', 'Deluxe room', 'active', 'Kumar',
        guests: 4, total: 25000, paid: 5000, otp1Done: false),
    _seed('BK-1002', '125488', 'event', 'Convection Hall', 'Main Hall 1', 'active', 'Suresh Reddy',
        guests: 3000, total: 145000, paid: 75000, eventType: 'Wedding', otp1Done: true),
    _seed('BK-1003', '125489', 'stay', 'Sri meghana hotel', 'Deluxe room', 'upcoming', 'Kumar',
        guests: 4, total: 25000, paid: 5000),
    _seed('BK-1004', '125490', 'event', 'Convection Hall', 'Main Hall 1', 'upcoming', 'Suresh Reddy',
        guests: 3000, total: 145000, paid: 45000, eventType: 'Wedding'),
    _seed('BK-1005', '125491', 'stay', 'Sri meghana hotel', 'Deluxe room', 'completed', 'Kumar',
        guests: 4, total: 25000, paid: 25000, otp1Done: true, otp2Done: true, reviewed: true),
    _seed('BK-1006', '125492', 'event', 'Convection Hall', 'Main Hall 1', 'completed', 'Suresh Reddy',
        guests: 3000, total: 145000, paid: 145000, eventType: 'Wedding', otp1Done: true, otp2Done: true),
    _seed('BK-1007', '125493', 'stay', 'Sri meghana hotel', 'Deluxe room', 'cancelled', 'Kumar',
        guests: 4, total: 25000, paid: 5000, cancelReason: 'Cancelled by customer'),
    _seed('BK-1008', '125494', 'event', 'Convection Hall', 'Main Hall 1', 'cancelled', 'Suresh Reddy',
        guests: 3000, total: 145000, paid: 45000, eventType: 'Wedding',
        cancelReason: 'No advance payment by customer'),
  ];

  static Map<String, dynamic> _seed(
    String id,
    String confirmId,
    String kind,
    String property,
    String unit,
    String status,
    String customer, {
    required int guests,
    required double total,
    required double paid,
    String eventType = '',
    bool otp1Done = false,
    bool otp2Done = false,
    bool reviewed = false,
    String cancelReason = '',
  }) {
    final isEvent = kind == 'event';
    return {
      'id': id,
      'confirmId': confirmId,
      'kind': kind,
      'propertyName': property,
      'unitName': unit,
      'source': 'Direct Booking',
      'status': status,
      'customerName': customer,
      'mobile': '+91 000-000-0000',
      'eventType': eventType,
      'guests': guests,
      'bookingDate': 'March 27 , 2026',
      'startText': isEvent ? '10th Oct 2026 , 10:00 AM' : 'March 22 , 11:00 AM',
      'endText': isEvent ? '11th Oct 2026 , 10:00 AM' : 'March 24 , 05:00 AM',
      'checkInLabel': isEvent ? 'March 24 Check in 05:00 AM' : 'March 22 Check in 11:00 AM',
      'total': total,
      'advance': paid,
      'advanceMethod': 'Cash',
      'paid': paid,
      'due': total - paid,
      'balanceDueOn': '11 Oct 2026 , 10:00PM',
      'otp1Done': otp1Done,
      'otp2Done': otp2Done,
      'reviewed': reviewed,
      'cancelReason': cancelReason,
      'reference': completedRef(id),
    };
  }

  static String completedRef(String id) => '4${id.replaceAll(RegExp(r'[^0-9]'), '')}'.substring(0, 4);

  static Map<String, dynamic>? _find(String id) {
    for (final b in _bookings) {
      if (b['id'] == id) return b;
    }
    return null;
  }

  static Map<String, dynamic> _notFound() => {'success': false, 'message': 'Booking not found'};

  /// GET /hosts/bookings?status=active|upcoming|completed|cancelled
  static Map<String, dynamic> bookings(String status) {
    final list = _bookings.where((b) => b['status'] == status).map((b) => Map<String, dynamic>.from(b)).toList();
    return {'success': true, 'count': list.length, 'bookings': list};
  }

  /// GET /hosts/bookings/:id
  static Map<String, dynamic> booking(String id) {
    final b = _find(id);
    return b == null ? _notFound() : {'success': true, 'booking': Map<String, dynamic>.from(b)};
  }

  /// POST /hosts/bookings/:id/payments  (kind: 'advance' | 'balance')
  static Map<String, dynamic> collectPayment({
    required String id,
    required String kind,
    required String method,
    required double amount,
  }) {
    final b = _find(id);
    if (b == null) return _notFound();
    final paid = ((b['paid'] as num?) ?? 0).toDouble() + amount;
    final total = ((b['total'] as num?) ?? 0).toDouble();
    b['paid'] = paid;
    b['due'] = (total - paid).clamp(0, double.infinity);
    if (kind == 'advance') {
      b['advance'] = ((b['advance'] as num?) ?? 0).toDouble() + amount;
      b['advanceMethod'] = method;
    }
    return {
      'success': true,
      'transactionId': '${_txnSeq++}',
      'booking': Map<String, dynamic>.from(b),
    };
  }

  /// POST /hosts/bookings/:id/otp  (otpNumber 1 = check-in, 2 = completion)
  static Map<String, dynamic> verifyOtp({
    required String id,
    required int otpNumber,
    required String otp,
  }) {
    final b = _find(id);
    if (b == null) return _notFound();
    if (otp != testOtp) return {'success': false, 'message': 'Wrong PIN'};
    if (otpNumber == 1) {
      b['otp1Done'] = true;
      b['status'] = 'active';
    } else {
      b['otp2Done'] = true;
      b['status'] = 'completed';
    }
    return {'success': true, 'booking': Map<String, dynamic>.from(b)};
  }

  /// POST /hosts/bookings/:id/review
  static Map<String, dynamic> submitReview({
    required String id,
    required Map<String, int> ratings,
    required String comment,
  }) {
    final b = _find(id);
    if (b == null) return _notFound();
    b['reviewed'] = true;
    b['status'] = 'completed';
    return {'success': true, 'booking': Map<String, dynamic>.from(b)};
  }

  /// POST /hosts/bookings/:id/cancel
  static Map<String, dynamic> cancelBooking({required String id, required String reason}) {
    final b = _find(id);
    if (b == null) return _notFound();
    b['status'] = 'cancelled';
    b['cancelReason'] = reason;
    return {'success': true, 'booking': Map<String, dynamic>.from(b)};
  }

  /// POST /hosts/bookings/offline
  static Map<String, dynamic> createOfflineBooking(Map<String, dynamic> data) {
    final id = 'BK-${_idSeq++}';
    final isEvent = data['kind'] == 'event';
    final total = ((data['total'] as num?) ?? 0).toDouble();
    final advance = ((data['advance'] as num?) ?? 0).toDouble();
    final b = {
      'id': id,
      'confirmId': '${_idSeq + 123000}',
      'kind': data['kind'] ?? 'stay',
      'propertyName': data['propertyName'] ?? (isEvent ? 'Convection Hall' : 'Sri meghana hotel'),
      'unitName': data['unitName'] ?? '',
      'source': 'Direct Booking',
      'status': 'upcoming',
      'customerName': data['customerName'] ?? '',
      'mobile': data['mobile'] ?? '',
      'eventType': data['eventType'] ?? '',
      'guests': data['guests'] ?? 0,
      'bookingDate': data['bookingDate'] ?? '',
      'startText': data['startText'] ?? '',
      'endText': data['endText'] ?? '',
      'checkInLabel': data['startText'] ?? '',
      'total': total,
      'advance': advance,
      'advanceMethod': data['advanceMethod'] ?? '',
      'paid': advance,
      'due': (total - advance).clamp(0, double.infinity),
      'balanceDueOn': '',
      'otp1Done': false,
      'otp2Done': false,
      'reviewed': false,
      'cancelReason': '',
      'reference': completedRef(id),
    };
    _bookings.insert(0, b);
    return {'success': true, 'booking': Map<String, dynamic>.from(b)};
  }

  // ---------------------------------------------------------------------------
  // Availability calendar and venue rates (in-memory)
  // ---------------------------------------------------------------------------

  static const List<String> halls = ['Main Hall 1', 'Main Hall 2'];

  static final Map<String, String> _slotTimes = {
    'slot1': '06:00 AM - 01:00 PM',
    'slot2': '04:00 PM - 11:00 PM',
  };

  /// hall -> 'YYYY-MM-DD' -> {'slot1': {...}, 'slot2': {...}}; missing = available.
  static final Map<String, Map<String, Map<String, Map<String, dynamic>>>> _availability = {
    'Main Hall 1': {
      '2026-04-15': {
        'slot1': {'state': 'blocked', 'reason': 'Maintenance'},
        'slot2': {'state': 'blocked', 'reason': 'Maintenance'},
      },
      '2026-04-17': {
        'slot1': {
          'state': 'zaatra',
          'booking': {
            'customer': 'Ravi Sharma',
            'event': 'Wedding, guest 800',
            'vegPlates': 500,
            'nonVegPlates': 300,
            'acRooms': 2,
            'deluxeRooms': 4,
            'total': 8500,
            'taxes': 4500,
          },
        },
        'slot2': {'state': 'offline'},
      },
      '2026-04-23': {
        'slot1': {'state': 'blocked', 'reason': 'Personal'},
      },
    },
    'Main Hall 2': {},
  };

  /// hall -> 'YYYY-MM-DD' -> {'slot1': rate, 'slot2': rate}; missing = base rate.
  static final Map<String, Map<String, Map<String, int>>> _rateOverrides = {
    'Main Hall 1': {},
    'Main Hall 2': {},
  };
  static final Map<String, Map<String, int>> _baseRates = {
    'Main Hall 1': {'slot1': 80000, 'slot2': 85000, 'stay': 4500},
    'Main Hall 2': {'slot1': 60000, 'slot2': 65000, 'stay': 4000},
  };

  static String _key(int y, int m, int d) =>
      "${m.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}";

  static Map<String, dynamic> _notFoundHall() => {'success': false, 'message': 'Hall not found'};

  /// GET /hosts/availability?hall=&year=&month=
  static Map<String, dynamic> availability({
    required String hall, // may be empty = first hall
    required int year,
    required int month,
  }) {
    // An empty hall means "the first hall" (the caller doesn't know the list yet).
    if (hall.isEmpty) hall = halls.first;
    final store = _availability[hall];
    if (store == null) return _notFoundHall();
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final days = <String, dynamic>{};
    var zaatraDays = 0, offlineDays = 0, blockedDays = 0, availableDays = 0;
    var zaatraSlots = 0, offlineSlots = 0, blockedSlots = 0, availableSlots = 0;
    for (var d = 1; d <= daysInMonth; d++) {
      final key = _key(year, month, d);
      final day = store[key] ?? const <String, Map<String, dynamic>>{};
      final slot1 = Map<String, dynamic>.from(day['slot1'] ?? {'state': 'available'});
      final slot2 = Map<String, dynamic>.from(day['slot2'] ?? {'state': 'available'});
      days[key] = {'slot1': slot1, 'slot2': slot2};
      final states = [slot1['state'], slot2['state']];
      for (final st in states) {
        switch (st) {
          case 'zaatra':
            zaatraSlots++;
            break;
          case 'offline':
            offlineSlots++;
            break;
          case 'blocked':
            blockedSlots++;
            break;
          default:
            availableSlots++;
        }
      }
      if (states.contains('zaatra')) {
        zaatraDays++;
      } else if (states.contains('offline')) {
        offlineDays++;
      } else if (states.every((st) => st == 'blocked')) {
        blockedDays++;
      } else {
        availableDays++;
      }
    }
    return {
      'success': true,
      'hall': hall,
      'halls': halls,
      'slotTimes': Map<String, String>.from(_slotTimes),
      'days': days,
      'summary': {
        'zaatra': {'days': zaatraDays, 'slots': zaatraSlots},
        'offline': {'days': offlineDays, 'slots': offlineSlots},
        'blocked': {'days': blockedDays, 'slots': blockedSlots},
        'available': {'days': availableDays, 'slots': availableSlots},
      },
    };
  }

  /// POST /hosts/availability/block   dates: ['YYYY-MM-DD'], slots: [1, 2]
  static Map<String, dynamic> blockDates({
    required String hall,
    required List<String> dates,
    required List<int> slots,
    required String reason,
  }) {
    final store = _availability[hall];
    if (store == null) return _notFoundHall();
    for (final date in dates) {
      final day = store.putIfAbsent(date, () => {});
      for (final slot in slots) {
        final existing = day['slot$slot'];
        // Booked slots cannot be blocked.
        if (existing != null && (existing['state'] == 'zaatra' || existing['state'] == 'offline')) {
          return {
            'success': false,
            'message': 'A booking exists on $date (slot $slot). Cancel it before blocking.',
          };
        }
      }
    }
    for (final date in dates) {
      final day = store[date]!;
      for (final slot in slots) {
        day['slot$slot'] = {'state': 'blocked', 'reason': reason};
      }
    }
    return {'success': true, 'blocked': dates.length};
  }

  /// POST /hosts/availability/unblock
  static Map<String, dynamic> unblockDates({
    required String hall,
    required List<String> dates,
    required List<int> slots,
  }) {
    final store = _availability[hall];
    if (store == null) return _notFoundHall();
    for (final date in dates) {
      final day = store[date];
      if (day == null) continue;
      for (final slot in slots) {
        if (day.containsKey('slot$slot')) {
          day['slot$slot'] = {'state': 'available'};
        }
      }
    }
    return {'success': true};
  }

  /// PUT /hosts/availability/timings
  static Map<String, dynamic> setSlotTimings({required String slot1, required String slot2}) {
    _slotTimes['slot1'] = slot1;
    _slotTimes['slot2'] = slot2;
    return {'success': true, 'slotTimes': Map<String, String>.from(_slotTimes)};
  }

  /// GET /hosts/rates?hall=&year=&month=
  static Map<String, dynamic> rates({
    required String hall,
    required int year,
    required int month,
  }) {
    if (hall.isEmpty) hall = halls.first;
    final base = _baseRates[hall];
    if (base == null) return _notFoundHall();
    final overrides = _rateOverrides[hall]!;
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final days = <String, dynamic>{};
    for (var d = 1; d <= daysInMonth; d++) {
      final key = _key(year, month, d);
      final o = overrides[key];
      days[key] = {
        'slot1': o?['slot1'] ?? base['slot1'],
        'slot2': o?['slot2'] ?? base['slot2'],
      };
    }
    return {
      'success': true,
      'hall': hall,
      'halls': halls,
      'stayRate': base['stay'],
      'days': days,
    };
  }

  /// PUT /hosts/rates   from/to: 'YYYY-MM-DD' (inclusive)
  static Map<String, dynamic> updateRates({
    required String hall,
    required String from,
    required String to,
    required int slot1,
    required int slot2,
    int? stayRate,
  }) {
    final overrides = _rateOverrides[hall];
    final base = _baseRates[hall];
    if (overrides == null || base == null) return _notFoundHall();
    final start = DateTime.tryParse(from);
    final end = DateTime.tryParse(to);
    if (start == null || end == null || end.isBefore(start)) {
      return {'success': false, 'message': 'Invalid date range'};
    }
    var count = 0;
    for (var d = start; !d.isAfter(end); d = d.add(const Duration(days: 1))) {
      overrides[_key(d.year, d.month, d.day)] = {'slot1': slot1, 'slot2': slot2};
      count++;
    }
    if (stayRate != null) base['stay'] = stayRate;
    return {'success': true, 'daysUpdated': count};
  }

  // ---------------------------------------------------------------------------
  // Messages and booking requests (in-memory)
  // ---------------------------------------------------------------------------
  //
  // conversation = {
  //   id, name, initials, type: 'request' | 'chat' | 'support', lastMessage, time, unread,
  //   request: null | {kind: 'stay'|'event', status: 'pending'|'accepted'|'declined'|'countered',
  //                    expiresInSeconds, details: {label: value, ...}, price, taxes},
  //   messages: [{from: 'customer'|'host'|'system', text, time}]
  // }

  static final List<Map<String, dynamic>> _conversations = [
    {
      'id': 'C-1',
      'name': 'Sri Lakshmi Hall',
      'initials': 'SL',
      'type': 'chat',
      'lastMessage': 'IN - 0089 - Vendor send Count offer',
      'time': '10:30 AM',
      'unread': 2,
      'request': null,
      'messages': [
        {'from': 'customer', 'text': 'Hello, is the hall free on 15 Sep?', 'time': '10:20 AM'},
        {'from': 'host', 'text': 'IN - 0089 - Vendor send Count offer', 'time': '10:30 AM'},
      ],
    },
    {
      'id': 'C-2',
      'name': 'Ravi Sharma',
      'initials': 'RS',
      'type': 'chat',
      'lastMessage': 'Is Catering Available',
      'time': '10:30 AM',
      'unread': 1,
      'request': null,
      'messages': [
        {'from': 'customer', 'text': 'Is Catering Available', 'time': '10:30 AM'},
      ],
    },
    {
      'id': 'C-3',
      'name': 'ZAATRA Support',
      'initials': 'ZA',
      'type': 'support',
      'lastMessage': 'Your booking ID 854 is confirmed',
      'time': '10:30 AM',
      'unread': 1,
      'request': null,
      'messages': [
        {'from': 'system', 'text': 'Your booking ID 854 is confirmed', 'time': '10:30 AM'},
      ],
    },
    {
      'id': 'R-1',
      'name': 'shiva',
      'initials': 'SH',
      'type': 'request',
      'lastMessage': 'Booking request: The Sriharsha Hotel',
      'time': '10:31 AM',
      'unread': 1,
      'request': {
        'kind': 'stay',
        'status': 'pending',
        'expiresInSeconds': 435, // 7:15
        'details': {
          'Property': 'The Sriharsha Hotel',
          'Check - in': 'Friday 17 Sep 2026',
          'Check - out': 'Friday 17 Sep 2026',
          'Deluxe Rooms': '4',
          'Adults': '0',
          'Children': '0',
        },
        'price': 5400,
        'taxes': 270,
      },
      'messages': [
        {'from': 'customer', 'text': 'Booking request', 'time': '10:31 AM'},
      ],
    },
    {
      'id': 'R-2',
      'name': 'shiva',
      'initials': 'SH',
      'type': 'request',
      'lastMessage': 'Booking request: Sri vandana convention hall',
      'time': '10:40 AM',
      'unread': 1,
      'request': {
        'kind': 'event',
        'status': 'pending',
        'expiresInSeconds': 315, // 5:15
        'details': {
          'Event': 'Wedding',
          'Date': '15 Sep 2026',
          'Time': '6:00 - 10:00',
          'Hall': 'main Hall 1',
          'Guest': '800',
          'Veg plate': '300',
          'Non veg plate': '500',
          'AC rooms': '2',
          'Deluxe rooms': '4',
        },
        'price': 8500,
        'taxes': 4500,
      },
      'messages': [
        {'from': 'customer', 'text': 'Booking request', 'time': '10:40 AM'},
      ],
    },
  ];

  static Map<String, dynamic>? _findConversation(String id) {
    for (final c in _conversations) {
      if (c['id'] == id) return c;
    }
    return null;
  }

  static Map<String, dynamic> _convNotFound() => {'success': false, 'message': 'Conversation not found'};

  static Map<String, dynamic> _copy(Map<String, dynamic> c) {
    return {
      ...c,
      'request': c['request'] == null
          ? null
          : {
              ...(c['request'] as Map<String, dynamic>),
              'details': Map<String, dynamic>.from((c['request'] as Map<String, dynamic>)['details']),
            },
      'messages': (c['messages'] as List).map((m) => Map<String, dynamic>.from(m as Map)).toList(),
    };
  }

  /// GET /hosts/messages?filter=all|requests
  static Map<String, dynamic> conversations(String filter) {
    final all = _conversations.map(_copy).toList();
    final requests = all.where((c) => c['type'] == 'request').toList();
    return {
      'success': true,
      'allCount': all.length,
      'requestsCount': requests.length,
      'conversations': filter == 'requests' ? requests : all,
    };
  }

  /// GET /hosts/messages/:id  (also marks it read)
  static Map<String, dynamic> conversation(String id) {
    final c = _findConversation(id);
    if (c == null) return _convNotFound();
    c['unread'] = 0;
    return {'success': true, 'conversation': _copy(c)};
  }

  static String _now() {
    final n = DateTime.now();
    final h = n.hour % 12 == 0 ? 12 : n.hour % 12;
    return "${n.minute.toString().padLeft(2, '0')} ${n.hour >= 12 ? 'PM' : 'AM'}";
  }

  /// POST /hosts/messages/:id
  static Map<String, dynamic> sendMessage({required String id, required String text}) {
    final c = _findConversation(id);
    if (c == null) return _convNotFound();
    final time = _now();
    (c['messages'] as List).add({'from': 'host', 'text': text, 'time': time});
    c['lastMessage'] = text;
    c['time'] = time;
    return {'success': true, 'conversation': _copy(c)};
  }

  /// POST /hosts/messages/:id/respond   action: 'accept' | 'decline'
  static Map<String, dynamic> respondToRequest({required String id, required String action}) {
    final c = _findConversation(id);
    if (c == null) return _convNotFound();
    final req = c['request'] as Map<String, dynamic>?;
    if (req == null) return {'success': false, 'message': 'This conversation has no booking request'};
    if (req['status'] != 'pending' && req['status'] != 'countered') {
      return {'success': false, 'message': 'This request was already answered'};
    }
    final time = _now();
    if (action == 'accept') {
      req['status'] = 'accepted';
      (c['messages'] as List).add({'from': 'system', 'text': 'Request accepted', 'time': time});
      // An accepted request becomes an upcoming booking.
      final details = Map<String, dynamic>.from(req['details'] as Map);
      final isEvent = req['kind'] == 'event';
      createOfflineBooking({
        'kind': req['kind'],
        'propertyName': details['Property'] ?? (isEvent ? 'Convection Hall' : 'Sri meghana hotel'),
        'unitName': details['Hall']?.toString() ?? (details['Deluxe Rooms'] != null ? 'Deluxe room' : ''),
        'customerName': c['name'],
        'eventType': details['Event'] ?? '',
        'guests': int.tryParse('${details['Guest'] ?? details['Adults'] ?? 0}') ?? 0,
        'startText': '${details['Date'] ?? details['Check - in'] ?? ''}',
        'endText': '${details['Check - out'] ?? ''}',
        'total': ((req['price'] as num?) ?? 0) + ((req['taxes'] as num?) ?? 0),
        'advance': 0,
      });
    } else {
      req['status'] = 'declined';
      (c['messages'] as List).add({'from': 'system', 'text': 'Request declined', 'time': time});
    }
    c['lastMessage'] = req['status'] == 'accepted' ? 'Request accepted' : 'Request declined';
    c['time'] = time;
    return {'success': true, 'conversation': _copy(c)};
  }

  /// POST /hosts/messages/:id/counter-offer   details: edited request fields
  static Map<String, dynamic> sendCounterOffer({
    required String id,
    required Map<String, dynamic> details,
    required num price,
    required num taxes,
  }) {
    final c = _findConversation(id);
    if (c == null) return _convNotFound();
    final req = c['request'] as Map<String, dynamic>?;
    if (req == null) return {'success': false, 'message': 'This conversation has no booking request'};
    if (req['status'] != 'pending' && req['status'] != 'countered') {
      return {'success': false, 'message': 'This request was already answered'};
    }
    req['status'] = 'countered';
    req['details'] = Map<String, dynamic>.from(details);
    req['price'] = price;
    req['taxes'] = taxes;
    final time = _now();
    (c['messages'] as List).add({'from': 'host', 'text': 'Counter offer sent', 'time': time});
    c['lastMessage'] = 'Counter offer sent';
    c['time'] = time;
    return {'success': true, 'conversation': _copy(c)};
  }

  // ---------------------------------------------------------------------------
  // Host profile and notification preferences (in-memory)
  // ---------------------------------------------------------------------------

  static final Map<String, dynamic> _profile = {
    'name': 'Manohar',
    'hostSince': 'May 2022',
    'phone': '+91 00000 00000',
    'email': 'manohar@example.com',
  };

  static final Map<String, bool> _notificationPrefs = {
    'newBookings': true,
    'bookingRequests': true,
    'messages': true,
    'paymentUpdates': true,
    'promotions': false,
  };

  /// GET /hosts/profile
  static Map<String, dynamic> profile() =>
      {'success': true, 'profile': Map<String, dynamic>.from(_profile)};

  /// PUT /hosts/profile
  static Map<String, dynamic> updateProfile({required String name, required String email}) {
    _profile['name'] = name;
    _profile['email'] = email;
    return {'success': true, 'profile': Map<String, dynamic>.from(_profile)};
  }

  /// GET /hosts/notification-preferences
  static Map<String, dynamic> notificationPrefs() =>
      {'success': true, 'preferences': Map<String, bool>.from(_notificationPrefs)};

  /// PUT /hosts/notification-preferences
  static Map<String, dynamic> setNotificationPrefs(Map<String, bool> prefs) {
    _notificationPrefs.addAll(prefs);
    return {'success': true, 'preferences': Map<String, bool>.from(_notificationPrefs)};
  }
}

