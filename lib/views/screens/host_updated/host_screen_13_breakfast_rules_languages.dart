import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/host_updated_property_draft_model.dart';
import '../../../services/host_api_service.dart';
import 'widgets/host_components.dart';
import 'host_screen_14_pet_policy.dart';

class HostScreen13BreakfastRulesLanguages extends StatefulWidget {
  final HostUpdatedPropertyDraft draft;

  const HostScreen13BreakfastRulesLanguages({
    super.key,
    required this.draft,
  });

  @override
  State<HostScreen13BreakfastRulesLanguages> createState() => _HostScreen13BreakfastRulesLanguagesState();
}

class _HostScreen13BreakfastRulesLanguagesState extends State<HostScreen13BreakfastRulesLanguages> {
  late HostUpdatedPropertyDraft _draft;
  late bool _servesBreakfast;
  late bool _allowsChildren;
  late List<String> _languages;
  late Set<String> _selectedLanguages;

  final List<String> _defaultLanguages = [
    'Assamese',
    'Bengali',
    'Gujarati',
    'Hindi',
    'Kannada',
    'Kashmiri',
    'Malayalam',
    'Marathi',
    'Malayali',
    'Odia',
    'Punjabi',
    'Santali',
    'Tamil',
    'Telugu',
    'Urdu',
    'English',
  ];

  @override
  void initState() {
    super.initState();
    _draft = widget.draft;
    _servesBreakfast = _draft.servesBreakfast;
    _allowsChildren = _draft.allowsChildren;
    _languages = List<String>.from(_defaultLanguages);
    for (final l in _draft.staffLanguages) {
      if (!_languages.contains(l)) {
        _languages.add(l);
      }
    }
    _selectedLanguages = _draft.staffLanguages.isNotEmpty
        ? _draft.staffLanguages.toSet()
        : {'Hindi', 'English', 'Telugu'};
    _loadMetadata();
  }

  Future<void> _loadMetadata() async {
    final meta = await HostApiService.getPropertiesMetadata();
    if (!mounted) return;
    if (meta['success'] == true && meta['metadata'] is Map) {
      final m = meta['metadata'] as Map<String, dynamic>;
      if (m['languages'] is List && (m['languages'] as List).isNotEmpty) {
        final fetched = (m['languages'] as List).map((e) => e.toString()).toList();
        setState(() {
          for (final l in fetched) {
            if (!_languages.contains(l)) {
              _languages.add(l);
            }
          }
        });
      }
    }
  }

  void _toggleLanguage(String lang) {
    setState(() {
      if (_selectedLanguages.contains(lang)) {
        _selectedLanguages.remove(lang);
      } else {
        _selectedLanguages.add(lang);
      }
    });
  }

  void _showAddLanguageDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Add Language',
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Enter language (e.g. French, German)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5E42C2)),
            onPressed: () async {
              final text = controller.text.trim();
              Navigator.pop(ctx);
              if (text.isNotEmpty) {
                // Call API 5
                await HostApiService.addCustomLanguage(
                  language: text,
                  propertyId: _draft.propertyId,
                );

                if (mounted) {
                  setState(() {
                    if (!_languages.contains(text)) {
                      _languages.add(text);
                    }
                    _selectedLanguages.add(text);
                  });
                }
              }
            },
            child: const Text('Add', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _onContinue() async {
    final updated = _draft.copyWith(
      servesBreakfast: _servesBreakfast,
      allowsChildren: _allowsChildren,
      staffLanguages: _selectedLanguages.toList(),
    );

    // Save Step 10 asynchronously
    HostApiService.saveWizardStep(
      step: 10,
      propertyId: updated.propertyId,
      payload: {
        'servesBreakfast': _servesBreakfast,
        'allowsChildren': _allowsChildren,
        'languagesSpoken': _selectedLanguages.toList(),
      },
    );

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HostScreen14PetPolicy(draft: updated),
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
    final half = (_languages.length / 2).ceil();
    final leftLangs = _languages.sublist(0, half);
    final rightLangs = _languages.sublist(half);

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
              title: 'Breakfast & Policies',
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
                      'Do you serve guests breakfast?',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E1E24),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildYesNoRadio(
                      selected: _servesBreakfast == true,
                      title: 'Yes',
                      onTap: () => setState(() => _servesBreakfast = true),
                    ),
                    const SizedBox(height: 8),
                    _buildYesNoRadio(
                      selected: _servesBreakfast == false,
                      title: 'No',
                      onTap: () => setState(() => _servesBreakfast = false),
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: Color(0xFFEEEEF2)),
                    const SizedBox(height: 12),
                    Text(
                      'Children',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E1E24),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Do you allow children?',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF1E1E24),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildYesNoRadio(
                      selected: _allowsChildren == true,
                      title: 'Yes',
                      onTap: () => setState(() => _allowsChildren = true),
                    ),
                    const SizedBox(height: 8),
                    _buildYesNoRadio(
                      selected: _allowsChildren == false,
                      title: 'No',
                      onTap: () => setState(() => _allowsChildren = false),
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: Color(0xFFEEEEF2)),
                    const SizedBox(height: 12),
                    Text(
                      'What language do you or your staff speak?',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E1E24),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Select Languages',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: const Color(0xFF757585),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            children: leftLangs.map((l) => _buildLanguageCheckbox(l)).toList(),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            children: rightLangs.map((l) => _buildLanguageCheckbox(l)).toList(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: TextButton(
                        onPressed: _showAddLanguageDialog,
                        child: Text(
                          'Add Additional Language',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1E1E24),
                          ),
                        ),
                      ),
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

  Widget _buildYesNoRadio({
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

  Widget _buildLanguageCheckbox(String language) {
    final isChecked = _selectedLanguages.contains(language);

    return InkWell(
      onTap: () => _toggleLanguage(language),
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: Row(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: isChecked ? const Color(0xFF5E42C2) : const Color(0xFFE8E5F3),
                borderRadius: BorderRadius.circular(4),
              ),
              child: isChecked
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                language,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF424252),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
