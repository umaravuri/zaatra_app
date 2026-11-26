import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/navigation/app_navigator.dart';
import '../../../../models/hotel_model.dart';
import '../../../../models/heritage_place_model.dart';
import '../../../../services/auth_service.dart';
import '../../../../services/customer_notification_service.dart';
import '../../../../services/google_maps_service.dart';
import '../../../../services/heritage_service.dart';
import '../customer-stay/property_detail_screen_62.dart';
import '../customer-ride/ride_search_map_screen_44.dart';
import '../customer-stay/stay_search_results_screen_45.dart';
import '../customer-stay/stay_ride_search_screen_41.dart';
import '../customer-common/my_wishlist_screen.dart';
import '../customer-stay-updated/customer_my_bookings_screen_updated.dart';
import '../customer-common/customer_profile_screen_44.dart';
import '../customer-common/customer_messages_screen.dart';
import '../customer-common/notifications_screen_52.dart';
import '../customer-stay/heritage_places_screen.dart';
import '../customer-stay/heritage_detail_screen.dart';
import '../customer-stay/city_detail_screen.dart';
import '../customer-event/event_search_screen.dart';
import '../../../widgets/customer_location_sharing_banner.dart';

class CustomerHomeScreen extends StatefulWidget {
  static const String routeName = AppRoutes.customerHome;
  final String? userName;

  const CustomerHomeScreen({
    super.key,
    this.userName,
  });

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  int _currentNavIndex = 0;
  final Set<String> _favoriteIds = {};
  late String _displayName;
  String _currentLocation = 'Madhapur , road no 2 Hyderabad';
  HeritagePlace? _featuredHeritagePlace;
  List<HeritagePlace> _famousHeritagePlaces = [];
  bool _hasUnreadNotifications = true;

  @override
  void initState() {
    super.initState();
    _displayName = (widget.userName != null && widget.userName!.trim().isNotEmpty)
        ? widget.userName!.trim()
        : '';
    _loadUserName();
    _loadFeaturedHeritagePlace();
    _initCurrentLocation();
    _checkUnreadNotifications();
  }

  Future<void> _checkUnreadNotifications() async {
    try {
      final count = await CustomerNotificationService.getUnreadCount();
      if (mounted) {
        setState(() {
          _hasUnreadNotifications = count > 0;
        });
      }
    } catch (_) {}
  }

  Future<void> _initCurrentLocation() async {
    // 1. Instant cached location display
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedAddress = prefs.getString('user_current_address');
      if (mounted && cachedAddress != null && cachedAddress.isNotEmpty) {
        setState(() {
          _currentLocation = cachedAddress;
        });
      }
    } catch (_) {}

