// Figma: 1:1447 (City Page - Hyderabad)
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/customer_static_data.dart';
import '../../../widgets/customer_booking_widgets.dart';
import '../customer-event/event_search_screen.dart';
import 'stay_ride_search_screen_41.dart';

class CityDetailScreen extends StatelessWidget {
  final String city;

  const CityDetailScreen({super.key, this.city = 'Hyderabad'});

  @override
  Widget build(BuildContext context) {
    final guide = CustomerStaticData.hyderabadCityGuide;
    final stays = (guide['nearbyStays'] as List<dynamic>).cast<Map<String, dynamic>>();
    final halls = (guide['nearbyHalls'] as List<dynamic>).cast<Map<String, dynamic>>();
    final reviews = (guide['reviews'] as List<dynamic>).cast<Map<String, dynamic>>();
    final faqs = (guide['faqs'] as List<dynamic>).cast<Map<String, dynamic>>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomerAppBar(
        title: city,
        subtitle: guide['tagline'].toString(),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const CustomerSafeImage(
            assetPath: 'assets/images/image 27.png',
            width: double.infinity,
            height: 180,
            borderRadius: 16,
          ),
          const SizedBox(height: 16),
          Text(
            'About $city',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            guide['about'].toString(),
            style: const TextStyle(fontSize: 13.5, color: AppColors.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 20),

          // Stays Nearby
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Stays Nearby',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const StayRideSearchScreen()),
                  );
                },
                child: const Text('Explore All', style: TextStyle(color: AppColors.primary)),
              ),
            ],
          ),
          ...stays.map((s) => _CityPlaceTile(
                title: s['name'].toString(),
                subtitle: s['area'].toString(),
                price: s['price'].toString(),
                rating: s['rating'].toString(),
                image: s['image'].toString(),
              )),
          const SizedBox(height: 16),

          // Event Halls Nearby
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Event Halls Nearby',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const EventSearchScreen()),
                  );
                },
                child: const Text('Explore All', style: TextStyle(color: AppColors.primary)),
              ),
            ],
          ),
          ...halls.map((h) => _CityPlaceTile(
                title: h['name'].toString(),
                subtitle: '${h['area']} • ${h['capacity']}',
                price: h['price'].toString(),
                rating: h['rating'].toString(),
                image: h['image'].toString(),
              )),
          const SizedBox(height: 18),

          // Reviews
          const Text(
            'Traveler Reviews',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          ...reviews.map((r) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          r['author'].toString(),
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, size: 16, color: AppColors.accent),
                            const SizedBox(width: 4),
                            Text('${r['rating']}',
                                style: const TextStyle(fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      r['comment'].toString(),
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 14),

          // FAQs
          const Text(
            'Frequently Asked Questions',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          ...faqs.map((faq) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: ExpansionTile(
                  title: Text(
                    faq['q'].toString(),
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                      child: Text(
                        faq['a'].toString(),
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _CityPlaceTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String price;
  final String rating;
  final String image;

  const _CityPlaceTile({
    required this.title,
    required this.subtitle,
    required this.price,
    required this.rating,
    required this.image,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CustomerSafeImage(assetPath: image, width: 68, height: 68, borderRadius: 10),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      price,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, size: 15, color: AppColors.accent),
                        const SizedBox(width: 2),
                        Text(rating, style: const TextStyle(fontSize: 12.5)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
