import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../services/host_api_service.dart';
import 'widgets/host_components.dart';
import 'widgets/host_form_widgets.dart';

const Color _kPurple = Color(0xFF5E42C2);
const Color _kInk = Color(0xFF1E1E24);
const Color _kBorder = Color(0xFFE5E4ED);
const Color _kMuted = Color(0xFFA0A0B2);

const List<String> _kMonths = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];
const List<String> _kWeekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
const List<String> _kReasons = ['Maintenance', 'Personal', 'Festive', 'Other'];

String _iso(DateTime d) =>
    '{d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// 'April 17 & 23', 'April 17, 23 & 25'. Spans months when needed.
String _summary(List<DateTime> dates) {
  if (dates.isEmpty) return '';
  final sorted = [...dates]..sort();
  final parts = <String>[];
  for (var i = 0; i < sorted.length; i++) {
    final d = sorted[i];
    final newMonth = i == 0 || sorted[i - 1].month != d.month;
    parts.add(newMonth ? '${_kMonths[d.month - 1]} {d.day}');
  }
  if (parts.length == 1) return parts.first;
  return '${parts.sublist(0, parts.length - 1).join(', ')} & ${parts.last}';
}

/// Figma: frame 1228744544 (node 1:5391)
/// Figma: frame 1228744546 (node 1:5431)
class HostBlockDatesScreen extends StatefulWidget {
  const HostBlockDatesScreen({super.key, required this.hall, required this.initialDate});

  final String hall;
  final DateTime initialDate;

  @override
  State<HostBlockDatesScreen> createState() => _HostBlockDatesScreenState();
}

class _HostBlockDatesScreenState extends State<HostBlockDatesScreen> {
  late DateTime _month;
  final Set<DateTime> _selected = {};
  Map<String, dynamic> _days = {};
  bool _loading = true;
  String? _loadError;
  bool _saving = false;

