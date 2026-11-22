import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/host_updated_property_draft_model.dart';
import 'widgets/host_components.dart';
import 'host_screen_8_location_map.dart';

class HostScreen7ListingConfirmation extends StatefulWidget {
  final HostUpdatedPropertyDraft draft;

  const HostScreen7ListingConfirmation({
    super.key,
    required this.draft,
  });

  @override
  State<HostScreen7ListingConfirmation> createState() => _HostScreen7ListingConfirmationState();
}

class _HostScreen7ListingConfirmationState extends State<HostScreen7ListingConfirmation> {
  late HostUpdatedPropertyDraft _draft;

  @override
  void initState() {
    super.initState();
    _draft = widget.draft;
  }

  void _onContinue() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HostScreen8LocationMap(draft: _draft),
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
    final isMultiple = _draft.listingCountMode == 'multiple';
    final confirmationText = isMultiple
        ? 'Multiple properties where guest can book a unit'
        : 'One property where guest can book a unit';

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
              title: 'You are Listing',
              onBack: () => Navigator.pop(context, _draft),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    Text(
                      confirmationText,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E1E24),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  HostBottomButton(
                    text: 'Continue',
                    onPressed: _onContinue,
                  ),
                  const SizedBox(height: 12),
                  HostBottomButton(
                    text: 'No, I need to make a change',
                    isSecondary: true,
                    onPressed: () => Navigator.pop(context, _draft),
                  ),
                ],
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
