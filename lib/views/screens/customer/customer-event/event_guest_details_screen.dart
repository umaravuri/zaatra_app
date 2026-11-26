// Figma: 1:2436 (Event Guest Details Form)
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../widgets/customer_booking_widgets.dart';
import 'event_booking_summary_screen.dart';

class EventGuestDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> venue;
  final Map<String, dynamic> hall;
  final String eventType;
  final String eventDate;
  final int guestCount;
  final String selectedSlot;
  final int addonsTotal;

  const EventGuestDetailsScreen({
    super.key,
    required this.venue,
    required this.hall,
    required this.eventType,
    required this.eventDate,
    required this.guestCount,
    required this.selectedSlot,
    required this.addonsTotal,
  });

  @override
  State<EventGuestDetailsScreen> createState() => _EventGuestDetailsScreenState();
}

class _EventGuestDetailsScreenState extends State<EventGuestDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController(text: 'Vikram Aditya');
  final _emailCtrl = TextEditingController(text: 'vikram.events@example.com');
  final _phoneCtrl = TextEditingController(text: '+91 98480 12345');
  final _guestsCtrl = TextEditingController();
  String _cateringPackage = 'Veg Deluxe Plate';

  @override
  void initState() {
    super.initState();
    _guestsCtrl.text = '${widget.guestCount}';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _guestsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vegRate = widget.venue['vegPlatePrice'] as int;
    final nonVegRate = widget.venue['nonVegPlatePrice'] as int;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomerAppBar(
        title: 'Organizer Details',
        subtitle: 'Event Contact & Catering Preference',
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomerFormField(
                      label: 'Organizer Full Name *',
                      hint: 'Enter organizer name',
                      controller: _nameCtrl,
                      prefixIcon: Icons.person_outline_rounded,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Organizer name is required' : null,
                    ),
                    const SizedBox(height: 14),
                    CustomerFormField(
                      label: 'Email Address *',
                      hint: 'Booking voucher will be sent here',
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: Icons.email_outlined,
                      validator: (v) =>
                          (v == null || !v.contains('@')) ? 'Valid email is required' : null,
                    ),
                    const SizedBox(height: 14),
                    CustomerFormField(
                      label: 'Phone Number *',
                      hint: '+91 98480 12345',
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      prefixIcon: Icons.phone_outlined,
                      validator: (v) =>
                          (v == null || v.trim().length < 10) ? 'Valid phone is required' : null,
                    ),
                    const SizedBox(height: 14),
                    CustomerFormField(
                      label: 'Confirmed Guest Count',
                      hint: 'e.g. 350',
                      controller: _guestsCtrl,
                      keyboardType: TextInputType.number,
                      prefixIcon: Icons.groups_outlined,
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Select Catering Package',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...[
                      'Veg Deluxe Plate (₹$vegRate/plate)',
                      'Non-Veg Royal Plate (₹$nonVegRate/plate)',
                      'Hall Only (No Catering)',
                    ].map((pkg) {
                      final selected = _cateringPackage == pkg ||
                          (pkg.startsWith('Veg') && _cateringPackage == 'Veg Deluxe Plate');
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected ? AppColors.primary : AppColors.border,
                          ),
                        ),
                        child: RadioListTile<String>(
                          value: pkg,
                          groupValue: _cateringPackage.contains('(')
                              ? _cateringPackage
                              : 'Veg Deluxe Plate (₹$vegRate/plate)',
                          activeColor: AppColors.primary,
                          title: Text(
                            pkg,
                            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                          ),
                          onChanged: (v) => setState(() => _cateringPackage = v!),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
          BookingPriceBar(
            priceText: '₹ ${(widget.hall['rent'] as int) + widget.addonsTotal}',
            subText: '${widget.hall['name']} • ${widget.eventDate}',
            buttonText: 'Next: Summary',
            onPressed: () {
              if (!_formKey.currentState!.validate()) return;
              final parsedGuests = int.tryParse(_guestsCtrl.text.trim()) ?? widget.guestCount;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EventBookingSummaryScreen(
                    venue: widget.venue,
                    hall: widget.hall,
                    eventType: widget.eventType,
                    eventDate: widget.eventDate,
                    guestCount: parsedGuests,
                    selectedSlot: widget.selectedSlot,
                    addonsTotal: widget.addonsTotal,
                    organizerName: _nameCtrl.text.trim(),
                    cateringPackage: _cateringPackage,
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