    // 2. Request and acquire live GPS location using default system dialog
    try {
      final hasPermission = await GoogleMapsService.requestSystemLocationPermission();
      if (hasPermission) {
        final loc = await GoogleMapsService.getCurrentLocation();
        if (mounted && loc != null && loc.formattedAddress.isNotEmpty) {
          setState(() {
            _currentLocation = loc.formattedAddress;
          });
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_current_address', loc.formattedAddress);
          await prefs.setDouble('user_current_lat', loc.latitude);
          await prefs.setDouble('user_current_lng', loc.longitude);
        }
      }
    } catch (e) {
      debugPrint('Location acquisition error: $e');
    }
  }

  Future<void> _loadUserName() async {
    final name = await AuthService.getUserName(defaultFallback: '');
    if (mounted) {
      setState(() {
        _displayName = name;
      });
    }
  }

  Future<void> _loadFeaturedHeritagePlace() async {
    try {
      final famous = await HeritageService.getFamousPlaces();
      if (mounted && famous.isNotEmpty) {
        setState(() {
          _famousHeritagePlaces = famous;
          _featuredHeritagePlace = famous.first;
        });
      }
    } catch (_) {}
  }

  void _toggleFavorite(String id) {
    setState(() {
      if (_favoriteIds.contains(id)) {
        _favoriteIds.remove(id);
      } else {
        _favoriteIds.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppNavigator.buildRootExitGuard(
      context: context,
      homeName: 'Customer Home',
      child: Scaffold(
        backgroundColor: const Color(0xFFFBFBFE),
        body: SafeArea(
          child: Column(
            children: [
              const CustomerLocationSharingBanner(),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Top Purple Header Section with 3 Hero Cards matching 38.png
                      _buildTopHeader(),

                      // 2. Explore Your Next Destination Promo Banner matching 38.png
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        child: _buildPromoBanner(),
                      ),

                      // 3. Main Sections Content
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 20),

                            // Section 1: Recent Search
                            _buildSectionHeader(
                              'Recent Search',
                              onViewAll: () => _navigateToStayResults('Recent Search'),
                            ),
                            const SizedBox(height: 12),
                            _buildPropertyCarousel(
                              items: _getRecentSearchItems(),
                              carouselHeight: 250,
                            ),

                            const SizedBox(height: 24),

                            // Section 2: Recent Cities
                            _buildSectionHeader(
                              'Recent Cities',
                              onViewAll: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const CityDetailScreen(city: 'Hyderabad'),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 12),
                            _buildRecentCitiesCarousel(),

                            const SizedBox(height: 24),

                            // Section 3: Hotels
                            _buildSectionHeader(
                              'Hotels',
                              onViewAll: () => _navigateToStayResults('Hotels'),
                            ),
                            const SizedBox(height: 12),
                            _buildPropertyCarousel(
                              items: _getHotelItems(),
                              carouselHeight: 250,
                            ),

                            const SizedBox(height: 24),

                            // Section 4: Resorts
                            _buildSectionHeader(
                              'Resorts',
                              onViewAll: () => _navigateToStayResults('Resorts'),
                            ),
                            const SizedBox(height: 12),
                            _buildPropertyCarousel(
                              items: _getResortItems(),
                              carouselHeight: 250,
                            ),

                            const SizedBox(height: 24),

                            // Section 5: Banquet Halls
                            _buildSectionHeader(
                              'Banquet Halls',
                              onViewAll: () => _navigateToStayResults('Banquet Halls'),
                            ),
                            const SizedBox(height: 12),
                            _buildPropertyCarousel(
                              items: _getBanquetHallItems(),
                              carouselHeight: 250,
                            ),

                            const SizedBox(height: 24),

                            // Section 6: Farms Stays
                            _buildSectionHeader(
                              'Farms Stays',
                              onViewAll: () => _navigateToStayResults('Farms Stays'),
                            ),
                            const SizedBox(height: 12),
                            _buildPropertyCarousel(
                              items: _getFarmStayItems(),
                              carouselHeight: 250,
                            ),

                            const SizedBox(height: 24),

                            // Section 7: Heritage & Historic
                            _buildSectionHeader(
                              'Heritage & Historic',
                              onViewAll: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const HeritagePlacesScreen()),
                                );
                              },
                            ),
                            const SizedBox(height: 12),
                            _buildHeritageCarousel(),

                            const SizedBox(height: 24),

                            // Section 8: Reviews
                            _buildSectionHeader(
                              'Reviews',
                              onViewAll: () => _navigateToStayResults('Reviews'),
                            ),
                            const SizedBox(height: 12),
                            _buildReviewsCarousel(),

                            const SizedBox(height: 28),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom Navigation Bar
              _buildBottomNavigationBar(),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToStayResults(String category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StaySearchResultsScreen(
          locationName: category,
        ),
      ),
    );
  }

  // 1. Top Purple Header Section matching 38.png
  Widget _buildTopHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
      decoration: const BoxDecoration(
        color: Color(0xFF673AB7),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting & Profile Row
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  image: const DecorationImage(
                    image: AssetImage('assets/images/image 27.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          _displayName.isNotEmpty ? 'Hello, $_displayName' : 'Hello',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text('👋', style: TextStyle(fontSize: 16)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.white70, size: 13),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            _currentLocation,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.w400,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CustomerNotificationsScreen()),
                  );
                  _checkUnreadNotifications();
                },
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.notifications_rounded, color: Colors.white, size: 21),
                    ),
                    if (_hasUnreadNotifications)
                      Positioned(
                        right: 2,
                        top: 2,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFF3B30),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // 3 Hero Cards (Stay, Event Halls, Ride) in a row matching 38.png
          Row(
            children: [
              Expanded(
                child: _buildHeroCard(
                  title: 'Stay',
                  subtitle: 'Find a comfortable place to stay that feels relaxing',
                  iconAsset: 'assets/images/hero_stay_3d_icon.png',
                  fallbackIcon: Icons.home_rounded,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const StayRideSearchScreen()),
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildHeroCard(
                  title: 'Event Halls',
                  subtitle: 'Find the perfect venue for your special occasion',
                  iconAsset: 'assets/images/hero_event_3d_icon.png',
                  fallbackIcon: Icons.celebration_rounded,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EventSearchScreen(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildHeroCard(
                  title: 'Ride',
                  subtitle: 'Find convenient rides to your destinations',
                  iconAsset: 'assets/images/hero_ride_3d_icon.png',
                  fallbackIcon: Icons.directions_car_rounded,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const RideSearchMapScreen()),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard({
    required String title,
    required String subtitle,
    required String iconAsset,
    required IconData fallbackIcon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 145,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFF512DA8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.16), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 9.5,
                    color: Colors.white.withValues(alpha: 0.85),
                    height: 1.25,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Image.asset(
                  iconAsset,
                  width: 32,
                  height: 32,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Icon(
                    fallbackIcon,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(Icons.chevron_right_rounded, color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 2. Explore Your Next Destination Promo Banner matching 38.png
  Widget _buildPromoBanner() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const StaySearchResultsScreen()),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.asset(
            'assets/images/customer_promo_banner_38.png',
            width: double.infinity,
            fit: BoxFit.fitWidth,
            errorBuilder: (_, __, ___) => Container(
              height: 140,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE8DEF8), Color(0xFFD0BCFF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'EXPLORE\nYour Next Destination',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Discover amazing places and travel with ease.',
                          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.flight_takeoff_rounded, size: 48, color: AppColors.primary),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 3. Section Header with View All -> matching 38.png
  Widget _buildSectionHeader(String title, {VoidCallback? onViewAll}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        GestureDetector(
          onTap: onViewAll ?? () => _navigateToStayResults(title),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'View All',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF673AB7),
                ),
              ),
              SizedBox(width: 4),
              Icon(Icons.arrow_forward_rounded, size: 14, color: Color(0xFF673AB7)),
            ],
          ),
        ),
      ],
    );
  }

  // 4. Reusable Horizontal Property Carousel matching 38.png
  Widget _buildPropertyCarousel({
    required List<DashboardPropertyData> items,
    double carouselHeight = 250,
  }) {
    return SizedBox(
      height: carouselHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final item = items[index];
          final isFav = _favoriteIds.contains(item.id);
          return _buildPropertyCard(item, isFav);
        },
      ),
    );
  }

  Widget _buildPropertyCard(DashboardPropertyData item, bool isFav) {
    return GestureDetector(
      onTap: () {
        final targetHotel = item.hotelRef ?? mockHotels.first;
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => PropertyDetailScreen(hotel: targetHotel)),
        );
      },
      child: Container(
        width: 172,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Image with Heart Icon
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  child: Image.asset(
                    item.imageAsset,
                    height: 128,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 128,
                      color: const Color(0xFFF3EDF7),
                      child: const Center(
                        child: Icon(Icons.villa_rounded, size: 36, color: AppColors.primary),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () => _toggleFavorite(item.id),
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.black12, blurRadius: 4),
                        ],
                      ),
                      child: Icon(
                        isFav ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
                        color: const Color(0xFFFF5252),
                        size: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Card Body Info
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Location and Pricing Row
                  if (item.hasPlatePricing)
                    // Veg & Non-Veg plate pricing for Banquets matching 38.png
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 11, color: Color(0xFFFF5252)),
                            const SizedBox(width: 2),
                            Expanded(
                              child: Text(
                                item.location,
                                style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(color: Color(0xFF2E7D32), shape: BoxShape.circle),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  item.vegPrice ?? '₹ 600 / Plate',
                                  style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(color: Color(0xFFD32F2F), shape: BoxShape.circle),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  item.nonVegPrice ?? '₹ 900 / Plate',
                                  style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    )
                  else
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              const Icon(Icons.location_on_outlined, size: 11, color: Color(0xFFFF5252)),
                              const SizedBox(width: 2),
                              Expanded(
                                child: Text(
                                  item.location,
                                  style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 4),
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: item.priceAmount,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF673AB7),
                                ),
                              ),
                              TextSpan(
                                text: item.priceUnit,
                                style: const TextStyle(
                                  fontSize: 9,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: 6),

                  // Rating and Distance Row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF3E0),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star_rounded, size: 10, color: Color(0xFFFFB800)),
                            const SizedBox(width: 2),
                            Text(
                              item.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFE65100),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        item.distance,
                        style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 5. Recent Cities Carousel matching 38.png
  Widget _buildRecentCitiesCarousel() {
    final cities = [
      {'name': 'Hyderabaad', 'image': 'assets/images/customer_dashboard_stay_sample.png'},
      {'name': 'Goa', 'image': 'assets/images/customer_dashboard_stay_sample.png'},
      {'name': 'Jaipur', 'image': 'assets/images/customer_dashboard_stay_sample.png'},
      {'name': 'Bengaluru', 'image': 'assets/images/customer_dashboard_stay_sample.png'},
    ];

    return SizedBox(
      height: 170,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: cities.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final city = cities[index];
          final isFav = _favoriteIds.contains('city_${city['name']}');
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StaySearchResultsScreen(
                    destinationCity: city['name'],
                  ),
                ),
              );
            },
            child: Container(
              width: 172,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                        child: Image.asset(
                          city['image']!,
                          height: 120,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            height: 120,
                            color: const Color(0xFFF3EDF7),
                            child: const Center(
                              child: Icon(Icons.location_city_rounded, size: 36, color: AppColors.primary),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () => _toggleFavorite('city_${city['name']}'),
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isFav ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
                              color: const Color(0xFFFF5252),
                              size: 15,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textPrimary),
                        const SizedBox(width: 4),
                        Text(
                          city['name']!,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // 6. Heritage & Historic Carousel matching 38.png
  Widget _buildHeritageCarousel() {
    final heritageItems = [
      {
        'id': 'HP-MAN-1',
        'title': 'Manchariala Fort',
        'location': 'Hyderabad , telengana',
        'rating': '★ 4.2 (70 reviews)',
        'distance': '5 KM away',
        'image': 'assets/images/customer_dashboard_heritage_sample.png',
      },
      {
        'id': 'HP-MAN-2',
        'title': 'Golconda Fort Heritage',
        'location': 'Hyderabad , telengana',
        'rating': '★ 4.8 (120 reviews)',
        'distance': '12 KM away',
        'image': 'assets/images/customer_dashboard_heritage_sample.png',
      },
    ];

    return SizedBox(
      height: 250,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: heritageItems.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final item = heritageItems[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => HeritageDetailScreen(
                    placeId: item['id']!,
                    initialPlace: _featuredHeritagePlace,
                  ),
                ),
              );
            },
            child: Container(
              width: 185,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                        child: Image.asset(
                          item['image']!,
                          height: 140,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            height: 140,
                            color: const Color(0xFFF3EDF7),
                            child: const Center(
                              child: Icon(Icons.castle_rounded, size: 36, color: AppColors.primary),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.share_outlined, color: AppColors.textPrimary, size: 14),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['title']!,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 11, color: Color(0xFFFF5252)),
                            const SizedBox(width: 2),
                            Expanded(
                              child: Text(
                                item['location']!,
                                style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            Text(
                              item['rating']!,
                              style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFFE65100)),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              item['distance']!,
                              style: const TextStyle(fontSize: 9.5, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // 7. Reviews Carousel matching 38.png
  Widget _buildReviewsCarousel() {
    final reviews = [
      {
        'title': 'Sri Sai Hotel & Resorts',
        'quote': 'Its very good resort & nice amenities',
        'author': 'Mr . Kumar , Hyderabad.',
        'rating': '4.2',
        'image': 'assets/images/customer_dashboard_heritage_sample.png',
      },
      {
        'title': 'Sri Sai Hotel & Resorts',
        'quote': 'Its very good resort & nice amenities',
        'author': 'Mr . Kumar , Hyderabad.',
        'rating': '4.2',
        'image': 'assets/images/customer_dashboard_heritage_sample.png',
      },
    ];

    return SizedBox(
      height: 255,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: reviews.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final rev = reviews[index];
          return Container(
            width: 185,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                      child: Image.asset(
                        rev['image']!,
                        height: 140,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 140,
                          color: const Color(0xFFF3EDF7),
                          child: const Center(
                            child: Icon(Icons.hotel_rounded, size: 36, color: AppColors.primary),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFA000),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded, size: 10, color: Colors.white),
                            const SizedBox(width: 2),
                            Text(
                              rev['rating']!,
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.share_outlined, color: AppColors.textPrimary, size: 14),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rev['title']!,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        rev['quote']!,
                        style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        rev['author']!,
                        style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Datasets for Category Sections
  List<DashboardPropertyData> _getRecentSearchItems() {
    return [
      DashboardPropertyData(
        id: 'RS-1',
        title: 'Best luxury stay',
        location: 'Jaipur, Rajasthan',
        priceAmount: '₹ 4,000',
        priceUnit: ' / Night',
        rating: 4.2,
        distance: '5 KM away',
        imageAsset: 'assets/images/customer_dashboard_stay_sample.png',
        hotelRef: mockHotels[1],
      ),
      DashboardPropertyData(
        id: 'RS-2',
        title: 'Best luxury stay',
        location: 'Jaipur, Rajasthan',
        priceAmount: '₹ 4,000',
        priceUnit: ' / Night',
        rating: 4.2,
        distance: '5 KM away',
        imageAsset: 'assets/images/customer_dashboard_stay_sample.png',
        hotelRef: mockHotels[2],
      ),
    ];
  }

  List<DashboardPropertyData> _getHotelItems() {
    return [
      DashboardPropertyData(
        id: 'HT-1',
        title: 'Best luxury stay',
        location: 'Jaipur, Rajasthan',
        priceAmount: '₹ 4,000',
        priceUnit: ' / Night',
        rating: 4.2,
        distance: '5 KM away',
        imageAsset: 'assets/images/customer_dashboard_stay_sample.png',
        hotelRef: mockHotels[0],
      ),
      DashboardPropertyData(
        id: 'HT-2',
        title: 'Best luxury stay',
        location: 'Jaipur, Rajasthan',
        priceAmount: '₹ 4,000',
        priceUnit: ' / Night',
        rating: 4.2,
        distance: '5 KM away',
        imageAsset: 'assets/images/customer_dashboard_stay_sample.png',
        hotelRef: mockHotels[1],
      ),
    ];
  }

  List<DashboardPropertyData> _getResortItems() {
    return [
      DashboardPropertyData(
        id: 'RS-RT-1',
        title: 'Best luxury stay',
        location: 'Jaipur, Rajasthan',
        priceAmount: '₹ 4,000',
        priceUnit: ' / Night',
        rating: 4.2,
        distance: '5 KM away',
        imageAsset: 'assets/images/customer_dashboard_stay_sample.png',
        hotelRef: mockHotels[2],
      ),
      DashboardPropertyData(
        id: 'RS-RT-2',
        title: 'Best luxury stay',
        location: 'Jaipur, Rajasthan',
        priceAmount: '₹ 4,000',
        priceUnit: ' / Night',
        rating: 4.2,
        distance: '5 KM away',
        imageAsset: 'assets/images/customer_dashboard_stay_sample.png',
        hotelRef: mockHotels[3],
      ),
    ];
  }

  List<DashboardPropertyData> _getBanquetHallItems() {
    return [
      DashboardPropertyData(
        id: 'BQ-1',
        title: 'Best luxury stay',
        location: 'Jaipur, Rajasthan',
        priceAmount: '₹ 40,000',
        priceUnit: ' Per Event',
        rating: 4.2,
        distance: '5 KM away',
        imageAsset: 'assets/images/customer_dashboard_stay_sample.png',
        hotelRef: mockHotels[4],
      ),
      DashboardPropertyData(
        id: 'BQ-2',
        title: 'Best luxury stay',
        location: 'Jaipur, Rajasthan',
        priceAmount: '',
        priceUnit: '',
        hasPlatePricing: true,
        vegPrice: '₹ 600 / Plate',
        nonVegPrice: '₹ 900 / Plate',
        rating: 4.2,
        distance: '5 KM away',
        imageAsset: 'assets/images/customer_dashboard_stay_sample.png',
        hotelRef: mockHotels[4],
      ),
    ];
  }

  List<DashboardPropertyData> _getFarmStayItems() {
    return [
      DashboardPropertyData(
        id: 'FS-1',
        title: 'Best luxury stay',
        location: 'Jaipur, Rajasthan',
        priceAmount: '₹ 4,000',
        priceUnit: ' / Night',
        rating: 4.2,
        distance: '5 KM away',
        imageAsset: 'assets/images/customer_dashboard_stay_sample.png',
        hotelRef: mockHotels[3],
      ),
      DashboardPropertyData(
        id: 'FS-2',
        title: 'Best luxury stay',
        location: 'Jaipur, Rajasthan',
        priceAmount: '₹ 4,000',
        priceUnit: ' / Night',
        rating: 4.2,
        distance: '5 KM away',
        imageAsset: 'assets/images/customer_dashboard_stay_sample.png',
        hotelRef: mockHotels[3],
      ),
    ];
  }

  // Bottom Navigation Bar
  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentNavIndex,
        onTap: (index) {
          // Other tabs open their own screen, so the dashboard keeps Home
          // highlighted (otherwise the pushed tab stays highlighted on return).
          if (index == 0) {
            setState(() => _currentNavIndex = 0);
          } else if (index == 1) {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const MyWishlistScreen()));
          } else if (index == 2) {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const CustomerMyBookingsScreenUpdated()));
          } else if (index == 3) {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const CustomerMessagesScreen()));
          } else if (index == 4) {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const CustomerProfileScreen()));
          }
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF673AB7),
        unselectedItemColor: AppColors.textSecondary,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        elevation: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_filled),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_outline_rounded),
            label: 'Wishlist',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_outlined),
            label: 'Booking',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline_rounded),
            label: 'Message',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class DashboardPropertyData {
  final String id;
  final String title;
  final String location;
  final String priceAmount;
  final String priceUnit;
  final bool hasPlatePricing;
  final String? vegPrice;
  final String? nonVegPrice;
  final double rating;
  final String distance;
  final String imageAsset;
  final Hotel? hotelRef;

  const DashboardPropertyData({
    required this.id,
    required this.title,
    required this.location,
    required this.priceAmount,
    required this.priceUnit,
    this.hasPlatePricing = false,
    this.vegPrice,
    this.nonVegPrice,
    required this.rating,
    required this.distance,
    required this.imageAsset,
    this.hotelRef,
  });
}