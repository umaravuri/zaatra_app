enum PreferenceItemType { checkbox, counter }

class PreferenceItem {
  final String id;
  final String key;
  final String label;
  final PreferenceItemType type;
  bool enabled;
  int count;
  final bool isCustom;
  final String? icon;

  PreferenceItem({
    required this.id,
    required this.key,
    required this.label,
    required this.type,
    this.enabled = false,
    this.count = 0,
    this.isCustom = false,
    this.icon,
  });

  factory PreferenceItem.fromJson(Map<String, dynamic> json, {bool isCustom = false}) {
    final typeStr = json['type']?.toString().toLowerCase() ?? 'checkbox';
    return PreferenceItem(
      id: json['id']?.toString() ?? '',
      key: json['key']?.toString() ?? json['id']?.toString() ?? '',
      label: json['label']?.toString() ?? json['title']?.toString() ?? '',
      type: typeStr == 'counter' ? PreferenceItemType.counter : PreferenceItemType.checkbox,
      enabled: json['enabled'] == true,
      count: (json['count'] is num) ? (json['count'] as num).toInt() : (int.tryParse(json['count']?.toString() ?? '') ?? 0),
      isCustom: isCustom || json['isCustom'] == true,
      icon: json['icon']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'key': key,
    'label': label,
    'type': type == PreferenceItemType.counter ? 'counter' : 'checkbox',
    'enabled': enabled,
    'count': count,
    'isCustom': isCustom,
    if (icon != null) 'icon': icon,
  };
}

class PreferenceSection {
  final String title;
  final List<PreferenceItem> items;
  final String addButtonTitle;
  final String category; // 'driver', 'customer', 'feature'

  PreferenceSection({
    required this.title,
    required this.items,
    required this.addButtonTitle,
    required this.category,
  });

  factory PreferenceSection.fromJson(Map<String, dynamic> json, String defaultCategory) {
    final rawItems = json['items'] is List ? json['items'] as List : [];
    final addBtn = json['addButton'] is Map ? json['addButton'] as Map<String, dynamic> : {};
    return PreferenceSection(
      title: json['title']?.toString() ?? '',
      items: rawItems
          .whereType<Map<String, dynamic>>()
          .map((item) => PreferenceItem.fromJson(item))
          .toList(),
      addButtonTitle: addBtn['title']?.toString() ?? '+ Add Custom',
      category: addBtn['category']?.toString() ?? defaultCategory,
    );
  }
}

class RidePreferenceTemplate {
  final bool success;
  final String screenTitle;
  final PreferenceSection driverPreferences;
  final PreferenceSection customerPreferences;
  final PreferenceSection rideFeatures;
  final String bookingMode;
  final String rideType;
  final bool acceptDoorToDoor;
  final num? wholeCarPrice;
  final String smoking;
  final bool ac;
  final bool usbCharging;
  final bool wifi;

  RidePreferenceTemplate({
    required this.success,
    required this.screenTitle,
    required this.driverPreferences,
    required this.customerPreferences,
    required this.rideFeatures,
    this.bookingMode = 'instant_booking',
    this.rideType = 'door_to_door',
    this.acceptDoorToDoor = true,
    this.wholeCarPrice,
    this.smoking = 'not_allowed',
    this.ac = true,
    this.usbCharging = false,
    this.wifi = false,
  });

