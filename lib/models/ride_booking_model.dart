import 'place_location_model.dart';

num? getNum(dynamic v) => (v is num) ? v : num.tryParse(v?.toString() ?? '');

class RidePreferences {
  final bool autoApproval;
  final String autoApprovalBadge;
  final bool ac;
  final bool smokingAllowed;
  final bool wifi;
  final bool usbCharging;
  final int luggageCount;
  final int mediumBagCount;
  final String luggageSummaryText;
  final List<String> driverPreferences;
  final List<String> customerPreferences;
  final List<String> rideFeatures;
  final List<String> featuresList;

  const RidePreferences({
    this.autoApproval = false,
    this.autoApprovalBadge = '',
    this.ac = false,
    this.smokingAllowed = false,
    this.wifi = false,
    this.usbCharging = false,
    this.luggageCount = 1,
    this.mediumBagCount = 1,
    this.luggageSummaryText = '',
    this.driverPreferences = const [],
    this.customerPreferences = const [],
    this.rideFeatures = const [],
    this.featuresList = const [],
  });

  factory RidePreferences.fromJson(dynamic json, {dynamic rootJson}) {
    if (json == null && rootJson is! Map<String, dynamic>) {
      return const RidePreferences();
    }
    final p = json is Map<String, dynamic> ? json : (json is Map ? Map<String, dynamic>.from(json) : <String, dynamic>{});
    final root = rootJson is Map<String, dynamic> ? rootJson : (rootJson is Map ? Map<String, dynamic>.from(rootJson) : <String, dynamic>{});

    final dp = (root['driverPreferences'] is Map ? root['driverPreferences'] as Map : null) ??
        (p['driverPreferences'] is Map ? p['driverPreferences'] as Map : null) ??
        (root['preferences'] is Map ? root['preferences'] as Map : null) ??
        (p['preferences'] is Map ? p['preferences'] as Map : null);

    bool isTruthy(dynamic v) {
      if (v == null) return false;
      if (v is bool) return v;
      if (v is num) return v == 1;
      final s = v.toString().toLowerCase().trim();
      return s == 'true' || s == '1' || s == 'yes';
    }

    // Also check if driverPreferences.items has autoApproval checked/enabled
    bool hasAutoItemInList = false;
    if (dp != null && dp['items'] is List) {
      for (final it in dp['items']) {
        if (it is Map && (it['key'] == 'autoApproval' || it['id'] == 'dp-auto-approval')) {
          if (isTruthy(it['checked']) || isTruthy(it['enabled']) || isTruthy(it['value'])) {
            hasAutoItemInList = true;
            break;
          }
        }
      }
    }

    final autoBadgeCandidate = (root['autoApprovalBadge'] ?? p['autoApprovalBadge'] ?? dp?['autoApprovalBadge'])?.toString().toLowerCase() ?? '';
    final hasAutoBadge = autoBadgeCandidate.contains('auto') || autoBadgeCandidate.contains('instant');

    final auto = isTruthy(p['autoApproval']) ||
        isTruthy(root['autoApproval']) ||
        isTruthy(dp?['autoApproval']) ||
        isTruthy(root['autoApprovalOfPassenger']) ||
        isTruthy(p['autoApprovalOfPassenger']) ||
        isTruthy(root['instantBooking']) ||
        isTruthy(p['instantBooking']) ||
        hasAutoItemInList ||
        hasAutoBadge;

    final autoBadge = (root['autoApprovalBadge'] ?? p['autoApprovalBadge'] ?? dp?['autoApprovalBadge'])?.toString() ??
        (auto ? 'Instant Booking (Auto Approval)' : 'Manual Confirmation Required');

    final rf = (root['rideFeatures'] is Map ? root['rideFeatures'] as Map : null) ??
        (p['rideFeatures'] is Map ? p['rideFeatures'] as Map : null);
    final cpMap = (root['customerPreferences'] is Map ? root['customerPreferences'] as Map : null) ??
        (p['customerPreferences'] is Map ? p['customerPreferences'] as Map : null);

    final ac = isTruthy(p['ac']) ||
        isTruthy(p['airConditioning']) ||
        isTruthy(root['ac']) ||
        isTruthy(root['airConditioning']) ||
        isTruthy(rf?['ac']) ||
        isTruthy(rf?['airConditioning']);
    final smoking = isTruthy(p['smokingAllowed']) ||
        isTruthy(p['smoking']) ||
        isTruthy(root['smokingAllowed']) ||
        isTruthy(root['smoking']) ||
        isTruthy(cpMap?['smokingAllowed']) ||
        isTruthy(cpMap?['smoking']);

    final wifi = isTruthy(p['wifi']) || isTruthy(root['wifi']) || isTruthy(rf?['wifi']);
    final usb = isTruthy(p['usbCharging']) || isTruthy(root['usbCharging']) || isTruthy(rf?['usbCharging']);

    // Check luggage object if returned by projection (API 5)
    final luggageObj = root['luggage'] is Map
        ? root['luggage'] as Map
        : (p['luggage'] is Map ? p['luggage'] as Map : null);

    final luggage = (luggageObj != null && luggageObj['maxLuggagePerPassenger'] is num)
        ? (luggageObj['maxLuggagePerPassenger'] as num).toInt()
        : ((p['luggageCount'] is num)
            ? (p['luggageCount'] as num).toInt()
            : (int.tryParse(p['luggageCount']?.toString() ?? '') ??
                (root['maxLuggagePerPassenger'] is num ? (root['maxLuggagePerPassenger'] as num).toInt() : 1)));

    final mediumBag = (luggageObj != null && luggageObj['mediumBag'] is num)
        ? (luggageObj['mediumBag'] as num).toInt()
        : ((p['mediumBagCount'] is num)
            ? (p['mediumBagCount'] as num).toInt()
            : (int.tryParse(p['mediumBagCount']?.toString() ?? '') ?? 1));

    final summaryText = luggageObj != null && luggageObj['summaryText'] != null
        ? luggageObj['summaryText'].toString()
        : (p['summaryText']?.toString() ?? root['summaryText']?.toString() ?? '');

    void addUnique(List<String> list, dynamic val) {
      if (val == null) return;
      String str;
      if (val is Map) {
        final extracted = val['label'] ?? val['name'] ?? val['title'] ?? val['key'];
        if (extracted == null) return;
        str = extracted.toString().trim();
      } else {
        str = val.toString().trim();
      }

      // Handle cases where a stringified map or json was passed e.g. "{id: ..., label: AC, ...}"
      if (str.startsWith('{')) {
        if (str.contains('label:')) {
          final match = RegExp(r'label:\s*([^,}]+)').firstMatch(str);
          if (match != null && match.group(1) != null) {
            str = match.group(1)!.trim();
          }
        } else if (str.contains('"label":')) {
          final match = RegExp(r'"label":\s*"([^"]+)"').firstMatch(str);
          if (match != null && match.group(1) != null) {
            str = match.group(1)!.trim();
          }
        }
      }

      if (str.isEmpty || str.startsWith('{')) return;
      if (!list.any((existing) => existing.toLowerCase() == str.toLowerCase())) {
        list.add(str);
      }
    }

    final dPrefs = <String>[];
    if (p['driverPreferences'] is List) {
      for (final dp in p['driverPreferences'] as List) {
        addUnique(dPrefs, dp);
      }
    }
    if (root['driverPreferences'] is List) {
      for (final dp in root['driverPreferences'] as List) {
        addUnique(dPrefs, dp);
      }
    }
    if (dp != null && dp['items'] is List) {
      for (final it in dp['items']) {
        if (it is Map && (isTruthy(it['checked']) || isTruthy(it['enabled']) || isTruthy(it['value']))) {
          addUnique(dPrefs, it['label'] ?? it['title'] ?? it['name']);
        }
      }
    }
    if (root['customPreferences'] is List) {
      for (final cp in root['customPreferences']) {
        addUnique(dPrefs, cp);
      }
    }
    if (p['customPreferences'] is List) {
      for (final cp in p['customPreferences']) {
        addUnique(dPrefs, cp);
      }
    }
    if (root['driverRules'] is List) {
      for (final dr in root['driverRules']) {
        addUnique(dPrefs, dr);
      }
    }

    final cPrefs = <String>[];
    if (smoking) {
      addUnique(cPrefs, 'Smoking allowed');
    } else {
      addUnique(cPrefs, 'No smoking');
    }
    if (p['customerPreferences'] is List) {
      for (final cp in p['customerPreferences'] as List) {
        addUnique(cPrefs, cp);
      }
    }
    if (root['customerPreferences'] is List) {
      for (final cp in root['customerPreferences'] as List) {
        addUnique(cPrefs, cp);
      }
    }
    if (cpMap != null && cpMap['items'] is List) {
      for (final it in cpMap['items']) {
        if (it is Map && (isTruthy(it['checked']) || isTruthy(it['enabled']) || (it['count'] is num && (it['count'] as num) > 0))) {
          final label = it['label'] ?? it['title'] ?? it['name'];
          if (label != null) {
            final count = it['count'];
            final displayLabel = (count is num && count > 1) ? '$count $label' : label.toString();
            addUnique(cPrefs, displayLabel);
          }
        }
      }
    }
    if (root['customCustomerPrefs'] is List) {
      for (final ccp in root['customCustomerPrefs']) {
        addUnique(cPrefs, ccp);
      }
    }

    final features = <String>[];
    if (ac) addUnique(features, 'AC');
    if (usb) addUnique(features, 'USB Charging');
    if (wifi) addUnique(features, 'Free WiFi');

    if (p['rideFeatures'] is List) {
      for (final f in p['rideFeatures'] as List) {
        addUnique(features, f);
      }
    }
    if (root['rideFeatures'] is List) {
      for (final f in root['rideFeatures'] as List) {
        addUnique(features, f);
      }
    }
    if (rf != null && rf['items'] is List) {
      for (final it in rf['items']) {
        if (it is Map && (isTruthy(it['checked']) || isTruthy(it['enabled']) || isTruthy(it['value']))) {
          addUnique(features, it['label'] ?? it['title'] ?? it['name']);
        }
      }
    }
    if (p['customFeatures'] is List) {
      for (final cf in p['customFeatures'] as List) {
        addUnique(features, cf);
      }
    }
    if (root['customFeatures'] is List) {
      for (final cf in root['customFeatures'] as List) {
        addUnique(features, cf);
      }
    }
    if (root['amenities'] is List) {
      for (final am in root['amenities'] as List) {
        addUnique(features, am);
      }
    }
    if (p['amenities'] is List) {
      for (final am in p['amenities'] as List) {
        addUnique(features, am);
      }
    }
    if (root['customPreferences'] is List) {
      for (final cp in root['customPreferences'] as List) {
        addUnique(features, cp);
      }
    }
    if (p['customPreferences'] is List) {
      for (final cp in p['customPreferences'] as List) {
        addUnique(features, cp);
      }
    }
    if (root['features'] is List) {
      for (final f in root['features'] as List) {
        addUnique(features, f);
      }
    }
    if (p['features'] is List) {
      for (final f in p['features'] as List) {
        addUnique(features, f);
      }
    }

    // Direct projection: featuresList (API 5)
    final projectionFeatures = <String>[];
    final rawFeaturesList = root['featuresList'] ?? p['featuresList'];
    if (rawFeaturesList is List) {
      for (final f in rawFeaturesList) {
        addUnique(projectionFeatures, f);
      }
    }
    for (final f in features) {
      addUnique(projectionFeatures, f);
    }

    return RidePreferences(
      autoApproval: auto,
      autoApprovalBadge: autoBadge,
      ac: ac,
      smokingAllowed: smoking,
      wifi: wifi,
      usbCharging: usb,
      luggageCount: luggage > 0 ? luggage : 1,
      mediumBagCount: mediumBag > 0 ? mediumBag : 1,
      luggageSummaryText: summaryText.isNotEmpty ? summaryText : '$luggage Standard Luggage · $mediumBag Medium Bag',
      driverPreferences: dPrefs,
      customerPreferences: cPrefs,
      rideFeatures: features,
      featuresList: projectionFeatures.isNotEmpty ? projectionFeatures : features,
    );
  }

  RidePreferences copyWith({
    bool? autoApproval,
    String? autoApprovalBadge,
    bool? ac,
    bool? smokingAllowed,
    bool? wifi,
    bool? usbCharging,
    int? luggageCount,
    int? mediumBagCount,
    String? luggageSummaryText,
    List<String> driverPreferences = const [],
    List<String> customerPreferences = const [],
    List<String> rideFeatures = const [],
    List<String> featuresList = const [],
  }) {
    return RidePreferences(
      autoApproval: autoApproval ?? this.autoApproval,
      autoApprovalBadge: autoApprovalBadge ?? this.autoApprovalBadge,
      ac: ac ?? this.ac,
      smokingAllowed: smokingAllowed ?? this.smokingAllowed,
      wifi: wifi ?? this.wifi,
      usbCharging: usbCharging ?? this.usbCharging,
      luggageCount: luggageCount ?? this.luggageCount,
      mediumBagCount: mediumBagCount ?? this.mediumBagCount,
      luggageSummaryText: luggageSummaryText ?? this.luggageSummaryText,
      driverPreferences: driverPreferences.isNotEmpty ? driverPreferences : this.driverPreferences,
      customerPreferences: customerPreferences.isNotEmpty ? customerPreferences : this.customerPreferences,
      rideFeatures: rideFeatures.isNotEmpty ? rideFeatures : this.rideFeatures,
      featuresList: featuresList.isNotEmpty ? featuresList : this.featuresList,
    );
  }
}

