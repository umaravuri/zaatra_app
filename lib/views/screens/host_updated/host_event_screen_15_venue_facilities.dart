import 'package:flutter/material.dart';
import '../../../models/host_updated_property_draft_model.dart';
import 'widgets/host_form_widgets.dart';
import 'host_event_screen_16_outdoor_features.dart';

/// garden size, kitchen, washrooms, parking, lift, generator.
/// Figma: frame 1228744521 (node 1:3093)
class HostEventScreen15VenueFacilities extends StatefulWidget {
  final HostUpdatedPropertyDraft draft;
  final Map<String, dynamic> eventData;

  const HostEventScreen15VenueFacilities({
    super.key,
    required this.draft,
    required this.eventData,
  });

  @override
  State<HostEventScreen15VenueFacilities> createState() =>
      _HostEventScreen15VenueFacilitiesState();
}

class _HostEventScreen15VenueFacilitiesState extends State<HostEventScreen15VenueFacilities> {
  final _gardenLength = TextEditingController();
  final _gardenWidth = TextEditingController();
  final _kitchenRestrictions = TextEditingController();
  final _carCapacity = TextEditingController();

  bool _hasKitchen = false;
  String _kitchenUser = '';
  final Set<String> _cookingFacilities = {};

  bool _hasWashrooms = true;
  bool _separateWashrooms = false;
  bool _accessibleWashrooms = false;
  bool _washroomsInside = true;

  String _parking = 'Yes, free';
  bool _parkingPaved = false;
  bool _bikeArea = false;
  bool _valet = false;

  bool _groundFloor = true;
  bool _hasLift = false;
  bool _hasGenerator = false;
  bool _stairsBackup = false;
  final Set<String> _generatorCovers = {};

  static const _kitchenUsers = [
    'In - house category only',
    'Approved outside caterings',
    'Any outside caterings',
    'Customer can use it',
  ];
  static const _cookingOptions = [
    'Gas',
    'Induction',
    'Refrigerator',
    'Freezer',
    'Sinks',
    'Exhaust / ventilation',
    'Cooking vessels',
    'None',
  ];
  static const _parkingOptions = ['Yes, free', 'Yes, paid', 'No'];
  static const _generatorOptions = ['AC', 'Lights', 'Music'];

  @override
  void dispose() {
    _gardenLength.dispose();
    _gardenWidth.dispose();
    _kitchenRestrictions.dispose();
    _carCapacity.dispose();
    super.dispose();
  }