  factory RidePreferenceTemplate.fromJson(Map<String, dynamic> json) {
    final driverMap = json['driverPreferences'] is Map ? json['driverPreferences'] as Map<String, dynamic> : <String, dynamic>{};
    final custMap = json['customerPreferences'] is Map ? json['customerPreferences'] as Map<String, dynamic> : <String, dynamic>{};
    final featMap = json['rideFeatures'] is Map ? json['rideFeatures'] as Map<String, dynamic> : <String, dynamic>{};

    final bookingModeStr = driverMap['bookingMode']?.toString() ?? 'instant_booking';
    final rideTypeStr = driverMap['rideType']?.toString() ?? 'door_to_door';
    final acceptDoorToDoorBool = driverMap['acceptDoorToDoor'] == true || rideTypeStr == 'door_to_door';
    final wholeCarPriceNum = driverMap['wholeCarPrice'] as num?;

    final smokingStr = custMap['smoking']?.toString() ??
        (custMap['smokingPolicy'] is Map ? custMap['smokingPolicy']['selected']?.toString() : null) ??
        'not_allowed';

    final acBool = featMap['ac'] == true;
    final usbBool = featMap['usbCharging'] == true;
    final wifiBool = featMap['wifi'] == true;

    final driverSection = PreferenceSection.fromJson(
      driverMap,
      'driver',
    );

    final custSectionRaw = PreferenceSection.fromJson(
      custMap,
      'customer',
    );
    // Remove luggage and mediumBag
    final filteredCustItems = custSectionRaw.items
        .where((item) =>
            item.key != 'luggage' &&
            item.key != 'mediumBag' &&
            item.id != 'cp-luggage' &&
            item.id != 'cp-medium-bag' &&
            !item.label.toLowerCase().contains('luggage') &&
            !item.label.toLowerCase().contains('medium bag'))
        .toList();

    // Ensure smoking allowed or not allowed is present
    final hasSmoking = filteredCustItems.any((item) =>
        item.key == 'smokingAllowed' ||
        item.key == 'smoking' ||
        item.id == 'cp-smoking' ||
        item.label.toLowerCase().contains('smoking'));

    if (!hasSmoking) {
      filteredCustItems.insert(
        0,
        PreferenceItem(
          id: 'cp-smoking',
          key: 'smokingAllowed',
          label: 'Smoking allowed or not allowed',
          type: PreferenceItemType.checkbox,
          enabled: json['customerPreferences']?['smokingAllowed'] == true ||
              json['customerPreferences']?['smoking'] == true ||
              json['smokingAllowed'] == true ||
              json['smoking'] == true,
          icon: 'smoking',
        ),
      );
    }

    final customerSection = PreferenceSection(
      title: custSectionRaw.title.isNotEmpty ? custSectionRaw.title : 'Customer Preferences',
      items: filteredCustItems,
      addButtonTitle: custSectionRaw.addButtonTitle,
      category: 'customer',
    );

    final featSectionRaw = PreferenceSection.fromJson(
      json['rideFeatures'] is Map ? json['rideFeatures'] as Map<String, dynamic> : {},
      'feature',
    );
    // Remove wifi
    final filteredFeatItems = featSectionRaw.items
        .where((item) =>
            item.key != 'wifi' &&
            item.id != 'rf-wifi' &&
            !item.label.toLowerCase().contains('wi-fi') &&
            !item.label.toLowerCase().contains('wifi'))
        .toList();

    // Ensure AC is present
    final hasAc = filteredFeatItems.any((item) =>
        item.key == 'ac' ||
        item.key == 'airConditioning' ||
        item.id == 'rf-ac' ||
        item.label.toLowerCase() == 'ac' ||
        item.label.toLowerCase().contains('air condition'));

    if (!hasAc) {
      filteredFeatItems.insert(
        0,
        PreferenceItem(
          id: 'rf-ac',
          key: 'ac',
          label: 'AC',
          type: PreferenceItemType.checkbox,
          enabled: json['rideFeatures']?['ac'] == true ||
              json['rideFeatures']?['airConditioning'] == true ||
              json['ac'] == true,
          icon: 'ac',
        ),
      );
    }

    // Ensure USB charging is present
    final hasUsb = filteredFeatItems.any((item) =>
        item.key == 'usbCharging' || item.id == 'rf-usb-charging' || item.label.toLowerCase().contains('usb'));
    if (!hasUsb) {
      filteredFeatItems.add(
        PreferenceItem(
          id: 'rf-usb-charging',
          key: 'usbCharging',
          label: 'USB charging',
          type: PreferenceItemType.checkbox,
          enabled: json['rideFeatures']?['usbCharging'] == true || json['usbCharging'] == true,
          icon: 'usb',
        ),
      );
    }

    final rideFeaturesSection = PreferenceSection(
      title: featSectionRaw.title.isNotEmpty ? featSectionRaw.title : 'Ride Features',
      items: filteredFeatItems,
      addButtonTitle: featSectionRaw.addButtonTitle,
      category: 'feature',
    );

    return RidePreferenceTemplate(
      success: json['success'] == true,
      screenTitle: json['screenTitle']?.toString() ?? 'Preference',
      driverPreferences: driverSection,
      customerPreferences: customerSection,
      rideFeatures: rideFeaturesSection,
      bookingMode: bookingModeStr,
      rideType: rideTypeStr,
      acceptDoorToDoor: acceptDoorToDoorBool,
      wholeCarPrice: wholeCarPriceNum,
      smoking: smokingStr,
      ac: acBool,
      usbCharging: usbBool,
      wifi: wifiBool,
    );
  }

  /// Default fallback template strictly matching user specifications
  factory RidePreferenceTemplate.defaultTemplate() {
    return RidePreferenceTemplate(
      success: true,
      screenTitle: 'Preference',
      driverPreferences: PreferenceSection(
        title: 'Driver Preferences',
        items: [
          PreferenceItem(
            id: 'dp-auto-approval',
            key: 'autoApproval',
            label: 'Auto approval of passenger',
            type: PreferenceItemType.checkbox,
            enabled: false,
          ),
        ],
        addButtonTitle: '+ Add Custom Preference',
        category: 'driver',
      ),
      customerPreferences: PreferenceSection(
        title: 'Customer Preferences',
        items: [
          PreferenceItem(
            id: 'cp-smoking',
            key: 'smokingAllowed',
            label: 'Smoking allowed or not allowed',
            type: PreferenceItemType.checkbox,
            enabled: false,
            icon: 'smoking',
          ),
        ],
        addButtonTitle: '+ Add Custom Preference',
        category: 'customer',
      ),
      rideFeatures: PreferenceSection(
        title: 'Ride Features',
        items: [
          PreferenceItem(
            id: 'rf-ac',
            key: 'ac',
            label: 'AC',
            type: PreferenceItemType.checkbox,
            enabled: false,
            icon: 'ac',
          ),
          PreferenceItem(
            id: 'rf-usb-charging',
            key: 'usbCharging',
            label: 'USB charging',
            type: PreferenceItemType.checkbox,
            enabled: false,
            icon: 'usb',
          ),
        ],
        addButtonTitle: '+ Add Ride Feature',
        category: 'feature',
      ),
    );
  }
}