class RideDriver {
  final String id;
  final String name;
  final double rating;
  final String ratingText;
  final int reviewCount;
  final int tripsCount;
  final double pricePerSeat;
  final String carModel;
  final String vehicleNumber;
  final int seatsAvailable;
  final String departureTime;
  final String pickupPoint;
  final String destinationPoint;
  final List<String> amenities;
  final String avatarImage;
  final String phone;
  final String about;
  final String tripsText;
  final String driverSummary;
  final bool isOnline;
  final RidePreferences preferences;
  final bool isDoorstepAllowed;
  final double maxDetourRadiusKm;
  final double detourRatePerKm;
  final double doorstepBaseFee;
  final int totalSeats;
  final String rideType;
  final double wholeCarPrice;
  final String costPerSeatText;
  final List<String> viaLocations;
  final bool isWholeCarOnly;
  final String rideTypeBadge;
  final String bookingModeBadge;
  final String pricingType;
  final double totalPrice;
  final bool isVerifiedByAdmin;
  final int ratingCount;
  final String ratingBadge;

  const RideDriver({
    this.id = '',
    this.name = '',
    this.rating = 0.0,
    this.ratingText = '',
    this.reviewCount = 0,
    this.ratingCount = 126,
    this.ratingBadge = '★ 4.8 (126)',
    this.tripsCount = 0,
    this.pricePerSeat = 0.0,
    this.carModel = '',
    this.vehicleNumber = '',
    this.seatsAvailable = 0,
    this.totalSeats = 4,
    this.rideType = 'shared_ride',
    this.wholeCarPrice = 0.0,
    this.costPerSeatText = '',
    this.viaLocations = const [],
    this.isWholeCarOnly = false,
    this.rideTypeBadge = '',
    this.bookingModeBadge = '',
    this.pricingType = 'per_seat',
    this.totalPrice = 0.0,
    this.isVerifiedByAdmin = false,
    this.departureTime = '',
    this.pickupPoint = '',
    this.destinationPoint = '',
    this.amenities = const [],
    this.avatarImage = '',
    this.phone = '',
    this.about = '',
    this.tripsText = '',
    this.driverSummary = '',
    this.isOnline = true,
    this.preferences = const RidePreferences(),
    this.isDoorstepAllowed = false,
    this.maxDetourRadiusKm = 5.0,
    this.detourRatePerKm = 15.0,
    this.doorstepBaseFee = 0.0,
  });

  factory RideDriver.fromJson(Map<String, dynamic> json, {String? defaultCar, String? defaultPlate, double? defaultPrice, Map<String, dynamic>? rootJson}) {
    final driverMap = json['driver'] is Map<String, dynamic> ? json['driver'] as Map<String, dynamic> : (json['driver'] is Map ? Map<String, dynamic>.from(json['driver'] as Map) : null);
    final vehicleMap = json['vehicle'] is Map<String, dynamic> ? json['vehicle'] as Map<String, dynamic> : (json['vehicle'] is Map ? Map<String, dynamic>.from(json['vehicle'] as Map) : null);
    final pricingMap = json['pricing'] is Map<String, dynamic> ? json['pricing'] as Map<String, dynamic> : (json['pricing'] is Map ? Map<String, dynamic>.from(json['pricing'] as Map) : null);
    final tripMap = json['trip'] is Map<String, dynamic> ? json['trip'] as Map<String, dynamic> : (json['trip'] is Map ? Map<String, dynamic>.from(json['trip'] as Map) : null);

    final ratingVal = json['rating'] ?? json['ratings'] ?? driverMap?['rating'] ?? driverMap?['ratings'];
    final ratingNum = ratingVal is num ? ratingVal.toDouble() : (double.tryParse(ratingVal?.toString() ?? '') ?? 0.0);
    final ratingTxt = json['ratingText']?.toString() ?? driverMap?['ratingText']?.toString() ?? (ratingNum > 0 ? '★ ${ratingNum.toStringAsFixed(1)}' : '');

    final ratingCountVal = json['ratingCount'] ?? driverMap?['ratingCount'] ?? json['totalReviews'] ?? driverMap?['totalReviews'] ?? 126;
    final ratingCountNum = ratingCountVal is num ? ratingCountVal.toInt() : (int.tryParse(ratingCountVal?.toString() ?? '') ?? 126);
    final ratingBadge = json['ratingBadge']?.toString() ?? driverMap?['ratingBadge']?.toString() ?? (ratingNum > 0 ? '★ ${ratingNum.toStringAsFixed(1)} ($ratingCountNum)' : '★ 4.8 (126)');

    final tripsVal = json['trips'] ?? json['tripsCount'] ?? json['driverTrips'] ?? json['reviewCount'] ?? json['totalReviews'] ?? driverMap?['trips'] ?? driverMap?['tripsCount'] ?? driverMap?['reviewCount'];
    final tripsNum = tripsVal is num ? tripsVal.toInt() : (int.tryParse(tripsVal?.toString() ?? '') ?? 0);
    final tripsTxt = json['tripsText']?.toString() ?? driverMap?['tripsText']?.toString() ?? (tripsNum > 0 ? '🚗 $tripsNum trips' : '');

    final avatar = json['avatar']?.toString() ??
        json['avatarImage']?.toString() ??
        json['photo']?.toString() ??
        json['driverPhoto']?.toString() ??
        json['profilePicture']?.toString() ??
        driverMap?['avatar']?.toString() ??
        driverMap?['avatarImage']?.toString() ??
        driverMap?['photo']?.toString() ??
        driverMap?['driverPhoto']?.toString() ??
        '';

    final name = json['name']?.toString() ?? json['driverName']?.toString() ?? driverMap?['name']?.toString() ?? driverMap?['driverName']?.toString() ?? '';
    final car = json['carModel']?.toString() ??
        json['vehicleModel']?.toString() ??
        vehicleMap?['model']?.toString() ??
        vehicleMap?['name']?.toString() ??
        defaultCar ?? '';
    final plate = json['vehicleNumber']?.toString() ??
        json['numberPlate']?.toString() ??
        vehicleMap?['numberPlate']?.toString() ??
        defaultPlate ?? '';

    final summary = json['driverSummary']?.toString() ??
        driverMap?['driverSummary']?.toString() ??
        (name.isNotEmpty ? '$name , $tripsNum trips , $plate'.replaceAll(RegExp(r'\s*,\s*,'), ',').trim() : '');

    final rawPrice = json['pricePerSeat'] ?? pricingMap?['pricePerSeat'] ?? json['price'] ?? pricingMap?['price'] ?? defaultPrice;
    final price = rawPrice is num ? rawPrice.toDouble() : (double.tryParse(rawPrice?.toString() ?? '') ?? 0.0);

    final rawSeats = json['seatsAvailable'] ?? json['availableSeats'] ?? (json['seats'] is Map ? json['seats']['available'] : null) ?? json['totalSeats'] ?? 0;
    final seats = rawSeats is num ? rawSeats.toInt() : (int.tryParse(rawSeats.toString()) ?? 0);

    final prefsSource = json['preferences'] ??
        driverMap?['preferences'] ??
        json['driverPreferences'] ??
        rootJson?['driverPreferences'] ??
        rootJson?['preferences'];
    final prefsObj = RidePreferences.fromJson(prefsSource, rootJson: rootJson ?? json);

    final rawRideType = (json['rideType'] ??
            json['bookingType'] ??
            json['rideBookingCategory'] ??
            (json['driverPreferences'] is Map ? json['driverPreferences']['rideType'] : null) ??
            (json['preferences'] is Map ? json['preferences']['rideType'] : null) ??
            '')
        .toString()
        .toLowerCase()
        .trim();

    final isDoorToDoorRide = rawRideType == 'door_to_door' ||
        rawRideType == 'door-to-door' ||
        rawRideType.contains('door') ||
        json['acceptDoorToDoorRequest'] == true ||
        json['acceptDoorToDoor'] == true ||
        json['isDoorstepAllowed'] == true ||
        json['offerDoorstepPickupDrop'] == true ||
        json['doorstepPickupAllowed'] == true ||
        json['doorstepAllowed'] == true ||
        json['doorstepPickupDrop'] == true ||
        json['isWholeCarOnly'] == true ||
        json['pricingType'] == 'whole_vehicle' ||
        (json['driverPreferences'] is Map && json['driverPreferences']['acceptDoorToDoor'] == true) ||
        (json['preferences'] is Map &&
            (json['preferences']['doorstepPickupDrop'] == true ||
                json['preferences']['isDoorstepAllowed'] == true ||
                json['preferences']['offerDoorstepPickupDrop'] == true));

    final doorstepAllowed = isDoorToDoorRide;

    final rawDetourRadius = json['maxDetourRadiusKm'] ??
        json['detourRadiusKm'] ??
        (json['preferences'] is Map ? json['preferences']['maxDetourRadiusKm'] : null) ??
        5.0;
    final detourRadius = rawDetourRadius is num
        ? rawDetourRadius.toDouble()
        : (double.tryParse(rawDetourRadius?.toString() ?? '') ?? 5.0);

    final rawDetourRate = json['detourRatePerKm'] ??
        json['doorstepRatePerKm'] ??
        (json['preferences'] is Map ? json['preferences']['detourRatePerKm'] : null) ??
        15.0;
    final detourRate = rawDetourRate is num
        ? rawDetourRate.toDouble()
        : (double.tryParse(rawDetourRate?.toString() ?? '') ?? 15.0);

    final rawDoorstepBase = json['doorstepBaseFee'] ?? json['extraPickupCharge'] ?? 0.0;
    final doorstepBase = rawDoorstepBase is num
        ? rawDoorstepBase.toDouble()
        : (double.tryParse(rawDoorstepBase?.toString() ?? '') ?? 0.0);

    final rawTotalSeats = json['totalSeats'] ?? json['seats'] ?? vehicleMap?['seats'] ?? (json['seats'] is Map ? json['seats']['total'] : null) ?? 4;
    final totalSeats = rawTotalSeats is num ? rawTotalSeats.toInt() : (int.tryParse(rawTotalSeats.toString()) ?? 4);

    final rideType = isDoorToDoorRide ? 'door_to_door' : 'shared_ride';

    final rawWholeCarPrice = json['wholeCarPrice'] ??
        json['totalPrice'] ??
        (pricingMap?['wholeCarPrice'] ?? pricingMap?['totalPrice']) ??
        (json['pricingType'] == 'whole_vehicle' ? json['price'] : null) ??
        0.0;
    final wholeCarPrice = rawWholeCarPrice is num
        ? rawWholeCarPrice.toDouble()
        : (double.tryParse(rawWholeCarPrice.toString()) ?? 0.0);
    final vehicleSeatCount = totalSeats > 0 ? totalSeats : 4;
    final resolvedWholeCarPrice = (wholeCarPrice > 0 && wholeCarPrice > (price * 1.5))
        ? wholeCarPrice
        : (price > 0 ? (price * vehicleSeatCount) : (wholeCarPrice > 0 ? wholeCarPrice : 0.0));

    final costPerSeatText = json['costPerSeatText']?.toString() ?? pricingMap?['costPerSeatText']?.toString() ?? '';

    final isWholeCarOnly = json['isWholeCarOnly'] == true ||
        isDoorToDoorRide ||
        json['pricingType'] == 'whole_vehicle';

    final viaList = <String>[];
    if (json['intermediatePickups'] is List) {
      for (final it in json['intermediatePickups']) {
        if (it is Map && it['location'] != null && it['location'].toString().isNotEmpty) {
          viaList.add(it['location'].toString());
        } else if (it != null && it.toString().isNotEmpty) {
          viaList.add(it.toString());
        }
      }
    } else if (json['stops'] is List) {
      for (final it in json['stops']) {
        if (it != null && it.toString().isNotEmpty) viaList.add(it.toString());
      }
    } else if (json['via'] is List) {
      for (final it in json['via']) {
        if (it != null && it.toString().isNotEmpty) viaList.add(it.toString());
      }
    } else if (json['via'] is String && json['via'].toString().isNotEmpty) {
      viaList.add(json['via'].toString());
    }

    final rideTypeBadge = (json['rideTypeBadge']?.toString().isNotEmpty == true)
        ? json['rideTypeBadge'].toString()
        : (isDoorToDoorRide ? 'Accept Door to Door request' : 'Shared Ride');
    final bookingModeBadge = json['bookingModeBadge']?.toString() ??
        (prefsObj.autoApproval ? 'Instant booking' : 'Review every request');
    final pricingType = json['pricingType']?.toString() ??
        (isWholeCarOnly ? 'whole_vehicle' : 'per_seat');
    final rawTotalPrice = json['totalPrice'] ??
        (resolvedWholeCarPrice > 0 ? resolvedWholeCarPrice : price * vehicleSeatCount);
    final totalPrice = rawTotalPrice is num ? rawTotalPrice.toDouble() : (double.tryParse(rawTotalPrice.toString()) ?? resolvedWholeCarPrice);

    final isVerifiedByAdmin = json['isAdminVerified'] == true ||
        json['isVerified'] == true ||
        json['adminApproved'] == true ||
        driverMap?['isAdminVerified'] == true ||
        driverMap?['isVerified'] == true ||
        driverMap?['adminApproved'] == true ||
        driverMap?['status'] == 'approved' ||
        driverMap?['kycStatus'] == 'verified';

    return RideDriver(
      id: json['id']?.toString() ?? json['driverId']?.toString() ?? json['rideId']?.toString() ?? driverMap?['id']?.toString() ?? '',
      name: name,
      rating: ratingNum,
      ratingText: ratingTxt,
      reviewCount: tripsNum,
      ratingCount: ratingCountNum,
      ratingBadge: ratingBadge,
      tripsCount: tripsNum,
      tripsText: tripsTxt,
      driverSummary: summary,
      pricePerSeat: price,
      carModel: car,
      vehicleNumber: plate,
      seatsAvailable: seats,
      totalSeats: totalSeats > 0 ? totalSeats : 4,
      rideType: rideType,
      wholeCarPrice: resolvedWholeCarPrice,
      costPerSeatText: costPerSeatText,
      viaLocations: viaList,
      isWholeCarOnly: isWholeCarOnly,
      rideTypeBadge: rideTypeBadge,
      bookingModeBadge: bookingModeBadge,
      pricingType: pricingType,
      totalPrice: totalPrice,
      isVerifiedByAdmin: isVerifiedByAdmin,
      departureTime: json['departureTime']?.toString() ?? tripMap?['departureTime']?.toString() ?? '',
      pickupPoint: json['pickupPoint']?.toString() ?? json['pickupLocation']?.toString() ?? tripMap?['pickupLocation']?.toString() ?? '',
      destinationPoint: json['destinationPoint']?.toString() ?? json['destinationLocation']?.toString() ?? tripMap?['destinationLocation']?.toString() ?? '',
      amenities: json['amenities'] is List ? List<String>.from(json['amenities'].map((e) => e.toString())) : prefsObj.rideFeatures,
      avatarImage: avatar,
      phone: json['phone']?.toString() ?? driverMap?['phone']?.toString() ?? '',
      about: json['about']?.toString() ?? driverMap?['about']?.toString() ?? '',
      isOnline: json['isOnline'] != false && driverMap?['isOnline'] != false,
      preferences: prefsObj,
      isDoorstepAllowed: doorstepAllowed,
      maxDetourRadiusKm: detourRadius,
      detourRatePerKm: detourRate,
      doorstepBaseFee: doorstepBase,
    );
  }

