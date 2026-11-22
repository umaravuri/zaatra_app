import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/host_updated_property_draft_model.dart';
import '../../../services/host_api_service.dart';
import 'widgets/host_components.dart';
import 'host_screen_17_unit_details.dart';

class HostScreen16UnitType extends StatefulWidget {
  final HostUpdatedPropertyDraft draft;

  const HostScreen16UnitType({
    super.key,
    required this.draft,
  });

  @override
  State<HostScreen16UnitType> createState() => _HostScreen16UnitTypeState();
}

class _HostScreen16UnitTypeState extends State<HostScreen16UnitType> {
  late HostUpdatedPropertyDraft _draft;
  String _purpose = 'Stay / Accomadation';
  String _selectedUnitType = 'Double';

  List<String> _unitTypes = [
    'Single',
    'Double',
    'Twin',
    'Twin / Double',
    'Quadrapule',
    'Suite',
    'Family',
    'Studio',
    'Apartment',
    'Single room',
    'Dormitry Room',
    'Bed in Dormitory',
    'Flat',
  ];

  @override
  void initState() {
    super.initState();
    _draft = widget.draft;
    _loadMetadata();
  }

  Future<void> _loadMetadata() async {
    final meta = await HostApiService.getPropertiesMetadata();
    if (!mounted) return;
    if (meta['success'] == true && meta['metadata'] is Map) {
      final m = meta['metadata'] as Map<String, dynamic>;
      if (m['unitTypes'] is List && (m['unitTypes'] as List).isNotEmpty) {
        setState(() {
          _unitTypes = (m['unitTypes'] as List).map((e) => e.toString()).toList();
        });
      }
    }
  }

  void _onContinue() async {
    final updatedUnits = List<Map<String, dynamic>>.from(_draft.units);
    final unitData = {
      'purpose': _purpose,
      'unitType': _selectedUnitType,
    };

    final updatedDraft = _draft.copyWith(
      units: updatedUnits.isNotEmpty ? updatedUnits : [unitData],
    );

    // Save Step 13 asynchronously
    HostApiService.saveWizardStep(
      step: 13,
      propertyId: updatedDraft.propertyId,
      payload: {
        'listingPurpose': _purpose.toLowerCase().contains('event') ? 'event' : 'stay',
        'unitType': _selectedUnitType,
      },
    );

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HostScreen17UnitDetails(
          draft: updatedDraft,
          currentUnit: unitData,
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
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Are you listing this unit for?',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E1E24),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildPurposeRadio(
                      title: 'Stay / Accomadation',
                      value: 'Stay / Accomadation',
                    ),
                    const SizedBox(height: 12),
                    _buildPurposeRadio(
                      title: 'Event books',
                      value: 'Event books',
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'What type of unit is this',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF4A5568),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Custom Dropdown Display
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE5E4ED)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedUnitType,
                          isExpanded: true,
                          icon: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: Color(0xFF757585),
                            size: 24,
                          ),
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF1E1E24),
                          ),
                          items: _unitTypes.map((type) {
                            return DropdownMenuItem<String>(
                              value: type,
                              child: Text(type),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedUnitType = val);
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Inline List showing all types matching 16.png
                    ..._unitTypes.map((type) {
                      final isCurrent = _selectedUnitType == type;
                      return InkWell(
                        onTap: () {
                          setState(() => _selectedUnitType = type);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                          child: Text(
                            type,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
                              color: isCurrent ? const Color(0xFF5E42C2) : const Color(0xFF6E6E82),
                            ),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 32),
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

  Widget _buildPurposeRadio({
    required String title,
    required String value,
  }) {
    final isSelected = _purpose == value;

    return InkWell(
      onTap: () {
        setState(() => _purpose = value);
      },
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
                  width: isSelected ? 6.0 : 1.5,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF1E1E24),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
