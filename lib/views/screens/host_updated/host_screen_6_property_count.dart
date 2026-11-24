import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/host_updated_property_draft_model.dart';
import 'widgets/host_components.dart';
import 'host_screen_7_listing_confirmation.dart';

/// Figma: frame 1228744501 (node 1:981)
class HostScreen6PropertyCount extends StatefulWidget {
  final HostUpdatedPropertyDraft draft;

  const HostScreen6PropertyCount({
    super.key,
    required this.draft,
  });

  @override
  State<HostScreen6PropertyCount> createState() => _HostScreen6PropertyCountState();
}

class _HostScreen6PropertyCountState extends State<HostScreen6PropertyCount> {
  late HostUpdatedPropertyDraft _draft;
  late String _countMode;

  @override
  void initState() {
    super.initState();
    _draft = widget.draft;
    _countMode = _draft.listingCountMode.isNotEmpty ? _draft.listingCountMode : 'multiple';
  }

  void _onContinue() async {
    final updated = _draft.copyWith(listingCountMode: _countMode);
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HostScreen7ListingConfirmation(draft: updated),
      ),
    );

    if (result != null && result is HostUpdatedPropertyDraft && mounted) {
      setState(() {
        _draft = result;
        _countMode = _draft.listingCountMode;
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
                    const SizedBox(height: 12),
                    Text(
                      'How many ${_draft.propertyType.isNotEmpty ? _draft.propertyType.toLowerCase() : 'hotels'}/ properties are you listing?',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E1E24),
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildRadioItem(
                      value: 'single',
                      title: 'One ${_draft.propertyType.isNotEmpty ? _draft.propertyType.toLowerCase() : 'hotel'} / property with one or more rooms / venues for guests to book',
                    ),
                    const SizedBox(height: 16),
                    _buildRadioItem(
                      value: 'multiple',
                      title: 'Multiple ${_draft.propertyType.isNotEmpty ? _draft.propertyType.toLowerCase() : 'hotels'} / properties with one or more rooms / venues that guests book',
                    ),
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
    required String value,
    required String title,
  }) {
    final isSelected = _countMode == value;

    return InkWell(
      onTap: () {
        setState(() {
          _countMode = value;
        });
      },
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 2),
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
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF555566),
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

