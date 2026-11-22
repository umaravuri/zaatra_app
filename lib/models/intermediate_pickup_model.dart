import 'place_location_model.dart';

/// Data model representing an intermediate pickup point added by a driver.
class IntermediatePickupModel {
  String location;
  String pinCode;
  String? landmark;
  String time;
  String price;
  LocationPoint? locationPoint;

  IntermediatePickupModel({
    required this.location,
    this.pinCode = '',
    this.landmark,
    required this.time,
    required this.price,
    this.locationPoint,
  });

  /// Formatted JSON map for future backend POST API payload
  Map<String, dynamic> toJson() {
    return {
      'location': location,
      'pinCode': pinCode,
      'landmark': landmark ?? '',
      'time': time,
      'price': double.tryParse(price.replaceAll(RegExp(r'[^0-9.]'), '')) ?? price,
      if (locationPoint != null) ...{
        'latitude': locationPoint!.latitude,
        'longitude': locationPoint!.longitude,
        'formattedAddress': locationPoint!.formattedAddress,
      },
    };
  }

  factory IntermediatePickupModel.fromJson(Map<String, dynamic> json) {
    return IntermediatePickupModel(
      location: json['location']?.toString() ?? '',
      pinCode: json['pinCode']?.toString() ?? '',
      landmark: json['landmark']?.toString(),
      time: json['time']?.toString() ?? '',
      price: json['price']?.toString() ?? '',
      locationPoint: json['latitude'] != null && json['longitude'] != null
          ? LocationPoint(
              name: json['location']?.toString() ?? '',
              formattedAddress: json['formattedAddress']?.toString() ?? '',
              latitude: (json['latitude'] as num).toDouble(),
              longitude: (json['longitude'] as num).toDouble(),
            )
          : null,
    );
  }
}

/// Model representing a verified intermediate stop returned by the Highway Corridor Suggestions API.
class CorridorStopItem {
  final int stopNumber;
  final String name;
  final String location;
  final String address;
  final String landmark;
  final String pincode;
  final int distanceFromStartKm;
  final String distanceFromStart;
  final int distanceToDestinationKm;
  final String distanceToDestination;
  final int durationFromStartMinutes;
  final String time;
  final String calculatedTime;
  final num price;
  final num priceToDestination;
  final num priceFromOrigin;
  final num suggestedPrice;
  final String amountText;
  final bool isOnRoute;
  final bool isSelectable;

  const CorridorStopItem({
    this.stopNumber = 1,
    this.name = '',
    this.location = '',
    this.address = '',
    this.landmark = '',
    this.pincode = '',
    this.distanceFromStartKm = 0,
    this.distanceFromStart = '',
    this.distanceToDestinationKm = 0,
    this.distanceToDestination = '',
    this.durationFromStartMinutes = 0,
    this.time = '',
    this.calculatedTime = '',
    this.price = 0,
    this.priceToDestination = 0,
    this.priceFromOrigin = 0,
    this.suggestedPrice = 0,
    this.amountText = '',
    this.isOnRoute = true,
    this.isSelectable = true,
  });

