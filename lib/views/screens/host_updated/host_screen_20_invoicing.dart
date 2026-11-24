import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/host_updated_property_draft_model.dart';
import '../../../core/utils/host_validators.dart';
import 'widgets/host_components.dart';
import 'host_screen_21_verification.dart';

/// Figma: frame 1228744492 (node 1:538)
class HostScreen20Invoicing extends StatefulWidget {
  final HostUpdatedPropertyDraft draft;

  const HostScreen20Invoicing({
    super.key,
    required this.draft,
  });

  @override
  State<HostScreen20Invoicing> createState() => _HostScreen20InvoicingState();
}

class _HostScreen20InvoicingState extends State<HostScreen20Invoicing> {
  late HostUpdatedPropertyDraft _draft;
  late TextEditingController _invoiceNameController;
  bool _sameAddressAsProperty = true;

  @override
  void initState() {
    super.initState();
    _draft = widget.draft;
    _invoiceNameController = TextEditingController(
      text: _draft.invoiceName.isNotEmpty
          ? _draft.invoiceName
          : (_draft.propertyName.isNotEmpty ? _draft.propertyName : ''),
    );
    _sameAddressAsProperty = _draft.invoiceAddressSame;
  }

  @override
  void dispose() {
    _invoiceNameController.dispose();
    super.dispose();
  }

  void _onContinue() async {
    final error = HostValidators.required(_invoiceNameController.text, 'Legal name');
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.redAccent),
      );
      return;
    }

    final updated = _draft.copyWith(
      invoiceName: _invoiceNameController.text.trim(),
      invoiceAddressSame: _sameAddressAsProperty,
    );

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HostScreen21Verification(draft: updated),
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
                      'What name should be invoice',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E1E24),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _invoiceNameController,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: const Color(0xFF1E1E24),
                      ),
                      decoration: InputDecoration(
                        hintText: 'Enter Here',
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
                    const SizedBox(height: 28),
                    Text(
                      'Does this receive have the same address as your property',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E1E24),
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildAddressRadio(
                      title: 'Yes',
                      isSelected: _sameAddressAsProperty,
                      onTap: () => setState(() => _sameAddressAsProperty = true),
                    ),
                    const SizedBox(height: 12),
                    _buildAddressRadio(
                      title: 'No',
                      isSelected: !_sameAddressAsProperty,
                      onTap: () => setState(() => _sameAddressAsProperty = false),
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

  Widget _buildAddressRadio({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
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
}

