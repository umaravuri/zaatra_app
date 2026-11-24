import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/host_updated_property_draft_model.dart';
import 'widgets/host_form_widgets.dart';
import 'host_event_screen_19_alcohol_policy.dart';

/// rate plans per event type, and decoration, catering and
/// DJ / music policies.
/// Figma: frame 1228744526 (node 1:3734)
class HostEventScreen18RatePlans extends StatefulWidget {
  final HostUpdatedPropertyDraft draft;
  final Map<String, dynamic> eventData;

  const HostEventScreen18RatePlans({
    super.key,
    required this.draft,
    required this.eventData,
  });

  @override
  State<HostEventScreen18RatePlans> createState() => _HostEventScreen18RatePlansState();
}

class _HostEventScreen18RatePlansState extends State<HostEventScreen18RatePlans> {
  static const _planNames = [
    'Wedding + 10 rooms',
    'Birthday',
    'Any event + No accommodation rooms',
  ];
  static const _decorationOptions = [
    'Outside decorators',
    'Both inside and outside decorators',
    'Inside decorators only',
  ];
  static const _cateringOptions = [
    'Outside catering only',
    'Both inside and outside caterers',
    'Inside catering only',
  ];
  static const _djOptions = [
    'Outside DJ only',
    'Both inside and outside DJ',
    'Venue DJ only',
  ];

  late final List<TextEditingController> _planPrices;
  final _standardConditions = TextEditingController();
  final _decorationConditions = TextEditingController();
  final _cateringConditions = TextEditingController();
  final _djConditions = TextEditingController();

  String _decoration = '';
  String _catering = '';
  String _dj = '';

  @override
  void initState() {
    super.initState();
    _planPrices = List.generate(_planNames.length, (_) => TextEditingController());
  }

  @override
  void dispose() {
    for (final c in _planPrices) {
      c.dispose();
    }
    _standardConditions.dispose();
    _decorationConditions.dispose();
    _cateringConditions.dispose();
    _djConditions.dispose();
    super.dispose();
  }

  void _onContinue() async {
    if (_decoration.isEmpty) return showHostError(context, 'Select the decoration policy');
    if (_catering.isEmpty) return showHostError(context, 'Select the catering policy');
    if (_dj.isEmpty) return showHostError(context, 'Select who can provide DJ / music');

    final eventData = {
      ...widget.eventData,
      'ratePlans': [
        for (var i = 0; i < _planNames.length; i++)
          {'name': _planNames[i], 'guestKeyPrice': _planPrices[i].text.trim()},
      ],
      'standardRatePlanConditions': _standardConditions.text.trim(),
      'decorationPolicy': {'option': _decoration, 'conditions': _decorationConditions.text.trim()},
      'cateringPolicy': {'option': _catering, 'conditions': _cateringConditions.text.trim()},
      'djPolicy': {'option': _dj, 'conditions': _djConditions.text.trim()},
    };

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            HostEventScreen19AlcoholPolicy(draft: widget.draft, eventData: eventData),
      ),
    );
    if (result is HostUpdatedPropertyDraft && mounted) Navigator.pop(context, result);
  }

  Widget _heading(String text) => Padding(
        padding: const EdgeInsets.only(top: 28, bottom: 4),
        child: Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF5E42C2),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return HostFormPage(
      title: 'Rate plans',
      onContinue: _onContinue,
      children: [
        const HostQuestion('Plans', topSpace: 6),
        Row(
          children: [
            Expanded(
              child: Text('Events', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            ),
            SizedBox(
              width: 130,
              child: Text('Guest Key', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        for (var i = 0; i < _planNames.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Expanded(child: Text(_planNames[i], style: GoogleFonts.poppins(fontSize: 14))),
                SizedBox(
                  width: 130,
                  child: HostTextField(controller: _planPrices[i], hint: '₹', numeric: true),
                ),
              ],
            ),
          ),
        const HostQuestion('Standard rate plan'),
        HostTextField(
          controller: _standardConditions,
          hint: 'Please specify conditions',
          maxLines: 3,
        ),

        _heading('Decoration Policy'),
        HostSingleChoice(
          question: 'What is the venue’s decoration policy?',
          options: _decorationOptions,
          selected: _decoration,
          onChanged: (v) => setState(() => _decoration = v),
        ),
        const SizedBox(height: 8),
        HostTextField(
          controller: _decorationConditions,
          hint: 'Please specify conditions',
          maxLines: 2,
        ),

        _heading('Catering Policy'),
        HostSingleChoice(
          question: 'What is the venue’s catering policy?',
          options: _cateringOptions,
          selected: _catering,
          onChanged: (v) => setState(() => _catering = v),
        ),
        const SizedBox(height: 8),
        HostTextField(
          controller: _cateringConditions,
          hint: 'Please specify conditions',
          maxLines: 2,
        ),

        _heading('DJ / Music Policy'),
        HostSingleChoice(
          question: 'Who can provide DJ / Music',
          options: _djOptions,
          selected: _dj,
          onChanged: (v) => setState(() => _dj = v),
        ),
        const SizedBox(height: 8),
        HostTextField(
          controller: _djConditions,
          hint: 'Please specify conditions',
          maxLines: 2,
        ),
      ],
    );
  }
}

