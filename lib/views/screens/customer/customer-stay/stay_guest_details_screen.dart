// Figma: 1:2506 & 1:2436 (Fill your detail)
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../models/hotel_model.dart';
import '../../../widgets/customer_booking_widgets.dart';
import 'stay_booking_summary_screen.dart';

class StayGuestDetailsScreen extends StatefulWidget {
  final Hotel hotel;
  final String roomTitle;
  final double pricePerNight;
  final String ratePlan;

  const StayGuestDetailsScreen({
    super.key,
    required this.hotel,
    required this.roomTitle,
    required this.pricePerNight,
    required this.ratePlan,
  });

  @override
  State<StayGuestDetailsScreen> createState() => _StayGuestDetailsScreenState();
}

class _StayGuestDetailsScreenState extends State<StayGuestDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController(text: 'Rahul Verma');
  final _emailCtrl = TextEditingController(text: 'rahul.verma@example.com');
  final _phoneCtrl = TextEditingController(text: '+91 98765 43210');
  final _cityCtrl = TextEditingController(text: 'Hyderabad');
  final _countryCtrl = TextEditingController(text: 'India');
  final _postalCtrl = TextEditingController(text: '500081');
  final _notesCtrl = TextEditingController();
  bool _saveForFuture = true;
  String _checkInTime = '12:00 PM - 02:00 PM';

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _cityCtrl.dispose();
    _countryCtrl.dispose();
    _postalCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _onContinue() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StayBookingSummaryScreen(
          hotel: widget.hotel,
          roomTitle: widget.roomTitle,
          pricePerNight: widget.pricePerNight,
          ratePlan: widget.ratePlan,
          guestName: _nameCtrl.text.trim(),
          guestEmail: _emailCtrl.text.trim(),
          guestPhone: _phoneCtrl.text.trim(),
          checkInWindow: _checkInTime,
          specialNotes: _notesCtrl.text.trim(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomerAppBar(
        title: 'Fill Your Details',
        subtitle: 'Step 2 of 3 • Guest Information',
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
                      label: 'Full Name *',
                      hint: 'Enter your full name',
                      controller: _nameCtrl,
                      prefixIcon: Icons.person_outline_rounded,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Full name is required' : null,
                    ),
                    const SizedBox(height: 14),
                    CustomerFormField(
                      label: 'Email Address *',
                      hint: 'Confirmation voucher will be sent here',
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: Icons.email_outlined,
                      validator: (v) => (v == null || !v.contains('@'))
                          ? 'Enter a valid email address'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    CustomerFormField(
                      label: 'Phone Number *',
                      hint: '+91 98765 43210',
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      prefixIcon: Icons.phone_outlined,
                      validator: (v) =>
                          (v == null || v.trim().length < 10) ? 'Enter a valid phone number' : null,
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: CustomerFormField(
                            label: 'City',
                            hint: 'Hyderabad',
                            controller: _cityCtrl,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CustomerFormField(
                            label: 'Postal Code',
                            hint: '500081',
                            controller: _postalCtrl,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    CustomerFormField(
                      label: 'Country / Region',
                      hint: 'India',
                      controller: _countryCtrl,
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Estimated Check-in Time',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        '12:00 PM - 02:00 PM',
                        '02:00 PM - 06:00 PM',
                        'After 06:00 PM',
                      ].map((slot) {
                        final selected = _checkInTime == slot;
                        return ChoiceChip(
                          label: Text(
                            slot,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: selected ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                          selected: selected,
                          selectedColor: AppColors.primary,
                          backgroundColor: Colors.white,
                          side: BorderSide(
                            color: selected ? AppColors.primary : AppColors.border,
                          ),
                          onSelected: (_) => setState(() => _checkInTime = slot),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    CustomerFormField(
                      label: 'Special Requests (Optional)',
                      hint: 'Early check-in, high floor, airport pickup...',
                      controller: _notesCtrl,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        activeThumbColor: AppColors.primary,
                        title: const Text(
                          'Save details for future bookings',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        value: _saveForFuture,
                        onChanged: (v) => setState(() => _saveForFuture = v),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
          BookingPriceBar(
            priceText: '₹ ${(widget.pricePerNight * 2).toInt()}',
            subText: '2 Nights • ${widget.roomTitle}',
            buttonText: 'Next: Summary',
            onPressed: _onContinue,
          ),
        ],
      ),
    );
  }
}
