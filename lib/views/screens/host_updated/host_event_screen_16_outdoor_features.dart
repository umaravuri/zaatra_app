import 'package:flutter/material.dart';
import '../../../models/host_updated_property_draft_model.dart';
import 'widgets/host_form_widgets.dart';
import 'host_event_screen_17_unit_pricing.dart';

/// air conditioning, music, tent, lighting, outdoor setup.
/// Figma: frame 15-1 (node 1:3341)
class HostEventScreen16OutdoorFeatures extends StatefulWidget {
  final HostUpdatedPropertyDraft draft;
  final Map<String, dynamic> eventData;

  const HostEventScreen16OutdoorFeatures({
    super.key,
    required this.draft,
    required this.eventData,
  });

  @override
  State<HostEventScreen16OutdoorFeatures> createState() =>
      _HostEventScreen16OutdoorFeaturesState();
}

class _HostEventScreen16OutdoorFeaturesState extends State<HostEventScreen16OutdoorFeatures> {
  // (key, question) in the order shown in Figma.
  static const _questions = <(String, String)>[
    ('airConditioned', 'Does the venue have Air condition'),
    ('musicAllowedOutside', 'Is Music allowed outside'),
    ('tentAllowed', 'Can a tent or shamyana be erected'),
    ('outdoorLighting', 'Is there outdoor lighting for evening events'),
    ('outdoorSeatingSetup', 'Can Chairs And tables be setup outside'),
    ('outdoorCateringAllowed', 'Is Outdoor Catering permitted'),
    ('usableInRainySeason', 'Is the garden usable in rainy season or does it get waterlogged'),
    ('attachedGarden', 'Does the venue have attached outdoor garden or lawn area'),
  ];

  final Map<String, bool> _answers = {for (final q in _questions) q.$1: false};

  void _onContinue() async {
    final eventData = {
      ...widget.eventData,
      'outdoorFeatures': Map<String, bool>.from(_answers),
    };
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            HostEventScreen17UnitPricing(draft: widget.draft, eventData: eventData),
      ),
    );
    if (result is HostUpdatedPropertyDraft && mounted) Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    return HostFormPage(
      title: 'Venue features',
      onContinue: _onContinue,
      children: [
        for (var i = 0; i < _questions.length; i++)
          HostYesNo(
            question: _questions[i].$2,
            value: _answers[_questions[i].$1]!,
            onChanged: (v) => setState(() => _answers[_questions[i].$1] = v),
          ),
      ],
    );
  }
}


********************************************************************************
================================================================================
