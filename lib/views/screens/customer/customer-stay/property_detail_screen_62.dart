import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../models/hotel_model.dart';
import 'select_room_screen_54.dart';
import 'stay_host_chat_screen.dart';

class PropertyDetailScreen extends StatefulWidget {
  final Hotel? hotel;

  const PropertyDetailScreen({super.key, this.hotel});

  @override
  State<PropertyDetailScreen> createState() => _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends State<PropertyDetailScreen> {
  bool _isFavorite = false;
  int _selectedImageIndex = 0;
  bool _isDescriptionExpanded = false;
  int _testimonialIndex = 0;

  Hotel get _activeHotel => widget.hotel ?? mockHotels[0];

  late final List<String> _galleryImages;

  @override
  void initState() {
    super.initState();
    final hotel = _activeHotel;
    _galleryImages = [
      hotel.image,
      'assets/images/Rectangle 127.png',
      'assets/images/Rectangle 128.png',
      'assets/images/Rectangle 108.png',
    ];
  }

  final List<Map<String, String>> _testimonials = [
    {
      'name': 'Rohan Sharma',
      'stay': 'Stayed in July 2026',
      'rating': '5.0',
      'comment':
          'Amazing location right next to the sea! The hospitality was top-notch, food was delicious, and the rooms were pristine and spacious.',
    },
    {
      'name': 'Ananya Iyer',
      'stay': 'Stayed in June 2026',
      'rating': '4.8',
      'comment':
          'Exceptional amenities. The private pool and sunset views made our vacation unforgettable. The host was very responsive and helpful.',
    },
    {
      'name': 'Vikram Reddy',
      'stay': 'Stayed in May 2026',
      'rating': '4.9',
      'comment':
          'Great value for money. Very peaceful environment, perfectly suited for family vacations. Would definitely book again!',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final hotel = _activeHotel;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Multi-Photo Hero Gallery matching Stay.png
                    _buildGallerySection(hotel),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 2. Title & Category Pill Badge
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  hotel.title,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFDE7EE),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  hotel.type,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFE91E63),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 6),

