import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/host_updated_property_draft_model.dart';
import 'widgets/host_components.dart';
import 'host_event_screen_14_bridal_rooms.dart';

/// Figma: frame 1228744519 (node 1:2896)
class HostEventScreen13CapacityStageDining extends StatefulWidget {
  final HostUpdatedPropertyDraft draft;
  final Map<String, dynamic> eventData;

  const HostEventScreen13CapacityStageDining({
    super.key,
    required this.draft,
    required this.eventData,
  });

  @override
  State<HostEventScreen13CapacityStageDining> createState() =>
      _HostEventScreen13CapacityStageDiningState();
}

class _HostEventScreen13CapacityStageDiningState
    extends State<HostEventScreen13CapacityStageDining> {
  late HostUpdatedPropertyDraft _draft;
  late Map<String, dynamic> _eventData;

  late TextEditingController _seatingCapacityController;
  late TextEditingController _hallCapacityController;

  // Stage Location
  final Set<String> _stageLocations = {'Fixed indoor stage'};
  String _stageLength = 'Length';
  String _stageWidth = 'Width';
  String _stageHeight = 'Stage Height';

  final List<String> _stageLengths = const ['Length', '20 ft', '30 ft', '40 ft', '50 ft'];
  final List<String> _stageWidths = const ['Width', '15 ft', '20 ft', '25 ft', '30 ft'];
  final List<String> _stageHeights = const ['Stage Height', '2 ft', '3 ft', '4 ft', '5 ft'];

  // Dining
  bool _diningCoveredInHall = false;
  final Set<String> _diningLocations = {'Separate Indoor dining area / hall'};
  String _diningLength = 'Length';
  String _diningWidth = 'Width';
  String _diningHeight = 'Client Height';
  late TextEditingController _diningCapacityController;

  final List<String> _diningLengths = const ['Length', '40 ft', '60 ft', '80 ft', '100 ft'];
  final List<String> _diningWidths = const ['Width', '30 ft', '50 ft', '70 ft', '80 ft'];
  final List<String> _diningHeights = const ['Client Height', '12 ft', '15 ft', '18 ft'];

  @override
  void initState() {
    super.initState();
    _draft = widget.draft;
    _eventData = Map<String, dynamic>.from(widget.eventData);

    _seatingCapacityController = TextEditingController(
      text: _eventData['seatingCapacity']?.toString() ?? '2,000(guests)',
    );
    _hallCapacityController = TextEditingController(
      text: _eventData['hallCapacity']?.toString() ?? '3,000(guests)',
    );
    _diningCapacityController = TextEditingController(
      text: _eventData['diningCapacity']?.toString() ?? '1,000(guests)',
    );
  }

  @override
  void dispose() {
    _seatingCapacityController.dispose();
    _hallCapacityController.dispose();
    _diningCapacityController.dispose();
    super.dispose();
  }

  void _onContinue() async {
    final updatedEventData = {
      ..._eventData,
      'seatingCapacity': _seatingCapacityController.text.trim(),
      'hallCapacity': _hallCapacityController.text.trim(),
      'stageLocations': _stageLocations.toList(),
      'stageDimensions': {
        'length': _stageLength != 'Length' ? _stageLength : '',
        'width': _stageWidth != 'Width' ? _stageWidth : '',
        'height': _stageHeight != 'Stage Height' ? _stageHeight : '',
      },
      'diningCoveredInHall': _diningCoveredInHall,
      'diningLocations': _diningLocations.toList(),
      'diningDimensions': {
        'length': _diningLength != 'Length' ? _diningLength : '',
        'width': _diningWidth != 'Width' ? _diningWidth : '',
        'height': _diningHeight != 'Client Height' ? _diningHeight : '',
      },
      'diningCapacity': _diningCapacityController.text.trim(),
    };

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HostEventScreen14BridalRooms(
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
                  title: '',
                  onBack: () => Navigator.pop(context),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'What is the guest hall seating capacity?',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1E1E24),
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildInputField(controller: _seatingCapacityController, hint: '2,000(guests)'),
                        const SizedBox(height: 22),

                        Text(
                          'What is the guest hall capacity?',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1E1E24),
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildInputField(controller: _hallCapacityController, hint: '3,000(guests)'),
                        const SizedBox(height: 28),

                        const Divider(color: Color(0xFFE2E2EC), thickness: 1),
                        const SizedBox(height: 20),

                        // Stage Location
                        Text(
                          'Where is the stage located?',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1E1E24),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...[
                          'Fixed indoor stage',
                          'Fixed Outdoor stage',
                          'Temporary stage can be arranged',
                          'No stage',
                        ].map((loc) {
                          final isChecked = _stageLocations.contains(loc);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: _buildCheckboxTile(
                              title: loc,
                              isChecked: isChecked,
                              onChanged: (_) {
                                setState(() {
                                  if (isChecked) {
                                    _stageLocations.remove(loc);
                                  } else {
                                    _stageLocations.add(loc);
                                  }
                                });
                              },
                            ),
                          );
                        }),
                        const SizedBox(height: 18),

                        Text(
                          'What is the size of stage? (optional)',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF2E2E38),
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildDropdownPicker(
                          value: _stageLength,
                          items: _stageLengths,
                          onChanged: (val) {
                            if (val != null) setState(() => _stageLength = val);
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildDropdownPicker(
                          value: _stageWidth,
                          items: _stageWidths,
                          onChanged: (val) {
                            if (val != null) setState(() => _stageWidth = val);
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildDropdownPicker(
                          value: _stageHeight,
                          items: _stageHeights,
                          onChanged: (val) {
                            if (val != null) setState(() => _stageHeight = val);
                          },
                        ),

                        const SizedBox(height: 28),
                        const Divider(color: Color(0xFFE2E2EC), thickness: 1),
                        const SizedBox(height: 20),

                        // Dining Area
                        Text(
                          'The Dining Area is already covered in Event Hall Area?',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1E1E24),
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _buildRadioTile(
                          title: 'Yes',
                          isSelected: _diningCoveredInHall,
                          onTap: () => setState(() => _diningCoveredInHall = true),
                        ),
                        const SizedBox(height: 10),
                        _buildRadioTile(
                          title: 'No',
                          isSelected: !_diningCoveredInHall,
                          onTap: () => setState(() => _diningCoveredInHall = false),
                        ),
                        const SizedBox(height: 24),

                        Text(
                          'Where do guest eat?',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1E1E24),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...[
                          'Separate Indoor dining area / hall',
                          'Separate outdoor dining area',
                        ].map((loc) {
                          final isChecked = _diningLocations.contains(loc);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: _buildCheckboxTile(
                              title: loc,
                              isChecked: isChecked,
                              onChanged: (_) {
                                setState(() {
                                  if (isChecked) {
                                    _diningLocations.remove(loc);
                                  } else {
                                    _diningLocations.add(loc);
                                  }
                                });
                              },
                            ),
                          );
                        }),
                        const SizedBox(height: 18),

                        Text(
                          'What is the size of dining area (optional)',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF2E2E38),
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildDropdownPicker(
                          value: _diningLength,
                          items: _diningLengths,
                          onChanged: (val) {
                            if (val != null) setState(() => _diningLength = val);
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildDropdownPicker(
                          value: _diningWidth,
                          items: _diningWidths,
                          onChanged: (val) {
                            if (val != null) setState(() => _diningWidth = val);
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildDropdownPicker(
                          value: _diningHeight,
                          items: _diningHeights,
                          onChanged: (val) {
                            if (val != null) setState(() => _diningHeight = val);
                          },
                        ),
                        const SizedBox(height: 24),

                        Text(
                          'What is the guest Dining capacity?',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1E1E24),
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildInputField(controller: _diningCapacityController, hint: '1,000(guests)'),

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

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
  }) {
    return TextField(
      controller: controller,
      style: GoogleFonts.poppins(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: const Color(0xFF1E1E24),
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFFA0A0B0)),
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

