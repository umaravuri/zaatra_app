// Figma: 1:5204 (Event Booking Confirmed)
import 'package:flutter/material.dart';
import '../../../widgets/customer_booking_widgets.dart';
import 'event_booking_details_screen.dart';

class EventBookingConfirmedScreen extends StatelessWidget {
  final Map<String, dynamic> venue;
  final String hallName;
  final String eventType;
  final String eventDate;
  final String selectedSlot;
  final int guestCount;
  final int advancePaid;
  final int balanceDue;
  final int grandTotal;

  const EventBookingConfirmedScreen({
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
    return BookingConfirmationLayout(
      title: 'Event Venue Confirmed!',
      subtitle: 'Your $eventType slot at ${venue['name']} is reserved.',
      bookingId: 'ZTEV904512',
      advancePaid: '₹ $advancePaid',
      balanceDue: '₹ $balanceDue',
      details: [
        BookingSummaryRowData(label: 'Venue', value: venue['name'].toString()),
        BookingSummaryRowData(label: 'Hall Selected', value: hallName),
        BookingSummaryRowData(label: 'Event Date', value: eventDate),
        BookingSummaryRowData(label: 'Time Slot', value: selectedSlot),
        BookingSummaryRowData(label: 'Expected Guests', value: '$guestCount Guests'),
      ],
      primaryButtonLabel: 'View My Booking',
      onPrimaryAction: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EventBookingDetailsScreen(
              venue: venue,
              hallName: hallName,
              eventType: eventType,
              eventDate: eventDate,
              selectedSlot: selectedSlot,
              guestCount: guestCount,
              advancePaid: advancePaid,
              balanceDue: balanceDue,
              grandTotal: grandTotal,
            ),
          ),
        );
      },
      secondaryButtonLabel: 'Back to Home',
      onSecondaryAction: () => Navigator.popUntil(context, (route) => route.isFirst),
    );
  }
}