  RideDriver copyWith({
    String? id,
    String? name,
    double? rating,
    String? ratingText,
    int? reviewCount,
    int? tripsCount,
    double? pricePerSeat,
    String? carModel,
    String? vehicleNumber,
    int? seatsAvailable,
    int? totalSeats,
    String? rideType,
    double? wholeCarPrice,
    String? costPerSeatText,
    List<String>? viaLocations,
    bool? isWholeCarOnly,
    String? departureTime,
    String? pickupPoint,
    String? destinationPoint,
    List<String>? amenities,
    String? avatarImage,
    String? phone,
    String? about,
    String? tripsText,
    String? driverSummary,
    bool? isOnline,
    RidePreferences? preferences,
    bool? isDoorstepAllowed,
    double? maxDetourRadiusKm,
    double? detourRatePerKm,
    double? doorstepBaseFee,
    bool? isVerifiedByAdmin,
  }) {
    return RideDriver(
      id: id ?? this.id,
      name: name ?? this.name,
      rating: rating ?? this.rating,
      ratingText: ratingText ?? this.ratingText,
      reviewCount: reviewCount ?? this.reviewCount,
      tripsCount: tripsCount ?? this.tripsCount,
      pricePerSeat: pricePerSeat ?? this.pricePerSeat,
      carModel: carModel ?? this.carModel,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      seatsAvailable: seatsAvailable ?? this.seatsAvailable,
      totalSeats: totalSeats ?? this.totalSeats,
      rideType: rideType ?? this.rideType,
      wholeCarPrice: wholeCarPrice ?? this.wholeCarPrice,
      costPerSeatText: costPerSeatText ?? this.costPerSeatText,
      viaLocations: viaLocations ?? this.viaLocations,
      isWholeCarOnly: isWholeCarOnly ?? this.isWholeCarOnly,
      rideTypeBadge: this.rideTypeBadge,
      bookingModeBadge: this.bookingModeBadge,
      pricingType: this.pricingType,
      totalPrice: this.totalPrice,
      isVerifiedByAdmin: isVerifiedByAdmin ?? this.isVerifiedByAdmin,
      departureTime: departureTime ?? this.departureTime,
      pickupPoint: pickupPoint ?? this.pickupPoint,
      destinationPoint: destinationPoint ?? this.destinationPoint,
      amenities: amenities ?? this.amenities,
      avatarImage: avatarImage ?? this.avatarImage,
      phone: phone ?? this.phone,
      about: about ?? this.about,
      tripsText: tripsText ?? this.tripsText,
      driverSummary: driverSummary ?? this.driverSummary,
      isOnline: isOnline ?? this.isOnline,
      preferences: preferences ?? this.preferences,
      isDoorstepAllowed: isDoorstepAllowed ?? this.isDoorstepAllowed,
      maxDetourRadiusKm: maxDetourRadiusKm ?? this.maxDetourRadiusKm,
      detourRatePerKm: detourRatePerKm ?? this.detourRatePerKm,
      doorstepBaseFee: doorstepBaseFee ?? this.doorstepBaseFee,
    );
  }
}

class BoardingPointItem {
  final String id;
  final String location;
  final String time;
  final String landmark;
  final String pincode;
  final bool isStartPoint;
  final bool isSelectable;
  final double price;

  const BoardingPointItem({
    required this.id,
    required this.location,
    required this.time,
    required this.landmark,
    required this.pincode,
    this.isStartPoint = false,
    this.isSelectable = true,
    this.price = 250.0,
  });

  factory BoardingPointItem.fromJson(Map<String, dynamic> json) {
    return BoardingPointItem(
      id: json['id']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
      time: json['time']?.toString() ?? '',
      landmark: json['landmark']?.toString() ?? '',
      pincode: json['pincode']?.toString() ?? '',
      isStartPoint: json['isStartPoint'] == true,
      isSelectable: json['isSelectable'] != false,
      price: (json['price'] is num) ? (json['price'] as num).toDouble() : (double.tryParse(json['price']?.toString() ?? '') ?? 250.0),
    );
  }
}

class RouteTimelinePassenger {
  final String name;
  final String avatar;

  const RouteTimelinePassenger({required this.name, required this.avatar});

  factory RouteTimelinePassenger.fromJson(Map<String, dynamic> json) {
    return RouteTimelinePassenger(
      name: json['name']?.toString() ?? '',
      avatar: json['avatar']?.toString() ?? '',
    );
  }
}

class RouteTimelineStop {
  final String time;
  final String location;
  final String type;
  final String title;
  final String landmark;
  final String pincode;
  final int stopNumber;
  final double price;
  final String amountText;
  final double priceFromOrigin;
  final String amountFromOriginText;
  final int pickCount;
  final String passengerLabel;
  final List<RouteTimelinePassenger> passengers;

  const RouteTimelineStop({
    required this.time,
    required this.location,
    required this.type,
    this.title = '',
    this.landmark = '',
    this.pincode = '',
    this.stopNumber = 0,
    this.price = 0.0,
    this.amountText = '',
    this.priceFromOrigin = 0.0,
    this.amountFromOriginText = '',
    this.pickCount = 0,
    this.passengerLabel = '',
    this.passengers = const [],
  });

  factory RouteTimelineStop.fromJson(Map<String, dynamic> json) {
    final pList = (json['passengers'] as List?)
            ?.map((p) => RouteTimelinePassenger.fromJson(p is Map<String, dynamic> ? p : {}))
            .toList() ??
        [];

    final pCount = json['pickCount'] is num
        ? (json['pickCount'] as num).toInt()
        : (int.tryParse(json['pickCount']?.toString() ?? '') ?? (pList.isNotEmpty ? pList.length : 0));

    final rawPrice = json['price'] is num
        ? (json['price'] as num).toDouble()
        : (double.tryParse(json['price']?.toString() ?? '') ?? 0.0);

    final fromOriginPrice = json['priceFromOrigin'] is num
        ? (json['priceFromOrigin'] as num).toDouble()
        : (double.tryParse(json['priceFromOrigin']?.toString() ?? '') ?? 0.0);

    return RouteTimelineStop(
      time: json['time']?.toString() ?? '',
      location: json['location']?.toString() ?? json['name']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      landmark: json['landmark']?.toString() ?? '',
      pincode: json['pincode']?.toString() ?? '',
      stopNumber: json['stopNumber'] is num ? (json['stopNumber'] as num).toInt() : (int.tryParse(json['stopNumber']?.toString() ?? '') ?? 0),
      price: rawPrice,
      amountText: json['amountText']?.toString() ?? (rawPrice > 0 ? '₹ ${rawPrice.toInt()}' : ''),
      priceFromOrigin: fromOriginPrice,
      amountFromOriginText: json['amountFromOriginText']?.toString() ?? (fromOriginPrice > 0 ? '₹ ${fromOriginPrice.toInt()}' : ''),
      pickCount: pCount,
      passengerLabel: json['passengerLabel']?.toString() ?? (pCount > 0 ? 'Pick $pCount' : ''),
      passengers: pList,
    );
  }
}

class RideDetailData {
  final String rideId;
  final RideDriver driver;
  final String vehicleName;
  final String vehicleSummary;
  final String vehicleNumberPlate;
  final String vehicleColor;
  final String fuelType;
  final String from;
  final String to;
  final String departureDate;
  final String departureTime;
  final String arrivalDateFormatted;
  final String arrivalTime;
  final String duration;
  final String distance;
  final int totalSeats;
  final int availableSeats;
  final int bookedSeats;
  final String availableSeatsText;
  final double pricePerSeat;
  final String costPerSeatText;
  final String luggageText;
  final List<RouteTimelineStop> routeTimeline;
  final String staticMapUrl;
  final List<String> instructions;
  final bool canContactDriver;
  final bool canShareRide;
  final bool canBook;
  final RidePreferences preferences;

  const RideDetailData({
    required this.rideId,
    required this.driver,
    required this.vehicleName,
    required this.vehicleSummary,
    required this.vehicleNumberPlate,
    this.vehicleColor = '',
    this.fuelType = '',
    required this.from,
    required this.to,
    required this.departureDate,
    required this.departureTime,
    required this.arrivalDateFormatted,
    required this.arrivalTime,
    required this.duration,
    required this.distance,
    this.totalSeats = 4,
    required this.availableSeats,
    this.bookedSeats = 0,
    required this.availableSeatsText,
    required this.pricePerSeat,
    required this.costPerSeatText,
    this.luggageText = '1 Medium Bag',
    required this.routeTimeline,
    required this.staticMapUrl,
    required this.instructions,
    this.canContactDriver = true,
    this.canShareRide = true,
    this.canBook = true,
    this.preferences = const RidePreferences(),
  });

