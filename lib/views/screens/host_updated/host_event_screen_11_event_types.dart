import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/host_updated_property_draft_model.dart';
import 'widgets/host_components.dart';
import 'host_event_screen_12_venue_details.dart';
import 'host_screen_15_accommodation_rooms.dart';

/// Figma: frame 1228744514 (node 1:1970)
class HostEventScreen11EventTypes extends StatefulWidget {
  final HostUpdatedPropertyDraft draft;
  final Map<String, dynamic>? initialEventData;

  const HostEventScreen11EventTypes({
    super.key,
    required this.draft,
    this.initialEventData,
  });

  @override
  State<HostEventScreen11EventTypes> createState() => _HostEventScreen11EventTypesState();
}

class _HostEventScreen11EventTypesState extends State<HostEventScreen11EventTypes> {
  late HostUpdatedPropertyDraft _draft;

  String _listingPurpose = 'Events Booking';
  String _selectedVenueType = 'Banquet Hall';
  String _bookingAcceptance = 'Review every request';
  late TextEditingController _hallCountController;

  final List<String> _venueTypes = const [
    'Banquet Hall',
    'Convention Center',
    'Lawn / Open Ground',
    'Poolside Venue',
    'Terrace / Rooftop',
    'Conference Hall',
    'Auditorium',
    'Resort Grounds',
  ];

  // 10 Event Categories Definition
  final Map<String, List<String>> _eventCategoriesData = {
    '1. Wedding and marriage': [
      'Wedding',
      'Reception',
      'Engagement',
      'Sangeet',
      'Mehandi Night',
      'Haldi Cermony',
      'Pelli choopulu',
      'Pelli koduku',
    ],
    '2. Pre - Wedding Events': [
      'Bride and groom Introduction',
      'Ring Ceremony',
      'Roka Ceremony',
      'Pelli koduku Fest',
      'Bacheolor and Bachelorette Party',
    ],
    '3. Life stage Ceremonies': [
      'Upanayanam /Thread Ceremony',
      'Ear piercing Ceremony /Karnavedha',
      'Seemantham / Baby Shower',
      'Pelli koduku Fest',
      'Naming Ceremony / Craddle Ceremony',
      'Housing Ceremony / House Warming',
      'Puberty Ceremony',
    ],
    '4. Birthday and Anniversary': [
      'Birthday',
      'Silver Jubilee Function',
      'Golden Jubilee Function',
      'Wedding Anniversary',
    ],
    '5. Family and Social Events': [
      'Family get - together',
      'Reunion - School, college, Family',
      'Retirement Function',
      'Felicitation Ceremony',
      'Farewell Party',
      'Community Feast',
    ],
    '6. Funeral and memorial': [
      'Condolence Meeting',
      'Prayer Meeting',
      '11th Day Ceremony',
      'Annual Death Anniversary',
    ],
    '7. Religious Gathering': [
      'satyanarayana pooja Gathering',
      'Upanayanam Fest',
      'Community Religious Celebration',
      'Eid milan Party',
      'christmas celebration',
      'sankranthi celebrations',
      'Ugadi celebrations',
    ],
    '8. Corporate and Professionals': [
      'Conference and Seminar',
      'Workshop and Training',
      'Product Launch',
      'Award Function',
      'Annual Day',
      'Company Opening Ceremony',
      'Corporate party and Team outing',
      'Corporate Meeting',
      'Job fair and Exhibition',
    ],
    '9. Entertainment and Culture': [
      'Cultural programme',
      'Music and live performance',
      'Dance Programme',
      'DJ Night and Private Party',
      'Standup Comedy Show',
      'Fashion Show',
      'Film and photoshoot',
    ],
    '10. Other': [
      'Political and Social Party',
      'Association and Community Meeting',
      'Other',
    ],
  };

  // State of selected events
  late Map<String, Set<String>> _selectedEvents;

  @override
  void initState() {
    super.initState();
    _draft = widget.draft;
    final initial = widget.initialEventData ?? {};

    _listingPurpose = initial['purpose'] ?? 'Events Booking';
    _selectedVenueType = initial['venueType'] ?? 'Banquet Hall';
    _bookingAcceptance = initial['bookingMode'] ?? 'Review every request';
    _hallCountController = TextEditingController(
      text: initial['hallCount']?.toString() ?? '2',
    );

    // Initialize selections matching 11.png defaults
    _selectedEvents = {};
    if (initial['eventCategories'] != null && initial['eventCategories'] is Map) {
      final map = initial['eventCategories'] as Map;
      for (final entry in _eventCategoriesData.entries) {
        final savedList = map[entry.key] as List?;
        _selectedEvents[entry.key] = savedList != null
            ? Set<String>.from(savedList.map((e) => e.toString()))
            : <String>{};
      }
    } else {
      // Default selections matching wireframe 11.png
      for (final entry in _eventCategoriesData.entries) {
        final cat = entry.key;
        if (cat.startsWith('1.') || cat.startsWith('2.') || cat.startsWith('3.') ||
            cat.startsWith('4.') || cat.startsWith('5.') || cat.startsWith('6.')) {
          _selectedEvents[cat] = Set<String>.from(entry.value);
        } else if (cat.startsWith('8.')) {
          _selectedEvents[cat] = {
            'Conference and Seminar',
            'Workshop and Training',
            'Product Launch',
            'Award Function',
            'Annual Day',
            'Company Opening Ceremony',
            'Corporate party and Team outing',
            'Corporate Meeting',
          };
        } else if (cat.startsWith('9.')) {
          _selectedEvents[cat] = {
            'Cultural programme',
            'Music and live performance',
            'Dance Programme',
            'DJ Night and Private Party',
            'Standup Comedy Show',
            'Fashion Show',
            'Film and photoshoot',
          };
        } else if (cat.startsWith('10.')) {
          _selectedEvents[cat] = {'Political and Social Party'};
        } else {
          _selectedEvents[cat] = <String>{};
        }
      }
    }
  }

