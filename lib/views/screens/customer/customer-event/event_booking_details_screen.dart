// Figma: 1:3310 (Event Booking Details)
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../widgets/customer_booking_widgets.dart';

class EventBookingDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> venue;
  final String hallName;
  final String eventType;
  final String eventDate;
  final String selectedSlot;
  final int guestCount;
  final int advancePaid;
  final int balanceDue;
  final int grandTotal;

  const EventBookingDetailsScreen({
    super.key,
    required this.venue,
    required this.hallName,
    required this.eventType,
    required this.eventDate,
    required this.selectedSlot,
    required this.guestCount,
    required this.advancePaid,
    required this.balanceDue,
    required this.grandTotal,
  });

  @override
  Widget build(BuildContext context) {
    final amenities = (venue['amenities'] as List<dynamic>? ?? const ['Central AC', 'Valet Parking'])
        .cast<String>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomerAppBar(
        title: 'Event Booking Voucher',
        subtitle: 'ID: ZTEV904512 • Confirmed',
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          CustomerSafeImage(
            assetPath: venue['image'].toString(),
            width: double.infinity,
            height: 185,
            borderRadius: 16,
          ),
          const SizedBox(height: 16),
          BookingSummaryCard(
            title: venue['name'].toString(),
            subtitle: venue['location'].toString(),
            badgeText: 'Confirmed • $eventType',
            rows: [
              BookingSummaryRowData(label: 'Hall', value: hallName),
              BookingSummaryRowData(label: 'Date', value: eventDate),
              BookingSummaryRowData(label: 'Slot', value: selectedSlot),
              BookingSummaryRowData(label: 'Guests', value: '$guestCount Guests'),
            ],
          ),
          const SizedBox(height: 14),
          BookingSummaryCard(
            title: 'Payment Summary',
            subtitle: '50% advance paid online',
            rows: [
              BookingSummaryRowData(label: 'Total Package', value: '₹ $grandTotal'),
              BookingSummaryRowData(
                label: 'Advance Paid',
                value: '₹ $advancePaid',
                valueColor: AppColors.success,
              ),
              BookingSummaryRowData(
                label: 'Balance Payable at Venue',
                value: '₹ $balanceDue',
                valueColor: AppColors.accent,
                isHighlight: true,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Included Amenities',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
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
                const SizedBox(height: 14),
                const Divider(height: 1, color: AppColors.border),
                const SizedBox(height: 14),
                const Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.primaryBackground,
                      child: Icon(Icons.person_rounded, color: AppColors.primary),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Venue Manager: Rajeshwari Rao',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Verified Zaatra Venue Partner',
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Invoice PDF download queued')),
                    );
                  },
                  icon: const Icon(Icons.receipt_long_rounded, size: 18),
                  label: const Text('Invoice'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Cancellation support requested')),
                    );
                  },
                  icon: const Icon(Icons.cancel_outlined, size: 18),
                  label: const Text('Cancel'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