  factory RideDetailData.fromJson(
    Map<String, dynamic> json, {
    String? pickup,
    String? destination,
    double? fallbackPrice,
  }) {
    final root = json['data'] is Map<String, dynamic> ? json['data'] as Map<String, dynamic> : json;

    final rideId = root['rideId']?.toString() ?? root['id']?.toString() ?? '';
    final vehicle = root['vehicle'] is Map<String, dynamic> ? root['vehicle'] as Map<String, dynamic> : <String, dynamic>{};
    final trip = root['trip'] is Map<String, dynamic> ? root['trip'] as Map<String, dynamic> : <String, dynamic>{};
    final seats = root['seats'] is Map<String, dynamic> ? root['seats'] as Map<String, dynamic> : <String, dynamic>{};
    final pricing = root['pricing'] is Map<String, dynamic> ? root['pricing'] as Map<String, dynamic> : <String, dynamic>{};
    final map = root['map'] is Map<String, dynamic> ? root['map'] as Map<String, dynamic> : <String, dynamic>{};
    final luggage = root['luggage'] is Map<String, dynamic> ? root['luggage'] as Map<String, dynamic> : <String, dynamic>{};
    final actions = root['actions'] is Map<String, dynamic> ? root['actions'] as Map<String, dynamic> : <String, dynamic>{};

    final timelineList = (root['routeTimeline'] as List?)
            ?.map((item) => RouteTimelineStop.fromJson(item is Map<String, dynamic> ? item : {}))
            .toList() ??
        [];

    final firstTimelinePrice = timelineList.isNotEmpty && timelineList.first.price > 0 ? timelineList.first.price : 0.0;

    // 1. Explicit backend segment price fields returned for customer's queried segment
    final dynamic rawSegmentPrice = pricing['segmentPrice'] ??
        pricing['segmentFare'] ??
        pricing['priceForSegment'] ??
        root['segmentFare'] ??
        root['calculatedFare'] ??
        (root['segmentPricing'] is Map ? (root['segmentPricing']['pricePerSeat'] ?? root['segmentPricing']['fare']) : null);
    final num? parsedSegmentPrice = rawSegmentPrice is num
        ? rawSegmentPrice
        : (double.tryParse(rawSegmentPrice?.toString() ?? ''));

    // 2. Timeline stop differential calculation if stop prices are provided by backend
    double? timelineDifferentialPrice;
    if (pickup != null && destination != null && timelineList.isNotEmpty) {
      final pNorm = pickup.trim().toLowerCase();
      final dNorm = destination.trim().toLowerCase();
      int pIndex = -1;
      int dIndex = -1;
      for (int i = 0; i < timelineList.length; i++) {
        final loc = timelineList[i].location.toLowerCase();
        if (pIndex == -1 && loc.contains(pNorm)) pIndex = i;
        if (loc.contains(dNorm)) dIndex = i;
      }
      if (pIndex != -1 && dIndex != -1 && pIndex < dIndex) {
        final pStop = timelineList[pIndex];
        final dStop = timelineList[dIndex];
        if (dStop.priceFromOrigin > 0 && pStop.priceFromOrigin >= 0 && dStop.priceFromOrigin > pStop.priceFromOrigin) {
          timelineDifferentialPrice = dStop.priceFromOrigin - pStop.priceFromOrigin;
        }
      }
    }

    final fullRoutePrice = (pricing['pricePerSeat'] is num
        ? (pricing['pricePerSeat'] as num).toDouble()
        : (double.tryParse(pricing['pricePerSeat']?.toString() ?? '') ??
            (root['pricePerSeat'] is num
                ? (root['pricePerSeat'] as num).toDouble()
                : (double.tryParse(root['pricePerSeat']?.toString() ?? '') ??
                    (root['price'] is num
                        ? (root['price'] as num).toDouble()
                        : (double.tryParse(root['price']?.toString() ?? '') ?? firstTimelinePrice))))));

    // Priority hierarchy for customer segment fare:
    // 1. Explicit backend-calculated segment price returned in response
    // 2. Calculated timeline stop differential (destination - pickup cumulative)
    // 3. Customer search session validated segment fare (fallbackPrice)
    // 4. Default to full-route master price if booking whole route
    final rawPrice = parsedSegmentPrice?.toDouble() ??
        timelineDifferentialPrice ??
        (fallbackPrice != null && fallbackPrice > 0 ? fallbackPrice : fullRoutePrice);

    final pricePerSeat = rawPrice > 0 ? rawPrice : fullRoutePrice;

    final driverJson = root['driver'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(root['driver'] as Map)
        : <String, dynamic>{};
    if (root['isDoorstepAllowed'] != null) driverJson['isDoorstepAllowed'] = root['isDoorstepAllowed'];
    if (root['offerDoorstepPickupDrop'] != null) driverJson['offerDoorstepPickupDrop'] = root['offerDoorstepPickupDrop'];
    if (root['doorstepAllowed'] != null) driverJson['doorstepAllowed'] = root['doorstepAllowed'];
    if (root['doorstepPickupAllowed'] != null) driverJson['doorstepPickupAllowed'] = root['doorstepPickupAllowed'];
    if (root['maxDetourRadiusKm'] != null) driverJson['maxDetourRadiusKm'] = root['maxDetourRadiusKm'];
    if (root['detourRatePerKm'] != null) driverJson['detourRatePerKm'] = root['detourRatePerKm'];
    if (root['preferences'] != null && driverJson['preferences'] == null) driverJson['preferences'] = root['preferences'];
    if (root['driverPreferences'] != null) driverJson['driverPreferences'] = root['driverPreferences'];
    if (root['customerPreferences'] != null) driverJson['customerPreferences'] = root['customerPreferences'];
    if (root['rideFeatures'] != null) driverJson['rideFeatures'] = root['rideFeatures'];
    if (root['autoApproval'] != null) driverJson['autoApproval'] = root['autoApproval'];
    if (root['autoApprovalBadge'] != null) driverJson['autoApprovalBadge'] = root['autoApprovalBadge'];
    if (root['featuresList'] != null) driverJson['featuresList'] = root['featuresList'];
    if (root['features'] != null) driverJson['features'] = root['features'];
    if (root['amenities'] != null) driverJson['amenities'] = root['amenities'];

    final driver = RideDriver.fromJson(
      driverJson,
      defaultCar: vehicle['model']?.toString() ?? vehicle['name']?.toString() ?? vehicle['summary']?.toString() ?? '',
      defaultPlate: vehicle['numberPlate']?.toString() ?? '',
      defaultPrice: pricePerSeat,
      rootJson: root,
    );

    final instrList = (root['instructions'] as List?)?.map((e) => e.toString()).toList() ?? [];

    final availSeats = seats['available'] is num
        ? (seats['available'] as num).toInt()
        : (int.tryParse(seats['available']?.toString() ?? '') ??
            (root['availableSeats'] is num
                ? (root['availableSeats'] as num).toInt()
                : (root['seatsAvailable'] is num ? (root['seatsAvailable'] as num).toInt() : 0)));

    final totSeats = seats['total'] is num
        ? (seats['total'] as num).toInt()
        : (int.tryParse(seats['total']?.toString() ?? '') ??
            (root['totalSeats'] is num ? (root['totalSeats'] as num).toInt() : 4));

    final bkdSeats = seats['booked'] is num
        ? (seats['booked'] as num).toInt()
        : (int.tryParse(seats['booked']?.toString() ?? '') ??
            (root['bookedSeats'] is num ? (root['bookedSeats'] as num).toInt() : 0));

    final vehicleSummary = vehicle['vehicleSummary']?.toString() ??
        vehicle['summary']?.toString() ??
        (vehicle['model'] != null || vehicle['name'] != null
            ? '${vehicle['model'] ?? vehicle['name'] ?? ''}${vehicle['color'] != null ? " • ${vehicle['color']}" : ""}${vehicle['numberPlate'] != null ? " • ${vehicle['numberPlate']}" : ""}'.trim()
            : (driver.driverSummary.isNotEmpty ? driver.driverSummary : ''));

    final startLocation = trip['from']?.toString() ??
        trip['pickupLocation']?.toString() ??
        root['pickupLocation']?.toString() ??
        root['from']?.toString() ??
        (timelineList.isNotEmpty ? timelineList.first.location : '');

    final destLocation = trip['to']?.toString() ??
        trip['destinationLocation']?.toString() ??
        root['destinationLocation']?.toString() ??
        root['to']?.toString() ??
        (timelineList.isNotEmpty ? timelineList.last.location : '');

    final depDate = trip['departureDate']?.toString() ??
        root['departureDate']?.toString() ??
        root['date']?.toString() ??
        '';

    final depTime = trip['departureTime']?.toString() ??
        root['departureTime']?.toString() ??
        root['time']?.toString() ??
        (timelineList.isNotEmpty ? timelineList.first.time : '');

    final arrTime = trip['arrivalTime']?.toString() ??
        root['arrivalTime']?.toString() ??
        (timelineList.isNotEmpty ? timelineList.last.time : '');

    return RideDetailData(
      rideId: rideId,
      driver: driver,
      vehicleName: vehicle['model']?.toString() ?? vehicle['name']?.toString() ?? '',
      vehicleSummary: vehicleSummary,
      vehicleNumberPlate: vehicle['numberPlate']?.toString() ?? '',
      vehicleColor: vehicle['color']?.toString() ?? '',
      fuelType: vehicle['fuelType']?.toString() ?? '',
      from: startLocation,
      to: destLocation,
      departureDate: depDate,
      departureTime: depTime,
      arrivalDateFormatted: trip['arrivalDateFormatted']?.toString() ?? root['arrivalDateFormatted']?.toString() ?? '',
      arrivalTime: arrTime,
      duration: trip['duration']?.toString() ?? root['duration']?.toString() ?? '',
      distance: trip['distance']?.toString() ?? root['distance']?.toString() ?? '',
      totalSeats: totSeats,
      availableSeats: availSeats,
      bookedSeats: bkdSeats,
      availableSeatsText: seats['availableSeatsText']?.toString() ??
          root['availableSeatsText']?.toString() ??
          (availSeats > 0 ? 'Available $availSeats seats' : 'No seats available'),
      pricePerSeat: pricePerSeat,
      costPerSeatText: pricing['costPerSeatText']?.toString() ??
          root['costPerSeatText']?.toString() ??
          (pricePerSeat > 0 ? 'Cost Per Seat ₹ ${pricePerSeat.toInt()}' : ''),
      luggageText: luggage['luggageText']?.toString() ?? root['luggage']?.toString() ?? '1 Medium Bag',
      routeTimeline: timelineList,
      staticMapUrl: map['interactiveMapUrl']?.toString() ?? map['routeMapUrl']?.toString() ?? '',
      instructions: instrList,
      canContactDriver: actions['canContactDriver'] != false,
      canShareRide: actions['canShareRide'] != false,
      canBook: actions['canBook'] != false,
      preferences: driver.preferences,
    );
  }
}

class RideBookingSession {
  final String rideId;
  final String bookingId;
  final RideDriver driver;
  final String pickup;
  final String destination;
  final String boardingPoint;
  final String customerPickupAddress;
  final String customerDropAddress;
  final String customerPickupPincode;
  final String customerPickupLandmark;
  final String date;
  final String time;
  final int seatsCount;
  final bool isDoorstepPickup;
  final double detourDistanceKm;
  final double detourCharge;
  final double perKmDetourRate;
  final String passengerName;
  final String passengerPhone;
  final String passengerEmail;
  final String luggage;
  final String paymentMethod;
  final double totalAmount;
  final String quoteId;
  final FareQuoteResult? fareQuote;
  final String boardingPin;
  final String razorpayOrderId;
  final String razorpayPaymentId;
  final String razorpaySignature;
  final RideDetailData? rideDetailData;

  const RideBookingSession({
    this.rideId = '',
    this.bookingId = '',
    this.driver = const RideDriver(),
    this.pickup = '',
    this.destination = '',
    this.boardingPoint = '',
    this.customerPickupAddress = '',
    this.customerDropAddress = '',
    this.customerPickupPincode = '',
    this.customerPickupLandmark = '',
    this.date = '',
    this.time = '',
    this.seatsCount = 1,
    this.isDoorstepPickup = false,
    this.detourDistanceKm = 0.0,
    this.detourCharge = 0.0,
    this.perKmDetourRate = 0.0,
    this.passengerName = '',
    this.passengerPhone = '',
    this.passengerEmail = '',
    this.luggage = '',
    this.paymentMethod = 'UPI',
    this.totalAmount = 0.0,
    this.quoteId = '',
    this.fareQuote,
    this.boardingPin = '',
    this.razorpayOrderId = '',
    this.razorpayPaymentId = '',
    this.razorpaySignature = '',
    this.rideDetailData,
  });

  RideBookingSession copyWith({
    String? rideId,
    String? bookingId,
    RideDriver? driver,
    String? pickup,
    String? destination,
    String? boardingPoint,
    String? customerPickupAddress,
    String? customerDropAddress,
    String? customerPickupPincode,
    String? customerPickupLandmark,
    String? date,
    String? time,
    int? seatsCount,
    bool? isDoorstepPickup,
    double? detourDistanceKm,
    double? detourCharge,
    double? perKmDetourRate,
    String? passengerName,
    String? passengerPhone,
    String? passengerEmail,
    String? luggage,
    String? paymentMethod,
    double? totalAmount,
    String? quoteId,
    FareQuoteResult? fareQuote,
    String? boardingPin,
    String? razorpayOrderId,
    String? razorpayPaymentId,
    String? razorpaySignature,
    RideDetailData? rideDetailData,
  }) {
    return RideBookingSession(
      rideId: rideId ?? this.rideId,
      bookingId: bookingId ?? this.bookingId,
      driver: driver ?? this.driver,
      pickup: pickup ?? this.pickup,
      destination: destination ?? this.destination,
      boardingPoint: boardingPoint ?? this.boardingPoint,
      customerPickupAddress: customerPickupAddress ?? this.customerPickupAddress,
      customerDropAddress: customerDropAddress ?? this.customerDropAddress,
      customerPickupPincode: customerPickupPincode ?? this.customerPickupPincode,
      customerPickupLandmark: customerPickupLandmark ?? this.customerPickupLandmark,
      date: date ?? this.date,
      time: time ?? this.time,
      seatsCount: seatsCount ?? this.seatsCount,
      isDoorstepPickup: isDoorstepPickup ?? this.isDoorstepPickup,
      detourDistanceKm: detourDistanceKm ?? this.detourDistanceKm,
      detourCharge: detourCharge ?? this.detourCharge,
      perKmDetourRate: perKmDetourRate ?? this.perKmDetourRate,
      passengerName: passengerName ?? this.passengerName,
      passengerPhone: passengerPhone ?? this.passengerPhone,
      passengerEmail: passengerEmail ?? this.passengerEmail,
      luggage: luggage ?? this.luggage,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      totalAmount: totalAmount ?? this.totalAmount,
      quoteId: quoteId ?? this.quoteId,
      fareQuote: fareQuote ?? this.fareQuote,
      boardingPin: boardingPin ?? this.boardingPin,
      razorpayOrderId: razorpayOrderId ?? this.razorpayOrderId,
      razorpayPaymentId: razorpayPaymentId ?? this.razorpayPaymentId,
      razorpaySignature: razorpaySignature ?? this.razorpaySignature,
      rideDetailData: rideDetailData ?? this.rideDetailData,
    );
  }