  @override
  void dispose() {
    _hallCountController.dispose();
    super.dispose();
  }

  void _toggleCategoryAll(String category, bool selectAll) {
    setState(() {
      if (selectAll) {
        _selectedEvents[category] = Set<String>.from(_eventCategoriesData[category]!);
      } else {
        _selectedEvents[category]?.clear();
      }
    });
  }

  void _toggleItem(String category, String item) {
    setState(() {
      final set = _selectedEvents[category] ?? <String>{};
      if (set.contains(item)) {
        set.remove(item);
      } else {
        set.add(item);
      }
      _selectedEvents[category] = set;
    });
  }

  void _onContinue() async {
    final eventCategoriesMap = _selectedEvents.map(
      (key, value) => MapEntry(key, value.toList()),
    );

    final hallCount = int.tryParse(_hallCountController.text.trim()) ?? 0;
    final anyEventSelected = _selectedEvents.values.any((v) => v.isNotEmpty);
    final error = hallCount < 1
        ? 'Enter how many halls / units of this type you have'
        : (!anyEventSelected ? 'Select at least one event type' : null);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.redAccent),
      );
      return;
    }

    // Existing data first, so what the host just chose here wins when editing.
    final eventData = {
      ...(widget.initialEventData ?? {}),
      'unitType': _selectedVenueType,
      'purpose': _listingPurpose,
      'venueType': _selectedVenueType,
      'bookingMode': _bookingAcceptance,
      'hallCount': hallCount,
      'eventCategories': eventCategoriesMap,
      // Real number of events offered per category (used by the summary screen).
      'eventCategoryTotals': {
        for (final e in _eventCategoriesData.entries) e.key: e.value.length,
      },
    };

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HostEventScreen12VenueDetails(
          draft: _draft,
          eventData: eventData,
        ),
      ),
    );

    if (result != null && result is HostUpdatedPropertyDraft && mounted) {
      Navigator.pop(context, result);
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
                  title: 'Add Unite 2',
                  onBack: () => Navigator.pop(context),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                        _buildRadioTile(
                          title: 'Accommodations',
                          isSelected: _listingPurpose == 'Accommodations',
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => HostScreen15AccommodationRooms(draft: _draft),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 10),

                        // Events Booking radio
                        _buildRadioTile(
                          title: 'Events Booking',
                          isSelected: _listingPurpose == 'Events Booking',
                          onTap: () => setState(() => _listingPurpose = 'Events Booking'),
                        ),
                        const SizedBox(height: 24),

                        // Venue Type Dropdown
                        Text(
                          'Property Type',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF2E2E38),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E2EC)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedVenueType,
                              isExpanded: true,
                              icon: const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: Color(0xFF1E1E24),
                                size: 26,
                              ),
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFF1E1E24),
                              ),
                              items: _venueTypes.map((type) {
                                return DropdownMenuItem(value: type, child: Text(type));
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _selectedVenueType = val);
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Booking Acceptance mode
                        Text(
                          'How do you accept bookings?',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1E1E24),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildRadioTile(
                          title: 'Instant bookings (bookings are confirmed)',
                          isSelected: _bookingAcceptance == 'Instant bookings',
                          onTap: () => setState(() => _bookingAcceptance = 'Instant bookings'),
                        ),
                        const SizedBox(height: 10),
                        _buildRadioTile(
                          title: 'Review every request',
                          isSelected: _bookingAcceptance == 'Review every request',
                          onTap: () => setState(() => _bookingAcceptance = 'Review every request'),
                        ),
                        const SizedBox(height: 24),

                        // Quantity
                        Text(
                          'How many Halls / Units of this type do you have?\n(exactly os same size, capacity of features)',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF2E2E38),
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _hallCountController,
                          keyboardType: TextInputType.number,
                          style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF1E1E24)),
                          decoration: InputDecoration(
                            hintText: '2',
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
                        const SizedBox(height: 28),

                        const Divider(color: Color(0xFFE2E2EC), thickness: 1),
                        const SizedBox(height: 16),

                        // Event Checklist Header
                        Text(
                          'What type of events do you offer?',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1E1E24),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // 10 Event Categories
                        ..._eventCategoriesData.entries.map((entry) {
                          return _buildCategorySection(
                            categoryTitle: entry.key,
                            items: entry.value,
                          );
                        }),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
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

  Widget _buildCategorySection({
    required String categoryTitle,
    required List<String> items,
  }) {
    final selectedSet = _selectedEvents[categoryTitle] ?? <String>{};
    final isAllSelected = selectedSet.length == items.length && items.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            categoryTitle,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E1E24),
            ),
          ),
          const SizedBox(height: 10),

          // All master checkbox
          _buildCheckboxTile(
            title: 'All',
            isChecked: isAllSelected,
            onChanged: (val) => _toggleCategoryAll(categoryTitle, val ?? false),
          ),
          const SizedBox(height: 6),

          // Items in 2-column layout or list
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: items.map((item) {
              final isChecked = selectedSet.contains(item);
              return SizedBox(
                width: MediaQuery.of(context).size.width > 360
                    ? (MediaQuery.of(context).size.width - 70) / 2
                    : double.infinity,
                child: _buildCheckboxTile(
                  title: item,
                  isChecked: isChecked,
                  onChanged: (_) => _toggleItem(categoryTitle, item),
                ),
              );
            }).toList(),
          ),
        ],
      ),
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
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF2E2E38),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

