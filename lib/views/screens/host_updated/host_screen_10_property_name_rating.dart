import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/host_updated_property_draft_model.dart';
import '../../../services/host_api_service.dart';
import '../../../core/utils/host_validators.dart';
import 'widgets/host_components.dart';
import 'host_screen_11_facilities.dart';

/// Figma: frame 1228744505 (node 1:1132)
class HostScreen10PropertyNameRating extends StatefulWidget {
  final HostUpdatedPropertyDraft draft;

  const HostScreen10PropertyNameRating({
    super.key,
    required this.draft,
  });

  @override
  State<HostScreen10PropertyNameRating> createState() => _HostScreen10PropertyNameRatingState();
}

class _HostScreen10PropertyNameRatingState extends State<HostScreen10PropertyNameRating> {
  late HostUpdatedPropertyDraft _draft;
  late TextEditingController _nameController;
  late String _starRating;
  late bool _isChainOrGroup;

  @override
  void initState() {
    super.initState();
    _draft = widget.draft;
    _nameController = TextEditingController(
      text: _draft.propertyName,
    );
    _starRating = _draft.starRating.isNotEmpty ? _draft.starRating : 'N/A';
    _isChainOrGroup = _draft.isChainOrGroup;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _onContinue() async {
    final error = HostValidators.required(_nameController.text, 'Property name');
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.redAccent),
      );
      return;
    }

    final updated = _draft.copyWith(
      propertyName: _nameController.text.trim(),
      starRating: _starRating,
      isChainOrGroup: _isChainOrGroup,
    );

    // Save Step 7 asynchronously
    HostApiService.saveWizardStep(
      step: 7,
      propertyId: updated.propertyId,
      payload: {
        'propertyName': updated.propertyName,
        'starRating': updated.starRating,
        'isPropertyManagementOrChain': updated.isChainOrGroup,
      },
    );

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HostScreen11Facilities(draft: updated),
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
              title: 'What is your property?',
              onBack: () => Navigator.pop(context, _draft),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    Text(
                      'Enter your property name',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF1E1E24),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE5E4ED)),
                      ),
                      child: TextField(
                        controller: _nameController,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: const Color(0xFF1E1E24),
                        ),
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          hintText: 'Hall 1',
                          hintStyle: GoogleFonts.poppins(
                            fontSize: 14,
                            color: const Color(0xFFA0A0B2),
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'This name will be seen by guests when they search for a place to stay.',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: const Color(0xFF555566),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    RichText(
                      text: TextSpan(
                        style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF757585), height: 1.4),
                        children: const [
                          TextSpan(
                            text: 'Example : ',
                            style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF555566)),
                          ),
                          TextSpan(
                            text: 'The blue Hotel, Luxury Resort Near Gachibowli, Best farm stay near srisailam, The grand Banquet Hall, Hyderabad.',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Divider(color: Color(0xFFEEEEF2)),
                    const SizedBox(height: 12),
                    Text(
                      'What is Star rating of your Property?',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E1E24),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildStarOption(val: 'N/A', stars: 0),
                    _buildStarOption(val: '1', stars: 1),
                    _buildStarOption(val: '2', stars: 2),
                    _buildStarOption(val: '3', stars: 3),
                    _buildStarOption(val: '4', stars: 4),
                    _buildStarOption(val: '5', stars: 5),
                    const SizedBox(height: 16),
                    const Divider(color: Color(0xFFEEEEF2)),
                    const SizedBox(height: 12),
                    Text(
                      'Are you a property management company or party of a group or chain?',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E1E24),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildChainOption(
                      selected: _isChainOrGroup == true,
                      title: 'Yes',
                      onTap: () => setState(() => _isChainOrGroup = true),
                    ),
                    const SizedBox(height: 10),
                    _buildChainOption(
                      selected: _isChainOrGroup == false,
                      title: 'No',
                      onTap: () => setState(() => _isChainOrGroup = false),
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

  Widget _buildStarOption({required String val, required int stars}) {
    final isSelected = _starRating == val;

    return InkWell(
      onTap: () => setState(() => _starRating = val),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5.0),
        child: Row(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? const Color(0xFF5E42C2) : const Color(0xFFA0A0B2),
                  width: isSelected ? 5.5 : 1.5,
                ),
              ),
            ),
            const SizedBox(width: 12),
            if (stars == 0)
              Text(
                'N/A',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF555566),
                ),
              )
            else
              Row(
                children: List.generate(
                  stars,
                  (index) => const Padding(
                    padding: EdgeInsets.only(right: 3.0),
                    child: Icon(Icons.star_rounded, size: 18, color: Color(0xFF9E9E9E)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildChainOption({
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
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF555566),
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