  Map<String, dynamic> toBookPayload() {
    final parts = passengerName.trim().split(' ');
    final lastName = parts.length > 1 ? parts.sublist(1).join(' ') : (parts.isNotEmpty ? parts.first : '');

    return {
      'rideId': rideId.isNotEmpty ? rideId : driver.id,
      'fullName': passengerName,
      'lastName': lastName,
      'phoneNumber': passengerPhone,
      'emailID': passengerEmail,
      'numberOfSeats': seatsCount,
      'boardingPoint': boardingPoint.isNotEmpty ? boardingPoint : pickup,
      'destination': destination,
    };
  }

  Map<String, dynamic> toJson() => toBookPayload();
}

class IntermediateStopFare {
  final int stopNumber;
  final String location;
  final double price;
  final double priceFromOrigin;
  final double priceToDestination;
  final double suggestedPriceFromOrigin;
  final double suggestedPriceToDestination;
  final double distanceFromOriginKm;
  final double distanceToDestinationKm;
  final String amountText;

  const IntermediateStopFare({
    this.stopNumber = 0,
    this.location = '',
    this.price = 0.0,
    this.priceFromOrigin = 0.0,
    this.priceToDestination = 0.0,
    this.suggestedPriceFromOrigin = 0.0,
    this.suggestedPriceToDestination = 0.0,
    this.distanceFromOriginKm = 0.0,
    this.distanceToDestinationKm = 0.0,
    this.amountText = '',
  });

  factory IntermediateStopFare.fromJson(Map<String, dynamic> json) {
    num getNum(dynamic v) => v is num ? v : (num.tryParse(v?.toString() ?? '') ?? 0);
    final p = getNum(json['price']).toDouble();
    final pFromOrigin = getNum(json['priceFromOrigin'] ?? json['suggestedPriceFromOrigin']).toDouble();
    final pToDest = getNum(json['priceToDestination'] ?? json['suggestedPriceToDestination']).toDouble();

    return IntermediateStopFare(
      stopNumber: (json['stopNumber'] is num) ? (json['stopNumber'] as num).toInt() : (int.tryParse(json['stopNumber']?.toString() ?? '') ?? 0),
      location: json['location']?.toString() ?? '',
      price: p,
      priceFromOrigin: pFromOrigin,
      priceToDestination: pToDest,
      suggestedPriceFromOrigin: pFromOrigin,
      suggestedPriceToDestination: pToDest,
      distanceFromOriginKm: getNum(json['distanceFromOriginKm']).toDouble(),
      distanceToDestinationKm: getNum(json['distanceToDestinationKm']).toDouble(),
      amountText: json['amountText']?.toString() ?? (p > 0 ? '₹ ${p.toInt()}' : (pFromOrigin > 0 ? '₹ ${pFromOrigin.toInt()}' : '')),
    );
  }
}

class RouteSegmentFare {
  final String from;
  final String to;
  final double distanceKm;
  final double price;

  const RouteSegmentFare({
    this.from = '',
    this.to = '',
    this.distanceKm = 0.0,
    this.price = 0.0,
  });

  factory RouteSegmentFare.fromJson(Map<String, dynamic> json) {
    num getNum(dynamic v) => v is num ? v : (num.tryParse(v?.toString() ?? '') ?? 0);
    return RouteSegmentFare(
      from: json['from']?.toString() ?? '',
      to: json['to']?.toString() ?? '',
      distanceKm: getNum(json['distanceKm']).toDouble(),
      price: getNum(json['price']).toDouble(),
    );
  }
}

class IntermediateFareResult {
  final String origin;
  final String destination;
  final String totalDistance;
  final double totalPrice;
  final double ratePerKm;
  final String ratePerKmText;
  final List<IntermediateStopFare> intermediatePickups;
  final List<RouteSegmentFare> allSegments;

  const IntermediateFareResult({
    this.origin = '',
    this.destination = '',
    this.totalDistance = '',
    this.totalPrice = 0.0,
    this.ratePerKm = 0.0,
    this.ratePerKmText = '',
    this.intermediatePickups = const [],
    this.allSegments = const [],
  });

  factory IntermediateFareResult.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : (json['data'] is Map ? Map<String, dynamic>.from(json['data'] as Map) : json);

    num getNum(dynamic v) => v is num ? v : (num.tryParse(v?.toString() ?? '') ?? 0);

    final stopsList = (data['intermediatePickups'] as List?)
            ?.map((e) => IntermediateStopFare.fromJson(e is Map<String, dynamic> ? e : (e is Map ? Map<String, dynamic>.from(e) : {})))
            .toList() ??
        [];

    final segmentsList = (data['allSegments'] as List?)
            ?.map((e) => RouteSegmentFare.fromJson(e is Map<String, dynamic> ? e : (e is Map ? Map<String, dynamic>.from(e) : {})))
            .toList() ??
        [];

    final rateNum = getNum(data['ratePerKm']).toDouble();

    return IntermediateFareResult(
      origin: data['origin']?.toString() ?? data['from']?.toString() ?? '',
      destination: data['destination']?.toString() ?? data['to']?.toString() ?? '',
      totalDistance: data['totalDistance']?.toString() ?? '',
      totalPrice: getNum(data['totalPrice'] ?? data['price']).toDouble(),
      ratePerKm: rateNum,
      ratePerKmText: data['ratePerKmText']?.toString() ?? (rateNum > 0 ? '₹ $rateNum/km' : ''),
      intermediatePickups: stopsList,
      allSegments: segmentsList,
    );
  }
}

class SeatGridItem {
  final String seat;
  final String status; // "Booked", "Available", "Boarded", "Selected"
  final String passengerName;
  final bool isPassengerSeat;

  const SeatGridItem({
    required this.seat,
    this.status = 'Available',
    this.passengerName = '',
    this.isPassengerSeat = false,
  });

  bool get isBooked => status.toLowerCase() == 'booked';
  bool get isAvailable => status.toLowerCase() == 'available';
  bool get isBoarded => status.toLowerCase() == 'boarded';

  factory SeatGridItem.fromJson(Map<String, dynamic> json) {
    return SeatGridItem(
      seat: json['seat']?.toString() ?? json['seatNumber']?.toString() ?? 'S-1',
      status: json['status']?.toString() ?? (json['isBooked'] == true ? 'Booked' : 'Available'),
      passengerName: json['passengerName']?.toString() ?? json['name']?.toString() ?? '',
      isPassengerSeat: json['isPassengerSeat'] == true,
    );
  }
}

class PassengerBoardingVerifyDetails {
  final String bookingId;
  final String rideId;
  final String passengerName;
  final String pickupLocation;
  final String dropoffLocation;
  final String seatNumber;
  final int pinLength;
  final String expectedPin;
  final bool isBoarded;
  final List<SeatGridItem> seatGrid;

  const PassengerBoardingVerifyDetails({
    this.bookingId = '',
    this.rideId = '',
    this.passengerName = '',
    this.pickupLocation = '',
    this.dropoffLocation = '',
    this.seatNumber = 'S-1',
    this.pinLength = 4,
    this.expectedPin = '',
    this.isBoarded = false,
    this.seatGrid = const [],
  });

  factory PassengerBoardingVerifyDetails.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> root = json;
    final Map<String, dynamic> passObj = (json['passenger'] is Map<String, dynamic>)
        ? json['passenger'] as Map<String, dynamic>
        : (json['passenger'] is Map
            ? Map<String, dynamic>.from(json['passenger'] as Map)
            : (json['data'] is Map<String, dynamic>
                ? json['data'] as Map<String, dynamic>
                : (json['data'] is Map ? Map<String, dynamic>.from(json['data'] as Map) : json)));

    final pName = passObj['name']?.toString() ??
        passObj['customerName']?.toString() ??
        passObj['passengerName']?.toString() ??
        passObj['fullName']?.toString() ??
        passObj['userName']?.toString() ??
        root['passengerName']?.toString() ??
        root['name']?.toString() ??
        '';

    final pSeat = passObj['seatId']?.toString() ??
        passObj['seatNumber']?.toString() ??
        passObj['seat']?.toString() ??
        root['seatNumber']?.toString() ??
        root['seat']?.toString() ??
        '';

    final pFrom = passObj['from']?.toString() ??
        passObj['pickupLocation']?.toString() ??
        passObj['pickup']?.toString() ??
        passObj['boardingPoint']?.toString() ??
        root['pickupLocation']?.toString() ??
        '';

    final pTo = passObj['to']?.toString() ??
        passObj['dropoffLocation']?.toString() ??
        passObj['destination']?.toString() ??
        passObj['destinationLocation']?.toString() ??
        root['dropoffLocation']?.toString() ??
        '';

    final pBookingId = passObj['bookingId']?.toString() ??
        passObj['_id']?.toString() ??
        root['bookingId']?.toString() ??
        '';

    final pPin = passObj['boardingPin']?.toString() ??
        passObj['pin']?.toString() ??
        passObj['expectedPin']?.toString() ??
        root['expectedPin']?.toString() ??
        root['boardingPin']?.toString() ??
        '';

    final pBoarded = passObj['isBoarded'] == true || root['isBoarded'] == true;

    final rawSeats = (root['seatsAvailable'] is List)
        ? root['seatsAvailable'] as List
        : ((root['seatGrid'] is List) ? root['seatGrid'] as List : null);

    List<SeatGridItem> gridList;
    if (rawSeats != null && rawSeats.isNotEmpty) {
      gridList = rawSeats.map<SeatGridItem>((e) {
        final m = e is Map ? Map<String, dynamic>.from(e) : <String, dynamic>{};
        final sNum = (m['seatNumber'] ?? m['seat'] ?? '').toString();
        final statusRaw = (m['status'] ?? '').toString().toLowerCase();
        final cleanPSeat = pSeat.replaceAll('Seat ', '').trim();
        final isMatch = cleanPSeat.isNotEmpty &&
            (sNum == cleanPSeat ||
                'S-$sNum' == cleanPSeat ||
                sNum.replaceAll('S-', '') == cleanPSeat.replaceAll('S-', ''));

        String cleanStatus;
        if (statusRaw == 'boarding' || isMatch) {
          cleanStatus = 'Boarding';
        } else if (statusRaw == 'booked' || m['isBooked'] == true) {
          cleanStatus = 'Booked';
        } else {
          cleanStatus = 'Available';
        }

        return SeatGridItem(
          seat: sNum.startsWith('S-') ? sNum : (sNum.startsWith('S') ? 'S-${sNum.substring(1)}' : 'S-$sNum'),
          status: cleanStatus,
          passengerName: isMatch ? pName : (m['passengerName']?.toString() ?? ''),
          isPassengerSeat: isMatch,
        );
      }).toList();
    } else {
      final cleanPSeat = pSeat.replaceAll('Seat ', '').trim();
      final passengerSeatNum = int.tryParse(cleanPSeat.replaceAll(RegExp(r'[^0-9]'), '')) ?? 2;
      gridList = List.generate(4, (i) {
        final seatNum = i + 1;
        final isCurrent = seatNum == passengerSeatNum;
        return SeatGridItem(
          seat: 'S-$seatNum',
          status: isCurrent ? 'Boarding' : 'Booked',
          passengerName: isCurrent ? pName : '',
          isPassengerSeat: isCurrent,
        );
      });
    }

    return PassengerBoardingVerifyDetails(
      bookingId: pBookingId,
      rideId: root['rideId']?.toString() ?? '',
      passengerName: pName,
      pickupLocation: pFrom,
      dropoffLocation: pTo,
      seatNumber: pSeat,
      pinLength: root['pinLength'] is int ? root['pinLength'] as int : 4,
      expectedPin: pPin,
      isBoarded: pBoarded,
      seatGrid: gridList,
    );
  }
}

