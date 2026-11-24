import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/host_updated_property_draft_model.dart';
import '../../../services/host_api_service.dart';
import '../../../core/utils/host_validators.dart';
import 'widgets/host_components.dart';
import 'host_screen_18_upload_photos.dart';

/// Figma: frame 1228744490 (node 1:277)
/// Figma: frame 1228744513 (node 1:1745)
class HostScreen17UnitDetails extends StatefulWidget {
  final HostUpdatedPropertyDraft draft;
  final Map<String, dynamic>? currentUnit;

  const HostScreen17UnitDetails({
    super.key,
    required this.draft,
    this.currentUnit,
  });

  @override
  State<HostScreen17UnitDetails> createState() => _HostScreen17UnitDetailsState();
}

class _HostScreen17UnitDetailsState extends State<HostScreen17UnitDetails> {
  late HostUpdatedPropertyDraft _draft;

  // 1. Booking Mode
  String _bookingAcceptMode = 'instant'; // 'instant' or 'review'

  // 2. Room Count
  late TextEditingController _roomsCountController;

  // 3. Bed Counters
  int _singleBeds = 0;
  int _doubleBeds = 1;
  int _largeBeds = 0;
  int _extraLargeBeds = 1;

  // 4. Room Size
  late TextEditingController _roomSizeController;
  String _roomSizeUnit = 'Sqm';

  // 5. Smoking
  bool _smokingAllowed = true;

  // 6. Bathroom
  bool _bathroomPrivate = true;
  final Set<String> _selectedBathroomItems = {
    'Toilet Paper',
    'Shower',
    'Toilet',
    'Hair dryer',
    'Towels',
  };

  // 7. Parking
  String _parkingAvailability = 'free'; // 'free', 'paid', 'no'

  // 8. Amenities
  final Set<String> _selectedAmenities = {
    'Flat - screen TV',
    'Air Conditionality',
    'Linen',
    'Desk',
    'Ward rode or closet',
  };
  final Set<String> _selectedOutdoor = {'Balcony'};
  final Set<String> _selectedFoodDrink = {'Electric kettle', 'Tea / coffee maker'};

  // 9. Room Name
  String _roomName = 'Double room';

  // 10. Check-in / Check-out Times
  String _checkInFrom = '12:00';
  String _checkInUntil = '12:00';
  String _checkOutFrom = '00:00';
  String _checkOutUntil = '10:00';

  // 11. Pricing
  late TextEditingController _priceController;
  final bool _helpInLanguage = true;
  final bool _autoConfirmedBooking = true;
  final bool _promoteGoogleSocial = true;

  // 12. Rate Plans & Policies
  bool _freeCancellation24h = true;
  bool _freeCancellationBefore18 = true;
  bool _childrenStayFree = true;
  bool _nonRefundableGuestsCannotCancel = true;
  bool _nonRefundableDiscount10 = true;

  // 13. Rules & Safety
  late TextEditingController _propertyRulesController;
  late TextEditingController _safetySecurityController;

  @override
  void initState() {
    super.initState();
    _draft = widget.draft;
    // Restore values when editing an existing unit; otherwise start empty.
    final unit = widget.currentUnit ?? const <String, dynamic>{};
    _roomsCountController = TextEditingController(text: unit['roomsCount']?.toString() ?? '1');
    _roomSizeController = TextEditingController(text: '25');
    _priceController = TextEditingController(text: unit['pricePerNight']?.toString() ?? '');
    _propertyRulesController = TextEditingController(text: unit['rules']?.toString() ?? '');
    _safetySecurityController = TextEditingController(text: unit['safety']?.toString() ?? '');
  }

  @override
  void dispose() {
    _roomsCountController.dispose();
    _roomSizeController.dispose();
    _priceController.dispose();
    _propertyRulesController.dispose();
    _safetySecurityController.dispose();
    super.dispose();
  }

  double get _basePrice => double.tryParse(_priceController.text.replaceAll(',', '')) ?? 0.0;
  double get _zaatraEarnings => _basePrice * 0.73; // ~INR 3,285 on 4,500 after 20% comm + taxes

