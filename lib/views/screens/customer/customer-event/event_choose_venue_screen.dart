// Figma: 1:4588 (Choose Event Venue / Hall)
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../widgets/customer_booking_widgets.dart';
import 'event_guest_details_screen.dart';

class EventChooseVenueScreen extends StatefulWidget {
  final Map<String, dynamic> venue;
  final String eventType;
  final String eventDate;
  final int guestCount;
  final String selectedSlot;
  final int addonsTotal;

  const EventChooseVenueScreen({
    super.key,
    required this.venue,
    required this.eventType,
    required this.eventDate,
    required this.guestCount,
    required this.selectedSlot,
    required this.addonsTotal,
  });

  @override
  State<EventChooseVenueScreen> createState() => _EventChooseVenueScreenState();
}

class _EventChooseVenueScreenState extends State<EventChooseVenueScreen> {
  int _selectedHallIdx = 0;

  @override
  Widget build(BuildContext context) {
    final halls = (widget.venue['halls'] as List<dynamic>).cast<Map<String, dynamic>>();
    final selectedHall = halls[_selectedHallIdx];
    final hallRent = (selectedHall['rent'] as int) + widget.addonsTotal;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomerAppBar(
        title: 'Choose Venue Hall',
        subtitle: widget.venue['name'].toString(),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: halls.length,
              itemBuilder: (context, index) {
                final hall = halls[index];
                final isSelected = _selectedHallIdx == index;
                return GestureDetector(
                  onTap: () => setState(() => _selectedHallIdx = index),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.border,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                hall['name'].toString(),
                                style: const TextStyle(
                                  fontSize: 16.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primaryBackground,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                hall['type'].toString(),
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          hall['description'].toString(),
                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Text(
                              'Seating: ${hall['seating']}  •  Floating: ${hall['floating']}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
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
                            Text(
                              '₹ ${hall['rent']} / slot',
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () => setState(() => _selectedHallIdx = index),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    isSelected ? AppColors.primary : AppColors.primaryBackground,
                                foregroundColor: isSelected ? Colors.white : AppColors.primary,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: Text(isSelected ? 'Selected' : 'Select Hall'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          BookingPriceBar(
            priceText: '₹ $hallRent',
            subText: selectedHall['name'].toString(),
            buttonText: 'Continue',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EventGuestDetailsScreen(
                    venue: widget.venue,
                    hall: selectedHall,
                    eventType: widget.eventType,
                    eventDate: widget.eventDate,
                    guestCount: widget.guestCount,
                    selectedSlot: widget.selectedSlot,
                    addonsTotal: widget.addonsTotal,
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