class StartRideLockStatus {
  final bool canStartRide;
  final bool isLocked;
  final String departureDateTime;
  final String departureFormatted;
  final String startRideAllowedFrom;
  final String startRideAllowedFromFormatted;
  final double hoursRemainingUntilStart;
  final int minutesRemainingUntilStart;
  final String lockReason;
  final String buttonText;
  final bool preTripAlertSent;
  final bool hasActiveRideConflict;
  final ConflictingRide? conflictingRide;

  const StartRideLockStatus({
    this.canStartRide = true,
    this.isLocked = false,
    this.departureDateTime = '',
    this.departureFormatted = '',
    this.startRideAllowedFrom = '',
    this.startRideAllowedFromFormatted = '',
    this.hoursRemainingUntilStart = 0.0,
    this.minutesRemainingUntilStart = 0,
    this.lockReason = '',
    this.buttonText = 'Start Navigation',
    this.preTripAlertSent = false,
    this.hasActiveRideConflict = false,
    this.conflictingRide,
  });

  factory StartRideLockStatus.fromJson(Map<String, dynamic> json) {
    num getNum(dynamic v) => (v is num) ? v : (num.tryParse(v?.toString() ?? '') ?? 0);
    ConflictingRide? cRide;
    if (json['conflictingRide'] is Map) {
      cRide = ConflictingRide.fromJson(Map<String, dynamic>.from(json['conflictingRide'] as Map));
    }

    final isConflict = json['error'] == 'ACTIVE_RIDE_ALREADY_RUNNING' ||
        json['hasActiveRideConflict'] == true;

    return StartRideLockStatus(
      canStartRide: !isConflict && (json['canStartRide'] == true || json['canStartNavigation'] == true),
      isLocked: isConflict || json['isLocked'] == true,
      departureDateTime: json['departureDateTime']?.toString() ?? '',
      departureFormatted: json['departureFormatted']?.toString() ?? '',
      startRideAllowedFrom: json['startRideAllowedFrom']?.toString() ?? '',
      startRideAllowedFromFormatted: json['startRideAllowedFromFormatted']?.toString() ?? '',
      hoursRemainingUntilStart: getNum(json['hoursRemainingUntilStart']).toDouble(),
      minutesRemainingUntilStart: getNum(json['minutesRemainingUntilStart']).toInt(),
      lockReason: json['lockReason']?.toString() ?? json['startRideLockReason']?.toString() ?? json['message']?.toString() ?? '',
      buttonText: isConflict
          ? 'Active Trip Running'
          : (json['buttonText']?.toString() ?? json['startRideButtonText']?.toString() ?? (json['isLocked'] == true ? 'Locked' : 'Start Navigation')),
      preTripAlertSent: json['preTripAlertSent'] == true,
      hasActiveRideConflict: isConflict,
      conflictingRide: cRide,
    );
  }
}

/// Represents a ride that conflicts with a driver action (Schedule Overlap or Active Trip In Progress).
class ConflictingRide {
  final String rideId;
  final String from;
  final String to;
  final String status;
  final String date;
  final String departureTime;

  const ConflictingRide({
    this.rideId = '',
    this.from = '',
    this.to = '',
    this.status = '',
    this.date = '',
    this.departureTime = '',
  });

  factory ConflictingRide.fromJson(Map<String, dynamic> json) {
    return ConflictingRide(
      rideId: json['rideId']?.toString() ?? json['id']?.toString() ?? json['_id']?.toString() ?? '',
      from: json['from']?.toString() ?? json['pickup']?.toString() ?? json['pickupLocation']?.toString() ?? '',
      to: json['to']?.toString() ?? json['destination']?.toString() ?? json['destinationLocation']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      date: json['date']?.toString() ?? json['departureDate']?.toString() ?? '',
      departureTime: json['departureTime']?.toString() ?? json['time']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rideId': rideId,
      'from': from,
      'to': to,
      'status': status,
      'date': date,
      'departureTime': departureTime,
    };
  }

  /// Clean route string, e.g. "Miyapur ➔ Vijayawada" or "Miyapur, Hyderabad ➔ Vijayawada"
  String get formattedRoute {
    final cleanFrom = from.split(',').first.trim();
    final cleanTo = to.split(',').first.trim();
    if (cleanFrom.isNotEmpty && cleanTo.isNotEmpty) {
      return '$cleanFrom ➔ $cleanTo';
    } else if (cleanFrom.isNotEmpty) {
      return cleanFrom;
    }
    return 'Your scheduled route';
  }
}

/// Unified container for backend 409 Conflict rejection payloads:
/// - API 2: DRIVER_SCHEDULE_CONFLICT / SCHEDULE_OVERLAP_CONFLICT
/// - API 3: DRIVER_TRIP_CONFLICT / ACTIVE_RIDE_IN_PROGRESS
/// - API 4: ACTIVE_RIDE_ALREADY_RUNNING
class RideConflictResponse {
  final bool hasConflict;
  final String? errorCode;
  final String? conflictType;
  final String message;
  final ConflictingRide? conflictingRide;

  const RideConflictResponse({
    this.hasConflict = false,
    this.errorCode,
    this.conflictType,
    this.message = '',
    this.conflictingRide,
  });

  /// True if driver already has a ride scheduled at this same date & time (API 2)
  bool get isScheduleOverlap =>
      errorCode == 'DRIVER_SCHEDULE_CONFLICT' ||
      conflictType == 'SCHEDULE_OVERLAP_CONFLICT';

  /// True if driver is currently traveling on an active trip and tries to post a ride (API 3)
  bool get isActiveRideInProgress =>
      errorCode == 'DRIVER_TRIP_CONFLICT' ||
      conflictType == 'ACTIVE_RIDE_IN_PROGRESS';

  /// True if driver attempts to start Ride B while Ride A is already in progress (API 4)
  bool get isActiveRideAlreadyRunning =>
      errorCode == 'ACTIVE_RIDE_ALREADY_RUNNING' ||
      conflictType == 'ACTIVE_RIDE_ALREADY_RUNNING';

  factory RideConflictResponse.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> source = json['data'] is Map
        ? Map<String, dynamic>.from(json['data'] as Map)
        : json;

    final err = source['error']?.toString() ?? json['error']?.toString();
    final cType = source['conflictType']?.toString() ?? json['conflictType']?.toString();
    final msg = source['message']?.toString() ?? json['message']?.toString() ?? '';

    ConflictingRide? ride;
    final rawRide = source['conflictingRide'] ?? json['conflictingRide'];
    if (rawRide is Map) {
      ride = ConflictingRide.fromJson(Map<String, dynamic>.from(rawRide));
    }

    final isConf = err == 'DRIVER_SCHEDULE_CONFLICT' ||
        err == 'DRIVER_TRIP_CONFLICT' ||
        err == 'ACTIVE_RIDE_ALREADY_RUNNING' ||
        cType == 'SCHEDULE_OVERLAP_CONFLICT' ||
        cType == 'ACTIVE_RIDE_IN_PROGRESS' ||
        json['statusCode'] == 409 ||
        source['statusCode'] == 409;

    return RideConflictResponse(
      hasConflict: isConf,
      errorCode: err,
      conflictType: cType,
      message: msg,
      conflictingRide: ride,
    );
  }
}

class PreTripAlertResponse {
  final bool success;
  final String message;
  final String rideId;
  final bool preTripAlertSent;
  final String preTripAlertSentAt;
  final bool driverNotified;
  final int passengersCount;

  const PreTripAlertResponse({
    this.success = false,
    this.message = '',
    this.rideId = '',
    this.preTripAlertSent = false,
    this.preTripAlertSentAt = '',
    this.driverNotified = false,
    this.passengersCount = 0,
  });

  factory PreTripAlertResponse.fromJson(Map<String, dynamic> json) {
    final notifs = json['notificationsSent'] is Map ? json['notificationsSent'] as Map : {};
    num getNum(dynamic v) => (v is num) ? v : (num.tryParse(v?.toString() ?? '') ?? 0);
    return PreTripAlertResponse(
      success: json['success'] == true,
      message: json['message']?.toString() ?? '',
      rideId: json['rideId']?.toString() ?? '',
      preTripAlertSent: json['preTripAlertSent'] == true,
      preTripAlertSentAt: json['preTripAlertSentAt']?.toString() ?? '',
      driverNotified: notifs['driver'] == true,
      passengersCount: getNum(notifs['passengersCount']).toInt(),
    );
  }
}

class RideConfirmationModal {
  final String title;
  final String subtitle;
  final String status;
  final String boardingPin;
  final String pinLabel;
  final String carAndPlate;
  final String carAndPlateLabel;
  final String payToDriver;
  final String payToDriverLabel;
  final double amount;
  final String amountFormatted;
  final String paymentMethod;
  final String driverName;
  final String driverPhone;
  final String vehicle;
  final String vehicleNumberPlate;
  final String viewTripDetailsAction;
  final String showRouteMapAction;
  final String goToDashboardAction;

  const RideConfirmationModal({
    this.title = 'Ride Accepted & Confirmed!',
    this.subtitle = '',
    this.status = 'confirmed',
    this.boardingPin = '',
    this.pinLabel = 'Boarding 4-Digit PIN:',
    this.carAndPlate = '',
    this.carAndPlateLabel = 'Car & Plate:',
    this.payToDriver = '',
    this.payToDriverLabel = 'Pay to Driver:',
    this.amount = 0.0,
    this.amountFormatted = '',
    this.paymentMethod = 'Cash/UPI',
    this.driverName = '',
    this.driverPhone = '',
    this.vehicle = '',
    this.vehicleNumberPlate = '',
    this.viewTripDetailsAction = '',
    this.showRouteMapAction = '',
    this.goToDashboardAction = '',
  });

  factory RideConfirmationModal.fromJson(Map<String, dynamic> json) {
    final modal = json['confirmationModal'] is Map<String, dynamic>
        ? json['confirmationModal'] as Map<String, dynamic>
        : (json['data'] is Map<String, dynamic>
            ? (json['data']['confirmationModal'] is Map<String, dynamic>
                ? json['data']['confirmationModal'] as Map<String, dynamic>
                : json['data'] as Map<String, dynamic>)
            : json);

    final actions = modal['actions'] is Map<String, dynamic>
        ? modal['actions'] as Map<String, dynamic>
        : <String, dynamic>{};

    final rawAmt = modal['amount'] ?? modal['totalAmount'] ?? 0;
    final amt = (rawAmt is num) ? rawAmt.toDouble() : (double.tryParse(rawAmt.toString()) ?? 0.0);

    return RideConfirmationModal(
      title: modal['title']?.toString() ?? 'Ride Accepted & Confirmed!',
      subtitle: modal['subtitle']?.toString() ?? '',
      status: modal['status']?.toString() ?? 'confirmed',
      boardingPin: modal['boardingPin']?.toString() ?? modal['pin']?.toString() ?? '',
      pinLabel: modal['pinLabel']?.toString() ?? 'Boarding 4-Digit PIN:',
      carAndPlate: modal['carAndPlate']?.toString() ?? '',
      carAndPlateLabel: modal['carAndPlateLabel']?.toString() ?? 'Car & Plate:',
      payToDriver: modal['payToDriver']?.toString() ?? (amt > 0 ? '₹${amt.toInt()} (Cash/UPI)' : ''),
      payToDriverLabel: modal['payToDriverLabel']?.toString() ?? 'Pay to Driver:',
      amount: amt,
      amountFormatted: modal['amountFormatted']?.toString() ?? (amt > 0 ? '₹${amt.toInt()}' : ''),
      paymentMethod: modal['paymentMethod']?.toString() ?? 'Cash/UPI',
      driverName: modal['driverName']?.toString() ?? '',
      driverPhone: modal['driverPhone']?.toString() ?? '',
      vehicle: modal['vehicle']?.toString() ?? '',
      vehicleNumberPlate: modal['vehicleNumberPlate']?.toString() ?? '',
      viewTripDetailsAction: actions['viewTripDetails']?.toString() ?? '',
      showRouteMapAction: actions['showRouteMap']?.toString() ?? '',
      goToDashboardAction: actions['goToDashboard']?.toString() ?? '',
    );
  }
}

class TripPassStop {
  final String time;
  final String location;
  final String type;
  final bool isStart;
  final bool isEnd;
  final String icon;
  final double? lat;
  final double? lng;

  const TripPassStop({
    this.time = '',
    this.location = '',
    this.type = 'stop',
    this.isStart = false,
    this.isEnd = false,
    this.icon = 'circle',
    this.lat,
    this.lng,
  });

  factory TripPassStop.fromJson(Map<String, dynamic> json) {
    num? getNum(dynamic v) => (v is num) ? v : num.tryParse(v?.toString() ?? '');
    return TripPassStop(
      time: json['time']?.toString() ?? '',
      location: json['location']?.toString() ?? json['title']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      isStart: json['isStart'] == true,
      isEnd: json['isEnd'] == true,
      icon: json['icon']?.toString() ?? 'circle',
      lat: getNum(json['lat'])?.toDouble(),
      lng: getNum(json['lng'])?.toDouble(),
    );
  }
}