  factory CorridorStopItem.fromJson(Map<String, dynamic> json) {
    num parseNum(dynamic val, [num fallback = 0]) {
      if (val == null) return fallback;
      if (val is num) return val;
      return num.tryParse(val.toString()) ?? fallback;
    }

    int parseInt(dynamic val, [int fallback = 0]) {
      if (val == null) return fallback;
      if (val is int) return val;
      if (val is num) return val.toInt();
      return int.tryParse(val.toString().replaceAll(RegExp(r'[^0-9]'), '')) ?? fallback;
    }

    final pToDest = parseNum(json['priceToDestination'] ?? json['price'] ?? json['suggestedPrice']);
    final pFromOrig = parseNum(json['priceFromOrigin']);
    final sugPrice = parseNum(json['suggestedPrice'] ?? pToDest);

    return CorridorStopItem(
      stopNumber: parseInt(json['stopNumber'], 1),
      name: json['name']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      landmark: json['landmark']?.toString() ?? '',
      pincode: json['pincode']?.toString() ?? '',
      distanceFromStartKm: parseInt(json['distanceFromStartKm']),
      distanceFromStart: json['distanceFromStart']?.toString() ?? '',
      distanceToDestinationKm: parseInt(json['distanceToDestinationKm']),
      distanceToDestination: json['distanceToDestination']?.toString() ?? '',
      durationFromStartMinutes: parseInt(json['durationFromStartMinutes']),
      time: json['time']?.toString() ?? json['calculatedTime']?.toString() ?? '',
      calculatedTime: json['calculatedTime']?.toString() ?? json['time']?.toString() ?? '',
      price: pToDest,
      priceToDestination: pToDest,
      priceFromOrigin: pFromOrig,
      suggestedPrice: sugPrice,
      amountText: json['amountText']?.toString() ?? '₹ ${sugPrice.toInt()}',
      isOnRoute: json['isOnRoute'] == true,
      isSelectable: json['isSelectable'] != false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'stopNumber': stopNumber,
      'name': name,
      'location': location,
      'address': address,
      'landmark': landmark,
      'pincode': pincode,
      'distanceFromStartKm': distanceFromStartKm,
      'distanceFromStart': distanceFromStart,
      'distanceToDestinationKm': distanceToDestinationKm,
      'distanceToDestination': distanceToDestination,
      'durationFromStartMinutes': durationFromStartMinutes,
      'time': time,
      'calculatedTime': calculatedTime,
      'price': price,
      'priceToDestination': priceToDestination,
      'priceFromOrigin': priceFromOrigin,
      'suggestedPrice': suggestedPrice,
      'amountText': amountText,
      'isOnRoute': isOnRoute,
      'isSelectable': isSelectable,
    };
  }
}

/// Response container for Highway Corridor Suggestions API.
class CorridorStopsResult {
  final bool success;
  final bool allowed;
  final String corridor;
  final String origin;
  final String destination;
  final String departureTime;
  final int totalDistanceKm;
  final num totalTripPricePerSeat;
  final int count;
  final List<CorridorStopItem> stops;
  final String? errorCode;
  final String? errorMessage;

  const CorridorStopsResult({
    this.success = false,
    this.allowed = true,
    this.corridor = '',
    this.origin = '',
    this.destination = '',
    this.departureTime = '',
    this.totalDistanceKm = 0,
    this.totalTripPricePerSeat = 0,
    this.count = 0,
    this.stops = const [],
    this.errorCode,
    this.errorMessage,
  });

  factory CorridorStopsResult.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> map = (json['data'] is Map)
        ? Map<String, dynamic>.from(json['data'] as Map)
        : json;
    final rawStops = (map['stops'] ?? json['stops']) as List<dynamic>? ?? [];
    final parsedStops = rawStops.map<CorridorStopItem>((m) {
      if (m is Map<String, dynamic>) return CorridorStopItem.fromJson(m);
      if (m is Map) return CorridorStopItem.fromJson(Map<String, dynamic>.from(m));
      return const CorridorStopItem();
    }).toList();

    return CorridorStopsResult(
      success: json['success'] == true || map['success'] == true,
      allowed: json['allowed'] != false && map['allowed'] != false,
      corridor: (map['corridor'] ?? json['corridor'])?.toString() ?? '',
      origin: (map['origin'] ?? json['origin'])?.toString() ?? '',
      destination: (map['destination'] ?? json['destination'])?.toString() ?? '',
      departureTime: (map['departureTime'] ?? json['departureTime'])?.toString() ?? '',
      totalDistanceKm: ((map['totalDistanceKm'] ?? json['totalDistanceKm']) is num)
          ? ((map['totalDistanceKm'] ?? json['totalDistanceKm']) as num).toInt()
          : 0,
      totalTripPricePerSeat: ((map['totalTripPricePerSeat'] ?? json['totalTripPricePerSeat']) is num)
          ? (map['totalTripPricePerSeat'] ?? json['totalTripPricePerSeat']) as num
          : 0,
      count: (map['count'] ?? json['count']) is int
          ? (map['count'] ?? json['count']) as int
          : parsedStops.length,
      stops: parsedStops,
      errorCode: (json['error'] ?? json['code'] ?? map['error'] ?? map['code'])?.toString(),
      errorMessage: (json['message'] ?? map['message'])?.toString(),
    );
  }

  factory CorridorStopsResult.error({
    required String code,
    required String message,
  }) {
    return CorridorStopsResult(
      success: false,
      allowed: false,
      errorCode: code,
      errorMessage: message,
      stops: const [],
    );
  }
}
