import 'package:flutter/material.dart';
import '../../../models/host_updated_property_draft_model.dart';
import 'widgets/host_form_widgets.dart';

/// non-refundable plan, payment and refund policy, property
/// rules and safety & security. This is the last event step: it saves the unit.
/// Figma: frame 1228744530 (node 1:3991)
class HostEventScreen20PaymentRefundPolicy extends StatefulWidget {
  final HostUpdatedPropertyDraft draft;
  final Map<String, dynamic> eventData;

  const HostEventScreen20PaymentRefundPolicy({
    super.key,
    required this.draft,
    required this.eventData,
  });

  @override
  State<HostEventScreen20PaymentRefundPolicy> createState() =>
      _HostEventScreen20PaymentRefundPolicyState();
}

class _HostEventScreen20PaymentRefundPolicyState
    extends State<HostEventScreen20PaymentRefundPolicy> {
  static const _refundOptions = [
    'Advance amount can be refunded with cancellation fee',
    'Advance amount cannot be refundable',
  ];

  final _nonRefundableConditions = TextEditingController();
  final _paymentRefundConditions = TextEditingController();
  final _propertyRules = TextEditingController();
  final _safetySecurity = TextEditingController();

  String _refund = '';

  @override
  void dispose() {
    _nonRefundableConditions.dispose();
    _paymentRefundConditions.dispose();
    _propertyRules.dispose();
    _safetySecurity.dispose();
    super.dispose();
  }

  void _onSaveUnit() {
    if (_refund.isEmpty) {
      return showHostError(context, 'Select a refund option for the non-refundable rate plan');
    }

    // Everything collected across the event steps becomes one unit.
    final eventUnit = <String, dynamic>{
      'unitId': 'unit_${DateTime.now().millisecondsSinceEpoch}',
      'purpose': 'Events Booking',
      ...widget.eventData,
      'nonRefundablePlan': {
        'option': _refund,
        'conditions': _nonRefundableConditions.text.trim(),
      },
      'paymentRefundConditions': _paymentRefundConditions.text.trim(),
      'propertyRules': _propertyRules.text.trim(),
      'safetySecurity': _safetySecurity.text.trim(),
    };

    final updatedUnits = List<Map<String, dynamic>>.from(widget.draft.units)..add(eventUnit);
    final updatedDraft = widget.draft.copyWith(units: updatedUnits);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Event unit added successfully!'),
        backgroundColor: Color(0xFF2E7D32),
      ),
    );
    Navigator.pop(context, updatedDraft);
  }

  @override
  Widget build(BuildContext context) {
    return HostFormPage(
      title: 'Policies',
      buttonText: 'Save Event Unit',
      onContinue: _onSaveUnit,
      children: [
        HostSingleChoice(
          question: 'Non - refundable rate plan',
          options: _refundOptions,
          selected: _refund,
          onChanged: (v) => setState(() => _refund = v),
        ),
        const SizedBox(height: 8),
        HostTextField(
          controller: _nonRefundableConditions,
          hint: 'Specify any conditions',
          maxLines: 2,
        ),
        const HostQuestion('Payment and refund policy', topSpace: 28),
        HostTextField(
          controller: _paymentRefundConditions,
          hint: 'Specify any conditions',
          maxLines: 3,
        ),
        const HostQuestion('Property rules', topSpace: 28),
        HostTextField(controller: _propertyRules, hint: 'Enter property rules', maxLines: 3),
        const HostQuestion('Safety & security', topSpace: 28),
        HostTextField(
          controller: _safetySecurity,
          hint: 'Specify Safety & security conditions',
          maxLines: 3,
        ),
      ],
    );
  }
}

