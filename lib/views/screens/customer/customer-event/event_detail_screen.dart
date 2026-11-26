// Figma: 1:4112 (Event Detail)
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../widgets/customer_booking_widgets.dart';
import 'event_choose_venue_screen.dart';

class EventDetailScreen extends StatefulWidget {
  final Map<String, dynamic> venue;
  final String eventType;
  final String eventDate;
  final int guestCount;

  const EventDetailScreen({
    super.key,
    required this.venue,
    required this.eventType,
    required this.eventDate,
    required this.guestCount,
  });

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  late String _selectedSlot;
  bool _includeDecor = true;
  bool _includeDj = false;

  @override
  void initState() {
    super.initState();
    final slots = (widget.venue['slots'] as List<dynamic>).cast<String>();
    _selectedSlot = slots.first;
  }

  @override
  Widget build(BuildContext context) {
    final venue = widget.venue;
    final slots = (venue['slots'] as List<dynamic>).cast<String>();
    final amenities = (venue['amenities'] as List<dynamic>).cast<String>();
    final baseRent = venue['baseHallRent'] as int;
    final decorPrice = _includeDecor ? (venue['decorStartingPrice'] as int) : 0;
    final djPrice = _includeDj ? (venue['djPrice'] as int) : 0;
    final estimatedRent = baseRent + decorPrice + djPrice;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomerAppBar(
        title: venue['name'].toString(),
        subtitle: venue['location'].toString(),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                CustomerSafeImage(
                  assetPath: venue['image'].toString(),
                  width: double.infinity,
                  height: 200,
                  borderRadius: 16,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        venue['name'].toString(),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBackground,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star_rounded, size: 16, color: AppColors.accent),
                          const SizedBox(width: 4),
                          Text(
                            '${venue['rating']}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${widget.eventType} • ${widget.eventDate} • ${widget.guestCount} Guests',
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 18),

                // Select Time Slot
                const Text(
                  'Select Event Slot',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                ...slots.map((slot) {
                  final selected = _selectedSlot == slot;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected ? AppColors.primary : AppColors.border,
                        width: selected ? 1.5 : 1,
                      ),
                    ),
                    child: RadioListTile<String>(
                      value: slot,
                      groupValue: _selectedSlot,
                      activeColor: AppColors.primary,
                      title: Text(
                        slot,
                        style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                      ),
                      onChanged: (v) => setState(() => _selectedSlot = v!),
                    ),
                  );
                }),
                const SizedBox(height: 16),

                // Plate Pricing & Add-ons
                const Text(
                  'Catering & Add-ons',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      BookingInfoRow(
                        label: 'Veg Plate Starting Rate',
                        value: '₹ ${venue['vegPlatePrice']} / plate',
                      ),
                      const SizedBox(height: 8),
                      BookingInfoRow(
                        label: 'Non-Veg Plate Starting Rate',
                        value: '₹ ${venue['nonVegPlatePrice']} / plate',
                      ),
                      const Divider(height: 20, color: AppColors.border),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        activeThumbColor: AppColors.primary,
                        title: const Text(
                          'Stage & Floral Decoration',
                          style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text('+ ₹ ${venue['decorStartingPrice']}'),
                        value: _includeDecor,
                        onChanged: (v) => setState(() => _includeDecor = v),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        activeThumbColor: AppColors.primary,
                        title: const Text(
                          'DJ & Sound System',
                          style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text('+ ₹ ${venue['djPrice']}'),
                        value: _includeDj,
                        onChanged: (v) => setState(() => _includeDj = v),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Amenities
                const Text(
                  'Venue Facilities',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: amenities
                      .map((a) => Chip(
                            label: Text(a, style: const TextStyle(fontSize: 12)),
                            backgroundColor: AppColors.primaryBackground,
                            side: BorderSide.none,
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
          BookingPriceBar(
            priceText: '₹ $estimatedRent',
            subText: 'Hall + selected add-ons (excl. catering)',
            buttonText: 'Choose Hall',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EventChooseVenueScreen(
                    venue: venue,
                    eventType: widget.eventType,
                    eventDate: widget.eventDate,
                    guestCount: widget.guestCount,
                    selectedSlot: _selectedSlot,
                    addonsTotal: decorPrice + djPrice,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
