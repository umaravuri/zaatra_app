import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/utils/host_validators.dart';
import '../../../models/host_booking_model.dart';
import '../../../services/host_api_service.dart';
import 'host_payment_success_screen.dart';
import 'widgets/host_components.dart';
import 'widgets/host_form_widgets.dart';

const Color _kPurple = Color(0xFF5E42C2);
const Color _kInk = Color(0xFF1E1E24);
const Color _kMuted = Color(0xFF7C7C90);

/// Figma: frame 22/1 (node 1:4237, 1:4317)
class HostCollectPaymentScreen extends StatefulWidget {
  const HostCollectPaymentScreen({
    super.key,
    required this.bookingId,
    required this.isAdvance,
  });

  final String bookingId;
  final bool isAdvance;

  @override
  State<HostCollectPaymentScreen> createState() => _HostCollectPaymentScreenState();
}

class _HostCollectPaymentScreenState extends State<HostCollectPaymentScreen> {
  static const _payLater = 'Pay later';

  final _amountCtrl = TextEditingController();
  HostBooking? _booking;
  bool _loading = true;
  bool _submitting = false;
  String _error = '';
  String _method = '';

  List<String> get _methods => widget.isAdvance
      ? const ['UPI', 'Credit/debit card', 'Cash', 'Net Banking', _payLater]
      : const ['UPI', 'Credit/debit card', 'Cash'];

  double get _due {
    final b = _booking;
    if (b == null) return 0;
    if (b.due > 0) return b.due;
    final d = b.total - b.paid;
    return d > 0 ? d : 0;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = '';
    });
    final res = await HostApiService.getBooking(widget.bookingId);
    if (!mounted) return;
    if (res['success'] == true && res['booking'] is Map) {
      final b = HostBooking.fromMap(Map<String, dynamic>.from(res['booking'] as Map));
      setState(() {
        _booking = b;
        _loading = false;
        if (!widget.isAdvance) _amountCtrl.text = _due.round().toString();
      });
    } else {
      setState(() {
        _loading = false;
        _error = '${res['message'] ?? 'Could not load the booking'}';
      });
    }
  }

  Future<void> _continue() async {
    if (_submitting) return;
    if (_method.isEmpty) {
      showHostError(context, 'Select a payment method');
      return;
    }
    if (_method == _payLater) {
      Navigator.pop(context, false);
      return;
    }
    final err = HostValidators.amount(_amountCtrl.text);
    if (err != null) {
      showHostError(context, err);
      return;
    }
    final amount = double.parse(_amountCtrl.text.replaceAll(',', '').trim());
    if (amount > _due) {
      showHostError(context, 'Amount cannot exceed the due amount of ₹ ${formatRupees(_due)}');
      return;
    }
    setState(() => _submitting = true);
    final res = await HostApiService.collectPayment(
      bookingId: widget.bookingId,
      kind: widget.isAdvance ? 'advance' : 'balance',
      method: _method,
      amount: amount,
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (res['success'] != true) {
      showHostError(context, '${res['message'] ?? 'Payment failed. Please try again.'}');
      return;
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => HostPaymentSuccessScreen(
          bookingId: widget.bookingId,
          amount: amount,
          transactionId: '${res['transactionId'] ?? ''}',
          isAdvance: widget.isAdvance,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isAdvance ? 'Collect advance' : 'Collect Balance';
    final b = _booking;
    if (_loading || b == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              HostTopBar(title: title, onBack: () => Navigator.pop(context)),
              Expanded(
                child: Center(
                  child: _loading
                      ? const CircularProgressIndicator(color: _kPurple)
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_error, style: GoogleFonts.poppins(color: _kInk)),
                            TextButton(onPressed: _load, child: const Text('Retry')),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return HostFormPage(
      title: title,
      buttonText: _submitting ? 'Please wait...' : 'Continue',
      onContinue: _continue,
      children: [
        if (!widget.isAdvance) ...[
          _row('Total amount', '₹ ${formatRupees(b.total)}', bold: true),
          const SizedBox(height: 16),
          _balanceInfo(b),
        ],
        HostQuestion(widget.isAdvance ? 'Advance amount' : 'Amount to collect', topSpace: 16),
        HostTextField(controller: _amountCtrl, hint: 'Enter amount', numeric: true),
        HostSingleChoice(
          question: 'Select Payment Method',
          options: _methods,
          selected: _method,
          onChanged: (v) => setState(() => _method = v),
        ),
      ],
    );
  }

  Widget _balanceInfo(HostBooking b) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kPurple.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kPurple.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Balance amount Info',
            style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: _kPurple),
          ),
          const SizedBox(height: 10),
          _row('Total Amount', '₹ ${formatRupees(b.total)}'),
          _row('Advance Amount', '₹ ${formatRupees(b.advance)}'),
          _row('Balance due Amount', '₹ ${formatRupees(_due)}', bold: true),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool bold = false}) {
    final weight = bold ? FontWeight.w600 : FontWeight.w400;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.poppins(fontSize: 14, color: _kMuted, fontWeight: weight)),
          Text(value, style: GoogleFonts.poppins(fontSize: 14, color: _kInk, fontWeight: weight)),
        ],
      ),
    );
  }
}


********************************************************************************
================================================================================
