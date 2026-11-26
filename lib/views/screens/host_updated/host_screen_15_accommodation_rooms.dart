import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../models/host_updated_property_draft_model.dart';
import '../../../services/host_api_service.dart';
import '../../../core/utils/host_validators.dart';
import 'widgets/host_components.dart';
import 'host_event_screen_11_event_types.dart';

/// Figma: frame 1228744515 (node 1:2312)
class HostScreen15AccommodationRooms extends StatefulWidget {
  final HostUpdatedPropertyDraft draft;

  const HostScreen15AccommodationRooms({
    super.key,
    required this.draft,
  });

  @override
  State<HostScreen15AccommodationRooms> createState() => _HostScreen15AccommodationRoomsState();
}

class _HostScreen15AccommodationRoomsState extends State<HostScreen15AccommodationRooms> {
  late HostUpdatedPropertyDraft _draft;

  // 1. Accommodation Rooms
  bool _hasAccommodationRooms = true;
  late TextEditingController _roomsCountController;

  // 2. Bed Steppers
  int _singleBeds = 0;
  int _doubleBeds = 1;
  int _largeBeds = 0;
  int _extraLargeBeds = 1;
  int _guestCount = 3;

  // 3. Bathroom Details
  bool _isBathroomPrivate = true;
  final Set<String> _selectedBathroomItems = {
    'Toilet Paper',
    'Shower',
    'Toilet',
    'Hair dryer',
    'Bath',
  };

  final List<String> _allBathroomItems = const [
    'Toilet Paper',
    'Shower',
    'Toilet',
    'Hair dryer',
    'Bath',
    'Free toilets',
    'Bidet',
    'Slippers',
    'Spa bath',
  ];

  // 4. Outdoor and Views
  final Set<String> _selectedOutdoorViews = {'Balcony'};
  final List<String> _allOutdoorViews = const ['Balcony', 'Terrace', 'View'];

  // 5. Food and Drink
  final Set<String> _selectedFoodDrink = {'Electric kettle', 'Tea / coffee maker'};
  final List<String> _allFoodDrink = const [
    'Electric kettle',
    'Tea / coffee maker',
    'Dining Area',
    'Dining Table',
    'Microwave',
  ];

  // 6. Room Name
  String _selectedRoomName = 'Double room';
  final List<String> _roomNameOptions = const [
    'Double room',
    'Single room',
    'Twin room',
    'Deluxe Room',
    'Family Suite',
    'Studio Apartment',
  ];

  // 7. Check-in / Checkout times
  String _checkInFrom = '12:00';
  String _checkInUntil = '12:00';
  String _checkOutFrom = '00:00';
  String _checkOutUntil = '10:00';

  final List<String> _timeOptions = const [
    '00:00', '06:00', '08:00', '10:00', '11:00', '12:00',
    '13:00', '14:00', '16:00', '18:00', '20:00', '22:00',
  ];

  // 8. Pricing & Commission
  late TextEditingController _priceController;
  String _selectedCurrency = 'INR';
  bool _helpInLanguage = true;
  bool _autoConfirmedBooking = true;
  bool _promoteGoogleSocial = true;

  // 9. Standard rate plan
  // 10. Cancellation Policy
  bool _cancel24hWaived = true;
  bool _cancelFreeBefore18 = true;

