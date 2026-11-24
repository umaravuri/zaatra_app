import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/host_updated_property_draft_model.dart';
import 'widgets/host_components.dart';
import 'host_event_screen_13_capacity_stage_dining.dart';

/// Figma: frame 1228744517 (node 1:2718)
/// Figma: frame 1228744518 (node 1:2785)
class HostEventScreen12VenueDetails extends StatefulWidget {
  final HostUpdatedPropertyDraft draft;
  final Map<String, dynamic> eventData;

  const HostEventScreen12VenueDetails({
    super.key,
    required this.draft,
    required this.eventData,
  });

  @override
  State<HostEventScreen12VenueDetails> createState() => _HostEventScreen12VenueDetailsState();
}

class _HostEventScreen12VenueDetailsState extends State<HostEventScreen12VenueDetails> {
  late HostUpdatedPropertyDraft _draft;
  late Map<String, dynamic> _eventData;


  // View Types Checkboxes
  final List<String> _viewOptions = const [
    'Lake View',
    'Mountain / Hill View',
    'Beach View',
    'City View',
    'Pool View',
    'No Special View',
    'Garden View',
  ];
  final Set<String> _selectedViews = {};

  // Indoor / Outdoor
  final Set<String> _indoorOutdoor = {'Indoor'};

  // Expected venue space
  final Set<String> _expectedSpaces = {'Hall'};

  // Hall Dimensions (Optional)
  String _selectedLength = 'Length';
  String _selectedWidth = 'Width';
  String _selectedCeilingHeight = 'Ceiling Height';

  final List<String> _dimensionLengths = const ['Length', '40 ft', '60 ft', '80 ft', '100 ft', '150 ft', '200 ft'];
  final List<String> _dimensionWidths = const ['Width', '30 ft', '50 ft', '70 ft', '80 ft', '100 ft'];
  final List<String> _dimensionHeights = const ['Ceiling Height', '12 ft', '15 ft', '18 ft', '20 ft', '25 ft'];

  // Guest Seating
  final Set<String> _seatingOptions = {'Indoor Seating'};

  @override
  void initState() {
    super.initState();
    _draft = widget.draft;
    _eventData = Map<String, dynamic>.from(widget.eventData);

    if (_eventData['views'] != null) {
      _selectedViews.addAll(List<String>.from(_eventData['views']));
    }
    if (_eventData['indoorOutdoor'] != null) {
      _indoorOutdoor.clear();
      _indoorOutdoor.addAll(List<String>.from(_eventData['indoorOutdoor']));
    }
    if (_eventData['expectedSpaces'] != null) {
      _expectedSpaces.clear();
      _expectedSpaces.addAll(List<String>.from(_eventData['expectedSpaces']));
    }
  }

  void _onContinue() async {
    final updatedEventData = {
      ..._eventData,
      'views': _selectedViews.toList(),
      'indoorOutdoor': _indoorOutdoor.toList(),
      'expectedSpaces': _expectedSpaces.toList(),
      'hallDimensions': {
        'length': _selectedLength != 'Length' ? _selectedLength : '',
        'width': _selectedWidth != 'Width' ? _selectedWidth : '',
        'ceilingHeight': _selectedCeilingHeight != 'Ceiling Height' ? _selectedCeilingHeight : '',
      },
      'seatingOptions': _seatingOptions.toList(),
    };

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HostEventScreen13CapacityStageDining(
          draft: _draft,
          eventData: updatedEventData,
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
                  title: 'Selected Options',
                  onBack: () => Navigator.pop(context),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'You have selected',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1E1E24),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Selected Categories summary table matching 12.png
                        _buildSummaryRows(),
                        const SizedBox(height: 20),

                        Text(
                          'Is this correct?',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF1E1E24),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Edit and Confirm Buttons Row
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 44,
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: Color(0xFF5E42C2)),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  onPressed: () => Navigator.pop(context),
                                  child: Text(
                                    'Edit',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF5E42C2),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: SizedBox(
                                height: 44,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF5E42C2),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  onPressed: () {
                                    // Nothing to save here yet: the selections are kept in
                                    // the event data and saved with the unit on the last step.
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Selected event categories confirmed!'),
                                        duration: Duration(seconds: 1),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    'Confirm and save',
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 28),
                        const Divider(color: Color(0xFFE2E2EC), thickness: 1),
                        const SizedBox(height: 16),