class TripPassTicket {
  final String checkInLabel;
  final String checkInDate;
  final String checkInTime;
  final String checkOutLabel;
  final String checkOutDate;
  final String checkOutTime;
  final String seatConfirmedLabel;
  final String seatConfirmedValue;
  final int seatsCount;

  const TripPassTicket({
    this.checkInLabel = 'Check - in',
    this.checkInDate = '',
    this.checkInTime = '',
    this.checkOutLabel = 'Check - Out',
    this.checkOutDate = '',
    this.checkOutTime = '',
    this.seatConfirmedLabel = 'Seat Confirmed',
    this.seatConfirmedValue = 'A 1',
    this.seatsCount = 1,
  });

  factory TripPassTicket.fromJson(Map<String, dynamic> json) {
    final checkIn = json['checkIn'] is Map ? json['checkIn'] as Map : {};
    final checkOut = json['checkOut'] is Map ? json['checkOut'] as Map : {};
    final seat = json['seatConfirmed'] is Map ? json['seatConfirmed'] as Map : {};

    num? getNum(dynamic v) => (v is num) ? v : num.tryParse(v?.toString() ?? '');

    return TripPassTicket(
      checkInLabel: checkIn['label']?.toString() ?? 'Check - in',
      checkInDate: checkIn['date']?.toString() ?? '',
      checkInTime: checkIn['time']?.toString() ?? '',
      checkOutLabel: checkOut['label']?.toString() ?? 'Check - Out',
      checkOutDate: checkOut['date']?.toString() ?? '',
      checkOutTime: checkOut['time']?.toString() ?? '',
      seatConfirmedLabel: seat['label']?.toString() ?? 'Seat Confirmed',
      seatConfirmedValue: seat['value']?.toString() ?? seat['seatNumber']?.toString() ?? 'A 1',
      seatsCount: getNum(seat['seatsCount'])?.toInt() ?? 1,
    );
  }
}

class TripPassMapPreview {
  final String pickupLocation;
  final String destinationLocation;
  final double pickupLat;
  final double pickupLng;
  final double destLat;
  final double destLng;
  final double vehicleLiveLat;
  final double vehicleLiveLng;
  final String routePolyline;
  final List<Map<String, dynamic>> intermediateStops;

  const TripPassMapPreview({
    this.pickupLocation = '',
    this.destinationLocation = '',
    this.pickupLat = 0.0,
    this.pickupLng = 0.0,
    this.destLat = 0.0,
    this.destLng = 0.0,
    this.vehicleLiveLat = 0.0,
    this.vehicleLiveLng = 0.0,
    this.routePolyline = '',
    this.intermediateStops = const [],
  });

  factory TripPassMapPreview.fromJson(Map<String, dynamic> json) {
    num? getNum(dynamic v) => (v is num) ? v : num.tryParse(v?.toString() ?? '');
    final pCoords = json['pickupCoordinates'] is Map ? json['pickupCoordinates'] as Map : {};
    final dCoords = json['destinationCoordinates'] is Map ? json['destinationCoordinates'] as Map : {};
    final vCoords = json['vehicleLiveLocation'] is Map ? json['vehicleLiveLocation'] as Map : {};

    final stopsList = <Map<String, dynamic>>[];
    if (json['intermediateStops'] is List) {
      for (final item in json['intermediateStops'] as List) {
        if (item is Map) stopsList.add(Map<String, dynamic>.from(item));
      }
    }

    return TripPassMapPreview(
      pickupLocation: json['pickupLocation']?.toString() ?? '',
      destinationLocation: json['destinationLocation']?.toString() ?? '',
      pickupLat: getNum(pCoords['lat'])?.toDouble() ?? 0.0,
      pickupLng: getNum(pCoords['lng'])?.toDouble() ?? 0.0,
      destLat: getNum(dCoords['lat'])?.toDouble() ?? 0.0,
      destLng: getNum(dCoords['lng'])?.toDouble() ?? 0.0,
      vehicleLiveLat: getNum(vCoords['lat'])?.toDouble() ?? 0.0,
      vehicleLiveLng: getNum(vCoords['lng'])?.toDouble() ?? 0.0,
      routePolyline: json['routePolyline']?.toString() ?? '',
      intermediateStops: stopsList,
    );
  }
}

class TripPassDetails {
  final String headerDateTime;
  final TripPassTicket ticket;
  final String boardingPin;
  final String qrPassToken;
  final String driverName;
  final String driverPhone;
  final String driverAvatar;
  final String vehicleSummary;
  final double driverRating;
  final int driverCompletedTrips;
  final String callAction;
  final String messageAction;
  final List<TripPassStop> routeStops;
  final String coTravelersNote;
  final String fuelShareNote;
  final String fuelSharePriceFormatted;
  final String bookingId;
  final String bookingBy;
  final String customerPhone;
  final String bookingRequestDate;
  final String rideAcceptDate;
  final String rideAcceptedDate;
  final String amountFormatted;
  final String paymentStatus;
  final String paymentMethod;
  final TripPassMapPreview mapPreview;
  final String cancellationPolicyTitle;
  final String cancellationPolicyDescription;
  final String cancelBookingEndpoint;
  final bool canCancelBooking;
  final String shareTicketUrl;
  final String boardingPinBannerText;
  final Map<String, dynamic> driverPreferences;
  final Map<String, dynamic> customerPreferences;
  final List<Map<String, dynamic>> rideFeatures;

  const TripPassDetails({
    this.headerDateTime = '',
    this.ticket = const TripPassTicket(),
    this.boardingPin = '',
    this.qrPassToken = '',
    this.driverName = 'Driver',
    this.driverPhone = '',
    this.driverAvatar = '',
    this.vehicleSummary = '',
    this.driverRating = 4.9,
    this.driverCompletedTrips = 0,
    this.callAction = '',
    this.messageAction = '',
    this.routeStops = const [],
    this.coTravelersNote = '',
    this.fuelShareNote = '',
    this.fuelSharePriceFormatted = '',
    this.bookingId = '',
    this.bookingBy = '',
    this.customerPhone = '',
    this.bookingRequestDate = '',
    this.rideAcceptDate = '',
    this.rideAcceptedDate = '',
    this.amountFormatted = '',
    this.paymentStatus = 'paid',
    this.paymentMethod = 'Cash/UPI',
    this.mapPreview = const TripPassMapPreview(),
    this.cancellationPolicyTitle = 'Cancellation policy',
    this.cancellationPolicyDescription = '',
    this.cancelBookingEndpoint = '',
    this.canCancelBooking = true,
    this.shareTicketUrl = '',
    this.boardingPinBannerText = '',
    this.driverPreferences = const {},
    this.customerPreferences = const {},
    this.rideFeatures = const [],
  });

  factory TripPassDetails.fromJson(Map<String, dynamic> json) {
    final trip = json['tripDetails'] is Map<String, dynamic>
        ? json['tripDetails'] as Map<String, dynamic>
        : (json['data'] is Map<String, dynamic>
            ? (json['data']['tripDetails'] is Map<String, dynamic>
                ? json['data']['tripDetails'] as Map<String, dynamic>
                : json['data'] as Map<String, dynamic>)
            : json);

    final ticketJson = trip['ticket'] is Map<String, dynamic> ? trip['ticket'] as Map<String, dynamic> : <String, dynamic>{};
    final dProfile = trip['driverProfile'] is Map<String, dynamic> ? trip['driverProfile'] as Map<String, dynamic> : <String, dynamic>{};
    final dActions = dProfile['actions'] is Map ? dProfile['actions'] as Map : {};
    final callObj = dActions['call'] is Map ? dActions['call'] as Map : {};
    final msgObj = dActions['message'] is Map ? dActions['message'] as Map : {};

    final rTimeline = trip['routeTimeline'] is Map<String, dynamic> ? trip['routeTimeline'] as Map<String, dynamic> : <String, dynamic>{};
    final stopsList = <TripPassStop>[];
    if (rTimeline['stops'] is List) {
      for (final s in rTimeline['stops'] as List) {
        if (s is Map) stopsList.add(TripPassStop.fromJson(Map<String, dynamic>.from(s)));
      }
    }

    final bDetails = trip['bookingDetails'] is Map<String, dynamic> ? trip['bookingDetails'] as Map<String, dynamic> : <String, dynamic>{};
    final mapJson = trip['mapPreview'] is Map<String, dynamic> ? trip['mapPreview'] as Map<String, dynamic> : <String, dynamic>{};
    final cPolicy = trip['cancellationPolicy'] is Map<String, dynamic> ? trip['cancellationPolicy'] as Map<String, dynamic> : <String, dynamic>{};
    final actions = trip['actions'] is Map<String, dynamic> ? trip['actions'] as Map<String, dynamic> : <String, dynamic>{};
    final cancelObj = actions['cancelBooking'] is Map ? actions['cancelBooking'] as Map : {};

    // Preferences & Features per new ticket pass schema
    final Map<String, dynamic> dPrefs = trip['driverPreferences'] is Map
        ? Map<String, dynamic>.from(trip['driverPreferences'] as Map)
        : (json['driverPreferences'] is Map ? Map<String, dynamic>.from(json['driverPreferences'] as Map) : <String, dynamic>{});
    final Map<String, dynamic> cPrefs = trip['customerPreferences'] is Map
        ? Map<String, dynamic>.from(trip['customerPreferences'] as Map)
        : (json['customerPreferences'] is Map ? Map<String, dynamic>.from(json['customerPreferences'] as Map) : <String, dynamic>{});
    final List<Map<String, dynamic>> rFeatures = [];
    final rawFeatures = trip['rideFeatures'] ?? json['rideFeatures'];
    if (rawFeatures is List) {
      for (final f in rawFeatures) {
        if (f is Map) rFeatures.add(Map<String, dynamic>.from(f));
      }
    }

    final pinBanner = trip['boardingPinBanner'] is Map ? trip['boardingPinBanner'] as Map : {};
    final pinBannerText = pinBanner['displayText']?.toString() ?? '';
    final pinVal = trip['boardingPin']?.toString() ??
        (pinBanner['pin']?.toString() ??
            (json['boardingPin']?.toString() ?? ''));

    num? getNum(dynamic v) => (v is num) ? v : num.tryParse(v?.toString() ?? '');

    return TripPassDetails(
      headerDateTime: trip['headerDateTime']?.toString() ?? json['headerDateTime']?.toString() ?? '',
      ticket: TripPassTicket.fromJson(ticketJson),
      boardingPin: pinVal,
      qrPassToken: trip['qrPassToken']?.toString() ?? '',
      driverName: dProfile['driverName']?.toString() ?? dProfile['name']?.toString() ?? 'Driver',
      driverPhone: dProfile['driverPhone']?.toString() ?? dProfile['phone']?.toString() ?? '',
      driverAvatar: dProfile['driverAvatar']?.toString() ?? dProfile['avatar']?.toString() ?? '',
      vehicleSummary: dProfile['subtitle']?.toString() ?? (dProfile['vehicle'] != null ? '${dProfile['vehicle']} • ${dProfile['vehicleNumberPlate'] ?? ""}' : ''),
      driverRating: getNum(dProfile['rating'])?.toDouble() ?? 4.9,
      driverCompletedTrips: getNum(dProfile['completedTrips'])?.toInt() ?? 0,
      callAction: callObj['action']?.toString() ?? '',
      messageAction: msgObj['action']?.toString() ?? '',
      routeStops: stopsList,
      coTravelersNote: rTimeline['coTravelersNote']?.toString() ?? '',
      fuelShareNote: rTimeline['fuelShareNote']?.toString() ?? '',
      fuelSharePriceFormatted: rTimeline['totalFuelShareAmountFormatted']?.toString() ?? rTimeline['fuelSharePriceFormatted']?.toString() ?? '',
      bookingId: bDetails['bookingId']?.toString() ?? json['bookingId']?.toString() ?? '',
      bookingBy: bDetails['bookingByText']?.toString() ?? (bDetails['bookingBy'] != null ? 'Booking by ${bDetails['bookingBy']}' : ''),
      customerPhone: bDetails['customerPhone']?.toString() ?? '',
      bookingRequestDate: bDetails['bookingRequest']?.toString() ?? '',
      rideAcceptDate: bDetails['rideAccept']?.toString() ?? '',
      rideAcceptedDate: bDetails['rideAccepted']?.toString() ?? '',
      amountFormatted: bDetails['amountFormatted']?.toString() ?? '',
      paymentStatus: bDetails['paymentStatus']?.toString() ?? 'paid',
      paymentMethod: bDetails['paymentMethod']?.toString() ?? 'Cash/UPI',
      mapPreview: TripPassMapPreview.fromJson(mapJson),
      cancellationPolicyTitle: cPolicy['title']?.toString() ?? 'Cancellation policy',
      cancellationPolicyDescription: cPolicy['description']?.toString() ?? '',
      cancelBookingEndpoint: cancelObj['endpoint']?.toString() ?? '',
      canCancelBooking: actions['canCancelBooking'] != false,
      shareTicketUrl: actions['shareTicketUrl']?.toString() ?? '',
      boardingPinBannerText: pinBannerText,
      driverPreferences: dPrefs,
      customerPreferences: cPrefs,
      rideFeatures: rFeatures,
    );
  }
}

