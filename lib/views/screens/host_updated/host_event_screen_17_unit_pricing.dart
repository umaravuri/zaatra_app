import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/utils/host_validators.dart';
import '../../../models/host_updated_property_draft_model.dart';
import 'widgets/host_form_widgets.dart';
import 'host_event_screen_18_rate_plans.dart';

/// event unit name, photography areas, cuisine, facilities,
/// time slots and pricing.
/// Figma: frame 1228744516 (node 1:2567)
class HostEventScreen17UnitPricing extends StatefulWidget {
  final HostUpdatedPropertyDraft draft;
  final Map<String, dynamic> eventData;

  const HostEventScreen17UnitPricing({
    super.key,
    required this.draft,
    required this.eventData,
  });

  @override
  State<HostEventScreen17UnitPricing> createState() => _HostEventScreen17UnitPricingState();
}

class _HostEventScreen17UnitPricingState extends State<HostEventScreen17UnitPricing> {
  static const double _commissionRate = 0.15;

  static const _photographyAreas = ['Garden', 'Lawn', 'Courtyard', 'Terrace', 'Poolside', 'Other'];
  static const _cuisines = ['Veg', 'Non-Veg', 'Both Veg & Non Veg'];
  static const _facilities = [
    'Fans',
    'CCTV',
    'Sound system',
    'Lift',
    'Led screen',
    'Fire safety',
    'Microphone',
    'Wheel chairs',
    'Projector',
    'Swimming pool',
    'WIFI',
    'Gas',
  ];

  final _nameController = TextEditingController();
  final _slot1Controller = TextEditingController();
  final _slot2Controller = TextEditingController();
  final _priceController = TextEditingController();
  final _vegPlateController = TextEditingController();
  final _nonVegPlateController = TextEditingController();
  final _couponController = TextEditingController();

  final Set<String> _photographyOutdoor = {};
  final Set<String> _unitFacilities = {};
  String _cuisine = '';
  bool _twentyFourHours = false;
  String? _appliedCoupon;

  @override
  void initState() {
    super.initState();
    // Pre-fill the unit name when editing or when only one hall type was entered.
    final venueType = widget.eventData['venueType']?.toString() ?? '';
    _nameController.text = widget.eventData['unitName']?.toString() ?? venueType;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _slot1Controller.dispose();
    _slot2Controller.dispose();
    _priceController.dispose();
    _vegPlateController.dispose();
    _nonVegPlateController.dispose();
    _couponController.dispose();
    super.dispose();
  }

  double get _price => double.tryParse(_priceController.text.replaceAll(',', '')) ?? 0;
  double get _earnings => _price * (1 - _commissionRate);

  String _inr(double v) => v.toStringAsFixed(v == v.roundToDouble() ? 0 : 2);

  void _applyCoupon() {
    final code = _couponController.text.trim();
    if (code.isEmpty) {
      showHostError(context, 'Enter a coupon code');
      return;
    }
    // STATIC: coupons are not validated until the backend is integrated.
    setState(() => _appliedCoupon = code);
  }