                          // 3. Rating & Distance
                          Row(
                            children: [
                              const Icon(Icons.star_rounded, color: Color(0xFFFFB800), size: 18),
                              const SizedBox(width: 4),
                              Text(
                                '${hotel.rating}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                ' (${hotel.reviewCount} Reviews) . Very good',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.location_on, size: 15, color: AppColors.textSecondary),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  '(${hotel.distanceFormatted ?? "2.5 KMs Away"})',
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    color: AppColors.textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 18),

                          // 4. Reservation Selector Card matching Stay.png
                          _buildReservationCard(hotel),

                          const SizedBox(height: 22),

                          // 5. About Property Section
                          const Text(
                            'About Property',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            hotel.description,
                            maxLines: _isDescriptionExpanded ? null : 3,
                            overflow: _isDescriptionExpanded ? null : TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13.5,
                              color: AppColors.textSecondary,
                              height: 1.5,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _isDescriptionExpanded = !_isDescriptionExpanded;
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                _isDescriptionExpanded ? 'Show Less' : 'Show More',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // 6. Popular Amenities Grid matching Stay.png
                          _buildAmenitiesSection(),

                          const SizedBox(height: 24),

                          // 7. Guests Review Progress Bars matching Stay.png
                          _buildReviewBarsSection(),

                          const SizedBox(height: 24),

                          // 8. What Our Guests Say (Testimonial Slider)
                          _buildTestimonialsSection(),

                          const SizedBox(height: 24),

                          // 9. FAQ Accordion & Host Message Card
                          _buildFaqSection(context, hotel),

                          const SizedBox(height: 24),

                          // 10. Location Preview
                          _buildLocationPreview(hotel),

                          const SizedBox(height: 24),

                          // 11. Policies Accordion
                          _buildPoliciesSection(),

                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 12. Sticky Bottom Availability Bar matching Stay.png
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '₹${hotel.basePrice.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const Text(
                          'Price for 4 Nights',
                          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SelectRoomScreen(hotel: hotel),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child: const Text(
                          'See Availability',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 1. Gallery Section with 4-thumbnail strip matching Stay.png
  Widget _buildGallerySection(Hotel hotel) {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              height: 240,
              width: double.infinity,
              color: const Color(0xFFF3EDF7),
              child: Image.asset(
                _galleryImages[_selectedImageIndex],
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Center(
                  child: Icon(Icons.hotel_rounded, size: 64, color: AppColors.primary),
                ),
              ),
            ),
            // Floating Top Controls
            Positioned(
              top: 14,
              left: 14,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(Icons.arrow_back, color: AppColors.textPrimary, size: 20),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 14,
              right: 14,
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(Icons.share_outlined, color: AppColors.textPrimary, size: 19),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => setState(() => _isFavorite = !_isFavorite),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          color: _isFavorite ? const Color(0xFFE91E63) : AppColors.primary,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // 4 Thumbnails strip
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Row(
            children: List.generate(4, (index) {
              final isLast = index == 3;
              final isSelected = _selectedImageIndex == index;

              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedImageIndex = index),
                  child: Container(
                    height: 64,
                    margin: EdgeInsets.only(right: index == 3 ? 0 : 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.asset(
                            _galleryImages[index],
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Center(
                              child: Icon(Icons.image, color: Colors.grey, size: 20),
                            ),
                          ),
                          if (isLast)
                            Container(
                              color: Colors.black.withValues(alpha: 0.48),
                              child: const Center(
                                child: Text(
                                  '+12 More',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  // 4. Reservation Selector Card matching Stay.png
  Widget _buildReservationCard(Hotel hotel) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F5FD),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8DEF8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.calendar_month_outlined, color: AppColors.primary, size: 20),
                  SizedBox(width: 8),
                  Text(
                    '15 aug, fri  -  20 aug, sat',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: AppColors.primary, size: 18),
                onPressed: () {},
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(height: 1, color: Color(0xFFEAE3F7)),
          ),
          Row(
            children: const [
              Icon(Icons.people_outline_rounded, color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Text(
                '4 Rooms, 4 Adults, 0 Childrens',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(height: 1, color: Color(0xFFEAE3F7)),
          ),
          Text(
            'Price for 1 Night , 4 Adults: ₹${hotel.basePrice.toStringAsFixed(0)} + ₹270 Taxes & Charges',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // 6. Popular Amenities Grid
  Widget _buildAmenitiesSection() {
    final amenitiesList = [
      {'name': 'Wi-Fi', 'icon': Icons.wifi_rounded},
      {'name': 'Tv', 'icon': Icons.tv_rounded},
      {'name': 'Kitchen', 'icon': Icons.soup_kitchen_rounded},
      {'name': 'Parking', 'icon': Icons.local_parking_rounded},
      {'name': 'Pool', 'icon': Icons.pool_rounded},
      {'name': 'Washing', 'icon': Icons.local_laundry_service_rounded},
      {'name': 'hot water', 'icon': Icons.hot_tub_rounded},
      {'name': 'Break fast', 'icon': Icons.free_breakfast_rounded},
      {'name': 'Lunch', 'icon': Icons.restaurant_rounded},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Popular Amenities',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: amenitiesList.map((item) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFAF9FD),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFEAE7F2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(item['icon'] as IconData, size: 16, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text(
                    item['name'] as String,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // 7. Guests Review Progress Bars matching Stay.png
  Widget _buildReviewBarsSection() {
    final categories = [
      {'name': 'Cleanliness', 'score': 4.3},
      {'name': 'Comfort', 'score': 4.1},
      {'name': 'Amenities', 'score': 4.3},
      {'name': 'Locations', 'score': 4.3},
      {'name': 'Staff', 'score': 4.3},
      {'name': 'Value For Money', 'score': 5.0},
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFBFBFE),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFECEBF2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Guests Review',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              Text(
                'Overall 4.8 / 5.0',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...categories.map((c) {
            final name = c['name'] as String;
            final score = c['score'] as double;
            final percent = score / 5.0;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  SizedBox(
                    width: 120,
                    child: Text(
                      name,
                      style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                    ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: percent,
                        minHeight: 6,
                        backgroundColor: const Color(0xFFEDE7F6),
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    score.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  // 8. What Our Guests Say (Testimonials Slider)
  Widget _buildTestimonialsSection() {
    final t = _testimonials[_testimonialIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'What Our Guests Say',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE8E6F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primaryBackground,
                        ),
                        child: const Center(
                          child: Icon(Icons.person, color: AppColors.primary, size: 20),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t['name']!,
                            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            t['stay']!,
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: List.generate(
                      5,
                      (_) => const Icon(Icons.star_rounded, color: Color(0xFFFFB800), size: 16),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '“${t['comment']!}”',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.4,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 12),
              // Dots pager
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _testimonials.length,
                  (dot) => GestureDetector(
                    onTap: () => setState(() => _testimonialIndex = dot),
                    child: Container(
                      width: 7,
                      height: 7,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _testimonialIndex == dot ? AppColors.primary : Colors.grey.shade300,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 9. FAQ Accordion & Host Messaging Card
  Widget _buildFaqSection(BuildContext context, Hotel hotel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Frequently Asked Questions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        _buildFaqTile(
          'What is the check-in and check-out time?',
          'Standard check-in starts at 12:00 PM and check-out is until 11:00 AM. Early check-in or late check-out is subject to room availability.',
        ),
        _buildFaqTile(
          'Is breakfast complimentary?',
          'Yes, a wholesome buffet breakfast is included in all booking packages and served daily between 7:30 AM and 10:30 AM.',
        ),
        _buildFaqTile(
          'Are pets allowed on the property?',
          'Yes! Verified domestic pets are welcomed. Please inform the host beforehand so necessary arrangements can be made.',
        ),
        _buildFaqTile(
          'Is parking available on site?',
          'Free private self-parking and valet assistance are available round-the-clock for all registered guests.',
        ),

        const SizedBox(height: 16),

        // Host Inquiry Banner matching Stay.png (Adaptive and responsive)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF6F2FD),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5DCF6)),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 330;

              if (isCompact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Have A Question?',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Ask the host about property details or request special packages.',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.3),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 42,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => StayHostChatScreen(hotel: hotel),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text(
                          'Message Host',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Have A Question?',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Ask the host about property details or request special packages.',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => StayHostChatScreen(hotel: hotel),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                    child: const Text(
                      'Message Host',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFaqTile(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEDEBF2)),
      ),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        children: [
          Text(
            answer,
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
          ),
        ],
      ),
    );
  }

  // 10. Location Preview
  Widget _buildLocationPreview(Hotel hotel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Location',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 6),
        Text(
          hotel.location,
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 10),
        Container(
          height: 140,
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFFF3EDF7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE4DFEC)),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Icon(Icons.map_rounded, size: 48, color: AppColors.primary),
              Positioned(
                bottom: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 4),
                    ],
                  ),
                  child: const Text(
                    'Exact address will be shared after booking confirmation',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 11. Policies Section
  Widget _buildPoliciesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Policies & House Rules',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 10),
        _buildFaqTile(
          'Cancellation Policy',
          'Free cancellation is available up to 48 hours prior to check-in date. Late cancellations may incur a 1-night retention fee.',
        ),
        _buildFaqTile(
          'Property Rules',
          'Quiet hours are observed between 10:00 PM and 7:00 AM. Smoking inside rooms is prohibited; designated outdoor smoking areas are available.',
        ),
        _buildFaqTile(
          'Safety & Hygiene',
          'Daily housekeeping, sanitization protocols, 24/7 CCTV surveillance in common areas, and on-call medical assistance.',
        ),
      ],
    );
  }
}