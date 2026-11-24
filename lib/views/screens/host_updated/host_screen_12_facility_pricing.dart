import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/host_updated_property_draft_model.dart';
import '../../../services/host_api_service.dart';
import 'widgets/host_components.dart';
import 'host_screen_13_breakfast_rules_languages.dart';

/// Figma: frame 1228744507 (node 1:1310)
class HostScreen12FacilityPricing extends StatefulWidget {
  final HostUpdatedPropertyDraft draft;

  const HostScreen12FacilityPricing({
    super.key,
    required this.draft,
  });

  @override
  State<HostScreen12FacilityPricing> createState() => _HostScreen12FacilityPricingState();
}

class _HostScreen12FacilityPricingState extends State<HostScreen12FacilityPricing> {
  late HostUpdatedPropertyDraft _draft;
  late Map<String, String> _facilityPricing;

  @override
  void initState() {
    super.initState();
    _draft = widget.draft;
    _facilityPricing = Map<String, String>.from(_draft.facilityPricing);

    // Default any unset facility to 'Included'
    for (final facility in _draft.facilities) {
      _facilityPricing.putIfAbsent(facility, () => 'Included');
    }
  }

  void _onContinue() async {
    final updated = _draft.copyWith(facilityPricing: _facilityPricing);

    // Save Step 9 asynchronously
    final provisioningList = updated.facilities.map((fac) {
      final type = _facilityPricing[fac] ?? 'Included';
      return {
        'facility': fac,
        'provisionType': type,
        'extraCharge': 0,
      };
    }).toList();

    HostApiService.saveWizardStep(
      step: 9,
      propertyId: updated.propertyId,
      payload: {
        'facilities': updated.facilities,
        'facilityProvisioning': provisioningList,
      },
    );

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HostScreen13BreakfastRulesLanguages(draft: updated),
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
              title: 'Facility Provisioning',
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
                      'How is each selected facility or service provided to guests?',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E1E24),
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (_draft.facilities.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32.0),
                        child: Text(
                          'No facilities selected. Go back to choose facilities.',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: const Color(0xFF757585),
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _draft.facilities.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 20),
                        itemBuilder: (context, index) {
                          final facility = _draft.facilities[index];
                          final currentPricing = _facilityPricing[facility] ?? 'Included';

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                facility,
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF1E1E24),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  _buildPricingRadio(
                                    facility: facility,
                                    option: 'Included',
                                    selected: currentPricing == 'Included',
                                  ),
                                  const SizedBox(width: 14),
                                  _buildPricingRadio(
                                    facility: facility,
                                    option: 'Extra Charge',
                                    selected: currentPricing == 'Extra Charge',
                                  ),
                                  const SizedBox(width: 14),
                                  _buildPricingRadio(
                                    facility: facility,
                                    option: 'On Request',
                                    selected: currentPricing == 'On Request',
                                  ),
                                ],
                              ),
                            ],
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

  Widget _buildPricingRadio({
    required String facility,
    required String option,
    required bool selected,
  }) {
    return InkWell(
      onTap: () {
        setState(() {
          _facilityPricing[facility] = option;
        });
      },
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
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? const Color(0xFF5E42C2) : const Color(0xFFA0A0B2),
                  width: selected ? 5.5 : 1.5,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              option,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
                color: const Color(0xFF424252),
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