  // 11. Photos
  final List<XFile> _pickedPhotos = [];
  final ImagePicker _picker = ImagePicker();
  // No pre-loaded sample photos; the host adds their own.
  final List<String> _samplePhotos = const [];

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _draft = widget.draft;
    _roomsCountController = TextEditingController(text: '2');
    _priceController = TextEditingController(text: '4500');
  }

  @override
  void dispose() {
    _roomsCountController.dispose();
    _priceController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  double get _enteredPrice => double.tryParse(_priceController.text.trim()) ?? 4500.0;
  double get _zaatraEarnings => _enteredPrice * 0.73; // ~INR 3,285 on 4,500 after 20% commission + taxes

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          _pickedPhotos.addAll(images);
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open gallery: $e')),
      );
    }
  }

  void _onContinue() async {
    if (!_hasAccommodationRooms) {
      Navigator.pop(context, _draft);
      return;
    }

    final error = HostValidators.required(_roomsCountController.text, 'Number of rooms') ??
        HostValidators.amount(_priceController.text, 'Price');
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.redAccent),
      );
      return;
    }

    final photoPaths = _pickedPhotos.isNotEmpty
        ? _pickedPhotos.map((f) => f.path).toList()
        : _samplePhotos;

    final accommodationUnit = {
      'unitId': 'unit_${DateTime.now().millisecondsSinceEpoch}',
      'purpose': 'Stay / Accommodation',
      'unitType': _selectedRoomName,
      'roomName': _selectedRoomName,
      'roomsCount': _roomsCountController.text.trim(),
      'guests': _guestCount.toString(),
      'beds': _doubleBeds + _extraLargeBeds + _singleBeds + _largeBeds,
      'bedSummary': '$_extraLargeBeds extra large double bed, $_doubleBeds double bed',
      'bathrooms': _isBathroomPrivate ? 'Private' : 'Shared',
      'bathroomItems': _selectedBathroomItems.toList(),
      'outdoorViews': _selectedOutdoorViews.toList(),
      'foodDrink': _selectedFoodDrink.toList(),
      'checkIn': 'From $_checkInFrom Until $_checkInUntil',
      'checkOut': 'From $_checkOutFrom Until $_checkOutUntil',
      'pricePerNight': _priceController.text.trim(),
      'basePrice': _priceController.text.trim(),
      'currency': _selectedCurrency,
      'photos': photoPaths,
      'ratePlan': {
        'occupancy': 'Rx3',
        'price': _priceController.text.trim(),
      },
      'cancellation': {
        'waiver24h': _cancel24hWaived,
        'freeBefore18': _cancelFreeBefore18,
      },
    };

    final updatedUnits = List<Map<String, dynamic>>.from(_draft.units)..add(accommodationUnit);
    final updatedDraft = _draft.copyWith(units: updatedUnits);

    // Save Step 15 asynchronously
    HostApiService.saveWizardStep(
      step: 15,
      propertyId: updatedDraft.propertyId,
      payload: {
        'roomsCount': int.tryParse(_roomsCountController.text.trim()) ?? 1,
        'beds': {
          'singleBedCount': _singleBeds,
          'doubleBedCount': _doubleBeds,
          'kingBedCount': _largeBeds,
          'extraLargeDoubleBedCount': _extraLargeBeds,
        },
      },
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Accommodation unit added successfully!'),
        backgroundColor: Color(0xFF2E7D32),
      ),
    );

    Navigator.pop(context, updatedDraft);
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
                  title: 'Add Unit 2',
                  onBack: () => Navigator.pop(context, _draft),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Are you listing this unit for
                        Text(
                          'Are you listing this unit for',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1E1E24),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Accommodations radio
                        _buildPurposeRadioTile(
                          title: 'Accommodations',
                          isSelected: true,
                          onTap: () {},
                        ),
                        const SizedBox(height: 10),

                        // Events Booking radio
                        _buildPurposeRadioTile(
                          title: 'Events Booking',
                          isSelected: false,
                          onTap: () {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (_) => HostEventScreen11EventTypes(draft: _draft),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 24),

                        // 1. Accommodation Rooms Radio
                        _buildSectionHeader('Accommodation Rooms'),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            _buildRadioOption(
                              label: 'Yes',
                              selected: _hasAccommodationRooms,
                              onTap: () => setState(() => _hasAccommodationRooms = true),
                            ),
                            const SizedBox(width: 28),
                            _buildRadioOption(
                              label: 'No',
                              selected: !_hasAccommodationRooms,
                              onTap: () => setState(() => _hasAccommodationRooms = false),
                            ),
                          ],
                        ),

                        if (_hasAccommodationRooms) ...[
                          const SizedBox(height: 24),

                          // 2. How many rooms of this type
                          Text(
                            'How many rooms of this type.',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF1E1E24),
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 48,
                            child: TextField(
                              controller: _roomsCountController,
                              keyboardType: TextInputType.number,
                              style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF1E1E24)),
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: Color(0xFFE5E4ED)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: Color(0xFFE5E4ED)),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // 3. Which beds are available in this room?
                          _buildSectionHeader('Which beds are available in this room?'),
                          const SizedBox(height: 14),
                          _buildBedStepper(
                            title: 'Single bed',
                            subtitle: '90 - 130 cm wide',
                            value: _singleBeds,
                            onChanged: (val) => setState(() => _singleBeds = val),
                          ),
                          _buildBedStepper(
                            title: 'Double ded',
                            subtitle: '131 - 150 cm wide',
                            value: _doubleBeds,
                            onChanged: (val) => setState(() => _doubleBeds = val),
                          ),
                          _buildBedStepper(
                            title: 'Large Bed (king size)',
                            subtitle: '151 - 180 cm wide',
                            value: _largeBeds,
                            onChanged: (val) => setState(() => _largeBeds = val),
                          ),
                          _buildBedStepper(
                            title: 'Extra - large double bed (super - large ) size',
                            subtitle: '181 - 910 cm',
                            value: _extraLargeBeds,
                            onChanged: (val) => setState(() => _extraLargeBeds = val),
                          ),
                          _buildBedStepper(
                            title: 'How many guests stay in this room',
                            subtitle: '',
                            value: _guestCount,
                            onChanged: (val) => setState(() => _guestCount = val),
                          ),
                          const SizedBox(height: 20),

                          // 4. Bathroom Details
                          _buildSectionHeader('Bathroom Details'),
                          const SizedBox(height: 10),
                          Text(
                            'Is the bathroom private?',
                            style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF555566)),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _buildRadioOption(
                                label: 'Yes',
                                selected: _isBathroomPrivate,
                                onTap: () => setState(() => _isBathroomPrivate = true),
                              ),
                              const SizedBox(width: 24),
                              _buildRadioOption(
                                label: 'NO , it is shared',
                                selected: !_isBathroomPrivate,
                                onTap: () => setState(() => _isBathroomPrivate = false),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Which bathroom items are available in this room?',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF1E1E24),
                            ),
                          ),
                          const SizedBox(height: 8),
                          ..._allBathroomItems.map((item) => _buildCheckboxTile(
                                label: item,
                                checked: _selectedBathroomItems.contains(item),
                                onChanged: (checked) {
                                  setState(() {
                                    if (checked) {
                                      _selectedBathroomItems.add(item);
                                    } else {
                                      _selectedBathroomItems.remove(item);
                                    }
                                  });
                                },
                              )),
                          const SizedBox(height: 20),

                          // 5. Outdoor and Views
                          _buildSectionHeader('Outdoor and views'),
                          const SizedBox(height: 8),
                          ..._allOutdoorViews.map((item) => _buildCheckboxTile(
                                label: item,
                                checked: _selectedOutdoorViews.contains(item),
                                onChanged: (checked) {
                                  setState(() {
                                    if (checked) {
                                      _selectedOutdoorViews.add(item);
                                    } else {
                                      _selectedOutdoorViews.remove(item);
                                    }
                                  });
                                },
                              )),
                          const SizedBox(height: 20),

                          // 6. Food and Drink
                          _buildSectionHeader('Food and drink'),
                          const SizedBox(height: 8),
                          ..._allFoodDrink.map((item) => _buildCheckboxTile(
                                label: item,
                                checked: _selectedFoodDrink.contains(item),
                                onChanged: (checked) {
                                  setState(() {
                                    if (checked) {
                                      _selectedFoodDrink.add(item);
                                    } else {
                                      _selectedFoodDrink.remove(item);
                                    }
                                  });
                                },
                              )),
                          const SizedBox(height: 20),

                          // 7. What is the name of this room?
                          _buildSectionHeader('What is the name of this room?'),
                          const SizedBox(height: 4),
                          Text(
                            'This is the name guest will see on your property page. Choose a name that most accurately describes a room.',
                            style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF757585), height: 1.35),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Room Name',
                            style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: const Color(0xFF1E1E24)),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFE5E4ED)),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedRoomName,
                                isExpanded: true,
                                icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF555566)),
                                items: _roomNameOptions.map((opt) {
                                  return DropdownMenuItem<String>(
                                    value: opt,
                                    child: Text(opt, style: GoogleFonts.poppins(fontSize: 14)),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) setState(() => _selectedRoomName = val);
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // 8. What are your check-in checkout times?
                          _buildSectionHeader('What are your check-in checkout times?'),
                          const SizedBox(height: 10),
                          Text(
                            'Check-in',
                            style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: const Color(0xFF1E1E24)),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(child: _buildTimeDropdown('From', _checkInFrom, (val) => setState(() => _checkInFrom = val))),
                              const SizedBox(width: 14),
                              Expanded(child: _buildTimeDropdown('Until', _checkInUntil, (val) => setState(() => _checkInUntil = val))),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Check-Out',
                            style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: const Color(0xFF1E1E24)),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(child: _buildTimeDropdown('From', _checkOutFrom, (val) => setState(() => _checkOutFrom = val))),
                              const SizedBox(width: 14),
                              Expanded(child: _buildTimeDropdown('Until', _checkOutUntil, (val) => setState(() => _checkOutUntil = val))),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // 9. How much do you want to charge per night?
                          _buildSectionHeader('How much do you want to charge per night?'),
                          const SizedBox(height: 12),
                          Text(
                            'Price guest pay',
                            style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF555566)),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            height: 48,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFE5E4ED)),
                            ),
                            child: Row(
                              children: [
                                DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _selectedCurrency,
                                    items: const ['INR', 'USD', 'EUR'].map((c) => DropdownMenuItem(value: c, child: Text(c, style: GoogleFonts.poppins(fontSize: 13)))).toList(),
                                    onChanged: (val) {
                                      if (val != null) setState(() => _selectedCurrency = val);
                                    },
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextField(
                                    controller: _priceController,
                                    keyboardType: TextInputType.number,
                                    onChanged: (_) => setState(() {}),
                                    style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: const Color(0xFF1E1E24)),
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  ),
                                ),
                                const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF555566)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          Center(
                            child: Text(
                              'including taxes, commission and charges',
                              style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF757585)),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Zaatra Commission 20%
                          Row(
                            children: [
                              Text(
                                'Zaatra Commission',
                                style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF1E1E24)),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xFFE5E4ED)),
                                ),
                                child: Text('20%', style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF555566))),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '(If any coupon applies then 15%)',
                                  style: GoogleFonts.poppins(fontSize: 10, color: const Color(0xFF888899)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Benefit checkboxes
                          _buildBenefitRow('24/7 helps in your language', _helpInLanguage, (v) => setState(() => _helpInLanguage = v)),
                          const SizedBox(height: 8),
                          _buildBenefitRow('Save time with automatically confirmed booking', _autoConfirmedBooking, (v) => setState(() => _autoConfirmedBooking = v)),
                          const SizedBox(height: 8),
                          _buildBenefitRow('We promote your place on google and social media platform', _promoteGoogleSocial, (v) => setState(() => _promoteGoogleSocial = v)),
                          const SizedBox(height: 14),

                          Text(
                            'Your earnings INR ${_zaatraEarnings.toStringAsFixed(2)} (including Taxes)',
                            style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFF555566)),
                          ),
                          const SizedBox(height: 24),

                          // 10. Standard rate plan
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildSectionHeader('Standard rate plan'),
                              const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF555566)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text('Price per group', style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF757585))),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Occupancy', style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF555566))),
                              Text('Guest Pay', style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF555566))),
                            ],
                          ),
                          const SizedBox(height: 6),
                          _buildRatePlanRow('Rx3', 'INR ${_enteredPrice.toStringAsFixed(0)}'),
                          _buildRatePlanRow('Rx2', 'INR ${_enteredPrice.toStringAsFixed(0)}'),
                          _buildRatePlanRow('Rx1', 'INR ${_enteredPrice.toStringAsFixed(0)}'),
                          const SizedBox(height: 16),

                          // Next Outline Button
                          SizedBox(
                            width: double.infinity,
                            height: 46,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFFE5E4ED)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: () {
                                _scrollController.animateTo(
                                  _scrollController.position.maxScrollExtent,
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeOut,
                                );
                              },
                              child: Text(
                                'Next',
                                style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF1E1E24)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // 11. Cancellation Policy
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildSectionHeader('Cancellation Policy'),
                              const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF555566)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          _buildCheckboxTile(
                            label: 'Guest who cancel within 24 hour will have their cancellation fee waived',
                            checked: _cancel24hWaived,
                            onChanged: (v) => setState(() => _cancel24hWaived = v),
                          ),
                          const SizedBox(height: 6),
                          _buildCheckboxTile(
                            label: 'Guests can cancel their booking for free before 18:00 on the day of arrival. The guests will be charged cost of the first night if they cancel after this.',
                            checked: _cancelFreeBefore18,
                            onChanged: (v) => setState(() => _cancelFreeBefore18 = v),
                          ),
                          const SizedBox(height: 24),

                          // 12. Photos
                          _buildSectionHeader('Photos'),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 68,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              children: [
                                ..._pickedPhotos.map((f) => Container(
                                      width: 68,
                                      height: 68,
                                      margin: const EdgeInsets.only(right: 10),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        color: const Color(0xFFE5E5EA),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: kIsWeb
                                            ? Image.network(f.path, fit: BoxFit.cover)
                                            : Image.file(File(f.path), fit: BoxFit.cover),
                                      ),
                                    )),
                                if (_pickedPhotos.isEmpty)
                                  ...List.generate(
                                    5,
                                    (i) => InkWell(
                                      onTap: _pickImages,
                                      child: Container(
                                        width: 68,
                                        height: 68,
                                        margin: const EdgeInsets.only(right: 10),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(8),
                                          color: const Color(0xFFD8D8E0),
                                        ),
                                        child: const Icon(Icons.add_photo_alternate_outlined, color: Colors.white, size: 28),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),
                        ],
                      ],
                    ),
                  ),
                ),

                // Bottom Continue Button
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: HostBottomButton(
                    text: 'Continue',
                    onPressed: _onContinue,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF1E1E24),
      ),
    );
  }

  Widget _buildRadioOption({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? const Color(0xFF5E42C2) : const Color(0xFFA0A0B2),
                width: 2,
              ),
            ),
            child: selected
                ? Center(
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF5E42C2),
                      ),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF1E1E24),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBedStepper({
    required String title,
    required String subtitle,
    required int value,
    required ValueChanged<int> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFA0A0B2), width: 1.5),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF1E1E24),
                  ),
                ),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF757585)),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE5E4ED)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: () {
                    if (value > 0) onChanged(value - 1);
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Text('-', style: TextStyle(fontSize: 16, color: Color(0xFF555566))),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text('$value', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
                ),
                InkWell(
                  onTap: () => onChanged(value + 1),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Text('+', style: TextStyle(fontSize: 16, color: Color(0xFF555566))),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckboxTile({
    required String label,
    required bool checked,
    required ValueChanged<bool> onChanged,
  }) {
    return InkWell(
      onTap: () => onChanged(!checked),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 18,
              height: 18,
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                color: checked ? const Color(0xFF5E42C2) : const Color(0xFFE8E5F3),
                borderRadius: BorderRadius.circular(4),
              ),
              child: checked
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 13,
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

  Widget _buildTimeDropdown(String label, String value, ValueChanged<String> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF757585))),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE5E4ED)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              items: _timeOptions.map((t) => DropdownMenuItem(value: t, child: Text(t, style: GoogleFonts.poppins(fontSize: 13)))).toList(),
              onChanged: (val) {
                if (val != null) onChanged(val);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBenefitRow(String text, bool checked, ValueChanged<bool> onChanged) {
    return Row(
      children: [
        InkWell(
          onTap: () => onChanged(!checked),
          child: Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: checked ? const Color(0xFF5E42C2) : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: checked ? const Color(0xFF5E42C2) : const Color(0xFFA0A0B2)),
            ),
            child: checked ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF424252)),
          ),
        ),
      ],
    );
  }

  Widget _buildRatePlanRow(String rx, String price) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(rx, style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF757585))),
          Text(price, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF1E1E24))),
        ],
      ),
    );
  }
  Widget _buildPurposeRadioTile({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? const Color(0xFF5E42C2) : const Color(0xFFA0A0B2),
                  width: isSelected ? 7.0 : 1.5,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF1E1E24),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
