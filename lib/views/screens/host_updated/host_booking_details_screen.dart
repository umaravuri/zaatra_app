import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/host_booking_model.dart';
import '../../../services/host_api_service.dart';
import 'host_bookings_list_screen.dart' show formatInr;
import 'host_cancel_booking_screen.dart';
import 'host_collect_payment_screen.dart';
import 'host_otp_confirm_screen.dart';
import 'widgets/host_components.dart';

const _purple = Color(0xFF5E42C2);
const _ink = Color(0xFF1E1E24);
const _grey = Color(0xFF757585);
const _border = Color(0xFFE5E4ED);

/// Figma: frame 1228744531 (node 1:4141)
class HostBookingDetailsScreen extends StatefulWidget {
  const HostBookingDetailsScreen({super.key, required this.bookingId});

  final String bookingId;

  @override
  State<HostBookingDetailsScreen> createState() => _HostBookingDetailsScreenState();
}

class _HostBookingDetailsScreenState extends State<HostBookingDetailsScreen> {
  bool _loading = true;
  String? _error;
  HostBooking? _booking;
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final res = await HostApiService.getBooking(widget.bookingId);
    if (!mounted) return;
    if (res['success'] == true && res['booking'] is Map) {
      _booking = HostBooking.fromMap(Map<String, dynamic>.from(res['booking'] as Map));
    } else {
      _error = '${res['message'] ?? 'Could not load booking'}';
    }
    setState(() => _loading = false);
  }

  /// Opens [screen], then reloads; remembers that something may have changed.
  Future<void> _open(Widget screen) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    _changed = true;
    if (mounted) _load();
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _close() => Navigator.pop(context, _changed);

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              HostTopBar(title: 'Booking Details', onBack: _close),
              Expanded(child: _body()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body() {
    if (_loading && _booking == null) {
      return const Center(child: CircularProgressIndicator(color: _purple));
    }
    final b = _booking;
    if (b == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _error ?? 'Could not load booking',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 14, color: _grey),
              ),
              const SizedBox(height: 12),
              OutlinedButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        _summaryCard(b),
        const SizedBox(height: 16),
        ..._buttons(b),
      ],
    );
  }

  String _money(double v) => '₹ ${formatInr(v)}';

  Widget _summaryCard(HostBooking b) {
    final advance = b.advance > 0
        ? '${_money(b.advance)}${b.advanceMethod.isEmpty ? '' : ' (${b.advanceMethod})'}'
        : '-';
    final rows = <List<String>>[
      [b.isEvent ? 'Event type' : 'Stay type', b.isEvent ? b.eventType : 'Stay'],
      ['Booking Date', b.bookingDate],
      ['Start Time', b.startText],
      ['End Time', b.endText],
      ['Guests', '${b.guests}'],
      ['Customer', b.customerName],
      ['Mobile No', b.mobile],
      ['Total Amount', _money(b.total)],
      ['Balance Amount', _money(b.due)],
      ['Advance', advance],
      ['Balance due on', b.balanceDueOn],
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            b.propertyName,
            style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: _ink),
          ),
          Text(
            'Confirm ID : ${b.confirmId}  |  ${b.unitName}',
            style: GoogleFonts.poppins(fontSize: 12, color: _grey),
          ),
          const Divider(height: 24, color: _border),
          for (final r in rows)
            if (r[1].isNotEmpty) _row(r[0], r[1]),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(label, style: GoogleFonts.poppins(fontSize: 13, color: _grey)),
          ),
          Expanded(
            flex: 6,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: _ink,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buttons(HostBooking b) {
    final upcoming = b.status == 'upcoming';
    final active = b.status == 'active';
    final items = <Widget>[];

    void add(String text, VoidCallback onTap, {bool secondary = false}) {
      if (items.isNotEmpty) items.add(const SizedBox(height: 12));
      items.add(HostBottomButton(text: text, onPressed: onTap, isSecondary: secondary));
    }

    if (upcoming && b.paid == 0) {
      add('Collect advance amount',
          () => _open(HostCollectPaymentScreen(bookingId: b.id, isAdvance: true)));
    }
    if (b.due > 0 && (upcoming || active)) {
      add('Collect Balance amount',
          () => _open(HostCollectPaymentScreen(bookingId: b.id, isAdvance: false)));
    }
    if ((upcoming || active) && !b.otp1Done) {
      add('Get OTP 1', () => _open(HostOtpConfirmScreen(bookingId: b.id, otpNumber: 1)));
    }
    if (active && b.otp1Done && !b.otp2Done) {
      add('Get OTP 2', () => _open(HostOtpConfirmScreen(bookingId: b.id, otpNumber: 2)));
    }
    if (b.isEvent) {
      add('Edit Event', () => _snack('Editing is not available yet'), secondary: true);
    }
    add('Get support', () => _snack('Support will contact you shortly'), secondary: true);
    if (upcoming || active) {
      add('Cancel booking', () => _open(HostCancelBookingScreen(bookingId: b.id)),
          secondary: true);
    }
    return items;
  }
}

