import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/host_updated_property_draft_model.dart';
import '../../../services/host_api_service.dart';
import 'widgets/host_components.dart';
import 'host_screen_15_property_hub.dart';

/// Figma: frame 1228744509 (node 1:1475)
class HostScreen14PetPolicy extends StatefulWidget {
  final HostUpdatedPropertyDraft draft;

  const HostScreen14PetPolicy({
    super.key,
    required this.draft,
  });

  @override
  State<HostScreen14PetPolicy> createState() => _HostScreen14PetPolicyState();
}

class _HostScreen14PetPolicyState extends State<HostScreen14PetPolicy> {
  late HostUpdatedPropertyDraft _draft;
  late String _allowsPets;
  late String _petFeeMode;

  @override
  void initState() {
    super.initState();
    _draft = widget.draft;
    _allowsPets = _draft.allowsPets.isNotEmpty ? _draft.allowsPets : 'yes';
    _petFeeMode = _draft.petFeeMode.isNotEmpty ? _draft.petFeeMode : 'free';
  }

  void _onContinue() async {
    final updated = _draft.copyWith(
      allowsPets: _allowsPets,
      petFeeMode: _petFeeMode,
    );

    // Save Step 11 asynchronously
    HostApiService.saveWizardStep(
      step: 11,
      propertyId: updated.propertyId,
      payload: {
        'allowPets': _allowsPets,
        'petCharges': _petFeeMode,
      },
    );

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HostScreen15PropertyHub(draft: updated),
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
              title: 'Pet Policy',
              onBack: () => Navigator.pop(context, _draft),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    Text(
                      'Do you allow pets?',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E1E24),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _buildRadioItem(
                      selected: _allowsPets == 'yes',
                      title: 'Yes',
                      onTap: () => setState(() => _allowsPets = 'yes'),
                    ),
                    const SizedBox(height: 10),
                    _buildRadioItem(
                      selected: _allowsPets == 'upon_request',
                      title: 'Upon Request',
                      onTap: () => setState(() => _allowsPets = 'upon_request'),
                    ),
                    const SizedBox(height: 10),
                    _buildRadioItem(
                      selected: _allowsPets == 'no',
                      title: 'No',
                      onTap: () => setState(() => _allowsPets = 'no'),
                    ),
                    const SizedBox(height: 20),
                    const Divider(color: Color(0xFFEEEEF2)),
                    const SizedBox(height: 16),
                    Text(
                      'Are they any additional changes for pets?',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E1E24),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _buildRadioItem(
                      selected: _petFeeMode == 'free',
                      title: 'Pets can stay for free',
                      onTap: () => setState(() => _petFeeMode = 'free'),
                    ),
                    const SizedBox(height: 10),
                    _buildRadioItem(
                      selected: _petFeeMode == 'charges',
                      title: 'Charges may apply',
                      onTap: () => setState(() => _petFeeMode = 'charges'),
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

  Widget _buildRadioItem({
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
            const SizedBox(width: 12),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF424252),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

