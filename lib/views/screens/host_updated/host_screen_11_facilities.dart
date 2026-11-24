import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/host_updated_property_draft_model.dart';
import '../../../services/host_api_service.dart';
import 'widgets/host_components.dart';
import 'host_screen_12_facility_pricing.dart';

/// Figma: frame 1228744506 (node 1:1194)
class HostScreen11Facilities extends StatefulWidget {
  final HostUpdatedPropertyDraft draft;

  const HostScreen11Facilities({
    super.key,
    required this.draft,
  });

  @override
  State<HostScreen11Facilities> createState() => _HostScreen11FacilitiesState();
}

class _HostScreen11FacilitiesState extends State<HostScreen11Facilities> {
  late HostUpdatedPropertyDraft _draft;
  late Set<String> _selectedFacilities;

  List<String> _leftFacilities = [
    'Restaurant',
    'Room Service',
    'Wifi',
    'Bar',
    '24-hour front desk',
    'Garden',
    'Terrace',
    'AC',
    'Charging rooms',
    'Kitchen',
    'Sound System',
    'Stage',
    'Catering',
    'Accommodation rooms',
  ];

  List<String> _rightFacilities = [
    'Power Backup',
    'Lift',
    'Parking',
    'Security / CCTV',
    'Swimming Pool',
    'Decoration',
    'Airport Shuttle',
    'Laundry',
    'Bonfire',
    'BBQ',
    'DJ / Sounds',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _draft = widget.draft;
    _selectedFacilities = _draft.facilities.isNotEmpty
        ? _draft.facilities.toSet()
        : {'Wifi', 'Garden', 'AC', 'Lift', 'Swimming Pool'};
    _loadMetadata();
  }

  Future<void> _loadMetadata() async {
    final meta = await HostApiService.getPropertiesMetadata();
    if (!mounted) return;
    if (meta['success'] == true && meta['metadata'] is Map) {
      final m = meta['metadata'] as Map<String, dynamic>;
      if (m['facilities'] is List && (m['facilities'] as List).isNotEmpty) {
        final List<String> fetched = (m['facilities'] as List).map((e) => e.toString()).toList();
        final mid = (fetched.length / 2).ceil();
        setState(() {
          _leftFacilities = fetched.sublist(0, mid);
          _rightFacilities = [...fetched.sublist(mid), 'Other'];
        });
      }
    }
  }

  void _toggleFacility(String name) {
    if (name == 'Other') {
      _showAddCustomFacilityDialog();
      return;
    }
    setState(() {
      if (_selectedFacilities.contains(name)) {
        _selectedFacilities.remove(name);
      } else {
        _selectedFacilities.add(name);
      }
    });
  }

  void _showAddCustomFacilityDialog() {
    final controller = TextEditingController();
    String provisionType = 'Included';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Create Custom Facility',
            style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Facility Name',
                style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: const Color(0xFF555566)),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: controller,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'e.g. Private Heated Jacuzzi',
                  hintStyle: GoogleFonts.poppins(fontSize: 13, color: Colors.grey),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E4ED))),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Provision Type',
                style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: const Color(0xFF555566)),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E4ED)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: provisionType,
                    isExpanded: true,
                    items: const ['Included', 'Extra Charge', 'On Request']
                        .map((t) => DropdownMenuItem(value: t, child: Text(t, style: GoogleFonts.poppins(fontSize: 13))))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => provisionType = val);
                    },
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5E42C2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                final text = controller.text.trim();
                if (text.isEmpty) return;
                Navigator.pop(ctx);

                // Call API 4
                await HostApiService.createCustomFacility(
                  name: text,
                  provisionType: provisionType,
                  propertyId: _draft.propertyId,
                );

                if (mounted) {
                  setState(() {
                    if (!_leftFacilities.contains(text) && !_rightFacilities.contains(text)) {
                      _leftFacilities.add(text);
                    }
                    _selectedFacilities.add(text);
                  });
                }
              },
              child: Text('Add Facility', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  void _onContinue() async {
    final updated = _draft.copyWith(
      facilities: _selectedFacilities.toList(),
    );

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HostScreen12FacilityPricing(draft: updated),
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
                  title: 'Facilities & Services',
                  onBack: () => Navigator.pop(context, _draft),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Text(
                          'What facilities and services can guests use at your property?',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1E1E24),
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                children: _leftFacilities.map((name) => _buildCheckboxItem(name)).toList(),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                children: _rightFacilities.map((name) => _buildCheckboxItem(name)).toList(),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: HostBottomButton(
                    text: 'Continue',
                    onPressed: _selectedFacilities.isNotEmpty ? _onContinue : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckboxItem(String name) {
    final isChecked = _selectedFacilities.contains(name);

    return InkWell(
      onTap: () => _toggleFacility(name),
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7.0),
        child: Row(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: isChecked ? const Color(0xFF5E42C2) : const Color(0xFFE8E5F3),
                borderRadius: BorderRadius.circular(4),
              ),
              child: isChecked
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF424252),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

