// Figma: 1:2780 (Booking Summary and Pay Now)
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../models/hotel_model.dart';
import '../../../widgets/customer_booking_widgets.dart';
import 'stay_booking_confirmed_screen.dart';
import 'stay_request_change_screen.dart';

class StayBookingSummaryScreen extends StatefulWidget {
  final Hotel hotel;
  final String roomTitle;
  final double pricePerNight;
  final String ratePlan;
  final String guestName;
  final String guestEmail;
  final String guestPhone;
  final String checkInWindow;
  final String specialNotes;

  const StayBookingSummaryScreen({
    super.key,
    required this.hotel,
    required this.roomTitle,
    required this.pricePerNight,
    required this.ratePlan,
    required this.guestName,
    required this.guestEmail,
    required this.guestPhone,
    required this.checkInWindow,
    this.specialNotes = '',
  });

  @override
  State<StayBookingSummaryScreen> createState() => _StayBookingSummaryScreenState();
}

class _StayBookingSummaryScreenState extends State<StayBookingSummaryScreen> {
  final _couponCtrl = TextEditingController();
  String? _appliedCoupon;
  double _discount = 0;
  final int _nights = 2;

  @override
  void dispose() {
    _couponCtrl.dispose();
    super.dispose();
  }

  void _applyCoupon() {
    final code = _couponCtrl.text.trim().toUpperCase();
    if (code.isEmpty) return;
    setState(() {
      _appliedCoupon = code;
      _discount = (widget.pricePerNight * _nights * 0.10).roundToDouble();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Coupon $code applied! Saved ₹ ${_discount.toInt()}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final roomSubtotal = widget.pricePerNight * _nights;
    final taxes = (roomSubtotal * 0.12).roundToDouble();
    final grandTotal = (roomSubtotal + taxes - _discount).clamp(0, double.infinity);
    final advancePay = (grandTotal * 0.5).roundToDouble();
    final balanceDue = grandTotal - advancePay;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomerAppBar(
        title: 'Booking Summary',
        subtitle: 'Review & Pay 50% Advance',
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                BookingSummaryCard(
                  title: widget.hotel.title,
                  subtitle: widget.hotel.location,
                  imageAsset: widget.hotel.image,
                  badgeText: widget.roomTitle,
                  rows: [
                    const BookingSummaryRowData(
                      label: 'Check-in / Check-out',
                      value: '22 Mar - 24 Mar (2 Nights)',
                    ),
                    BookingSummaryRowData(
                      label: 'Rate Plan',
                      value: widget.ratePlan,
                    ),
                    BookingSummaryRowData(
                      label: 'Guest Name',
                      value: widget.guestName,
                    ),
                    BookingSummaryRowData(
                      label: 'Check-in Time',
                      value: widget.checkInWindow,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                CouponInputRow(
                  controller: _couponCtrl,
                  appliedCode: _appliedCoupon,
                  onApply: _applyCoupon,
                  onRemove: () => setState(() {
                    _appliedCoupon = null;
                    _discount = 0;
                    _couponCtrl.clear();
                  }),
                ),
                const SizedBox(height: 14),
                BookingSummaryCard(
                  title: 'Price Breakdown',
                  subtitle: '50% online advance locks your reservation',
                  rows: [
                    BookingSummaryRowData(
                      label: 'Room Charges (₹ ${widget.pricePerNight.toInt()} x $_nights nights)',
                      value: '₹ ${roomSubtotal.toInt()}',
                    ),
                    BookingSummaryRowData(
                      label: 'Taxes & Service Charges (12%)',
                      value: '₹ ${taxes.toInt()}',
                    ),
                    if (_discount > 0)
                      BookingSummaryRowData(
                        label: 'Coupon Discount ($_appliedCoupon)',
                        value: '- ₹ ${_discount.toInt()}',
                        valueColor: AppColors.success,
                      ),
                    BookingSummaryRowData(
                      label: 'Grand Total',
                      value: '₹ ${grandTotal.toInt()}',
                      isHighlight: true,
                    ),
                    BookingSummaryRowData(
                      label: 'Balance at Property',
                      value: '₹ ${balanceDue.toInt()}',
                      valueColor: AppColors.textSecondary,
                    ),
                  ],
                  totalLabel: 'Pay Now (50% Advance)',
                  totalAmount: '₹ ${advancePay.toInt()}',
                ),
                const SizedBox(height: 14),
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StayRequestChangeScreen(hotel: widget.hotel),
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit_calendar_outlined, color: AppColors.primary),
                  label: const Text(
                    'Need to modify dates or rooms? Request Change',
                    style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          BookingPriceBar(
            priceText: '₹ ${advancePay.toInt()}',
            subText: '50% advance • Total ₹ ${grandTotal.toInt()}',
            buttonText: 'Pay Now',
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => StayBookingConfirmedScreen(
                    hotel: widget.hotel,
                    roomTitle: widget.roomTitle,
                    guestName: widget.guestName,
                    advancePaid: advancePay.toInt(),
                    balanceDue: balanceDue.toInt(),
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
