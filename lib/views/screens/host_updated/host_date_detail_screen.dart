import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../services/host_api_service.dart';
import 'host_block_dates_screen.dart';
import 'host_book_offline_screen.dart';
import 'host_slot_timings_screen.dart';
import 'widgets/host_components.dart';
import 'widgets/host_form_widgets.dart';

const _purple = Color(0xFF5E42C2);
const _ink = Color(0xFF1E1E24);
const _grey = Color(0xFF757585);
const _border = Color(0xFFE5E4ED);

const _months = [
  'January', 'February', 'March', 'April', 'May', 'June', 'July',
  'August', 'September', 'October', 'November', 'December',
];
const _weekdays = [
  'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
];

String _ordinal(int d) {
  if (d >= 11 && d <= 13) return '${d}th';
  switch (d % 10) {
    case 1:
      return '${d}st';
    case 2:
      return '${d}nd';
    case 3:
      return '${d}rd';
    default:
      return '${d}th';
  }
}

String _dateKey(DateTime d) =>
    "${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";

/// Indian digit grouping, e.g. 145000 -> 1,45,000.
String _inr(num v) {
  final s = v.round().abs().toString();
  if (s.length <= 3) return s;
  var head = s.substring(0, s.length - 3);
  final tail = s.substring(s.length - 3);
  final parts = <String>[];
  while (head.length > 2) {
    parts.insert(0, head.substring(head.length - 2));
    head = head.substring(0, head.length - 2);
  }
  if (head.isNotEmpty) parts.insert(0, head);
  return '${parts.join(',')},$tail';
}

/// Figma: frame 1228744547 (node 1:5517)
class HostDateDetailScreen extends StatefulWidget {
  const HostDateDetailScreen({super.key, required this.hall, required this.date});

  final String hall;
  final DateTime date;

  @override
  State<HostDateDetailScreen> createState() => _HostDateDetailScreenState();
}

class _HostDateDetailScreenState extends State<HostDateDetailScreen> {
  bool _loading = true;
  bool _changed = false;
  String? _error;
  Map<String, dynamic> _day = {};
  Map<String, dynamic> _slotTimes = {};

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
    final res = await HostApiService.getAvailability(
      hall: widget.hall,
      year: widget.date.year,
      month: widget.date.month,
    );
    if (!mounted) return;
    if (res['success'] == true) {
      final days = Map<String, dynamic>.from(res['days'] ?? {});
      setState(() {
        _day = Map<String, dynamic>.from(days[_dateKey(widget.date)] ?? {});
        _slotTimes = Map<String, dynamic>.from(res['slotTimes'] ?? {});
        _loading = false;
      });
    } else {
      setState(() {
        _error = (res['message'] ?? 'Could not load availability').toString();
        _loading = false;
      });
    }
  }

  void _close() => Navigator.pop(context, _changed);

  Future<void> _push(Widget screen) async {
    final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    if (!mounted) return;
    if (result == true) _changed = true;
    _load();
  }

  Future<void> _unblock(int slot) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Unblock slot?', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Text('This slot will be available for booking again.',
            style: GoogleFonts.poppins(fontSize: 14)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Unblock')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final res = await HostApiService.unblockDates(
      hall: widget.hall,
      dates: [_dateKey(widget.date)],
      slots: [slot],
    );
    if (!mounted) return;
    if (res['success'] == true) {
      _changed = true;
      _load();
    } else {
      showHostError(context, (res['message'] ?? 'Could not unblock').toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.date;
    final heading =
        '${_months[d.month - 1]} ${_ordinal(d.day)} ${d.year} , ${_weekdays[d.weekday - 1]}';
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
              HostTopBar(title: widget.hall, onBack: _close),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator(color: _purple))
                    : _error != null
                        ? _errorView()
                        : RefreshIndicator(
                            color: _purple,
                            onRefresh: _load,
                            child: ListView(
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                              children: [
                                Text(heading,
                                    style: GoogleFonts.poppins(
                                        fontSize: 16, fontWeight: FontWeight.w600, color: _ink)),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: HostBottomButton(
                                        text: 'Book Offline',
                                        onPressed: () =>
                                            _push(HostBookOfflineScreen(isEvent: true, initialDate: widget.date)),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: HostBottomButton(
                                        text: 'Change Timings',
                                        isSecondary: true,
                                        onPressed: () => _push(const HostSlotTimingsScreen()),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                _slotCard(1),
                                const SizedBox(height: 12),
                                _slotCard(2),
                              ],
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _errorView() => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center, style: GoogleFonts.poppins(color: _grey)),
              const SizedBox(height: 12),
              TextButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );

  Widget _slotCard(int slot) {
    final data = Map<String, dynamic>.from(_day['slot$slot'] ?? {'state': 'available'});
    final state = (data['state'] ?? 'available').toString();
    final time = (_slotTimes['slot$slot'] ?? '').toString();

    late final String label;
    late final Color color;
    switch (state) {
      case 'zaatra':
        label = 'ZAATRA Booked';
        color = _purple;
        break;
      case 'offline':
        label = 'Offline booked';
        color = const Color(0xFFE08A00);
        break;
      case 'blocked':
        final reason = (data['reason'] ?? '').toString();
        label = reason.isEmpty ? 'Blocked' : 'Blocked : $reason';
        color = const Color(0xFFD64545);
        break;
      default:
        label = 'Available';
        color = const Color(0xFF2E9E5B);
    }

    final children = <Widget>[
      Row(
        children: [
          Expanded(
            child: Text(slot == 1 ? '1st Slot' : '2nd Slot',
                style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: _ink)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(label,
                style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: color)),
          ),
        ],
      ),
      if (time.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(time, style: GoogleFonts.poppins(fontSize: 13, color: _grey)),
        ),
    ];

    if (state == 'zaatra' && data['booking'] is Map) {
      final b = Map<String, dynamic>.from(data['booking']);
      children.add(const SizedBox(height: 12));
      children.addAll([
        _row('Customer', b['customer']),
        _row('Event', b['event']),
        _row('Veg Plate', b['vegPlates']),
        _row('Non Veg Plate', b['nonVegPlates']),
        _row('AC Rooms', b['acRooms']),
        _row('Deluxe Rooms', b['deluxeRooms']),
        const SizedBox(height: 8),
        Text(
          'Total : ₹${_inr((b['total'] as num?) ?? 0)} + ₹${_inr((b['taxes'] as num?) ?? 0)} taxes and charges',
          style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: _ink),
        ),
      ]);
    }

    if (state == 'available' || state == 'blocked') {
      children.add(const SizedBox(height: 12));
      children.add(
        state == 'blocked'
            ? HostBottomButton(text: 'Unblock', isSecondary: true, onPressed: () => _unblock(slot))
            : HostBottomButton(
                text: 'Block Slot',
                isSecondary: true,
                onPressed: () =>
                    _push(HostBlockDatesScreen(hall: widget.hall, initialDate: widget.date)),
              ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  Widget _row(String label, dynamic value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 120,
              child: Text(label, style: GoogleFonts.poppins(fontSize: 13, color: _grey)),
            ),
            Expanded(
              child: Text('${value ?? '-'}',
                  style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: _ink)),
            ),
          ],
        ),
      );
}

