import 'package:flutter/foundation.dart';
import '../models/heritage_place_model.dart';
import '../models/hotel_model.dart';
import 'api_service.dart';

class HeritageService {
  /// Available Monument Types for Filtering
  static List<HeritageMonumentType> get filterTypes => HeritageMonumentType.values;

  /// Default Supported Heritage Cities
  static const List<String> defaultCities = ['Agra', 'Hyderabad', 'Jaipur', 'Mysuru'];

  static List<HeritagePlace>? _cachedMasterPlaces;

  /// Utility to normalize city names into standard Title Case
  static String normalizeCityName(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '';
    return trimmed.split(RegExp(r'\s+')).map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  /// Returns the master, unfiltered list of all heritage places
  static Future<List<HeritagePlace>> getAllMasterPlaces({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedMasterPlaces != null && _cachedMasterPlaces!.isNotEmpty) {
      return _cachedMasterPlaces!;
    }

    try {
      final response = await ApiService.get('/heritage?limit=100');
      if (response['success'] == true) {
        final data = response['data'] is Map<String, dynamic>
            ? response['data'] as Map<String, dynamic>
            : response;
        final resObj = HeritagePlacesResponse.fromJson(data);
        if (resObj.places.isNotEmpty) {
          _cachedMasterPlaces = resObj.places;
          return resObj.places;
        }
      }
    } catch (e) {
      debugPrint('HeritageService.getAllMasterPlaces error: $e');
    }

    _cachedMasterPlaces = _getFallbackPlaces();
    return _cachedMasterPlaces!;
  }

  /// Returns a map of city name to number of monuments across all places
  static Map<String, int> getAvailableCitiesWithCounts([List<HeritagePlace>? places]) {
    final list = (places != null && places.isNotEmpty) ? places : _getFallbackPlaces();
    final counts = <String, int>{};
    for (final p in list) {
      final c = normalizeCityName(p.city);
      if (c.isNotEmpty) {
        counts[c] = (counts[c] ?? 0) + 1;
      }
    }
    for (final defCity in defaultCities) {
      final normDef = normalizeCityName(defCity);
      counts.putIfAbsent(normDef, () => 0);
    }
    return counts;
  }

  /// 1. Get All Places (City-Wise / Multi-City / Search / Filters / Sorting)
  /// Endpoint: GET /api/heritage?city=...&category=...&search=...&sort=...&page=...&limit=...
  static Future<HeritagePlacesResponse> getPlaces({
    HeritageFilterState? filterState,
    String? city,
    List<String>? selectedCities,
    HeritageMonumentType? monumentType,
    String? category,
    String? search,
    HeritageSortOption sort = HeritageSortOption.topRated,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final state = filterState ??
          HeritageFilterState(
            selectedType: monumentType ??
                (category != null
                    ? HeritageMonumentType.fromCategory(category)
                    : HeritageMonumentType.all),
            city: city,
            selectedCities: selectedCities ?? const [],
            searchQuery: search,
            sortOption: sort,
          );

      final queryParams = state.toQueryParams(page: page, limit: limit);
      final queryString = Uri(queryParameters: queryParams).query;
      final endpoint = '/heritage${queryString.isNotEmpty ? '?$queryString' : ''}';

      final response = await ApiService.get(endpoint);
      if (response['success'] == true) {
        final data = response['data'] is Map<String, dynamic>
            ? response['data'] as Map<String, dynamic>
            : response;
        var resObj = HeritagePlacesResponse.fromJson(data);
        if (state.selectedCities.isNotEmpty) {
          final lowerSelected = state.selectedCities.map((c) => c.toLowerCase().trim()).toSet();
          final filteredPlaces = resObj.places.where((p) => lowerSelected.contains(p.city.toLowerCase().trim())).toList();
          resObj = HeritagePlacesResponse(
            success: resObj.success,
            count: filteredPlaces.length,
            total: filteredPlaces.length,
            page: resObj.page,
            totalPages: resObj.totalPages,
            places: filteredPlaces,
          );
        }
        return resObj;
      }
    } catch (e) {
      debugPrint('HeritageService.getPlaces error: $e');
    }

    // Fallback places list
    final fallbackList = _getFallbackPlaces();
    var filtered = List<HeritagePlace>.from(fallbackList);

    final activeSelectedCities = filterState?.selectedCities ?? selectedCities ?? const [];
    if (activeSelectedCities.isNotEmpty) {
      final lowerSelected = activeSelectedCities.map((c) => c.toLowerCase().trim()).toSet();
      filtered = filtered.where((p) => lowerSelected.contains(p.city.toLowerCase().trim())).toList();
    } else {
      final activeCity = filterState?.city ?? city;
      if (activeCity != null && activeCity.isNotEmpty && activeCity.toLowerCase() != 'all') {
        filtered = filtered.where((p) => p.city.toLowerCase().trim() == activeCity.toLowerCase().trim()).toList();
      }
    }

    final activeType = filterState?.selectedType ?? monumentType ?? (category != null ? HeritageMonumentType.fromCategory(category) : HeritageMonumentType.all);
    if (activeType != HeritageMonumentType.all) {
      filtered = filtered.where((p) => p.monumentType == activeType || p.category.toLowerCase() == activeType.apiCategory.toLowerCase()).toList();
    }

    final activeSearch = filterState?.searchQuery ?? search;
    if (activeSearch != null && activeSearch.isNotEmpty) {
      filtered = filtered.where((p) =>
          p.title.toLowerCase().contains(activeSearch.toLowerCase()) ||
          p.city.toLowerCase().contains(activeSearch.toLowerCase()) ||
          p.tagline.toLowerCase().contains(activeSearch.toLowerCase())).toList();
    }

    final activeSort = filterState?.sortOption ?? sort;
    switch (activeSort) {
      case HeritageSortOption.topRated:
        filtered.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case HeritageSortOption.mostVisited:
        filtered.sort((a, b) => b.reviewsCount.compareTo(a.reviewsCount));
        break;
      case HeritageSortOption.mustVisit:
        filtered.sort((a, b) => (b.mustVisit ? 1 : 0).compareTo(a.mustVisit ? 1 : 0));
        break;
      case HeritageSortOption.nameAsc:
        filtered.sort((a, b) => a.title.compareTo(b.title));
        break;
    }

    return HeritagePlacesResponse(
      success: true,
      count: filtered.length,
      total: filtered.length,
      page: 1,
      totalPages: 1,
      places: filtered,
    );
  }

  /// 2. Get Famous & Featured Places (For App Home Screen & Carousel)
  /// Endpoint: GET /api/heritage/famous
  static Future<List<HeritagePlace>> getFamousPlaces() async {
    try {
      final response = await ApiService.get('/heritage/famous');
      if (response['success'] == true) {
        final data = response['data'] is Map<String, dynamic>
            ? response['data'] as Map<String, dynamic>
            : response;
        final placesList = data['places'] as List<dynamic>?;
        if (placesList != null) {
          return placesList
              .map((p) => HeritagePlace.fromJson(p as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('HeritageService.getFamousPlaces error: $e');
    }

    return _getFallbackPlaces().where((p) => p.isFeatured || p.isPopular).toList();
  }

  /// 3. Get Full Place Details (For Detail / Profile Screen)
  /// Endpoint: GET /api/heritage/:id
  static Future<HeritagePlace?> getPlaceDetails(String id) async {
    try {
      final response = await ApiService.get('/heritage/$id');
      if (response['success'] == true) {
        final data = response['data'] is Map<String, dynamic>
            ? response['data'] as Map<String, dynamic>
            : response;
        final placeJson = data['place'] ?? data['data'] ?? data;
        if (placeJson is Map<String, dynamic>) {
          return HeritagePlace.fromJson(placeJson);
        }
      }
    } catch (e) {
      debugPrint('HeritageService.getPlaceDetails error: $e');
    }

    // Try finding in fallback list
    final fallback = _getFallbackPlaces().firstWhere(
      (p) => p.placeId == id || p.id == id,
      orElse: () => _getFallbackPlaces().first,
    );
    return fallback;
  }

  /// 4. Get Nearby Hotels / Stays for a Heritage Destination (GET API endpoint)
  /// Endpoint: GET /api/heritage/:id/nearby-properties?radius=5&limit=10&sort=distance_asc
  static Future<List<Hotel>> getNearbyHotels({
    required String city,
    String? placeId,
    double radius = 5,
    int limit = 10,
    String sort = 'distance_asc',
  }) async {
    try {
      if (placeId != null && placeId.isNotEmpty) {
        final endpoint = '/heritage/$placeId/nearby-properties?radius=$radius&limit=$limit&sort=$sort';
        final response = await ApiService.get(endpoint);
        if (response['success'] == true) {
          final data = response['data'] is Map<String, dynamic>
              ? response['data'] as Map<String, dynamic>
              : response;
          final rawList = data['properties'] as List? ??
              data['hotels'] as List? ??
              (data['data'] is List ? data['data'] as List : []);
          if (rawList.isNotEmpty) {
            return rawList
                .map((item) => Hotel.fromJson(item as Map<String, dynamic>))
                .toList();
          }
        }
      }

      // Fallback to city-wide hotels if no landmark-specific properties found
      final queryCity = Uri.encodeComponent(city.trim());
      final response = await ApiService.get('/hotels?city=$queryCity');
      if (response['success'] == true && response['data'] != null) {
        final rawList = response['data'] is List
            ? response['data'] as List
            : (response['data']['hotels'] as List? ?? []);
        final parsed = rawList
            .map((item) => Hotel.fromJson(item as Map<String, dynamic>))
            .toList();
        if (parsed.isNotEmpty) return parsed;
      }
    } catch (e) {
      debugPrint('HeritageService.getNearbyHotels (using curated fallback): $e');
    }

    return getHotelsForCity(city);
  }

  /// 5. Get Nearby Properties by Arbitrary GPS Coordinates
  /// Endpoint: GET /api/heritage/nearby-properties?lat=17.3616&lng=78.4747&radius=5
  static Future<List<Hotel>> getNearbyPropertiesByCoordinates({
    required double lat,
    required double lng,
    double radius = 5,
    int limit = 10,
    String sort = 'distance_asc',
  }) async {
    try {
      final endpoint = '/heritage/nearby-properties?lat=$lat&lng=$lng&radius=$radius&limit=$limit&sort=$sort';
      final response = await ApiService.get(endpoint);
      if (response['success'] == true) {
        final data = response['data'] is Map<String, dynamic>
            ? response['data'] as Map<String, dynamic>
            : response;
        final rawList = data['properties'] as List? ??
            data['hotels'] as List? ??
            (data['data'] is List ? data['data'] as List : []);
        if (rawList.isNotEmpty) {
          return rawList
              .map((item) => Hotel.fromJson(item as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('HeritageService.getNearbyPropertiesByCoordinates error: $e');
    }
    return [];
  }

  /// 6. Get Dynamic Categories and Supported Cities Metadata
  /// Endpoint: GET /api/heritage/categories
  static Future<HeritageCategoriesResponse> getCategoriesAndCities() async {
    try {
      final response = await ApiService.get('/heritage/categories');
      if (response['success'] == true) {
        final data = response['data'] is Map<String, dynamic>
            ? response['data'] as Map<String, dynamic>
            : response;
        return HeritageCategoriesResponse.fromJson(data);
      }
    } catch (e) {
      debugPrint('HeritageService.getCategoriesAndCities error: $e');
    }

    // Static fallback categories and cities
    return const HeritageCategoriesResponse(
      success: true,
      categories: [
        'All',
        'Historical Monument',
        'Fort',
        'Palace',
        'UNESCO World Heritage Site',
        'Temple & Pilgrimage',
        'Museum',
        'Nature & Caves',
        'Archaeological Site',
      ],
      cities: ['Agra', 'Hyderabad', 'Jaipur', 'Mysuru'],
    );
  }

  static List<HeritagePlace> _getFallbackPlaces() {
    return [
      const HeritagePlace(
        id: '6ab283a7a8cdf659e5655258',
        placeId: 'HP-1001',
        title: 'Charminar',
        tagline: 'The monumental global icon of Hyderabad',
        category: 'Historical Monument',
        city: 'Hyderabad',
        state: 'Telangana',
        address: 'Charminar Rd, Char Kaman, Ghansi Bazaar, Hyderabad, Telangana 500002',
        latitude: 17.3616,
        longitude: 78.4747,
        description: 'Charminar is a monument and mosque in Hyderabad, India. Listed among the most recognized structures in India.',
        history: 'Constructed in 1591 CE by Muhammad Quli Qutb Shah, the fifth ruler of the Qutb Shahi dynasty.',
        architectureDetails: 'Indo-Islamic architectural style with Persian influences. Four grand arches facing cardinal directions.',
        significance: 'Commemorates the founding of Hyderabad city and eradication of a deadly plague.',
        coverImage: 'https://images.unsplash.com/photo-1590490360182-c33d57733427?auto=format&fit=crop&w=800&q=80',
        images: [
          'https://images.unsplash.com/photo-1590490360182-c33d57733427?auto=format&fit=crop&w=800&q=80',
          'https://images.unsplash.com/photo-1608958435020-e8a7109ba809?auto=format&fit=crop&w=800&q=80',
        ],
        timings: HeritageTimings(
          openTime: '09:30 AM',
          closeTime: '05:30 PM',
          openDays: 'All Days',
          bestTimeToVisit: 'October to March (Evening for lighting)',
          averageVisitDuration: '1-2 Hours',
        ),
        entryFee: HeritageEntryFee(
          isFreeEntry: false,
          domestic: 25,
          foreigner: 300,
          children: 0,
          cameraFee: 25,
        ),
        famousHighlights: [
          'Panoramic views of Old Hyderabad from the top balcony',
          'Laad Bazaar (famous for pearls & bangles)',
          'Irani Chai & Osmania biscuits at Nimrah Cafe adjacent to Charminar',
          'Illuminated night view',
        ],
        guidelines: [
          'Entry allowed up to 5:00 PM',
          'Footwear allowed on outer premises',
          'Bags and luggage subject to security inspection',
        ],
        isFeatured: true,
        isPopular: true,
        mustVisit: true,
        rating: 4.8,
        reviewsCount: 1420,
      ),
      const HeritagePlace(
        id: '6ab283a7a8cdf659e5655259',
        placeId: 'HP-1002',
        title: 'Golconda Fort',
        tagline: 'Magnificent medieval fortress and diamond trade capital',
        category: 'Fort',
        city: 'Hyderabad',
        state: 'Telangana',
        address: 'Khair Complex, Ibrahim Bagh, Hyderabad, Telangana 500008',
        latitude: 17.3833,
        longitude: 78.4011,
        description: 'Golconda Fort was the capital of the medieval sultanate of the Qutb Shahi dynasty.',
        history: 'Originally built by the Kakatiyas in the 13th century, later expanded by the Qutb Shahi kings.',
        architectureDetails: 'Acoustic architecture where a hand clap at the entrance dome can be heard 1 km away at the hilltop pavilion.',
        significance: 'Source of legendary diamonds including the Koh-i-Noor and Hope Diamond.',
        coverImage: 'https://images.unsplash.com/photo-1608958435020-e8a7109ba809?auto=format&fit=crop&w=800&q=80',
        images: [
          'https://images.unsplash.com/photo-1608958435020-e8a7109ba809?auto=format&fit=crop&w=800&q=80',
        ],
        timings: HeritageTimings(
          openTime: '09:00 AM',
          closeTime: '05:30 PM',
          openDays: 'All Days',
          bestTimeToVisit: 'Afternoon till sunset for the Sound & Light show',
          averageVisitDuration: '3-4 Hours',
        ),
        entryFee: HeritageEntryFee(
          isFreeEntry: false,
          domestic: 25,
          foreigner: 300,
          children: 0,
          cameraFee: 25,
        ),
        famousHighlights: [
          'Acoustic Clap Phenomenon at Fateh Darwaza',
          'Sunset view from the Baradari topmost pavilion',
          'Evening Sound & Light show',
        ],
        guidelines: [
          'Comfortable walking shoes recommended',
          'Carry drinking water and umbrella',
        ],
        isFeatured: true,
        isPopular: true,
        mustVisit: true,
        rating: 4.9,
        reviewsCount: 2310,
      ),
      const HeritagePlace(
        id: '6ab283a7a8cdf659e5655260',
        placeId: 'HP-1003',
        title: 'Taj Mahal',
        tagline: 'An eternal symbol of love and UNESCO World Wonder',
        category: 'UNESCO World Heritage Site',
        city: 'Agra',
        state: 'Uttar Pradesh',
        address: 'Dharmapuri, Forest Colony, Tajganj, Agra, Uttar Pradesh 282001',
        latitude: 27.1751,
        longitude: 78.0421,
        description: 'An immense mausoleum of white marble, built in Agra between 1631 and 1648 by order of Mughal Emperor Shah Jahan.',
        history: 'Built in memory of Emperor Shah Jahan\'s favorite wife Mumtaz Mahal.',
        architectureDetails: 'The jewel of Muslim art in India and one of the universally admired masterpieces of the world\'s heritage.',
        significance: 'UNESCO World Heritage Site and one of the New 7 Wonders of the World.',
        coverImage: 'https://images.unsplash.com/photo-1564507592333-c60657eea523?auto=format&fit=crop&w=800&q=80',
        images: [
          'https://images.unsplash.com/photo-1564507592333-c60657eea523?auto=format&fit=crop&w=800&q=80',
        ],
        timings: HeritageTimings(
          openTime: '06:00 AM',
          closeTime: '06:30 PM',
          openDays: 'Saturday to Thursday (Closed on Friday)',
          bestTimeToVisit: 'Sunrise or Full Moon Nights',
          averageVisitDuration: '2-3 Hours',
        ),
        entryFee: HeritageEntryFee(
          isFreeEntry: false,
          domestic: 50,
          foreigner: 1100,
          children: 0,
          cameraFee: 0,
        ),
        famousHighlights: [
          'Pietra Dura marble inlay artwork',
          'Symmetrical Charbagh Mughal gardens',
          'Reflecting pool view from main gate',
        ],
        guidelines: [
          'Closed on Fridays for prayers',
          'Shoe covers provided at entrance',
          'No large bags or food items inside',
        ],
        isFeatured: true,
        isPopular: true,
        mustVisit: true,
        rating: 5.0,
        reviewsCount: 9800,
      ),
      const HeritagePlace(
        id: '6ab283a7a8cdf659e5655263',
        placeId: 'HP-1004',
        title: 'Hawa Mahal',
        tagline: 'The iconic Palace of Winds with 953 ornate jharokhas',
        category: 'Palace',
        city: 'Jaipur',
        state: 'Rajasthan',
        address: 'Hawa Mahal Rd, Badi Choupad, J.D.A. Market, Pink City, Jaipur, Rajasthan 302002',
        latitude: 26.9239,
        longitude: 75.8267,
        description: 'A five-storey pink and red sandstone palace constructed in 1799 in the form of Lord Krishna\'s crown.',
        history: 'Built by Maharaja Sawai Pratap Singh for royal women to observe festivals unseen.',
        architectureDetails: 'Rajput and Mughal architectural fusion with 953 honeycomb windows generating natural cooling.',
        significance: 'Iconic landmark of Jaipur Pink City World Heritage site.',
        coverImage: 'https://images.unsplash.com/photo-1599661046289-e31897846e41?auto=format&fit=crop&w=800&q=80',
        images: [
          'https://images.unsplash.com/photo-1599661046289-e31897846e41?auto=format&fit=crop&w=800&q=80',
        ],
        timings: HeritageTimings(
          openTime: '09:00 AM',
          closeTime: '05:00 PM',
          openDays: 'All Days',
          bestTimeToVisit: 'Morning when golden sunlight illuminates the facade',
          averageVisitDuration: '1-2 Hours',
        ),
        entryFee: HeritageEntryFee(
          isFreeEntry: false,
          domestic: 50,
          foreigner: 200,
          children: 20,
          cameraFee: 50,
        ),
        famousHighlights: [
          '953 carved sandstone Jharokhas (balconies)',
          'Rooftop view of City Palace and Jantar Mantar',
          'Tattoo Cafe & Wind View Cafe opposite for postcard photography',
        ],
        guidelines: [
          'Ramps are used inside instead of stairs',
          'Early morning visit recommended',
        ],
        isFeatured: true,
        isPopular: true,
        mustVisit: true,
        rating: 4.7,
        reviewsCount: 3890,
      ),
      const HeritagePlace(
        id: '6ab283a7a8cdf659e5655264',
        placeId: 'HP-1005',
        title: 'Qutub Shahi Tombs',
        tagline: 'Grand royal necropolis of the Qutb Shahi dynasty',
        category: 'Historical Monument',
        city: 'Hyderabad',
        state: 'Telangana',
        address: 'Fort Rd, Toli Chowki, Hyderabad, Telangana 500008',
        latitude: 17.3949,
        longitude: 78.3975,
        description: 'Magnificent domed tombs of the seven Qutb Shahi rulers surrounded by landscaped Ibrahim Bagh gardens.',
        history: 'Built during the 16th and 17th centuries by the Qutb Shahi sultans.',
        architectureDetails: 'Blend of Persian, Pashtun and Hindu architectural styles with domed granite structures.',
        significance: 'Historic burial complex of the founders of Hyderabad.',
        coverImage: 'https://images.unsplash.com/photo-1590490360182-c33d57733427?auto=format&fit=crop&w=800&q=80',
        images: [
          'https://images.unsplash.com/photo-1590490360182-c33d57733427?auto=format&fit=crop&w=800&q=80',
        ],
        timings: HeritageTimings(
          openTime: '09:30 AM',
          closeTime: '06:30 PM',
          openDays: 'All Days',
          bestTimeToVisit: 'Morning & Late afternoon',
          averageVisitDuration: '1.5-2 Hours',
        ),
        entryFee: HeritageEntryFee(
          isFreeEntry: false,
          domestic: 20,
          foreigner: 100,
          children: 10,
          cameraFee: 50,
        ),
        famousHighlights: [
          'Badi Baoli stepwell',
          'Tomb of Muhammad Quli Qutb Shah',
          'Serene landscaped gardens',
        ],
        guidelines: ['Footwear removal required inside inner tomb chambers'],
        isFeatured: false,
        isPopular: true,
        mustVisit: false,
        rating: 4.6,
        reviewsCount: 1650,
      ),
      const HeritagePlace(
        id: '6ab283a7a8cdf659e5655265',
        placeId: 'HP-1006',
        title: 'Agra Fort',
        tagline: 'Imperial walled Mughal city & UNESCO World Heritage Site',
        category: 'Fort',
        city: 'Agra',
        state: 'Uttar Pradesh',
        address: 'Agra Fort, Rakabganj, Agra, Uttar Pradesh 282003',
        latitude: 27.1795,
        longitude: 78.0211,
        description: 'Massive red sandstone fortress that was the main residence of the Mughal emperors until 1638.',
        history: 'Commissioned by Emperor Akbar in 1565 and completed by Shah Jahan.',
        architectureDetails: 'Red sandstone perimeter walls with marble palaces, including Sheesh Mahal and Diwan-i-Khas.',
        significance: 'UNESCO World Heritage fortress overlooking the Yamuna River.',
        coverImage: 'https://images.unsplash.com/photo-1564507592333-c60657eea523?auto=format&fit=crop&w=800&q=80',
        images: [
          'https://images.unsplash.com/photo-1564507592333-c60657eea523?auto=format&fit=crop&w=800&q=80',
        ],
        timings: HeritageTimings(
          openTime: '06:00 AM',
          closeTime: '06:00 PM',
          openDays: 'All Days',
          bestTimeToVisit: 'Morning to afternoon',
          averageVisitDuration: '2-3 Hours',
        ),
        entryFee: HeritageEntryFee(
          isFreeEntry: false,
          domestic: 50,
          foreigner: 650,
          children: 0,
          cameraFee: 0,
        ),
        famousHighlights: [
          'Distant views of the Taj Mahal from Musamman Burj',
          'Jahangir Palace and Sheesh Mahal mirror palace',
          'Diwan-i-Aam public audience hall',
        ],
        guidelines: ['Security check at Amar Singh Gate'],
        isFeatured: true,
        isPopular: true,
        mustVisit: true,
        rating: 4.8,
        reviewsCount: 5400,
      ),
      const HeritagePlace(
        id: '6ab283a7a8cdf659e5655266',
        placeId: 'HP-1007',
        title: 'Amer Fort',
        tagline: 'Opulent hilltop fortress overlooking Maota Lake',
        category: 'Fort',
        city: 'Jaipur',
        state: 'Rajasthan',
        address: 'Devisinghpura, Amer, Jaipur, Rajasthan 302001',
        latitude: 26.9855,
        longitude: 75.8513,
        description: 'Majestic Rajput hilltop fort famous for its artistic Hindu elements and mirror-studded palace.',
        history: 'Constructed by Raja Man Singh in 1592 atop Cheel ka Teela.',
        architectureDetails: 'Red sandstone and marble palace featuring Sheesh Mahal (hall of mirrors) and Ganesh Pol.',
        significance: 'Part of the Hill Forts of Rajasthan UNESCO World Heritage group.',
        coverImage: 'https://images.unsplash.com/photo-1599661046289-e31897846e41?auto=format&fit=crop&w=800&q=80',
        images: [
          'https://images.unsplash.com/photo-1599661046289-e31897846e41?auto=format&fit=crop&w=800&q=80',
        ],
        timings: HeritageTimings(
          openTime: '08:00 AM',
          closeTime: '05:30 PM',
          openDays: 'All Days',
          bestTimeToVisit: 'Morning or night illuminated tour',
          averageVisitDuration: '2-3 Hours',
        ),
        entryFee: HeritageEntryFee(
          isFreeEntry: false,
          domestic: 100,
          foreigner: 500,
          children: 20,
          cameraFee: 50,
        ),
        famousHighlights: [
          'Sheesh Mahal hall of thousands of tiny mirrors',
          'Elephant / Jeep ride up to Suraj Pol entrance',
          'Sound & Light show at evening',
        ],
        guidelines: ['Sturdy walking shoes recommended for fort ramps'],
        isFeatured: true,
        isPopular: true,
        mustVisit: true,
        rating: 4.9,
        reviewsCount: 6800,
      ),
      const HeritagePlace(
        id: '6ab283a7a8cdf659e5655267',
        placeId: 'HP-1008',
        title: 'City Palace, Jaipur',
        tagline: 'Royal palace complex with courtyards & museum',
        category: 'Palace',
        city: 'Jaipur',
        state: 'Rajasthan',
        address: 'Tulsi Marg, Gangori Bazaar, J.D.A. Market, Pink City, Jaipur, Rajasthan 302002',
        latitude: 26.9258,
        longitude: 75.8237,
        description: 'Grand royal residence of the Maharaja of Jaipur featuring Chandra Mahal, Mubarak Mahal, and museum galleries.',
        history: 'Established in 1727 by Maharaja Sawai Jai Singh II when shifting his capital from Amber.',
        architectureDetails: 'Fusion of Rajasthani and Mughal architectural styles with courtyards like Pritam Niwas Chowk.',
        significance: 'Seat of the royal family of Jaipur in the heart of the Pink City.',
        coverImage: 'https://images.unsplash.com/photo-1599661046289-e31897846e41?auto=format&fit=crop&w=800&q=80',
        images: [
          'https://images.unsplash.com/photo-1599661046289-e31897846e41?auto=format&fit=crop&w=800&q=80',
        ],
        timings: HeritageTimings(
          openTime: '09:30 AM',
          closeTime: '05:00 PM',
          openDays: 'All Days',
          bestTimeToVisit: 'Morning or afternoon',
          averageVisitDuration: '2 Hours',
        ),
        entryFee: HeritageEntryFee(
          isFreeEntry: false,
          domestic: 200,
          foreigner: 700,
          children: 100,
          cameraFee: 50,
        ),
        famousHighlights: [
          'Four seasons peacock gates at Pritam Niwas Chowk',
          'World\'s largest sterling silver urns (Gangajali)',
          'Royal textile and arms museum galleries',
        ],
        guidelines: ['Photography permitted in exterior courtyards'],
        isFeatured: false,
        isPopular: true,
        mustVisit: false,
        rating: 4.6,
        reviewsCount: 4200,
      ),
      const HeritagePlace(
        id: '6ab283a7a8cdf659e5655268',
        placeId: 'HP-1009',
        title: 'Mysore Palace',
        tagline: 'Dazzling Indo-Saracenic royal seat of the Wadiyar dynasty',
        category: 'Palace',
        city: 'Mysuru',
        state: 'Karnataka',
        address: 'Sayyaji Rao Rd, Agrahara, Chamrajpura, Mysuru, Karnataka 570001',
        latitude: 12.3051,
        longitude: 76.6552,
        description: 'One of India\'s most visited royal palaces, famous for ornate stained glass, carved mahogany ceilings, and Sunday night illumination.',
        history: 'Commissioned by Maharani Kempananjammanni Vani Vilasa Sannidhana in 1897 and completed in 1912.',
        architectureDetails: 'Indo-Saracenic masterpiece designed by British architect Henry Irwin featuring domes, arches, and colonnades.',
        significance: 'Centerpiece of Mysuru Dussehra festivities and historic seat of the Kingdom of Mysore.',
        coverImage: 'https://images.unsplash.com/photo-1600100397608-f010f4439c79?auto=format&fit=crop&w=800&q=80',
        images: [
          'https://images.unsplash.com/photo-1600100397608-f010f4439c79?auto=format&fit=crop&w=800&q=80',
        ],
        timings: HeritageTimings(
          openTime: '10:00 AM',
          closeTime: '05:30 PM',
          openDays: 'All Days',
          bestTimeToVisit: 'Sunday evening (7:00 PM - 7:45 PM for 100,000 bulb illumination)',
          averageVisitDuration: '2-3 Hours',
        ),
        entryFee: HeritageEntryFee(
          isFreeEntry: false,
          domestic: 70,
          foreigner: 200,
          children: 30,
          cameraFee: 0,
        ),
        famousHighlights: [
          'Durbar Hall with ornate gilded columns and stained glass ceiling',
          'Sunday night palace lighting with nearly 100,000 electric bulbs',
          'Golden Howdah used in Dussehra procession',
          'Kalyana Mantapa (marriage pavilion)',
        ],
        guidelines: [
          'Footwear must be deposited at the entrance counter',
          'Photography inside main halls is strictly restricted',
        ],
        isFeatured: true,
        isPopular: true,
        mustVisit: true,
        rating: 4.9,
        reviewsCount: 12400,
      ),
      const HeritagePlace(
        id: '6ab283a7a8cdf659e5655269',
        placeId: 'HP-1010',
        title: 'Chamundeshwari Temple',
        tagline: 'Ancient hill temple dedicated to the patron goddess of Mysuru',
        category: 'Temple & Pilgrimage',
        city: 'Mysuru',
        state: 'Karnataka',
        address: 'Chamundi Hill Rd, Chamundi Hill, Mysuru, Karnataka 570010',
        latitude: 12.2724,
        longitude: 76.6710,
        description: 'Centuries-old Dravidian temple atop Chamundi Hills overlooking panoramic vistas of Mysuru city.',
        history: 'Original temple built in the 12th century by Hoysala rulers; tower erected by Vijayanagara empire.',
        architectureDetails: 'Seven-tier gopuram (pyramidal tower) adorned with intricate stone sculptures and silver plated doors.',
        significance: 'One of the 18 Maha Shakti Peethas and patron deity of the Wadiyar royal family.',
        coverImage: 'https://images.unsplash.com/photo-1600100397608-f010f4439c79?auto=format&fit=crop&w=800&q=80',
        images: [
          'https://images.unsplash.com/photo-1600100397608-f010f4439c79?auto=format&fit=crop&w=800&q=80',
        ],
        timings: HeritageTimings(
          openTime: '07:30 AM',
          closeTime: '09:00 PM',
          openDays: 'All Days',
          bestTimeToVisit: 'Early morning for hill sunrise and temple darshan',
          averageVisitDuration: '1-2 Hours',
        ),
        entryFee: HeritageEntryFee(
          isFreeEntry: true,
          domestic: 0,
          foreigner: 0,
          children: 0,
          cameraFee: 0,
        ),
        famousHighlights: [
          'Monolithic Nandi (Bull) statue carved from a single boulder halfway up the hill',
          'Panoramic summit view of Mysuru city including Lalitha Mahal and Mysore Palace',
          'Historic 1000 stone step pilgrimage pathway',
        ],
        guidelines: [
          'Dress code: Traditional modest attire recommended',
          'Leather items restricted in sanctum sanctorum',
        ],
        isFeatured: false,
        isPopular: true,
        mustVisit: false,
        rating: 4.8,
        reviewsCount: 7800,
      ),
    ];
  }
}
