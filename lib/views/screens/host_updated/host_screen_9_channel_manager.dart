import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/host_updated_property_draft_model.dart';
import '../../../services/host_api_service.dart';
import 'widgets/host_components.dart';
import 'host_screen_10_property_name_rating.dart';

/// Figma: frame 1228744504 (node 1:1102)
class HostScreen9ChannelManager extends StatefulWidget {
  final HostUpdatedPropertyDraft draft;

  const HostScreen9ChannelManager({
    super.key,
    required this.draft,
  });

  @override
  State<HostScreen9ChannelManager> createState() => _HostScreen9ChannelManagerState();
}

class _HostScreen9ChannelManagerState extends State<HostScreen9ChannelManager> {
  late HostUpdatedPropertyDraft _draft;
  late bool _useChannelManager;

  @override
  void initState() {
    super.initState();
    _draft = widget.draft;
    _useChannelManager = _draft.useChannelManager;
  }

  void _onContinue() async {
    final updated = _draft.copyWith(useChannelManager: _useChannelManager);

    // Save Step 6 asynchronously
    HostApiService.saveWizardStep(
      step: 6,
      propertyId: updated.propertyId,
      payload: {
        'hasChannelManager': _useChannelManager,
      },
    );

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HostScreen10PropertyNameRating(draft: updated),
      ),
    );

    if (result != null && result is HostUpdatedPropertyDraft && mounted) {
      setState(() {
        _draft = result;
        _useChannelManager = _draft.useChannelManager;
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
              title: 'Connect to a channel manager',
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
                      'A channel manager is a third party tool that lets you manage rates and availability across different sites you might list your place on, including ZAATRA. If you’re already using a channel manager, you can select “yes” to connect it to your listing.',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF555566),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 28),
                    _buildRadioOption(
                      selected: _useChannelManager == true,
                      title: 'Yes, I will connect this listing to my channel manager',
                      onTap: () => setState(() => _useChannelManager = true),
                    ),
                    const SizedBox(height: 18),
                    _buildRadioOption(
                      selected: _useChannelManager == false,
                      title: 'No, I won’t be using a channel manager at this time',
                      onTap: () => setState(() => _useChannelManager = false),
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

  Widget _buildRadioOption({
    required bool selected,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
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
                  color: selected ? const Color(0xFF5E42C2) : const Color(0xFFA0A0B2),
                  width: selected ? 6.0 : 1.5,
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

