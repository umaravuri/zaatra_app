import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/host_updated_property_draft_model.dart';
import 'widgets/host_components.dart';
import 'host_screen_23_guest_pay.dart';

class HostScreen22GstPurpose extends StatefulWidget {
  final HostUpdatedPropertyDraft draft;

  const HostScreen22GstPurpose({
    super.key,
    required this.draft,
  });

  @override
  State<HostScreen22GstPurpose> createState() => _HostScreen22GstPurposeState();
}

class _HostScreen22GstPurposeState extends State<HostScreen22GstPurpose> {
  late HostUpdatedPropertyDraft _draft;
  bool _isGstRegistered = true;
  late TextEditingController _gstController;
  late TextEditingController _panController;

  @override
  void initState() {
    super.initState();
    _draft = widget.draft;
    _isGstRegistered = _draft.isGstRegistered;
    _gstController = TextEditingController(text: _draft.gstNumber);
    _panController = TextEditingController(text: _draft.panNumber);
  }

  @override
  void dispose() {
    _gstController.dispose();
    _panController.dispose();
    super.dispose();
  }

  void _onContinue() async {
    final updated = _draft.copyWith(
      isGstRegistered: _isGstRegistered,
      gstNumber: _isGstRegistered ? _gstController.text.trim().toUpperCase() : '',
      panNumber: _panController.text.trim().toUpperCase(),
    );

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HostScreen23GuestPay(draft: updated),
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
              title: 'GST Purpose',
              onBack: () => Navigator.pop(context, _draft),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Are you registered for GST purpose ?',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E1E24),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Radio Yes
                    _buildRadioOption(
                      title: 'Yes',
                      isSelected: _isGstRegistered,
                      onTap: () => setState(() => _isGstRegistered = true),
                    ),
                    const SizedBox(height: 14),

                    // Radio No
                    _buildRadioOption(
                      title: 'No',
                      isSelected: !_isGstRegistered,
                      onTap: () => setState(() => _isGstRegistered = false),
                    ),
                    const SizedBox(height: 24),

                    // Conditional Fields
                    if (_isGstRegistered) ...[
                      _buildTextField(
                        label: 'Enter GST Number',
                        hint: 'Enter Here',
                        controller: _gstController,
                        textCapitalization: TextCapitalization.characters,
                      ),
                      const SizedBox(height: 18),
                    ],

                    _buildTextField(
                      label: 'Pan Number',
                      hint: 'Enter Here',
                      controller: _panController,
                      textCapitalization: TextCapitalization.characters,
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

  Widget _buildRadioOption({
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
                  color: isSelected ? const Color(0xFF1E1E24) : const Color(0xFFA0A0B2),
                  width: isSelected ? 7.0 : 1.5,
                ),
              ),
            ),
            const SizedBox(width: 14),
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

  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF2E2E38),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          textCapitalization: textCapitalization,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: const Color(0xFF1E1E24),
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(
              fontSize: 14,
              color: const Color(0xFFA0A0B0),
            ),
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
        ),
      ],
    );
  }
}
