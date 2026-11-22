import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/host_updated_property_draft_model.dart';
import 'widgets/host_components.dart';

class HostEventScreen14BridalRooms extends StatefulWidget {
  final HostUpdatedPropertyDraft draft;
  final Map<String, dynamic> eventData;

  const HostEventScreen14BridalRooms({
    super.key,
    required this.draft,
    required this.eventData,
  });

  @override
  State<HostEventScreen14BridalRooms> createState() => _HostEventScreen14BridalRoomsState();
}

class _HostEventScreen14BridalRoomsState extends State<HostEventScreen14BridalRooms> {
  late HostUpdatedPropertyDraft _draft;
  late Map<String, dynamic> _eventData;

  final List<String> _amenityOptions = const [
    'AC',
    'Attached toilet',
    'Sofa',
    'Chairs',
    'Lockers  for jewellery',
    'Bed',
  ];

  // 1. Bridal Room
  bool _hasBridalRoom = true;
  final Set<String> _bridalAmenities = {'AC', 'Attached toilet', 'Sofa', 'Chairs', 'Bed'};

  // 2. Groom Room
  bool _hasGroomRoom = true;
  final Set<String> _groomAmenities = {'AC', 'Attached toilet', 'Sofa', 'Chairs'};

  // 3. VIP Room
  bool _hasVipRoom = true;
  final Set<String> _vipAmenities = {'AC', 'Attached toilet', 'Sofa'};

  // 4. Changing Room
  bool _hasChangingRoom = true;
  late TextEditingController _changingRoomCountController;
  final Set<String> _changingAmenities = {'AC', 'Attached toilet', 'Lockers  for jewellery'};

  @override
  void initState() {
    super.initState();
    _draft = widget.draft;
    _eventData = Map<String, dynamic>.from(widget.eventData);
    _changingRoomCountController = TextEditingController(text: '04');
  }

  @override
  void dispose() {
    _changingRoomCountController.dispose();
    super.dispose();
  }