class RoutePropertyItem {
  final String propertyId;
  final String title;
  final String type;
  final String city;
  final String location;
  final String address;
  final double price;
  final double pricePerHour;
  final String priceFormatted;
  final String pricePerHourFormatted;
  final double rating;
  final int reviewsCount;
  final String image;
  final double lat;
  final double lng;
  final double distanceFromRouteKm;
  final double distanceKm;
  final String distanceFormatted;
  final bool isNearby;
  final List<String> amenities;
  final String bookUrl;
  final String icon;

  const RoutePropertyItem({
    this.propertyId = '',
    this.title = '',
    this.type = 'Hotel',
    this.city = '',
    this.location = '',
    this.address = '',
    this.price = 0.0,
    this.pricePerHour = 0.0,
    this.priceFormatted = '',
    this.pricePerHourFormatted = '',
    this.rating = 4.8,
    this.reviewsCount = 0,
    this.image = '',
    this.lat = 0.0,
    this.lng = 0.0,
    this.distanceFromRouteKm = 0.0,
    this.distanceKm = 0.0,
    this.distanceFormatted = '',
    this.isNearby = false,
    this.amenities = const [],
    this.bookUrl = '',
    this.icon = 'resort_pin',
  });

  factory RoutePropertyItem.fromJson(Map<String, dynamic> json) {
    num? getNum(dynamic v) => (v is num) ? v : num.tryParse(v?.toString() ?? '');
    final coords = json['coordinates'] is Map ? json['coordinates'] as Map : {};

    final amenitiesList = <String>[];
    if (json['amenities'] is List) {
      for (final item in json['amenities'] as List) {
        amenitiesList.add(item.toString());
      }
    }

    final priceVal = getNum(json['price'] ?? json['pricePerNight'])?.toDouble() ?? 0.0;
    final priceHr = getNum(json['pricePerHour'])?.toDouble() ?? 0.0;
    final distRoute = getNum(json['distanceFromRouteKm'])?.toDouble() ?? 0.0;
    final distLive = getNum(json['distanceKm'])?.toDouble() ?? 0.0;

    return RoutePropertyItem(
      propertyId: json['propertyId']?.toString() ?? json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? json['name']?.toString() ?? '',
      type: json['type']?.toString() ?? 'Hotel',
      city: json['city']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
      address: json['address']?.toString() ?? json['location']?.toString() ?? '',
      price: priceVal,
      pricePerHour: priceHr,
      priceFormatted: json['priceFormatted']?.toString() ?? (priceVal > 0 ? '₹${priceVal.toInt()}/night' : ''),
      pricePerHourFormatted: json['pricePerHourFormatted']?.toString() ?? (priceHr > 0 ? '₹${priceHr.toInt()}/hr' : ''),
      rating: getNum(json['rating'])?.toDouble() ?? 4.8,
      reviewsCount: getNum(json['reviewsCount'] ?? json['reviews'])?.toInt() ?? 0,
      image: json['image']?.toString() ?? '',
      lat: getNum(coords['lat'] ?? json['latitude'])?.toDouble() ?? 0.0,
      lng: getNum(coords['lng'] ?? json['longitude'])?.toDouble() ?? 0.0,
      distanceFromRouteKm: distRoute,
      distanceKm: distLive > 0 ? distLive : distRoute,
      distanceFormatted: json['distanceFormatted']?.toString() ?? (distLive > 0 ? '$distLive km away' : (distRoute > 0 ? '$distRoute km off route' : '')),
      isNearby: json['isNearby'] == true || distLive <= 15,
      amenities: amenitiesList,
      bookUrl: json['bookUrl']?.toString() ?? '',
      icon: json['icon']?.toString() ?? 'resort_pin',
    );
  }
}

const List<RideDriver> mockRideDrivers = [];

// =============================================================================
// Backend API 2.4.0 Models (Corridor, Fare Quote, Live State, Cancellation)
// =============================================================================

/// Module 1: Response from POST /api/rides/validate-corridor-stop
class CorridorValidationResult {
  final bool isOnCorridor;
  final double detourDistanceKm;
  final int detourDurationMinutes;
  final bool isWithinAllowableDetour;
  final LocationPoint? suggestedStopLocation;
  final double recommendedFarePerSeat;
  final double? driverCustomFare;
  final String corridorHighwayName;

  const CorridorValidationResult({
    this.isOnCorridor = false,
    this.detourDistanceKm = 0.0,
    this.detourDurationMinutes = 0,
    this.isWithinAllowableDetour = false,
    this.suggestedStopLocation,
    this.recommendedFarePerSeat = 0.0,
    this.driverCustomFare,
    this.corridorHighwayName = '',
  });

  factory CorridorValidationResult.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> data = json['data'] is Map
        ? Map<String, dynamic>.from(json['data'] as Map)
        : json;

    LocationPoint? stopLoc;
    if (data['suggestedStopLocation'] is Map) {
      final s = Map<String, dynamic>.from(data['suggestedStopLocation'] as Map);
      stopLoc = LocationPoint(
        name: s['name']?.toString() ?? '',
        formattedAddress: s['formattedAddress']?.toString() ?? s['name']?.toString() ?? '',
        latitude: getNum(s['latitude'])?.toDouble() ?? 0.0,
        longitude: getNum(s['longitude'])?.toDouble() ?? 0.0,
      );
    }

    return CorridorValidationResult(
      isOnCorridor: data['isOnCorridor'] == true,
      detourDistanceKm: getNum(data['detourDistanceKm'])?.toDouble() ?? 0.0,
      detourDurationMinutes: getNum(data['detourDurationMinutes'])?.toInt() ?? 0,
      isWithinAllowableDetour: data['isWithinAllowableDetour'] == true,
      suggestedStopLocation: stopLoc,
      recommendedFarePerSeat: getNum(data['recommendedFarePerSeat'])?.toDouble() ?? 0.0,
      driverCustomFare: getNum(data['driverCustomFare'])?.toDouble(),
      corridorHighwayName: data['corridorHighwayName']?.toString() ?? '',
    );
  }
}

/// Module 2: Response from POST /api/rides/quote-fare
class FareQuoteResult {
  final String quoteId;
  final DateTime? expiresAt;
  final double baseFarePerSeat;
  final double seatFareSubtotal;
  final double detourSurcharge;
  final double detourKm;
  final double grossAmount;
  final double promoDiscount;
  final double platformFee;
  final double gstAmount;
  final double totalPayableAmount;
  final double driverEarnings;
  final String currency;

  const FareQuoteResult({
    this.quoteId = '',
    this.expiresAt,
    this.baseFarePerSeat = 0.0,
    this.seatFareSubtotal = 0.0,
    this.detourSurcharge = 0.0,
    this.detourKm = 0.0,
    this.grossAmount = 0.0,
    this.promoDiscount = 0.0,
    this.platformFee = 0.0,
    this.gstAmount = 0.0,
    this.totalPayableAmount = 0.0,
    this.driverEarnings = 0.0,
    this.currency = 'INR',
  });

  factory FareQuoteResult.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> data = json['data'] is Map
        ? Map<String, dynamic>.from(json['data'] as Map)
        : json;

    DateTime? exp;
    if (data['expiresAt'] != null) {
      exp = DateTime.tryParse(data['expiresAt'].toString());
    }

    return FareQuoteResult(
      quoteId: data['quoteId']?.toString() ?? '',
      expiresAt: exp,
      baseFarePerSeat: getNum(data['baseFarePerSeat'])?.toDouble() ?? 0.0,
      seatFareSubtotal: getNum(data['seatFareSubtotal'])?.toDouble() ?? 0.0,
      detourSurcharge: getNum(data['detourSurcharge'])?.toDouble() ?? 0.0,
      detourKm: getNum(data['detourKm'])?.toDouble() ?? 0.0,
      grossAmount: getNum(data['grossAmount'])?.toDouble() ?? 0.0,
      promoDiscount: getNum(data['promoDiscount'])?.toDouble() ?? 0.0,
      platformFee: getNum(data['platformFee'])?.toDouble() ?? 0.0,
      gstAmount: getNum(data['gstAmount'])?.toDouble() ?? 0.0,
      totalPayableAmount: getNum(data['totalPayableAmount'])?.toDouble() ?? 0.0,
      driverEarnings: getNum(data['driverEarnings'])?.toDouble() ?? 0.0,
      currency: data['currency']?.toString() ?? 'INR',
    );
  }
}

/// Module 5: Stop object in LiveRideStatusResult
class LiveRideStop {
  final int index;
  final String name;
  final String type; // 'ORIGIN' | 'PICKUP' | 'DESTINATION'
  final String status; // 'PENDING' | 'ARRIVED' | 'COMPLETED'
  final String expectedArrival;
  final List<Map<String, dynamic>> passengers;

  const LiveRideStop({
    this.index = 0,
    this.name = '',
    this.type = 'PICKUP',
    this.status = 'PENDING',
    this.expectedArrival = '',
    this.passengers = const [],
  });

  factory LiveRideStop.fromJson(Map<String, dynamic> json) {
    final rawPassengers = json['passengers'] is List ? json['passengers'] as List : [];
    return LiveRideStop(
      index: getNum(json['index'])?.toInt() ?? 0,
      name: json['name']?.toString() ?? '',
      type: json['type']?.toString() ?? 'PICKUP',
      status: json['status']?.toString() ?? 'PENDING',
      expectedArrival: json['expectedArrival']?.toString() ?? json['time']?.toString() ?? '',
      passengers: rawPassengers.map((e) => Map<String, dynamic>.from(e as Map)).toList(),
    );
  }
}

/// Module 5: Response from GET /api/rides/:rideId/live-status
class LiveRideStatusResult {
  final String rideId;
  final String tripStatus; // 'SCHEDULED' | 'IN_PROGRESS' | 'COMPLETED'
  final int totalSeats;
  final int occupiedSeats;
  final int availableSeats;
  final int currentStopIndex;
  final List<LiveRideStop> stops;
  final String nextActionRequired;

  const LiveRideStatusResult({
    this.rideId = '',
    this.tripStatus = 'SCHEDULED',
    this.totalSeats = 4,
    this.occupiedSeats = 0,
    this.availableSeats = 4,
    this.currentStopIndex = 0,
    this.stops = const [],
    this.nextActionRequired = '',
  });

  factory LiveRideStatusResult.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> data = json['data'] is Map
        ? Map<String, dynamic>.from(json['data'] as Map)
        : json;

    final rawStops = data['stops'] is List ? data['stops'] as List : [];
    final stopsList = rawStops
        .map((e) => LiveRideStop.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();

    return LiveRideStatusResult(
      rideId: data['rideId']?.toString() ?? '',
      tripStatus: data['tripStatus']?.toString() ?? 'SCHEDULED',
      totalSeats: getNum(data['totalSeats'])?.toInt() ?? 4,
      occupiedSeats: getNum(data['occupiedSeats'])?.toInt() ?? 0,
      availableSeats: getNum(data['availableSeats'])?.toInt() ?? 4,
      currentStopIndex: getNum(data['currentStopIndex'])?.toInt() ?? 0,
      stops: stopsList,
      nextActionRequired: data['nextActionRequired']?.toString() ?? '',
    );
  }
}

/// Module 6: Response from GET /api/bookings/:bookingId/cancellation-preview
class CancellationPreviewResult {
  final String bookingId;
  final double totalPaid;
  final double hoursBeforeDeparture;
  final double cancellationFee;
  final String penaltyTier;
  final double refundAmount;
  final String refundMethod;
  final String policySummary;

  const CancellationPreviewResult({
    this.bookingId = '',
    this.totalPaid = 0.0,
    this.hoursBeforeDeparture = 0.0,
    this.cancellationFee = 0.0,
    this.penaltyTier = '',
    this.refundAmount = 0.0,
    this.refundMethod = 'ORIGINAL_PAYMENT_SOURCE',
    this.policySummary = '',
  });

  factory CancellationPreviewResult.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> data = json['data'] is Map
        ? Map<String, dynamic>.from(json['data'] as Map)
        : json;

    return CancellationPreviewResult(
      bookingId: data['bookingId']?.toString() ?? '',
      totalPaid: getNum(data['totalPaid'])?.toDouble() ?? 0.0,
      hoursBeforeDeparture: getNum(data['hoursBeforeDeparture'])?.toDouble() ?? 0.0,
      cancellationFee: getNum(data['cancellationFee'])?.toDouble() ?? 0.0,
      penaltyTier: data['penaltyTier']?.toString() ?? '',
      refundAmount: getNum(data['refundAmount'])?.toDouble() ?? 0.0,
      refundMethod: data['refundMethod']?.toString() ?? 'ORIGINAL_PAYMENT_SOURCE',
      policySummary: data['policySummary']?.toString() ?? '',
    );
  }
}