  void _onNext() async {
    final roomsError = HostValidators.required(_roomsCountController.text, 'Number of rooms');
    final priceError = HostValidators.amount(_priceController.text, 'Price');
    final totalBeds = _singleBeds + _doubleBeds + _largeBeds + _extraLargeBeds;
    final error = roomsError ??
        priceError ??
        (totalBeds == 0 ? 'Select at least one bed' : null);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.redAccent),
      );
      return;
    }

    // Capacity is derived from the beds selected: 1 guest per single bed, 2 per other bed.
    final guests = _singleBeds + 2 * (_doubleBeds + _largeBeds + _extraLargeBeds);
    final bedParts = <String>[
      if (_singleBeds > 0) '$_singleBeds single',
      if (_doubleBeds > 0) '$_doubleBeds double',
      if (_largeBeds > 0) '$_largeBeds large',
      if (_extraLargeBeds > 0) '$_extraLargeBeds extra large',
    ];

    final unitData = {
      ...?widget.currentUnit,
      'bookingAcceptMode': _bookingAcceptMode,
      'roomsCount': _roomsCountController.text.trim(),
      'bedCounts': {
        'single': _singleBeds,
        'double': _doubleBeds,
        'large': _largeBeds,
        'extraLarge': _extraLargeBeds,
      },
      'beds': totalBeds,
      'bedSummary': bedParts.join(', '),
      'guests': guests.toString(),
      'bathrooms': 1,
      'basePrice': _priceController.text.replaceAll(',', '').trim(),
      'roomSize': '${_roomSizeController.text.trim()} $_roomSizeUnit',
      'smoking': _smokingAllowed,
      'bathroomPrivate': _bathroomPrivate,
      'bathroomItems': _selectedBathroomItems.toList(),
      'parking': _parkingAvailability,
      'amenities': _selectedAmenities.toList(),
      'outdoor': _selectedOutdoor.toList(),
      'foodDrink': _selectedFoodDrink.toList(),
      'roomName': _roomName,
      'checkIn': 'From $_checkInFrom Until $_checkInUntil',
      'checkOut': 'From $_checkOutFrom Until $_checkOutUntil',
      'pricePerNight': _priceController.text.trim(),
      'rules': _propertyRulesController.text.trim(),
      'safety': _safetySecurityController.text.trim(),
    };

    // Save Step 15 asynchronously
    HostApiService.saveWizardStep(
      step: 15,
      propertyId: _draft.propertyId,
      payload: {
        'bookingAcceptance': _bookingAcceptMode,
        'roomsCount': int.tryParse(_roomsCountController.text.trim()) ?? 2,
        'roomSize': '${_roomSizeController.text.trim()} $_roomSizeUnit',
        'beds': {
          'singleBedCount': _singleBeds,
          'doubleBedCount': _doubleBeds,
          'kingBedCount': _largeBeds,
          'extraLargeDoubleBedCount': _extraLargeBeds,
          'moreBedOptions': '',
        },
      },
    );

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HostScreen18UploadPhotos(
          draft: _draft,
          unitData: unitData,
        ),
      ),
    );

    if (result != null && result is HostUpdatedPropertyDraft && mounted) {
      setState(() {
        _draft = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            const HostBackgroundGraphic(),
            Column(
          children: [
            HostTopBar(
              title: '',
              onBack: () => Navigator.pop(context, _draft),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. How you accept booking
                    _buildSectionTitle('How you accept booking?'),
                    const SizedBox(height: 10),
                    _buildRadioRow(
                      selected: _bookingAcceptMode == 'instant',
                      title: 'Instant Bookings (bookings are instantly confirmed)',
                      onTap: () => setState(() => _bookingAcceptMode = 'instant'),
                    ),
                    const SizedBox(height: 8),
                    _buildRadioRow(
                      selected: _bookingAcceptMode == 'review',
                      title: 'Review every request (you review the every request)',
                      onTap: () => setState(() => _bookingAcceptMode = 'review'),
                    ),
                    const SizedBox(height: 20),
                    const Divider(color: Color(0xFFEEEEF2)),

                    // 2. How many rooms
                    _buildSectionTitle('How many rooms of this type do you have?'),
                    const SizedBox(height: 8),
                    _buildSimpleTextField(controller: _roomsCountController, hint: '2', isNumeric: true),
                    const SizedBox(height: 20),
                    const Divider(color: Color(0xFFEEEEF2)),

                    // 3. Which beds are available
                    _buildSectionTitle('Which beds are available in this room?'),
                    const SizedBox(height: 10),
                    _buildRadioRow(selected: true, title: 'Yes', onTap: () {}),
                    const SizedBox(height: 12),
                    _buildBedStepper(
                      title: 'Single bed',
                      subtitle: '90 - 130 cm wide',
                      count: _singleBeds,
                      onDec: () => setState(() => _singleBeds = (_singleBeds > 0) ? _singleBeds - 1 : 0),
                      onInc: () => setState(() => _singleBeds++),
                    ),
                    _buildBedStepper(
                      title: 'Double bed',
                      subtitle: '131 - 150 cm wide',
                      count: _doubleBeds,
                      onDec: () => setState(() => _doubleBeds = (_doubleBeds > 0) ? _doubleBeds - 1 : 0),
                      onInc: () => setState(() => _doubleBeds++),
                    ),
                    _buildBedStepper(
                      title: 'Large Bed (king size)',
                      subtitle: '151 - 180 cm wide',
                      count: _largeBeds,
                      onDec: () => setState(() => _largeBeds = (_largeBeds > 0) ? _largeBeds - 1 : 0),
                      onInc: () => setState(() => _largeBeds++),
                    ),
                    _buildBedStepper(
                      title: 'Extra - large double bed',
                      subtitle: '(super - large) size • 181 - 210 cm',
                      count: _extraLargeBeds,
                      onDec: () => setState(() => _extraLargeBeds = (_extraLargeBeds > 0) ? _extraLargeBeds - 1 : 0),
                      onInc: () => setState(() => _extraLargeBeds++),
                    ),
                    const SizedBox(height: 8),
                    _buildRadioRow(selected: false, title: 'More bed options', onTap: () {}),
                    const SizedBox(height: 20),
                    const Divider(color: Color(0xFFEEEEF2)),

                    // 4. Room size
                    _buildSectionTitle('How big is this room?'),
                    const SizedBox(height: 4),
                    Text('Room size - (optional)', style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF757585))),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: _buildSimpleTextField(controller: _roomSizeController, hint: '25', isNumeric: true),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE5E4ED)),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _roomSizeUnit,
                                isExpanded: true,
                                icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF757585)),
                                style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF1E1E24)),
                                items: const [
                                  DropdownMenuItem(value: 'Sqm', child: Text('Sqm')),
                                  DropdownMenuItem(value: 'Sqft', child: Text('Sqft')),
                                ],
                                onChanged: (v) {
                                  if (v != null) setState(() => _roomSizeUnit = v);
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Divider(color: Color(0xFFEEEEF2)),

                    // 5. Smoking allowed
                    _buildSectionTitle('Is smoking allowed in this room?'),
                    const SizedBox(height: 10),
                    _buildRadioRow(selected: _smokingAllowed == true, title: 'Yes', onTap: () => setState(() => _smokingAllowed = true)),
                    const SizedBox(height: 8),
                    _buildRadioRow(selected: _smokingAllowed == false, title: 'NO', onTap: () => setState(() => _smokingAllowed = false)),
                    const SizedBox(height: 20),
                    const Divider(color: Color(0xFFEEEEF2)),

                    // 6. Bathroom details
                    _buildSectionTitle('Bathroom Details'),
                    const SizedBox(height: 6),
                    Text('Is the bathroom private?', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 10),
                    _buildRadioRow(selected: _bathroomPrivate == true, title: 'Yes', onTap: () => setState(() => _bathroomPrivate = true)),
                    const SizedBox(height: 8),
                    _buildRadioRow(selected: _bathroomPrivate == false, title: 'NO , it is shared', onTap: () => setState(() => _bathroomPrivate = false)),
                    const SizedBox(height: 16),
                    Text('Which bathroom items are available in this room?', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 10),
                    ...['Toilet Paper', 'Shower', 'Toilet', 'Hair dryer', 'Bath', 'Free toilets', 'Bidet', 'Slippers', 'Spa bath'].map(
                      (item) => _buildCheckboxTile(
                        title: item,
                        checked: _selectedBathroomItems.contains(item),
                        onToggle: () {
                          setState(() {
                            if (_selectedBathroomItems.contains(item)) {
                              _selectedBathroomItems.remove(item);
                            } else {
                              _selectedBathroomItems.add(item);
                            }
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Divider(color: Color(0xFFEEEEF2)),

                    // 7. Parking
                    _buildSectionTitle('Is Parking available to guests?'),
                    const SizedBox(height: 10),
                    _buildRadioRow(selected: _parkingAvailability == 'free', title: 'Yes , free', onTap: () => setState(() => _parkingAvailability = 'free')),
                    const SizedBox(height: 8),
                    _buildRadioRow(selected: _parkingAvailability == 'paid', title: 'Yes , paid', onTap: () => setState(() => _parkingAvailability = 'paid')),
                    const SizedBox(height: 8),
                    _buildRadioRow(selected: _parkingAvailability == 'no', title: 'NO', onTap: () => setState(() => _parkingAvailability = 'no')),
                    const SizedBox(height: 20),
                    const Divider(color: Color(0xFFEEEEF2)),

                    // 8. Amenities
                    _buildSectionTitle('What can guest use in this room?'),
                    const SizedBox(height: 4),
                    Text('Generate Amenities', style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF757585))),
                    const SizedBox(height: 10),
                    ...[
                      'Cloth rack',
                      'Flat - screen TV',
                      'Air Conditionality',
                      'Linen',
                      'Desk',
                      'Wake - up service',
                      'Towels',
                      'Ward rode or closet',
                      'Heating',
                      'Fan',
                      'Safety deposit box',
                      'Towels / sheets (extra fee)',
                      'Entire unit located on ground floor',
                    ].map(
                      (a) => _buildCheckboxTile(
                        title: a,
                        checked: _selectedAmenities.contains(a),
                        onToggle: () {
                          setState(() {
                            if (_selectedAmenities.contains(a)) {
                              _selectedAmenities.remove(a);
                            } else {
                              _selectedAmenities.add(a);
                            }
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('Outdoor and views', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    ...['Balcony', 'Terrace', 'View'].map(
                      (o) => _buildCheckboxTile(
                        title: o,
                        checked: _selectedOutdoor.contains(o),
                        onToggle: () {
                          setState(() {
                            if (_selectedOutdoor.contains(o)) {
                              _selectedOutdoor.remove(o);
                            } else {
                              _selectedOutdoor.add(o);
                            }
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('Food and drink', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    ...['Electric kettle', 'Tea / coffee maker', 'Dining Area', 'Dining Table', 'Microwave'].map(
                      (f) => _buildCheckboxTile(
                        title: f,
                        checked: _selectedFoodDrink.contains(f),
                        onToggle: () {
                          setState(() {
                            if (_selectedFoodDrink.contains(f)) {
                              _selectedFoodDrink.remove(f);
                            } else {
                              _selectedFoodDrink.add(f);
                            }
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Divider(color: Color(0xFFEEEEF2)),

                    // 9. Room Name
                    _buildSectionTitle('What is the name of this room?'),
                    const SizedBox(height: 4),
                    Text(
                      'This is the name guest will see on your property page. Choose a name that most accurately describes a room.',
                      style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF555566), height: 1.4),
                    ),
                    const SizedBox(height: 12),
                    Text('Room Name', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE5E4ED)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _roomName,
                          isExpanded: true,
                          icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF757585)),
                          style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF1E1E24)),
                          items: const [
                            DropdownMenuItem(value: 'Double room', child: Text('Double room')),
                            DropdownMenuItem(value: 'Deluxe Suite', child: Text('Deluxe Suite')),
                            DropdownMenuItem(value: 'King Studio', child: Text('King Studio')),
                            DropdownMenuItem(value: 'Family Villa Room', child: Text('Family Villa Room')),
                          ],
                          onChanged: (v) {
                            if (v != null) setState(() => _roomName = v);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Divider(color: Color(0xFFEEEEF2)),

                    // 10. Check-in Check-out times
                    _buildSectionTitle('What are your check-in checkout times?'),
                    const SizedBox(height: 12),
                    Text('Check-in', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(child: _buildTimeDropdown('From', _checkInFrom, (v) => setState(() => _checkInFrom = v))),
                        const SizedBox(width: 14),
                        Expanded(child: _buildTimeDropdown('Until', _checkInUntil, (v) => setState(() => _checkInUntil = v))),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text('Check-Out', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(child: _buildTimeDropdown('From', _checkOutFrom, (v) => setState(() => _checkOutFrom = v))),
                        const SizedBox(width: 14),
                        Expanded(child: _buildTimeDropdown('Until', _checkOutUntil, (v) => setState(() => _checkOutUntil = v))),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Divider(color: Color(0xFFEEEEF2)),

                    // 11. Pricing & Commission
                    _buildSectionTitle('How much do you want to charge per night?'),
                    const SizedBox(height: 10),
                    Text('Price guest pay', style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF757585))),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFE5E4ED)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            children: [
                              Text('INR', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              SizedBox(width: 4),
                              Icon(Icons.arrow_drop_down, size: 20, color: Color(0xFF757585)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              border: Border.all(color: const Color(0xFFE5E4ED)),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _priceController,
                                    keyboardType: TextInputType.number,
                                    onChanged: (_) => setState(() {}),
                                    style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
                                    decoration: const InputDecoration(border: InputBorder.none),
                                  ),
                                ),
                                const Icon(Icons.edit, size: 18, color: Color(0xFF757585)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text('including taxes, commission and charges', style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF757585))),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text('Zaatra Commission', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFE5E4ED)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('20%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '(If any coupon applies then 15%)',
                            style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF757585)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildCheckFeature('24/7 helps in your language', _helpInLanguage),
                    _buildCheckFeature('Save time with automatically confirmed booking', _autoConfirmedBooking),
                    _buildCheckFeature('We promote your place on google and social media platform', _promoteGoogleSocial),
                    const SizedBox(height: 12),
                    Text(
                      'Your earnings INR ${_zaatraEarnings.toStringAsFixed(2)} (including Taxes)',
                      style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF2E7D32)),
                    ),
                    const SizedBox(height: 20),
                    const Divider(color: Color(0xFFEEEEF2)),

                    // 12. Standard rate plan
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSectionTitle('Standard rate plan'),
                        const Icon(Icons.edit, size: 18, color: Color(0xFF757585)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('Price per group', style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF757585))),
                    const SizedBox(height: 8),
                    _buildRatePlanRow('Rx3', 'INR ${_priceController.text.trim()}'),
                    _buildRatePlanRow('Rx2', 'INR ${_priceController.text.trim()}'),
                    _buildRatePlanRow('Rx1', 'INR ${_priceController.text.trim()}'),
                    const SizedBox(height: 20),
                    const Divider(color: Color(0xFFEEEEF2)),

                    // 13. Cancellation policy
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSectionTitle('Cancellation Policy'),
                        const Icon(Icons.edit, size: 18, color: Color(0xFF757585)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _buildCheckboxTile(
                      title: 'Guest who cancel within 24 hour will have their cancellation fee waived',
                      checked: _freeCancellation24h,
                      onToggle: () => setState(() => _freeCancellation24h = !_freeCancellation24h),
                    ),
                    _buildCheckboxTile(
                      title: 'Guests can cancel their booking for free before 18:00 on the day of arrival. The guests will be charged cost of the first night if they cancel after this.',
                      checked: _freeCancellationBefore18,
                      onToggle: () => setState(() => _freeCancellationBefore18 = !_freeCancellationBefore18),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSectionTitle('Child rates for families'),
                        const Icon(Icons.edit, size: 18, color: Color(0xFF757585)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildCheckboxTile(
                      title: 'Children stay for free',
                      checked: _childrenStayFree,
                      onToggle: () => setState(() => _childrenStayFree = !_childrenStayFree),
                    ),
                    const SizedBox(height: 16),
                    _buildSectionTitle('Non - refundable rate plan'),
                    const SizedBox(height: 4),
                    const Row(
                      children: [
                        Icon(Icons.info_outline, size: 16, color: Color(0xFF757585)),
                        SizedBox(width: 6),
                        Text('Price and cancellation policy', style: TextStyle(fontSize: 12, color: Color(0xFF757585))),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildCheckboxTile(
                      title: 'Guests cannot cancel their bookings for free at any time.',
                      checked: _nonRefundableGuestsCannotCancel,
                      onToggle: () => setState(() => _nonRefundableGuestsCannotCancel = !_nonRefundableGuestsCannotCancel),
                    ),
                    _buildCheckboxTile(
                      title: 'Guests will pay 10% less than the standard rate for a non refundable rate.',
                      checked: _nonRefundableDiscount10,
                      onToggle: () => setState(() => _nonRefundableDiscount10 = !_nonRefundableDiscount10),
                    ),
                    const SizedBox(height: 20),
                    const Divider(color: Color(0xFFEEEEF2)),

                    // 14. Property rules & Safety
                    _buildSectionTitle('Property rules'),
                    const SizedBox(height: 8),
                    _buildSimpleTextField(controller: _propertyRulesController, hint: 'Stay about property rules'),
                    const SizedBox(height: 16),
                    _buildSectionTitle('Safety Security'),
                    const SizedBox(height: 8),
                    _buildSimpleTextField(controller: _safetySecurityController, hint: 'Stay about Safety & security'),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: HostBottomButton(
                text: 'Next',
                onPressed: _onNext,
              ),
            ),
          ],
        ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF1E1E24),
      ),
    );
  }

  Widget _buildRadioRow({
    required bool selected,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 2),
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? const Color(0xFF5E42C2) : const Color(0xFFA0A0B2),
                  width: selected ? 5.5 : 1.5,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF424252),
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBedStepper({
    required String title,
    required String subtitle,
    required int count,
    required VoidCallback onDec,
    required VoidCallback onInc,
  }) {
    final hasCount = count > 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: hasCount ? const Color(0xFF5E42C2) : const Color(0xFFA0A0B2),
                      width: hasCount ? 5.5 : 1.5,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF1E1E24),
                        ),
                      ),
                      Text(
                        subtitle,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: const Color(0xFF757585),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE5E4ED)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove, size: 16),
                  onPressed: onDec,
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  padding: EdgeInsets.zero,
                ),
                Text('$count', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                IconButton(
                  icon: const Icon(Icons.add, size: 16),
                  onPressed: onInc,
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckboxTile({
    required String title,
    required bool checked,
    required VoidCallback onToggle,
  }) {
    return InkWell(
      onTap: onToggle,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 2),
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: checked ? const Color(0xFF5E42C2) : const Color(0xFFE8E5F3),
                borderRadius: BorderRadius.circular(4),
              ),
              child: checked ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF424252), height: 1.35),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckFeature(String title, bool checked) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: const Color(0xFF5E42C2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Icon(Icons.check, size: 14, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(title, style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF555566))),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeDropdown(String label, String value, ValueChanged<String> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE5E4ED)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text('$label ', style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF757585))),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: '00:00', child: Text('00:00')),
                  DropdownMenuItem(value: '10:00', child: Text('10:00')),
                  DropdownMenuItem(value: '12:00', child: Text('12:00')),
                  DropdownMenuItem(value: '14:00', child: Text('14:00')),
                  DropdownMenuItem(value: '18:00', child: Text('18:00')),
                ],
                onChanged: (v) {
                  if (v != null) onChanged(v);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatePlanRow(String rx, String price) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(rx, style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF555566))),
          Text(price, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF1E1E24))),
        ],
      ),
    );
  }

  Widget _buildSimpleTextField({
    required TextEditingController controller,
    required String hint,
    bool isNumeric = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E4ED)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
        style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF1E1E24)),
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          hintText: hint,
          border: InputBorder.none,
        ),
      ),
    );
  }
}


********************************************************************************
================================================================================