  void _onContinue() async {
    if (_hasKitchen && _kitchenUser.isEmpty) {
      showHostError(context, 'Select who can use the kitchen');
      return;
    }
    if (_parking != 'No' && (int.tryParse(_carCapacity.text.trim()) ?? 0) < 1) {
      showHostError(context, 'Enter how many cars can park at one time');
      return;
    }

    final eventData = {
      ...widget.eventData,
      'gardenSize': {
        'length': _gardenLength.text.trim(),
        'width': _gardenWidth.text.trim(),
      },
      'kitchen': {
        'available': _hasKitchen,
        'whoCanUse': _hasKitchen ? _kitchenUser : '',
        'cookingFacilities': _hasKitchen ? _cookingFacilities.toList() : <String>[],
        'restrictions': _kitchenRestrictions.text.trim(),
      },
      'washrooms': {
        'available': _hasWashrooms,
        'separateMenWomen': _hasWashrooms && _separateWashrooms,
        'accessible': _hasWashrooms && _accessibleWashrooms,
        'insideVenue': _hasWashrooms && _washroomsInside,
      },
      'parking': {
        'availability': _parking,
        'carCapacity': _parking == 'No' ? 0 : int.tryParse(_carCapacity.text.trim()) ?? 0,
        'paved': _parking != 'No' && _parkingPaved,
        'bikeArea': _parking != 'No' && _bikeArea,
        'valet': _parking != 'No' && _valet,
      },
      'building': {
        'groundFloor': _groundFloor,
        'lift': _hasLift,
        'stairsBackupIfLiftFails': _hasLift && _stairsBackup,
      },
      'generator': {
        'available': _hasGenerator,
        'covers': _hasGenerator ? _generatorCovers.toList() : <String>[],
      },
    };

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            HostEventScreen16OutdoorFeatures(draft: widget.draft, eventData: eventData),
      ),
    );
    if (result is HostUpdatedPropertyDraft && mounted) Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    return HostFormPage(
      title: 'Venue facilities',
      onContinue: _onContinue,
      children: [
        const HostQuestion('Size of garden / lawn Area?', topSpace: 6),
        Row(
          children: [
            Expanded(child: HostTextField(controller: _gardenLength, hint: 'Length', numeric: true)),
            const SizedBox(width: 12),
            Expanded(child: HostTextField(controller: _gardenWidth, hint: 'Width', numeric: true)),
          ],
        ),

        HostYesNo(
          question: 'Does the venue have a kitchen facility?',
          value: _hasKitchen,
          onChanged: (v) => setState(() => _hasKitchen = v),
        ),
        if (_hasKitchen) ...[
          HostSingleChoice(
            question: 'Who can use kitchen?',
            options: _kitchenUsers,
            selected: _kitchenUser,
            onChanged: (v) => setState(() => _kitchenUser = v),
          ),
          HostMultiChoice(
            question: 'What cooking facilities provided?',
            options: _cookingOptions,
            selected: _cookingFacilities,
            onChanged: () => setState(() {}),
          ),
          const HostQuestion('Restrictions , specify', topSpace: 14),
          HostTextField(controller: _kitchenRestrictions, hint: 'Enter here', maxLines: 2),
        ],

        const HostQuestion('Toilet / washroom Facilities', topSpace: 28),
        HostYesNo(
          question: 'Does the venue have washroom facilities?',
          value: _hasWashrooms,
          onChanged: (v) => setState(() => _hasWashrooms = v),
        ),
        if (_hasWashrooms) ...[
          HostYesNo(
            question: 'Is separate men’s & women’s washrooms',
            value: _separateWashrooms,
            onChanged: (v) => setState(() => _separateWashrooms = v),
          ),
          HostYesNo(
            question: 'Accessible / Disbled washrooms?',
            value: _accessibleWashrooms,
            onChanged: (v) => setState(() => _accessibleWashrooms = v),
          ),
          HostYesNo(
            question: 'Washrooms located inside venue?',
            value: _washroomsInside,
            onChanged: (v) => setState(() => _washroomsInside = v),
          ),
        ],

        const HostQuestion('Parking', topSpace: 28),
        HostSingleChoice(
          question: 'Is parking available to guests?',
          options: _parkingOptions,
          selected: _parking,
          onChanged: (v) => setState(() => _parking = v),
        ),
        if (_parking != 'No') ...[
          const HostQuestion('How many cars can park at one time?'),
          Row(
            children: [
              Expanded(child: HostTextField(controller: _carCapacity, hint: '400', numeric: true)),
              const SizedBox(width: 12),
              const Text('Cars'),
            ],
          ),
          HostYesNo(
            question: 'Is the parking surface paved with cement concrete or tiles?',
            value: _parkingPaved,
            onChanged: (v) => setState(() => _parkingPaved = v),
          ),
          HostYesNo(
            question: 'Is there a separate area for bikes?',
            value: _bikeArea,
            onChanged: (v) => setState(() => _bikeArea = v),
          ),
          HostYesNo(
            question: 'Is valet parking available?',
            value: _valet,
            onChanged: (v) => setState(() => _valet = v),
          ),
        ],

        const HostQuestion('Lift', topSpace: 28),
        HostYesNo(
          question: 'Is the hall on ground floor?',
          value: _groundFloor,
          onChanged: (v) => setState(() => _groundFloor = v),
        ),
        HostYesNo(
          question: 'Is there a lift in this building?',
          value: _hasLift,
          onChanged: (v) => setState(() => _hasLift = v),
        ),
        if (_hasLift)
          HostYesNo(
            question: 'Is there a staircase as backup if lift fails during events?',
            value: _stairsBackup,
            onChanged: (v) => setState(() => _stairsBackup = v),
          ),

        const HostQuestion('Power backup', topSpace: 28),
        HostYesNo(
          question: 'Is Generator available?',
          value: _hasGenerator,
          onChanged: (v) => setState(() => _hasGenerator = v),
        ),
        if (_hasGenerator)
          HostMultiChoice(
            question: 'Does generator cover which facility?',
            options: _generatorOptions,
            selected: _generatorCovers,
            onChanged: () => setState(() {}),
          ),
      ],
    );
  }
}

********************************************************************************
================================================================================