  bool _slot1 = false;
  bool _slot2 = false;
  String _reason = '';
  final _otherCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final i = widget.initialDate;
    _month = DateTime(i.year, i.month);
    _selected.add(DateTime(i.year, i.month, i.day));
    _load();
  }

  @override
  void dispose() {
    _otherCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    final res = await HostApiService.getAvailability(
      hall: widget.hall,
      year: _month.year,
      month: _month.month,
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res['success'] == true && res['days'] is Map) {
        _days = Map<String, dynamic>.from(res['days'] as Map);
      } else {
        _days = {};
        _loadError = (res['message'] ?? 'Could not load availability').toString();
      }
    });
  }

  void _changeMonth(int delta) {
    setState(() => _month = DateTime(_month.year, _month.month + delta));
    _load();
  }

  /// A day is unavailable when any of its slots is already booked.
  bool _isBooked(DateTime d) {
    final day = _days[_iso(d)];
    if (day is! Map) return false;
    for (final s in ['slot1', 'slot2']) {
      final st = day[s] is Map ? (day[s] as Map)['state'] : null;
      if (st == 'zaatra' || st == 'offline') return true;
    }
    return false;
  }

  bool _isBlocked(DateTime d) {
    final day = _days[_iso(d)];
    if (day is! Map) return false;
    return ['slot1', 'slot2'].every(
      (s) => day[s] is Map && (day[s] as Map)['state'] == 'blocked',
    );
  }

  bool _isPast(DateTime d) {
    final now = DateTime.now();
    return d.isBefore(DateTime(now.year, now.month, now.day));
  }

  Future<void> _submit() async {
    final reason = _reason == 'Other' ? _otherCtrl.text.trim() : _reason;
    if (_selected.isEmpty) return showHostError(context, 'Select at least one date');
    if (!_slot1 && !_slot2) return showHostError(context, 'Select at least one slot to block');
    if (reason.isEmpty) {
      return showHostError(
        context,
        _reason == 'Other' ? 'Please enter a reason' : 'Select a reason for blocking',
      );
    }
    final dates = _selected.toList()..sort();
    setState(() => _saving = true);
    final res = await HostApiService.blockDates(
      hall: widget.hall,
      dates: dates.map(_iso).toList(),
      slots: [if (_slot1) 1, if (_slot2) 2],
      reason: reason,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (res['success'] != true) {
      showHostError(context, (res['message'] ?? 'Could not block dates').toString());
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => _BlockedResultPage(summary: _summary(dates))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dates = _selected.toList()..sort();
    final label = dates.isEmpty ? 'Block dates' : 'Block ${_summary(dates)}';
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            HostTopBar(title: 'Block slot / date', onBack: () => Navigator.pop(context)),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Choose multiple dates and slots',
                      style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF6E6E82)),
                    ),
                    const SizedBox(height: 12),
                    _buildCalendar(),
                    const HostQuestion('Slots to block'),
                    HostCheckRow(
                      title: 'Block 1st slot',
                      checked: _slot1,
                      onTap: () => setState(() => _slot1 = !_slot1),
                    ),
                    HostCheckRow(
                      title: 'Block 2nd slot',
                      checked: _slot2,
                      onTap: () => setState(() => _slot2 = !_slot2),
                    ),
                    const HostQuestion('Reasons for blocking'),
                    for (final r in _kReasons)
                      HostRadioRow(
                        title: r,
                        selected: _reason == r,
                        onTap: () => setState(() => _reason = r),
                      ),
                    if (_reason == 'Other') ...[
                      const SizedBox(height: 10),
                      HostTextField(controller: _otherCtrl, hint: 'Enter reason'),
                    ],
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: HostBottomButton(
                text: _saving ? 'Blocking...' : label,
                onPressed: _saving ? null : _submit,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendar() {
    final first = DateTime(_month.year, _month.month, 1);
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final lead = first.weekday % 7; // Sunday first
    final cells = <Widget>[
      for (var i = 0; i < lead; i++) const SizedBox.shrink(),
      for (var d = 1; d <= daysInMonth; d++) _dayCell(DateTime(_month.year, _month.month, d)),
    ];
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => _changeMonth(-1),
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    '${_kMonths[_month.month - 1]} ${_month.year}',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _kInk,
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _changeMonth(1),
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
          Row(
            children: [
              for (final w in _kWeekdays)
                Expanded(
                  child: Center(
                    child: Text(w, style: GoogleFonts.poppins(fontSize: 11, color: _kMuted)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: CircularProgressIndicator(color: _kPurple),
            )
          else if (_loadError != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                children: [
                  Text(_loadError!, textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 13)),
                  TextButton(onPressed: _load, child: const Text('Retry')),
                ],
              ),
            )
          else
            GridView.count(
              crossAxisCount: 7,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
              children: cells,
            ),
        ],
      ),
    );
  }

  Widget _dayCell(DateTime d) {
    final booked = _isBooked(d);
    final disabled = booked || _isBlocked(d) || _isPast(d);
    final selected = _selected.contains(d);
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: disabled
          ? (booked ? () => showHostError(context, 'This date already has a booking') : null)
          : () => setState(() {
                if (!_selected.remove(d)) _selected.add(d);
              }),
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? _kPurple
              : booked
                  ? const Color(0xFFFDECEC)
                  : disabled
                      ? const Color(0xFFF5F5F7)
                      : null,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          '${d.day}',
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected
                ? Colors.white
                : booked
                    ? Colors.redAccent
                    : disabled
                        ? _kMuted
                        : _kInk,
            decoration: booked ? TextDecoration.lineThrough : null,
          ),
        ),
      ),
    );
  }
}

class _BlockedResultPage extends StatelessWidget {
  const _BlockedResultPage({required this.summary});

  final String summary;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).pop(true);
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 84,
                        height: 84,
                        decoration: BoxDecoration(
                          color: const Color(0xFF22A06B).withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check_rounded, size: 48, color: Color(0xFF22A06B)),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        '$summary are blocked',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: _kInk,
                        ),
                      ),
                    ],
                  ),
                ),
                HostBottomButton(text: 'Done', onPressed: () => Navigator.of(context).pop(true)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


********************************************************************************
================================================================================
