// Figma: 1:3593 (Event Search Results)
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/customer_event_static_data.dart';
import '../../../widgets/customer_booking_widgets.dart';
import 'event_detail_screen.dart';

class EventSearchResultsScreen extends StatefulWidget {
  final String location;
  final String eventType;
  final String eventDate;
  final int guestCount;

  const EventSearchResultsScreen({
    super.key,
    required this.location,
    required this.eventType,
    required this.eventDate,
    required this.guestCount,
  });

  @override
  State<EventSearchResultsScreen> createState() => _EventSearchResultsScreenState();
}

class _EventSearchResultsScreenState extends State<EventSearchResultsScreen> {
  String _activeFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final venues = CustomerEventStaticData.eventVenues.where((v) {
      if (_activeFilter == '500+ Capacity') {
        return (v['seatingCapacity'] as int) >= 500;
      }
      if (_activeFilter == 'Under ₹70k') {
        return (v['baseHallRent'] as int) <= 70000;
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomerAppBar(
        title: '${widget.eventType} Venues',
        subtitle: '${widget.location} • ${widget.eventDate} • ${widget.guestCount} Guests',
      ),
      body: Column(
        children: [
          // Filter Pills
          SizedBox(
            height: 54,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              children: ['All', '500+ Capacity', 'Under ₹70k', 'Veg & Non-Veg'].map((f) {
                final selected = _activeFilter == f;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(
                      f,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: selected ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    selected: selected,
                    selectedColor: AppColors.primary,
                    backgroundColor: Colors.white,
                    side: BorderSide(color: selected ? AppColors.primary : AppColors.border),
                    onSelected: (_) => setState(() => _activeFilter = f),
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              itemCount: venues.length,
              itemBuilder: (context, index) {
                final venue = venues[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EventDetailScreen(
                          venue: venue,
                          eventType: widget.eventType,
                          eventDate: widget.eventDate,
                          guestCount: widget.guestCount,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stack(
                          children: [
                            CustomerSafeImage(
                              assetPath: venue['image'].toString(),
                              width: double.infinity,
                              height: 165,
                              borderRadius: 16,
                            ),
                            Positioned(
                              top: 12,
                              left: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  venue['badge'].toString(),
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      venue['name'].toString(),
                                      style: const TextStyle(
                                        fontSize: 16.5,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      const Icon(Icons.star_rounded,
                                          size: 18, color: AppColors.accent),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${venue['rating']} (${venue['reviews']})',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                venue['location'].toString(),
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  _ChipBadge(
                                    icon: Icons.chair_alt_rounded,
                                    text: '${venue['seatingCapacity']} Seating',
                                  ),
                                  const SizedBox(width: 8),
                                  _ChipBadge(
                                    icon: Icons.groups_rounded,
                                    text: '${venue['floatingCapacity']} Floating',
                                  ),
                                ],
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Divider(height: 1, color: AppColors.border),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Veg ₹${venue['vegPlatePrice']} • Non-Veg ₹${venue['nonVegPlatePrice']}',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const Text(
                                        'per plate catering',
                                        style: TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    '₹ ${venue['baseHallRent']}',
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
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
    );
  }
}

class _ChipBadge extends StatelessWidget {
  final IconData icon;
  final String text;

  const _ChipBadge({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