  void _onSaveUnit() {
    final eventUnit = {
      'unitId': 'unit_${DateTime.now().millisecondsSinceEpoch}',
      'unitType': 'Banquet Hall',
      'purpose': _eventData['purpose'] ?? 'Events Booking',
      'venueType': _eventData['venueType'] ?? 'Banquet Hall',
      'bookingMode': _eventData['bookingMode'] ?? 'Review every request',
      'hallCount': _eventData['hallCount'] ?? 2,
      'eventCategories': _eventData['eventCategories'] ?? {},
      'views': _eventData['views'] ?? [],
      'indoorOutdoor': _eventData['indoorOutdoor'] ?? ['Indoor'],
      'expectedSpaces': _eventData['expectedSpaces'] ?? ['Hall'],
      'hallDimensions': _eventData['hallDimensions'] ?? {},
      'seatingOptions': _eventData['seatingOptions'] ?? ['Indoor Seating'],
      'seatingCapacity': _eventData['seatingCapacity'] ?? '2,000(guests)',
      'hallCapacity': _eventData['hallCapacity'] ?? '3,000(guests)',
      'stageLocations': _eventData['stageLocations'] ?? [],
      'stageDimensions': _eventData['stageDimensions'] ?? {},
      'diningCoveredInHall': _eventData['diningCoveredInHall'] ?? false,
      'diningLocations': _eventData['diningLocations'] ?? [],
      'diningDimensions': _eventData['diningDimensions'] ?? {},
      'diningCapacity': _eventData['diningCapacity'] ?? '1,000(guests)',
      'bridalRoom': {
        'hasRoom': _hasBridalRoom,
        'amenities': _bridalAmenities.toList(),
      },
      'groomRoom': {
        'hasRoom': _hasGroomRoom,
        'amenities': _groomAmenities.toList(),
      },
      'vipRoom': {
        'hasRoom': _hasVipRoom,
        'amenities': _vipAmenities.toList(),
      },
      'changingRooms': {
        'hasRoom': _hasChangingRoom,
        'count': _changingRoomCountController.text.trim(),
        'amenities': _changingAmenities.toList(),
      },
      'basePrice': '150000',
    };

    final updatedUnits = List<Map<String, dynamic>>.from(_draft.units)..add(eventUnit);
    final updatedDraft = _draft.copyWith(units: updatedUnits);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Event Unit (Banquet Hall) registered successfully!'),
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
                  title: 'Bridal room',
                  onBack: () => Navigator.pop(context),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Section 1: Bridal Room
                        _buildRoomSection(
                          title: 'Is there a separate bridle room?',
                          hasRoom: _hasBridalRoom,
                          onToggleRoom: (val) => setState(() => _hasBridalRoom = val),
                          selectedAmenities: _bridalAmenities,
                        ),
                        const SizedBox(height: 28),

                        // Section 2: Groom Room
                        _buildRoomSection(
                          sectionHeader: 'Groom Room',
                          title: 'Is there a separate bridle room?',
                          hasRoom: _hasGroomRoom,
                          onToggleRoom: (val) => setState(() => _hasGroomRoom = val),
                          selectedAmenities: _groomAmenities,
                        ),
                        const SizedBox(height: 28),

                        // Section 3: VIP Room
                        _buildRoomSection(
                          sectionHeader: 'VIP / Room Green Room',
                          title: 'Is there a separate bridle room?',
                          hasRoom: _hasVipRoom,
                          onToggleRoom: (val) => setState(() => _hasVipRoom = val),
                          selectedAmenities: _vipAmenities,
                        ),
                        const SizedBox(height: 28),

                        // Section 4: Changing Room
                        Text(
                          'Changing room/ Mockup room',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1E1E24),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _buildRadioTile(
                              title: 'Yes',
                              isSelected: _hasChangingRoom,
                              onTap: () => setState(() => _hasChangingRoom = true),
                            ),
                            const SizedBox(width: 24),
                            _buildRadioTile(
                              title: 'No',
                              isSelected: !_hasChangingRoom,
                              onTap: () => setState(() => _hasChangingRoom = false),
                            ),
                          ],
                        ),
                        if (_hasChangingRoom) ...[
                          const SizedBox(height: 16),
                          Text(
                            'How many changing rooms/Mockup rooms',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF2E2E38),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _changingRoomCountController,
                            keyboardType: TextInputType.number,
                            style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF1E1E24)),
                            decoration: InputDecoration(
                              hintText: '04',
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFE2E2EC)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFE2E2EC)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFF5E42C2), width: 1.5),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Amenities',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF2E2E38),
                            ),
                          ),
                          const SizedBox(height: 8),
                          ..._amenityOptions.map((amenity) {
                            final isChecked = _changingAmenities.contains(amenity);
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: _buildCheckboxTile(
                                title: amenity,
                                isChecked: isChecked,
                                onChanged: (_) {
                                  setState(() {
                                    if (isChecked) {
                                      _changingAmenities.remove(amenity);
                                    } else {
                                      _changingAmenities.add(amenity);
                                    }
                                  });
                                },
                              ),
                            );
                          }),
                        ],

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: HostBottomButton(
                    text: 'Save Event Unit',
                    onPressed: _onSaveUnit,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomSection({
    String? sectionHeader,
    required String title,
    required bool hasRoom,
    required ValueChanged<bool> onToggleRoom,
    required Set<String> selectedAmenities,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (sectionHeader != null) ...[
          Text(
            sectionHeader,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E1E24),
            ),
          ),
          const SizedBox(height: 8),
        ],
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 14.5,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF2E2E38),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _buildRadioTile(
              title: 'Yes',
              isSelected: hasRoom,
              onTap: () => onToggleRoom(true),
            ),
            const SizedBox(width: 24),
            _buildRadioTile(
              title: 'No',
              isSelected: !hasRoom,
              onTap: () => onToggleRoom(false),
            ),
          ],
        ),
        if (hasRoom) ...[
          const SizedBox(height: 16),
          Text(
            'Amenities',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2E2E38),
            ),
          ),
          const SizedBox(height: 8),
          ..._amenityOptions.map((amenity) {
            final isChecked = selectedAmenities.contains(amenity);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: _buildCheckboxTile(
                title: amenity,
                isChecked: isChecked,
                onChanged: (_) {
                  setState(() {
                    if (isChecked) {
                      selectedAmenities.remove(amenity);
                    } else {
                      selectedAmenities.add(amenity);
                    }
                  });
                },
              ),
            );
          }),
        ],
      ],
    );
  }

  Widget _buildRadioTile({
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
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? const Color(0xFF5E42C2) : const Color(0xFFA0A0B2),
                  width: isSelected ? 6.5 : 1.5,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF1E1E24),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckboxTile({
    required String title,
    required bool isChecked,
    required ValueChanged<bool?> onChanged,
  }) {
    return InkWell(
      onTap: () => onChanged(!isChecked),
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: isChecked ? const Color(0xFF5E42C2) : Colors.white,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: isChecked ? const Color(0xFF5E42C2) : const Color(0xFFA0A0B2),
                  width: 1.5,
                ),
              ),
              child: isChecked
                  ? const Icon(
                      Icons.check_rounded,
                      size: 14,
                      color: Colors.white,
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 13.5,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF2E2E38),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