  void _onContinue() async {
    final error = HostValidators.required(_nameController.text, 'Unit name') ??
        (_cuisine.isEmpty ? 'Select the type of cuisine' : null) ??
        ((!_twentyFourHours &&
                _slot1Controller.text.trim().isEmpty &&
                _slot2Controller.text.trim().isEmpty)
            ? 'Enter at least one time slot, or choose 24 Hours'
            : null) ??
        HostValidators.amount(_priceController.text, 'Price per event');
    if (error != null) {
      showHostError(context, error);
      return;
    }

    final eventData = {
      ...widget.eventData,
      'unitName': _nameController.text.trim(),
      'photographyAreas': _photographyOutdoor.toList(),
      'cuisine': _cuisine,
      'unitFacilities': _unitFacilities.toList(),
      'timeSlots': {
        'slot1': _slot1Controller.text.trim(),
        'slot2': _slot2Controller.text.trim(),
        'twentyFourHours': _twentyFourHours,
      },
      'basePrice': _priceController.text.replaceAll(',', '').trim(),
      'vegPlatePrice': _vegPlateController.text.trim(),
      'nonVegPlatePrice': _nonVegPlateController.text.trim(),
      'commissionPercent': (_commissionRate * 100).round(),
      'couponCode': _appliedCoupon ?? '',
    };

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HostEventScreen18RatePlans(draft: widget.draft, eventData: eventData),
      ),
    );
    if (result is HostUpdatedPropertyDraft && mounted) Navigator.pop(context, result);
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6, top: 4),
        child: Text(
          text,
          style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF6E6E82)),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return HostFormPage(
      title: 'Unit details',
      onContinue: _onContinue,
      children: [
        const HostQuestion('What is the name of this unit', topSpace: 6),
        HostTextField(controller: _nameController, hint: 'Main Hall 1', onChanged: (_) => setState(() {})),
        const SizedBox(height: 6),
        Text(
          'This is the name guests will see on your property page. Choose a name that most accurately describes this unit.',
          style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF6E6E82)),
        ),

        HostMultiChoice(
          question: 'Does the venue provide an outdoor area for photography?',
          options: _photographyAreas,
          selected: _photographyOutdoor,
          onChanged: () => setState(() {}),
        ),
        HostSingleChoice(
          question: 'What type of cuisines are served?',
          options: _cuisines,
          selected: _cuisine,
          onChanged: (v) => setState(() => _cuisine = v),
        ),
        HostMultiChoice(
          question: 'What can guests use at this unit?',
          options: _facilities,
          selected: _unitFacilities,
          onChanged: () => setState(() {}),
        ),

        const HostQuestion('What are your check in and check out time'),
        _label('Slot 1'),
        HostTextField(controller: _slot1Controller, hint: '06:00 AM to 01:00 PM'),
        const SizedBox(height: 10),
        _label('Slot 2'),
        HostTextField(controller: _slot2Controller, hint: '04:00 PM to 11:00 PM'),
        const SizedBox(height: 6),
        HostCheckRow(
          title: '24 Hours',
          checked: _twentyFourHours,
          onTap: () => setState(() => _twentyFourHours = !_twentyFourHours),
        ),

        const HostQuestion('How much do you want to charge per event / per function & per plate'),
        _label('Price per event (including taxes, commission and charges)'),
        HostTextField(
          controller: _priceController,
          hint: '₹ 2,00,000',
          numeric: true,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('Veg plate'),
                  HostTextField(controller: _vegPlateController, hint: '₹800', numeric: true),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('Non-veg plate'),
                  HostTextField(controller: _nonVegPlateController, hint: '₹1500', numeric: true),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF6F3FF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Zaatra Commission ${(_commissionRate * 100).round()}%  (if any coupon applies then 15%)',
                style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              for (final t in const [
                '24/7 helps in your language',
                'Save time with automatically confirmed booking',
                'We promote your place on google and social media platform',
              ])
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check_circle, size: 16, color: Color(0xFF2ECC71)),
                      const SizedBox(width: 8),
                      Expanded(child: Text(t, style: GoogleFonts.poppins(fontSize: 12.5))),
                    ],
                  ),
                ),
              const SizedBox(height: 6),
              Text(
                _price > 0
                    ? 'Your earnings INR ${_inr(_earnings)} (after commission)'
                    : 'Enter a price to see your earnings',
                style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),

        const HostQuestion('Apply Coupon'),
        Row(
          children: [
            Expanded(child: HostTextField(controller: _couponController, hint: 'Enter Coupon Code')),
            const SizedBox(width: 10),
            SizedBox(
              height: 48,
              child: OutlinedButton(onPressed: _applyCoupon, child: const Text('Apply')),
            ),
          ],
        ),
        if (_appliedCoupon != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Coupon "$_appliedCoupon" applied',
              style: GoogleFonts.poppins(fontSize: 12.5, color: const Color(0xFF2E7D32)),
            ),
          ),
      ],
    );
  }
}

