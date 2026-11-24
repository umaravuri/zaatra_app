import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../services/host_api_service.dart';
import 'widgets/host_form_widgets.dart';

const List<String> _reasons = [
  'No communication & cooperation from customer',
  'No advance payment by customer',
  'No respectful behaviour from customer',
  'No proper care from customer',
  'Not following rules & timing by customer',
  'Another reasons from customer',
  'Another reasons from us',
];

/// Figma: frame 1228744537 (node 1:4575)
class HostCancelBookingScreen extends StatefulWidget {
  const HostCancelBookingScreen({super.key, required this.bookingId});

  final String bookingId;

  @override
  State<HostCancelBookingScreen> createState() => _HostCancelBookingScreenState();
}

class _HostCancelBookingScreenState extends State<HostCancelBookingScreen> {
  final TextEditingController _problem = TextEditingController();
  bool _cancel = false;
  String _reason = '';
  bool _submitting = false;

  @override
  void dispose() {
    _problem.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (!_cancel) {
      Navigator.pop(context);
      return;
    }
    if (_reason.isEmpty) {
      showHostError(context, 'Please select a reason');
      return;
    }
    final text = _problem.text.trim();
    if (_reason.startsWith('Another reasons') && text.isEmpty) {
      showHostError(context, 'Please specify the problem');
      return;
    }
    setState(() => _submitting = true);
    final res = await HostApiService.cancelBooking(
      bookingId: widget.bookingId,
      reason: text.isEmpty ? _reason : '$_reason: $text',
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (res['success'] == true) {
      Navigator.pop(context, true);
    } else {
      showHostError(context, '${res['message'] ?? 'Could not cancel booking'}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return HostFormPage(
      title: 'Cancel booking',
      buttonText: 'Submit',
      onContinue: _submit,
      children: [
        HostYesNo(
          question: 'Do you want to cancel this booking?',
          value: _cancel,
          onChanged: (v) => setState(() => _cancel = v),
        ),
        if (_cancel) ...[
          HostSingleChoice(
            question: 'Specify reason',
            options: _reasons,
            selected: _reason,
            onChanged: (v) => setState(() => _reason = v),
          ),
          const HostQuestion('Specify if any problem you have'),
          HostTextField(controller: _problem, hint: 'Write here', maxLines: 4),
          const SizedBox(height: 16),
          Text(
            'The booking will move to the Cancelled tab.',
            style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF6E6E82)),
          ),
        ],
      ],
    );
  }
}

