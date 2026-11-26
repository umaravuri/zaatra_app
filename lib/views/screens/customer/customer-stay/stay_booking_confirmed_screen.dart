// Figma: 1:5121 (Booking Confirmed - stay)
import 'package:flutter/material.dart';
import '../../../../models/hotel_model.dart';
import '../../../widgets/customer_booking_widgets.dart';
import '../customer-stay-updated/customer_my_bookings_screen_updated.dart';
import 'stay_rate_sheet.dart';

class StayBookingConfirmedScreen extends StatelessWidget {
  final Hotel hotel;
  final String roomTitle;
  final String guestName;
  final int advancePaid;
  final int balanceDue;

  const StayBookingConfirmedScreen({
    super.key,
    required this.hotel,
    required this.roomTitle,
    required this.guestName,
    required this.advancePaid,
    required this.balanceDue,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: BookingConfirmationLayout(
              title: 'Stay Booking Confirmed!',
              subtitle: 'Your reservation at ${hotel.title} is locked in.',
              bookingId: 'ZT102456588',
              advancePaid: '₹ $advancePaid',
              balanceDue: '₹ $balanceDue',
              details: [
                BookingSummaryRowData(label: 'Property', value: hotel.title),
                BookingSummaryRowData(label: 'Room Type', value: roomTitle),
                BookingSummaryRowData(label: 'Primary Guest', value: guestName),
                const BookingSummaryRowData(label: 'Check-in', value: '22 Mar, 12:00 PM'),
                const BookingSummaryRowData(label: 'Check-out', value: '24 Mar, 11:00 AM'),
              ],
              primaryButtonLabel: 'View My Bookings',
              onPrimaryAction: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CustomerMyBookingsScreenUpdated(),
                  ),
                  (route) => route.isFirst,
                );
              },
              secondaryButtonLabel: 'Rate Your Stay Experience',
              onSecondaryAction: () => StayRateSheet.show(context, propertyName: hotel.title),
            ),
          ),
        ],
      ),
    );
  }
}
