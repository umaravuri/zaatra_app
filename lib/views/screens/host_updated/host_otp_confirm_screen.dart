import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../models/host_booking_model.dart';
import '../../../services/host_api_service.dart';
import 'host_payment_success_screen.dart';
import 'host_rate_customer_screen.dart';
import 'widgets/host_components.dart';
import 'widgets/host_form_widgets.dart';

const Color _kPurple = Color(0xFF5E42C2);
const Color _kInk = Color(0xFF1E1E24);
const Color _kMuted = Color(0xFF7C7C90);
const Color _kGreen = Color(0xFF2E9E5B);
const Color _kRed = Color(0xFFD64545);

enum _Stage { entry, wrong, success }

/// Figma: frame 1228744523 (node 1:3593)
/// Figma: frame Complete event (node 1:3629)
/// Figma: frame 1228744524 (node 1:3664)
/// Figma: frame 1228744525 (node 1:3699)
/// Figma: frame 1228744528 (node 1:3912)
/// Figma: frame 1228744529 (node 1:3931)
class HostOtpConfirmScreen extends StatefulWidget {
  const HostOtpConfirmScreen({super.key, required this.bookingId, required this.otpNumber});

  final String bookingId;
  final int otpNumber; // 1 = check-in, 2 = complete event/stay

  @override
  State<HostOtpConfirmScreen> createState() => _HostOtpConfirmScreenState();
}

class _HostOtpConfirmScreenState extends State<HostOtpConfirmScreen> {
  final _pinCtrl = TextEditingController();
  HostBooking? _booking;
  bool _loading = true;
  bool _busy = false;
  String _error = '';
  _Stage _stage = _Stage.entry;

  bool get _isComplete => widget.otpNumber == 2;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _pinCtrl.dispose();
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
      setState(() {
        _booking = HostBooking.fromMap(Map<String, dynamic>.from(res['booking'] as Map));
        _loading = false;
      });
    } else {
      setState(() {
        _loading = false;
        _error = '${res['message'] ?? 'Could not load the booking'}';
      });
    }
  }

  Future<void> _confirm() async {
    if (_busy) return;
    if (_pinCtrl.text.length != 4) {
      showHostError(context, 'Enter the 4-digit PIN');
      return;
    }
    setState(() => _busy = true);
    final res = await HostApiService.verifyBookingOtp(
      bookingId: widget.bookingId,
      otpNumber: widget.otpNumber,
      otp: _pinCtrl.text,
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _stage = res['success'] == true ? _Stage.success : _Stage.wrong;
    });
  }

  void _tryAgain() {
    _pinCtrl.clear();
    setState(() => _stage = _Stage.entry);
  }

  Future<void> _makeVacant() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mark as vacant?'),
        content: const Text('This will cancel the booking because the guest did not show up.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Yes')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    final res = await HostApiService.cancelBooking(
      bookingId: widget.bookingId,
      reason: 'No show - unit marked vacant',
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (res['success'] == true) {
      Navigator.pop(context, true);
    } else {
      showHostError(context, '${res['message'] ?? 'Could not mark the unit as vacant'}');
    }
  }

  Future<void> _callCustomer() async {
    final mobile = _booking?.mobile ?? '';
    if (mobile.isEmpty) {
      showHostError(context, 'Customer phone number is not available');
      return;
    }
    var launched = false;
    try {
      launched = await launchUrl(Uri(scheme: 'tel', path: mobile));
    } catch (_) {
      launched = false;
    }
    if (!launched && mounted) showHostError(context, 'Could not open the dialer');
  }

  @override
  Widget build(BuildContext context) {
    final b = _booking;
    if (_loading || b == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              HostTopBar(title: 'Confirm OTP', onBack: () => Navigator.pop(context)),
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
    switch (_stage) {
      case _Stage.entry:
        return _entry(b);
      case _Stage.wrong:
        return _resultPage(
          icon: Icons.cancel_rounded,
          color: _kRed,
          heading: 'Wrong Pin',
          subtext: 'Ask guest to open zaatra app - Booking - pin',
          buttons: [
            HostBottomButton(text: 'Try again', onPressed: _busy ? null : _tryAgain),
            const SizedBox(height: 12),
            HostBottomButton(
              text: 'Make as vacant',
              isSecondary: true,
              onPressed: _busy ? null : _makeVacant,
            ),
          ],
        );
      case _Stage.success:
        return _resultPage(
          icon: Icons.check_circle_rounded,
          color: _kGreen,
          heading: 'OTP Successfully Completed',
          buttons: [
            if (_isComplete) ...[
              HostBottomButton(
                text: 'Rate your Guest',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => HostRateCustomerScreen(bookingId: widget.bookingId),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            HostBottomButton(
              text: 'Done',
              isSecondary: _isComplete,
              onPressed: () => Navigator.pop(context, true),
            ),
          ],
        );
    }
  }

  Widget _entry(HostBooking b) {
    return HostFormPage(
      title: 'Confirm OTP',
      buttonText: _busy ? 'Please wait...' : 'Confirm OTP',
      onContinue: _confirm,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _kPurple.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Balance amount ₹ ${formatRupees(b.due)}',
                style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: _kInk),
              ),
              const SizedBox(height: 4),
              Text(
                'Booking ID : ${b.confirmId}',
                style: GoogleFonts.poppins(fontSize: 13, color: _kMuted),
              ),
              if (b.due <= 0) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, size: 16, color: _kGreen),
                    const SizedBox(width: 6),
                    Text(
                      'Paid successfully',
                      style: GoogleFonts.poppins(fontSize: 13, color: _kGreen),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        HostQuestion(_isComplete ? 'Enter the PIN to complete the event' : 'Enter the guest PIN'),
        TextField(
          controller: _pinCtrl,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 4,
          obscureText: true,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: GoogleFonts.poppins(
            fontSize: 26,
            fontWeight: FontWeight.w600,
            letterSpacing: 18,
            color: _kInk,
          ),
          decoration: InputDecoration(
            counterText: '',
            hintText: '- - - -',
            hintStyle: GoogleFonts.poppins(fontSize: 22, color: _kMuted, letterSpacing: 6),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _kPurple, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _callCustomer,
            icon: const Icon(Icons.call_rounded, color: _kPurple),
            label: Text('Call customer', style: GoogleFonts.poppins(color: _kPurple)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: _kPurple),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _resultPage({
    required IconData icon,
    required Color color,
    required String heading,
    String? subtext,
    required List<Widget> buttons,
  }) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            const HostBackgroundGraphic(),
            Column(
              children: [
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(icon, size: 80, color: color),
                          const SizedBox(height: 20),
                          Text(
                            heading,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: color,
                            ),
                          ),
                          if (subtext != null) ...[
                            const SizedBox(height: 10),
                            Text(
                              subtext,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(fontSize: 14, color: _kMuted),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(children: buttons),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

