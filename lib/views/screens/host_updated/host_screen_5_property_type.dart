import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/host_updated_property_draft_model.dart';
import '../../../services/host_api_service.dart';
import 'widgets/host_components.dart';
import 'host_screen_6_property_count.dart';

/// Figma: frame 1228744500 (node 1:897)
class HostScreen5PropertyType extends StatefulWidget {
  final HostUpdatedPropertyDraft? draft;

  const HostScreen5PropertyType({
    super.key,
    this.draft,
  });

  @override
  State<HostScreen5PropertyType> createState() => _HostScreen5PropertyTypeState();
}

class _HostScreen5PropertyTypeState extends State<HostScreen5PropertyType> {
  late HostUpdatedPropertyDraft _draft;
  String _selectedType = '';

  List<Map<String, dynamic>> _propertyCategories = [
    {'title': 'Hotel', 'icon': Icons.apartment_rounded},
    {'title': 'Villa', 'icon': Icons.holiday_village_rounded},
    {'title': 'Flats', 'icon': Icons.grid_view_rounded},
    {'title': 'Room', 'icon': Icons.bed_rounded},
    {'title': 'Apartments', 'icon': Icons.location_city_rounded},
    {'title': 'Farm stay', 'icon': Icons.cottage_rounded},
    {'title': 'Resort', 'icon': Icons.beach_access_rounded},
    {'title': 'Hall', 'icon': Icons.account_balance_rounded},
    {'title': 'Convention Hall', 'icon': Icons.stadium_rounded},
    {'title': 'Gardens / lawns', 'icon': Icons.park_rounded},
    {'title': 'Function Hall', 'icon': Icons.celebration_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _draft = widget.draft ?? const HostUpdatedPropertyDraft();
    _selectedType = _draft.propertyType.isNotEmpty ? _draft.propertyType : 'Hotel';
    _loadMetadata();
  }

  Future<void> _loadMetadata() async {
    final meta = await HostApiService.getPropertiesMetadata();
    if (!mounted) return;
    if (meta['success'] == true && meta['metadata'] is Map) {
      final m = meta['metadata'] as Map<String, dynamic>;
      if (m['categories'] is List && (m['categories'] as List).isNotEmpty) {
        final List<Map<String, dynamic>> dynamicCats = [];
        for (var c in m['categories']) {
          if (c is Map && c['name'] != null) {
            final name = c['name'].toString();
            dynamicCats.add({
              'title': name,
              'icon': _getCategoryIcon(name),
            });
          }
        }
        if (dynamicCats.isNotEmpty) {
          setState(() => _propertyCategories = dynamicCats);
        }
      }
    }
  }

  IconData _getCategoryIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('hotel')) return Icons.apartment_rounded;
    if (lower.contains('villa')) return Icons.holiday_village_rounded;
    if (lower.contains('flat')) return Icons.grid_view_rounded;
    if (lower.contains('room')) return Icons.bed_rounded;
    if (lower.contains('apartment')) return Icons.location_city_rounded;
    if (lower.contains('farm')) return Icons.cottage_rounded;
    if (lower.contains('resort')) return Icons.beach_access_rounded;
    if (lower.contains('convention')) return Icons.stadium_rounded;
    if (lower.contains('hall')) return Icons.account_balance_rounded;
    if (lower.contains('garden') || lower.contains('lawn')) return Icons.park_rounded;
    return Icons.holiday_village_outlined;
  }

  void _onContinue() async {
    var updated = _draft.copyWith(propertyType: _selectedType);

    // Save Step 2 asynchronously
    HostApiService.saveWizardStep(
      step: 2,
      propertyId: updated.propertyId,
      payload: {
        'category': _selectedType,
        'listingScope': updated.listingScope.isNotEmpty ? updated.listingScope : 'MULTIPLE_UNITS',
      },
    ).then((res) {
      if (res['property'] != null && res['property']['propertyId'] != null) {
        final newPropId = res['property']['propertyId'].toString();
        if (mounted) {
          _draft = _draft.copyWith(propertyId: newPropId);
        }
      }
    });

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HostScreen6PropertyCount(draft: updated),
      ),
    );

    if (result != null && result is HostUpdatedPropertyDraft && mounted) {
      setState(() {
        _draft = result;
        _selectedType = _draft.propertyType;
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
              title: 'Select Your Property',
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
                      'List your property on zatara and start your bookings?',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E1E24),
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'To get started, choose the type of property you want to list',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF757585),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 2.7,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                      ),
                      itemCount: _propertyCategories.length,
                      itemBuilder: (context, index) {
                        final item = _propertyCategories[index];
                        final title = item['title'] as String;
                        final icon = item['icon'] as IconData;
                        final isSelected = _selectedType == title;

                        return InkWell(
                          onTap: () {
                            setState(() {
                              _selectedType = title;
                            });
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFFF4F0FD) : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? const Color(0xFF5E42C2) : const Color(0xFFE5E4ED),
                                width: isSelected ? 1.8 : 1.0,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFF5E42C2).withValues(alpha: 0.08),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      )
                                    ]
                                  : null,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  icon,
                                  color: const Color(0xFF5E42C2),
                                  size: 24,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                      color: const Color(0xFF1E1E24),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: HostBottomButton(
                text: 'Continue',
                onPressed: _selectedType.isNotEmpty ? _onContinue : null,
              ),
            ),
          ],
        ),
          ],
        ),
      ),
    );
  }
}


********************************************************************************
================================================================================