                        // Venue Details Header
                        Text(
                          'Venue Details',
                          style: GoogleFonts.poppins(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1E1E24),
                          ),
                        ),
                        const SizedBox(height: 14),

                        Text(
                          'You have selected',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF2E2E38),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Views Checkboxes in 2-column layout
                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          children: _viewOptions.map((view) {
                            final isChecked = _selectedViews.contains(view);
                            return SizedBox(
                              width: (MediaQuery.of(context).size.width - 70) / 2,
                              child: _buildCheckboxTile(
                                title: view,
                                isChecked: isChecked,
                                onChanged: (val) {
                                  setState(() {
                                    if (isChecked) {
                                      _selectedViews.remove(view);
                                    } else {
                                      _selectedViews.add(view);
                                    }
                                  });
                                },
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 24),

                        // Where is the Event will happen Indoor / outdoor?
                        Text(
                          'Where is the Event will happen Indoor / outdoor?',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF2E2E38),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            _buildCheckboxTile(
                              title: 'Indoor',
                              isChecked: _indoorOutdoor.contains('Indoor'),
                              onChanged: (_) {
                                setState(() {
                                  if (_indoorOutdoor.contains('Indoor')) {
                                    _indoorOutdoor.remove('Indoor');
                                  } else {
                                    _indoorOutdoor.add('Indoor');
                                  }
                                });
                              },
                            ),
                            const SizedBox(width: 24),
                            _buildCheckboxTile(
                              title: 'Outdoor',
                              isChecked: _indoorOutdoor.contains('Outdoor'),
                              onChanged: (_) {
                                setState(() {
                                  if (_indoorOutdoor.contains('Outdoor')) {
                                    _indoorOutdoor.remove('Outdoor');
                                  } else {
                                    _indoorOutdoor.add('Outdoor');
                                  }
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Where we can expect event to happen?
                        Text(
                          'Where we can expect event to happen?',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF2E2E38),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 16,
                          runSpacing: 8,
                          children: ['Hall', 'Gardens', 'Farm stay', 'Resorts'].map((item) {
                            final isChecked = _expectedSpaces.contains(item);
                            return SizedBox(
                              width: (MediaQuery.of(context).size.width - 70) / 2,
                              child: _buildCheckboxTile(
                                title: item,
                                isChecked: isChecked,
                                onChanged: (_) {
                                  setState(() {
                                    if (isChecked) {
                                      _expectedSpaces.remove(item);
                                    } else {
                                      _expectedSpaces.add(item);
                                    }
                                  });
                                },
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 24),

                        // Dimensions (optional)
                        Text(
                          'Event hall any of 3 guests including size? (optional)',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF2E2E38),
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildDropdownPicker(
                          value: _selectedLength,
                          items: _dimensionLengths,
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedLength = val);
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildDropdownPicker(
                          value: _selectedWidth,
                          items: _dimensionWidths,
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedWidth = val);
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildDropdownPicker(
                          value: _selectedCeilingHeight,
                          items: _dimensionHeights,
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedCeilingHeight = val);
                          },
                        ),
                        const SizedBox(height: 24),

                        // Where do guests sit?
                        Text(
                          'Where do guests sit?',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF2E2E38),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Column(
                          children: [
                            _buildCheckboxTile(
                              title: 'Indoor Seating',
                              isChecked: _seatingOptions.contains('Indoor Seating'),
                              onChanged: (_) {
                                setState(() {
                                  if (_seatingOptions.contains('Indoor Seating')) {
                                    _seatingOptions.remove('Indoor Seating');
                                  } else {
                                    _seatingOptions.add('Indoor Seating');
                                  }
                                });
                              },
                            ),
                            const SizedBox(height: 8),
                            _buildCheckboxTile(
                              title: 'Outdoor seating',
                              isChecked: _seatingOptions.contains('Outdoor seating'),
                              onChanged: (_) {
                                setState(() {
                                  if (_seatingOptions.contains('Outdoor seating')) {
                                    _seatingOptions.remove('Outdoor seating');
                                  } else {
                                    _seatingOptions.add('Outdoor seating');
                                  }
                                });
                              },
                            ),
                            const SizedBox(height: 8),
                            _buildCheckboxTile(
                              title: 'Indoor + Outdoor Seating',
                              isChecked: _seatingOptions.contains('Indoor + Outdoor Seating'),
                              onChanged: (_) {
                                setState(() {
                                  if (_seatingOptions.contains('Indoor + Outdoor Seating')) {
                                    _seatingOptions.remove('Indoor + Outdoor Seating');
                                  } else {
                                    _seatingOptions.add('Indoor + Outdoor Seating');
                                  }
                                });
                              },
                            ),
                          ],
                        ),

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

  Widget _buildSummaryRows() {
    final categoriesMap = _eventData['eventCategories'] as Map? ?? {};

    // Standard list of display categories matching 12.png
    final displayRows = [
      {'name': 'Wedding day marriage', 'total': 9, 'key': '1. Wedding and marriage'},
      {'name': 'Pre wedding events', 'total': 5, 'key': '2. Pre - Wedding Events'},
      {'name': 'Life time Ceremony', 'total': 7, 'key': '3. Life stage Ceremonies'},
      {'name': 'Birthday & Anniversary', 'total': 6, 'key': '4. Birthday and Anniversary'},
      {'name': 'Family and Social Events', 'total': 6, 'key': '5. Family and Social Events'},
      {'name': 'Funeral and memorial', 'total': 4, 'key': '6. Funeral and memorial'},
      {'name': 'Religious gathering', 'total': 7, 'key': '7. Religious Gathering'},
      {'name': 'Corporate and professionals', 'total': 9, 'key': '8. Corporate and Professionals'},
      {'name': 'Entertainment and Culture', 'total': 7, 'key': '9. Entertainment and Culture'},
      {'name': 'Other', 'total': 3, 'key': '10. Other'},
    ];

    return Column(
      children: displayRows.map((row) {
        final key = row['key'] as String;
        final name = row['name'] as String;
        final totals = _eventData['eventCategoryTotals'] as Map? ?? {};
        final total = (totals[key] as int?) ?? (row['total'] as int);

        final selectedList = categoriesMap[key] as List? ?? [];
        final count = selectedList.length;

        String status;
        if (count == 0) {
          status = 'Not Accepted';
        } else if (count == total) {
          status = 'All $total Events';
        } else {
          status = '$count out of $total events';
        }

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            children: [
              Expanded(
                flex: 5,
                child: Text(
                  name,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: const Color(0xFF333340),
                  ),
                ),
              ),
              const Text(' - ', style: TextStyle(color: Color(0xFF757585))),
              Expanded(
                flex: 4,
                child: Text(
                  status,
                  textAlign: TextAlign.end,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: status == 'Not Accepted'
                        ? const Color(0xFF8E8E9F)
                        : const Color(0xFF1E1E24),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDropdownPicker({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E2EC)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Color(0xFF1E1E24),
            size: 24,
          ),
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF1E1E24),
          ),
          items: items.map((item) {
            return DropdownMenuItem(value: item, child: Text(item));
          }).toList(),
          onChanged: onChanged,
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
          mainAxisSize: MainAxisSize.min,
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
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 13,
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

********************************************************************************
================================================================================
