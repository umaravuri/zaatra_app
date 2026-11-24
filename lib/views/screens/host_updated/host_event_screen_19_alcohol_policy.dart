import 'package:flutter/material.dart';
import '../../../models/host_updated_property_draft_model.dart';
import 'widgets/host_form_widgets.dart';
import 'host_event_screen_20_payment_refund_policy.dart';

/// liquor / alcohol policy and cancellation policy.
/// Figma: frame 1228744527 (node 1:3829)
class HostEventScreen19AlcoholPolicy extends StatefulWidget {
  final HostUpdatedPropertyDraft draft;
  final Map<String, dynamic> eventData;

  const HostEventScreen19AlcoholPolicy({
    super.key,
    required this.draft,
    required this.eventData,
  });

  @override
  State<HostEventScreen19AlcoholPolicy> createState() => _HostEventScreen19AlcoholPolicyState();
}

class _HostEventScreen19AlcoholPolicyState extends State<HostEventScreen19AlcoholPolicy> {
  static const _permitOptions = ['Not Permitted', 'Permitted only with prior approval'];
  static const _arrangeOptions = ['Venue only', 'Licensed vendor only', 'Customer can arrange'];
  static const _locations = [
    'Designated bar area',
    'Dining Area',
    'Indoor event area',
    'Outdoor event area',
    'Lawn',
    'Pool side',
    'Private rooms',
    'Other designated area',
  ];
  static const _cancellationOptions = [
    'No cancellation by guests',
    'Guests who cancel within 24 hours will have their cancellation fee waived.',
  ];

  final _alcoholConditions = TextEditingController();
  final _cancellationConditions = TextEditingController();

  String _permit = _permitOptions.first;
  String _arrange = '';
  final Set<String> _consumeAt = {};
  String _cancellation = '';

  bool get _permitted => _permit != _permitOptions.first;

  @override
  void dispose() {
    _alcoholConditions.dispose();
    _cancellationConditions.dispose();
    super.dispose();
  }

  void _onContinue() async {
    if (_permitted && _arrange.isEmpty) {
      return showHostError(context, 'Select who can arrange alcohol');
    }
    if (_permitted && _consumeAt.isEmpty) {
      return showHostError(context, 'Select where alcohol can be consumed');
    }
    if (_cancellation.isEmpty) {
      return showHostError(context, 'Select a cancellation policy');
    }

    final eventData = {
      ...widget.eventData,
      'alcoholPolicy': {
        'permitted': _permit,
        'whoCanArrange': _permitted ? _arrange : '',
        'consumedAt': _permitted ? _consumeAt.toList() : <String>[],
        'conditions': _alcoholConditions.text.trim(),
      },
      'cancellationPolicy': {
        'option': _cancellation,
        'conditions': _cancellationConditions.text.trim(),
      },
    };

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            HostEventScreen20PaymentRefundPolicy(draft: widget.draft, eventData: eventData),
      ),
    );
    if (result is HostUpdatedPropertyDraft && mounted) Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    return HostFormPage(
      title: 'Liquor / Alcohol Policy',
      onContinue: _onContinue,
      children: [
        HostTextField(
          controller: _alcoholConditions,
          hint: 'Please specify conditions',
          maxLines: 2,
        ),
        HostSingleChoice(
          question: 'Is Alcohol permitted?',
          options: _permitOptions,
          selected: _permit,
          onChanged: (v) => setState(() => _permit = v),
        ),
        if (_permitted) ...[
          HostSingleChoice(
            question: 'Who can arrange alcohol?',
            options: _arrangeOptions,
            selected: _arrange,
            onChanged: (v) => setState(() => _arrange = v),
          ),
          HostMultiChoice(
            question: 'Where can alcohol be consumed?',
            options: _locations,
            selected: _consumeAt,
            onChanged: () => setState(() {}),
          ),
        ],
        HostSingleChoice(
          question: 'Cancellation policy',
          options: _cancellationOptions,
          selected: _cancellation,
          onChanged: (v) => setState(() => _cancellation = v),
        ),
        const SizedBox(height: 8),
        HostTextField(
          controller: _cancellationConditions,
          hint: 'Specify conditions',
          maxLines: 2,
        ),
      ],
    );
  }
}


********************************************************************************
================================================================================
