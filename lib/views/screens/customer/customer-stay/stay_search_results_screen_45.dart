import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../models/hotel_model.dart';
import 'property_detail_screen_62.dart';
import 'stay_filters_screen_43.dart';
import 'stay_map_search_screen_53.dart';
import 'stay_ride_search_screen_41.dart';

class StaySearchResultsScreen extends StatefulWidget {
  final String? destinationCity;
  final String? locationName;
  final String? checkInDate;
  final String? checkOutDate;
  final String? guestsSummary;
  final int? roomsCount;
  final int? adultsCount;
  final int? childrenCount;
  final bool? hasPets;

  const StaySearchResultsScreen({
    super.key,
    this.destinationCity,
    this.locationName,
    this.checkInDate,
    this.checkOutDate,
    this.guestsSummary,
    this.roomsCount,
    this.adultsCount,
    this.childrenCount,
    this.hasPets,
  });

  @override
  State<StaySearchResultsScreen> createState() => _StaySearchResultsScreenState();
}

class _StaySearchResultsScreenState extends State<StaySearchResultsScreen> {
  late List<Hotel> _hotels;
  final Set<String> _favoriteHotelIds = {};
  String _selectedSort = 'Recommended';

  @override
  void initState() {
    super.initState();
    _loadHotels();
  }

  void _loadHotels() {
    final searchTarget = widget.destinationCity ?? widget.locationName;
    if (searchTarget != null && searchTarget.isNotEmpty) {
      final queryLower = searchTarget.toLowerCase();
      final filtered = mockHotels.where((h) =>
          h.city.toLowerCase().contains(queryLower) ||
          h.location.toLowerCase().contains(queryLower) ||
          h.title.toLowerCase().contains(queryLower) ||
          queryLower.contains(h.city.toLowerCase()) ||
          (widget.locationName != null &&
              h.description.toLowerCase().contains(widget.locationName!.toLowerCase()))
      ).toList();
      _hotels = filtered.isNotEmpty ? List.from(filtered) : List.from(mockHotels);
    } else {
      _hotels = List.from(mockHotels);
    }

    // Ensure Goa search puts 'The Luxury resort' first
    if ((widget.destinationCity ?? '').toLowerCase().contains('goa')) {
      _hotels.sort((a, b) {
        if (a.title.toLowerCase().contains('luxury')) return -1;
        if (b.title.toLowerCase().contains('luxury')) return 1;
        return 0;
      });
    }
  }

  void _toggleFavorite(String hotelId) {
    setState(() {
      if (_favoriteHotelIds.contains(hotelId)) {
        _favoriteHotelIds.remove(hotelId);
      } else {
        _favoriteHotelIds.add(hotelId);
      }
    });
  }

  void _applySort(String sortType) {
    setState(() {
      _selectedSort = sortType;
      switch (sortType) {
        case 'Price: Low to High':
          _hotels.sort((a, b) => a.basePrice.compareTo(b.basePrice));
          break;
        case 'Price: High to Low':
          _hotels.sort((a, b) => b.basePrice.compareTo(a.basePrice));
          break;
        case 'Top Rated':
          _hotels.sort((a, b) => b.rating.compareTo(a.rating));
          break;
        case 'Distance: Nearest First':
          _hotels.sort((a, b) => (a.distanceKm ?? 99.0).compareTo(b.distanceKm ?? 99.0));
          break;
        case 'Recommended':
        default:
          _loadHotels();
          break;
      }
    });
  }

