// Figma: 1:2847 (Event Booking Summary)
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../widgets/customer_booking_widgets.dart';
import 'event_booking_confirmed_screen.dart';
import 'event_request_change_screen.dart';

class EventBookingSummaryScreen extends StatefulWidget {
  final Map<String, dynamic> venue;
  final Map<String, dynamic> hall;
  final String eventType;
  final String eventDate;
  final int guestCount;
  final String selectedSlot;
  final int addonsTotal;
  final String organizerName;
  final String cateringPackage;

  const EventBookingSummaryScreen({
    super.key,
    required this.venue,
    required this.hall,
    required this.eventType,
    required this.eventDate,
    required this.guestCount,
    required this.selectedSlot,
    required this.addonsTotal,
    required this.organizerName,
    required this.cateringPackage,
  });

  @override
  State<EventBookingSummaryScreen> createState() => _EventBookingSummaryScreenState();
}

class _EventBookingSummaryScreenState extends State<EventBookingSummaryScreen> {
  final _couponCtrl = TextEditingController();
  String? _appliedCoupon;
  int _discount = 0;

  @override
  void dispose() {
    _couponCtrl.dispose();
    super.dispose();
  }

  int get _cateringCost {
    if (widget.cateringPackage.contains('No Catering')) return 0;
    final rate = widget.cateringPackage.contains('Non-Veg')
        ? (widget.venue['nonVegPlatePrice'] as int)
        : (widget.venue['vegPlatePrice'] as int);
    return rate * widget.guestCount;
  }

  @override
  Widget build(BuildContext context) {
    final hallRent = widget.hall['rent'] as int;
    final catering = _cateringCost;
    final subtotal = hallRent + widget.addonsTotal + catering;
    final taxes = (subtotal * 0.18).round();
    final grandTotal = (subtotal + taxes - _discount).clamp(0, 99999999);
    final advancePay = (grandTotal * 0.5).round();
    final balanceDue = grandTotal - advancePay;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomerAppBar(
        title: 'Event Booking Summary',
        subtitle: 'Review & Pay 50% Advance',
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                BookingSummaryCard(
                  title: widget.venue['name'].toString(),
                  subtitle: widget.venue['location'].toString(),
                  imageAsset: widget.venue['image'].toString(),
                  badgeText: '${widget.eventType} • ${widget.hall['name']}',
                  rows: [
                    BookingSummaryRowData(label: 'Date', value: widget.eventDate),
                    BookingSummaryRowData(label: 'Slot', value: widget.selectedSlot),
                    BookingSummaryRowData(
                      label: 'Guests',
                      value: '${widget.guestCount} Attendees',
                    ),
                    BookingSummaryRowData(label: 'Organizer', value: widget.organizerName),
                  ],
                ),
                const SizedBox(height: 14),
                CouponInputRow(
                  controller: _couponCtrl,
                  appliedCode: _appliedCoupon,
                  onApply: () {
                    final code = _couponCtrl.text.trim().toUpperCase();
                    if (code.isEmpty) return;
                    setState(() {
                      _appliedCoupon = code;
                      _discount = (subtotal * 0.08).round();
                    });
                  },
                  onRemove: () => setState(() {
                    _appliedCoupon = null;
                    _discount = 0;
                    _couponCtrl.clear();
                  }),
                ),
                const SizedBox(height: 14),
                BookingSummaryCard(
                  title: 'Cost Breakdown',
                  subtitle: 'Pay 50% now to reserve your date & slot',
                  rows: [
                    BookingSummaryRowData(label: 'Hall Rental', value: '₹ $hallRent'),
                    if (widget.addonsTotal > 0)
                      BookingSummaryRowData(
                        label: 'Decor & DJ Add-ons',
                        value: '₹ ${widget.addonsTotal}',
                      ),
                    BookingSummaryRowData(
                      label: 'Catering (${widget.guestCount} plates)',
                      value: '₹ $catering',
                    ),
                    BookingSummaryRowData(label: 'GST & Service Taxes (18%)', value: '₹ $taxes'),
                    if (_discount > 0)
                      BookingSummaryRowData(
                        label: 'Coupon ($_appliedCoupon)',
                        value: '- ₹ $_discount',
                        valueColor: AppColors.success,
                      ),
                    BookingSummaryRowData(
                      label: 'Grand Total',
                      value: '₹ $grandTotal',
                      isHighlight: true,
                    ),
                    BookingSummaryRowData(
                      label: 'Balance at Venue',
                      value: '₹ $balanceDue',
                    ),
                  ],
                  totalLabel: 'Pay Now (50% Advance)',
                  totalAmount: '₹ $advancePay',
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EventRequestChangeScreen(
                          venueName: widget.venue['name'].toString(),
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit_calendar_outlined, color: AppColors.primary),
                  label: const Text(
                    'Need custom slot or headcount? Request Change',
                    style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          BookingPriceBar(
            priceText: '₹ $advancePay',
            subText: '50% advance • Total ₹ $grandTotal',
            buttonText: 'Confirm & Pay',
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => EventBookingConfirmedScreen(
                    venue: widget.venue,
                    hallName: widget.hall['name'].toString(),
                    eventType: widget.eventType,
                    eventDate: widget.eventDate,
                    selectedSlot: widget.selectedSlot,
                    guestCount: widget.guestCount,
                    advancePaid: advancePay,
                    balanceDue: balanceDue,
                    grandTotal: grandTotal,
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
