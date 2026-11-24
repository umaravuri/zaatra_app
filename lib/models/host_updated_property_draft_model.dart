class HostUpdatedPropertyDraft {
  final String propertyId;
  final String propertyType;
  final String listingCountMode; // 'single' or 'multiple'
  final String locationInput;
  final String hNo;
  final String street;
  final String city;
  final String postalCode;
  final String country;
  final double latitude;
  final double longitude;
  final bool updateAddressWithPin;
  final bool useChannelManager;
  final String propertyName;
  final String starRating; // 'N/A', '1', '2', '3', '4', '5'
  final bool isChainOrGroup;
  final List<String> facilities;
  final Map<String, String> facilityPricing; // e.g. {'Wifi': 'Included', 'Swimming Pool': 'Extra Charge'}
  final bool servesBreakfast;
  final bool allowsChildren;
  final List<String> staffLanguages;
  final String allowsPets; // 'yes', 'upon_request', 'no'
  final String petFeeMode; // 'free', 'charges'
  final List<Map<String, dynamic>> units;
  final Map<String, dynamic> payoutDetails;
  final String invoiceName;
  final bool invoiceAddressSame;
  final String entityType; // 'individual' or 'business'
  final List<Map<String, String>> owners; // [{'firstName': '', 'lastName': '', 'dob': ''}]
  final Map<String, String> businessRep; // {firstName, dob, designation, mobile, email, legalName, businessType}
  final bool isGstRegistered;
  final String gstNumber;
  final String panNumber;
  final String guestPaymentMethod;
  final String registrationGoal;
  final bool isLegitimateCertified;
  final bool acceptedTerms;

  const HostUpdatedPropertyDraft({
    this.propertyId = '',
    this.propertyType = '',
    this.listingCountMode = 'multiple',
    this.locationInput = '',
    this.hNo = '',
    this.street = '',
    this.city = '',
    this.postalCode = '',
    this.country = 'INDIA',
    this.latitude = 17.4486,
    this.longitude = 78.3908,
    this.updateAddressWithPin = true,
    this.useChannelManager = false,
    this.propertyName = '',
    this.starRating = 'N/A',
    this.isChainOrGroup = false,
    this.facilities = const [],
    this.facilityPricing = const {},
    this.servesBreakfast = true,
    this.allowsChildren = true,
    this.staffLanguages = const ['Hindi', 'English'],
    this.allowsPets = 'yes',
    this.petFeeMode = 'free',
    this.units = const [],
    this.payoutDetails = const {},
    this.invoiceName = '',
    this.invoiceAddressSame = true,
    this.entityType = 'individual',
    this.owners = const [],
    this.businessRep = const {},
    this.isGstRegistered = true,
    this.gstNumber = '',
    this.panNumber = '',
    this.guestPaymentMethod = 'direct_cards',
    this.registrationGoal = 'bookings',
    this.isLegitimateCertified = false,
    this.acceptedTerms = true,
  });

  String get listingScope =>
      listingCountMode.toLowerCase().contains('single') ? 'SINGLE_UNIT' : 'MULTIPLE_UNITS';

  HostUpdatedPropertyDraft copyWith({
    String? propertyId,
    String? propertyType,
    String? listingCountMode,
    String? locationInput,
    String? hNo,
    String? street,
    String? city,
    String? postalCode,
    String? country,
    double? latitude,
    double? longitude,
    bool? updateAddressWithPin,
    bool? useChannelManager,
    String? propertyName,
    String? starRating,
    bool? isChainOrGroup,
    List<String>? facilities,
    Map<String, String>? facilityPricing,
    bool? servesBreakfast,
    bool? allowsChildren,
    List<String>? staffLanguages,
    String? allowsPets,
    String? petFeeMode,
    List<Map<String, dynamic>>? units,
    Map<String, dynamic>? payoutDetails,
    String? invoiceName,
    bool? invoiceAddressSame,
    String? entityType,
    List<Map<String, String>>? owners,
    Map<String, String>? businessRep,
    bool? isGstRegistered,
    String? gstNumber,
    String? panNumber,
    String? guestPaymentMethod,
    String? registrationGoal,
    bool? isLegitimateCertified,
    bool? acceptedTerms,
  }) {
    return HostUpdatedPropertyDraft(
      propertyId: propertyId ?? this.propertyId,
      propertyType: propertyType ?? this.propertyType,
      listingCountMode: listingCountMode ?? this.listingCountMode,
      locationInput: locationInput ?? this.locationInput,
      hNo: hNo ?? this.hNo,
      street: street ?? this.street,
      city: city ?? this.city,
      postalCode: postalCode ?? this.postalCode,
      country: country ?? this.country,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      updateAddressWithPin: updateAddressWithPin ?? this.updateAddressWithPin,
      useChannelManager: useChannelManager ?? this.useChannelManager,
      propertyName: propertyName ?? this.propertyName,
      starRating: starRating ?? this.starRating,
      isChainOrGroup: isChainOrGroup ?? this.isChainOrGroup,
      facilities: facilities ?? this.facilities,
      facilityPricing: facilityPricing ?? this.facilityPricing,
      servesBreakfast: servesBreakfast ?? this.servesBreakfast,
      allowsChildren: allowsChildren ?? this.allowsChildren,
      staffLanguages: staffLanguages ?? this.staffLanguages,
      allowsPets: allowsPets ?? this.allowsPets,
      petFeeMode: petFeeMode ?? this.petFeeMode,
      units: units ?? this.units,
      payoutDetails: payoutDetails ?? this.payoutDetails,
      invoiceName: invoiceName ?? this.invoiceName,
      invoiceAddressSame: invoiceAddressSame ?? this.invoiceAddressSame,
      entityType: entityType ?? this.entityType,
      owners: owners ?? this.owners,
      businessRep: businessRep ?? this.businessRep,
      isGstRegistered: isGstRegistered ?? this.isGstRegistered,
      gstNumber: gstNumber ?? this.gstNumber,
      panNumber: panNumber ?? this.panNumber,
      guestPaymentMethod: guestPaymentMethod ?? this.guestPaymentMethod,
      registrationGoal: registrationGoal ?? this.registrationGoal,
      isLegitimateCertified: isLegitimateCertified ?? this.isLegitimateCertified,
      acceptedTerms: acceptedTerms ?? this.acceptedTerms,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'propertyId': propertyId,
      'propertyType': propertyType,
      'listingCountMode': listingCountMode,
      'locationInput': locationInput,
      'hNo': hNo,
      'street': street,
      'city': city,
      'postalCode': postalCode,
      'country': country,
      'latitude': latitude,
      'longitude': longitude,
      'updateAddressWithPin': updateAddressWithPin,
      'useChannelManager': useChannelManager,
      'propertyName': propertyName,
      'starRating': starRating,
      'isChainOrGroup': isChainOrGroup,
      'facilities': facilities,
      'facilityPricing': facilityPricing,
      'servesBreakfast': servesBreakfast,
      'allowsChildren': allowsChildren,
      'staffLanguages': staffLanguages,
      'allowsPets': allowsPets,
      'petFeeMode': petFeeMode,
      'units': units,
      'payoutDetails': payoutDetails,
      'invoiceName': invoiceName,
      'invoiceAddressSame': invoiceAddressSame,
      'entityType': entityType,
      'owners': owners,
      'businessRep': businessRep,
      'isGstRegistered': isGstRegistered,
      'gstNumber': gstNumber,
      'panNumber': panNumber,
      'guestPaymentMethod': guestPaymentMethod,
      'registrationGoal': registrationGoal,
      'isLegitimateCertified': isLegitimateCertified,
      'acceptedTerms': acceptedTerms,
    };
  }

  factory HostUpdatedPropertyDraft.fromMap(Map<String, dynamic> map) {
    return HostUpdatedPropertyDraft(
      propertyId: map['propertyId'] ?? '',
      propertyType: map['propertyType'] ?? '',
      listingCountMode: map['listingCountMode'] ?? 'multiple',
      locationInput: map['locationInput'] ?? '',
      hNo: map['hNo'] ?? '',
      street: map['street'] ?? '',
      city: map['city'] ?? '',
      postalCode: map['postalCode'] ?? '',
      country: map['country'] ?? 'INDIA',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 17.4486,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 78.3908,
      updateAddressWithPin: map['updateAddressWithPin'] ?? true,
      useChannelManager: map['useChannelManager'] ?? false,
      propertyName: map['propertyName'] ?? '',
      starRating: map['starRating'] ?? 'N/A',
      isChainOrGroup: map['isChainOrGroup'] ?? false,
      facilities: List<String>.from(map['facilities'] ?? const []),
      facilityPricing: Map<String, String>.from(map['facilityPricing'] ?? const {}),
      servesBreakfast: map['servesBreakfast'] ?? true,
      allowsChildren: map['allowsChildren'] ?? true,
      staffLanguages: List<String>.from(map['staffLanguages'] ?? const ['Hindi', 'English']),
      allowsPets: map['allowsPets'] ?? 'yes',
      petFeeMode: map['petFeeMode'] ?? 'free',
      units: List<Map<String, dynamic>>.from(map['units'] ?? const []),
      payoutDetails: Map<String, dynamic>.from(map['payoutDetails'] ?? const {}),
      invoiceName: map['invoiceName'] ?? '',
      invoiceAddressSame: map['invoiceAddressSame'] ?? true,
      entityType: map['entityType'] ?? 'individual',
      owners: (map['owners'] as List?)
              ?.map((e) => Map<String, String>.from(e as Map))
              .toList() ??
          const [],
      businessRep: Map<String, String>.from(map['businessRep'] ?? const {}),
      isGstRegistered: map['isGstRegistered'] ?? true,
      gstNumber: map['gstNumber'] ?? '',
      panNumber: map['panNumber'] ?? '',
      guestPaymentMethod: map['guestPaymentMethod'] ?? 'direct_cards',
      registrationGoal: map['registrationGoal'] ?? 'bookings',
      isLegitimateCertified: map['isLegitimateCertified'] ?? false,
      acceptedTerms: map['acceptedTerms'] ?? true,
    );
  }
}