  void _showSortModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final sortOptions = [
          'Recommended',
          'Price: Low to High',
          'Price: High to Low',
          'Top Rated',
          'Distance: Nearest First',
        ];

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Sort Stays By',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...sortOptions.map((opt) {
                  final isSelected = _selectedSort == opt;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      opt,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? AppColors.primary : AppColors.textPrimary,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle_rounded, color: AppColors.primary)
                        : null,
                    onTap: () {
                      Navigator.pop(ctx);
                      _applySort(opt);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openSearch() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StayRideSearchScreen(
          initialDestination: widget.destinationCity,
        ),
      ),
    );
  }

  String _formatPrice(double price) {
    if (price >= 1000) {
      final str = price.toStringAsFixed(0);
      final len = str.length;
      if (len > 3) {
        final lastThree = str.substring(len - 3);
        final remaining = str.substring(0, len - 3);
        return '$remaining,$lastThree';
      }
    }
    return price.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.destinationCity ?? widget.locationName ?? 'Goa, India';
    final checkIn = widget.checkInDate ?? '12 May';
    final checkOut = widget.checkOutDate ?? '15 May';
    final guests = widget.guestsSummary ?? '2 guest, 1 child ,1 room';
    final subtitle = '$checkIn - $checkOut . $guests';

    final nights = 4;
    final adults = widget.adultsCount ?? 3;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withOpacity(0.85),
                fontWeight: FontWeight.w400,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded, color: Colors.white, size: 22),
            onPressed: _openSearch,
          ),
        ],
        centerTitle: false,
        backgroundColor: AppColors.primary,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Pill Bar (Sort, Filter, Map) matching 45.png
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: _buildFilterPill(
                      icon: Icons.swap_vert_rounded,
                      label: 'Sort',
                      onTap: _showSortModal,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildFilterPill(
                      icon: Icons.tune_rounded,
                      label: 'Filter',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const StayFiltersScreen()),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildFilterPill(
                      icon: Icons.map_outlined,
                      label: 'Map',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const StayMapSearchScreen()),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Results List matching 45.png
            Expanded(
              child: _hotels.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.hotel_outlined, size: 54, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          const Text(
                            'No Stays Found',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Try adjusting your search criteria',
                            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                      itemCount: _hotels.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final hotel = _hotels[index];
                        final isFavorite = _favoriteHotelIds.contains(hotel.id);

                        final screenWidth = MediaQuery.of(context).size.width;
                        final imageWidth = screenWidth < 380 ? 102.0 : 114.0;

                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PropertyDetailScreen(hotel: hotel),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: const Color(0xFFE8E8EE)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Left Column: Full-Height Image with Heart Icon
                                Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(14),
                                      child: Container(
                                        width: imageWidth,
                                        height: 190,
                                        color: const Color(0xFFF3EDF7),
                                        child: Image.asset(
                                          hotel.image,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => const Center(
                                            child: Icon(Icons.hotel_rounded, color: AppColors.primary, size: 36),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: GestureDetector(
                                        onTap: () => _toggleFavorite(hotel.id),
                                        child: Container(
                                          width: 30,
                                          height: 30,
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.9),
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.12),
                                                blurRadius: 4,
                                              ),
                                            ],
                                          ),
                                          child: Center(
                                            child: Icon(
                                              isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                              color: isFavorite ? const Color(0xFFE91E63) : AppColors.primary,
                                              size: 17,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(width: 12),

                                // Right Column: Property Details & Amenities
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Title
                                      Text(
                                        hotel.title,
                                        style: const TextStyle(
                                          fontSize: 15.5,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textPrimary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),

                                      // Location
                                      Text(
                                        hotel.location,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 5),

                                      // Rating Row
                                      Row(
                                        children: [
                                          const Icon(Icons.star_rounded, size: 14, color: Color(0xFFFFB800)),
                                          const SizedBox(width: 3),
                                          Text(
                                            '${hotel.rating}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                          Flexible(
                                            child: Text(
                                              ' , Exceptional ${hotel.reviewCount} reviews',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: AppColors.textSecondary,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 6),

                                      // Amenities Row 1: Beds, living room, bedrooms
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 2,
                                        crossAxisAlignment: WrapCrossAlignment.center,
                                        children: [
                                          _buildIconTag(Icons.king_bed_outlined, hotel.specs.beds),
                                          _buildIconTag(Icons.meeting_room_outlined, '1 living room.'),
                                          _buildIconTag(Icons.bathtub_outlined, hotel.specs.baths),
                                        ],
                                      ),

                                      const SizedBox(height: 4),

                                      // Amenities Row 2: Free cancellation, no prepayment (Wrap for responsive safety)
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 2,
                                        crossAxisAlignment: WrapCrossAlignment.center,
                                        children: [
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: const [
                                              Icon(Icons.check_circle_outline, size: 12, color: Color(0xFF2E7D32)),
                                              SizedBox(width: 3),
                                              Text(
                                                'Free cancellation',
                                                style: TextStyle(
                                                  fontSize: 10.5,
                                                  color: Color(0xFF2E7D32),
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: const [
                                              Icon(Icons.credit_card_outlined, size: 12, color: AppColors.textSecondary),
                                              SizedBox(width: 3),
                                              Text(
                                                'no prepayment',
                                                style: TextStyle(
                                                  fontSize: 10.5,
                                                  color: AppColors.textSecondary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 4),

                                      // Amenities Row 3: Free breakfast, Swimming pool (Wrap for responsive safety)
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 2,
                                        crossAxisAlignment: WrapCrossAlignment.center,
                                        children: [
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: const [
                                              Icon(Icons.coffee_outlined, size: 12, color: AppColors.textSecondary),
                                              SizedBox(width: 3),
                                              Text(
                                                'Free breakfast',
                                                style: TextStyle(fontSize: 10.5, color: AppColors.textSecondary),
                                              ),
                                            ],
                                          ),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: const [
                                              Icon(Icons.pool_outlined, size: 12, color: AppColors.textSecondary),
                                              SizedBox(width: 3),
                                              Text(
                                                'Swimming pool',
                                                style: TextStyle(fontSize: 10.5, color: AppColors.textSecondary),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 6),

                                      // Pricing Label
                                      Text(
                                        'Price for $nights Nights , $adults guest.',
                                        style: const TextStyle(
                                          fontSize: 10.5,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),

                                      // Bold Price with FittedBox to prevent overflow
                                      FittedBox(
                                        fit: BoxFit.scaleDown,
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          '₹${_formatPrice(hotel.basePrice)} + ₹2000 Tax\'s & Charges',
                                          style: const TextStyle(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ),

                                      const SizedBox(height: 3),

                                      // Distance Tag
                                      Row(
                                        children: [
                                          const Icon(Icons.location_on, size: 12, color: AppColors.textSecondary),
                                          const SizedBox(width: 2),
                                          Text(
                                            hotel.distanceFormatted ?? '3.5 Km Away',
                                            style: const TextStyle(
                                              fontSize: 10.5,
                                              color: AppColors.textSecondary,
                                            ),
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterPill({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFEDE7F6),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 17, color: AppColors.textPrimary),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconTag(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: AppColors.textSecondary),
        const SizedBox(width: 2),
        Text(
          text,
          style: const TextStyle(
            fontSize: 10.5,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
