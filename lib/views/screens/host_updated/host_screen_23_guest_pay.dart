import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/host_updated_property_draft_model.dart';
import 'widgets/host_components.dart';
import 'host_screen_24_registration.dart';

class HostScreen23GuestPay extends StatefulWidget {
  final HostUpdatedPropertyDraft draft;

  const HostScreen23GuestPay({
    super.key,
    required this.draft,
  });

  @override
  State<HostScreen23GuestPay> createState() => _HostScreen23GuestPayState();
}

class _HostScreen23GuestPayState extends State<HostScreen23GuestPay> {
  late HostUpdatedPropertyDraft _draft;

  final String _onlineOption =
      "Online when they make reservation with payments by zaatara.com, we handle payment so you don't have to.";
  final String _directOption =
      "I want and i have ability to change guests create cards directed.";

  late String _selectedPaymentMethod;

  @override
  void initState() {
    super.initState();
    _draft = widget.draft;
    _selectedPaymentMethod = _draft.guestPaymentMethod.isNotEmpty
        ? (_draft.guestPaymentMethod == 'direct_cards' ? _directOption : _onlineOption)
        : _directOption; // Wireframe 8.png defaults to second option selected
  }

  void _onContinue() async {
    final updated = _draft.copyWith(
      guestPaymentMethod:
          _selectedPaymentMethod == _directOption ? 'direct_cards' : 'zaatra_online',
    );

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HostScreen24Registration(draft: updated),
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
              title: 'Guest Pay',
              onBack: () => Navigator.pop(context, _draft),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select payment',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E1E24),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Option 1
                    _buildPaymentRadio(
                      text: _onlineOption,
                      isSelected: _selectedPaymentMethod == _onlineOption,
                      onTap: () => setState(() => _selectedPaymentMethod = _onlineOption),
                    ),
                    const SizedBox(height: 18),

                    // Option 2
                    _buildPaymentRadio(
                      text: _directOption,
                      isSelected: _selectedPaymentMethod == _directOption,
                      onTap: () => setState(() => _selectedPaymentMethod = _directOption),
                    ),
                    const SizedBox(height: 32),

                    // Educational section matching 8.png
                    Text(
                      'How payment by zaatra.com works?',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E1E24),
                      ),
                    ),
                    const SizedBox(height: 16),

                    _buildBulletPoint(
                      'your guests pays through zaatara.com with more options thoughts razor pay',
                    ),
                    const SizedBox(height: 14),
                    _buildBulletPoint(
                      'We facility your guests payments you don\'t have to deal with Froud invalid.cards',
                    ),
                    const SizedBox(height: 14),
                    _buildBulletPoint(
                      'Zatara.com sends Payouts to you received a bank transfer by the 10th of each month that covers all booking with check outs in the previous months.',
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

  Widget _buildPaymentRadio({
    required String text,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2.0),
            child: Container(
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
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF4A4A58),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 6.0, right: 10.0),
          child: Container(
            width: 5,
            height: 5,
            decoration: const BoxDecoration(
              color: Color(0xFF555566),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF555566),
              height: 1.45,
            ),
          ),
        ),
      ],
    );
  }
}
