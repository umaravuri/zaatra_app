import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../services/host_api_service.dart';
import 'widgets/host_components.dart';
import 'widgets/host_form_widgets.dart';

const Color _kPurple = Color(0xFF5E42C2);
const Color _kInk = Color(0xFF1E1E24);
const Color _kBorder = Color(0xFFE2E2EC);

// The availability API is per hall but slot timings are global; any hall works
// for reading the current times. Override via [HostSlotTimingsScreen.hall].
const String _kDefaultHall = 'Main Hall 1';

String _fmt(TimeOfDay t) {
  final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
  final m = t.minute.toString().padLeft(2, '0');
  return 'm ${t.period == DayPeriod.am ? 'AM' : 'PM'}';
}

TimeOfDay? _parse(String s) {
  final m = RegExp(r'^\s*(\d{1,2}):(\d{2})\s*(AM|PM)\s*$', caseSensitive: false).firstMatch(s);
  if (m == null) return null;
  var h = int.parse(m.group(1)!) % 12;
  if (m.group(3)!.toUpperCase() == 'PM') h += 12;
  return TimeOfDay(hour: h, minute: int.parse(m.group(2)!));
}

int _mins(TimeOfDay t) => t.hour * 60 + t.minute;

/// Figma: frame 1228744542 (node 1:5338)
class HostSlotTimingsScreen extends StatefulWidget {
  const HostSlotTimingsScreen({super.key, this.hall = _kDefaultHall});

  final String hall;

  @override
  State<HostSlotTimingsScreen> createState() => _HostSlotTimingsScreenState();
}

class _HostSlotTimingsScreenState extends State<HostSlotTimingsScreen> {
  bool _loading = true;
  bool _saving = false;
  String? _error;

  TimeOfDay? _s1Start, _s1End, _s2Start, _s2End;

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
    final now = DateTime.now();
    final res = await HostApiService.getAvailability(
      hall: widget.hall,
      year: now.year,
      month: now.month,
    );
    if (!mounted) return;
    final times = res['slotTimes'];
    if (res['success'] == true && times is Map) {
      final s1 = '${times['slot1']}'.split(RegExp(r'\s+-\s+'));
      final s2 = '${times['slot2']}'.split(RegExp(r'\s+-\s+'));
      setState(() {
        _loading = false;
        if (s1.length == 2) {
          _s1Start = _parse(s1[0]);
          _s1End = _parse(s1[1]);
        }
        if (s2.length == 2) {
          _s2Start = _parse(s2[0]);
          _s2End = _parse(s2[1]);
        }
      });
    } else {
      setState(() {
        _loading = false;
        _error = (res['message'] ?? 'Could not load timings').toString();
      });
    }
  }

  Future<void> _pick(TimeOfDay? current, ValueChanged<TimeOfDay> onPicked) async {
    final t = await showTimePicker(
      context: context,
      initialTime: current ?? const TimeOfDay(hour: 9, minute: 0),
    );
    if (t != null) setState(() => onPicked(t));
  }

  Future<void> _save() async {
    final a = _s1Start, b = _s1End, c = _s2Start, d = _s2End;
    if (a == null || b == null || c == null || d == null) {
      return showHostError(context, 'Select start and end time for both slots');
    }
    if (_mins(b) <= _mins(a)) return showHostError(context, '1st slot must end after it starts');
    if (_mins(d) <= _mins(c)) return showHostError(context, '2nd slot must end after it starts');
    if (_mins(c) <= _mins(b)) {
      return showHostError(context, '2nd slot must start after the 1st slot ends');
    }
    setState(() => _saving = true);
    final res = await HostApiService.setSlotTimings(
      slot1: '${_fmt(a)} - ${_fmt(b)}',
      slot2: '${_fmt(c)} - ${_fmt(d)}',
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (res['success'] != true) {
      showHostError(context, (res['message'] ?? 'Could not update timings').toString());
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Timings updated')));
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            HostTopBar(title: 'Change timings', onBack: () => Navigator.pop(context)),
            Expanded(child: _body()),
            if (!_loading && _error == null)
              Padding(
                padding: const EdgeInsets.all(20),
                child: HostBottomButton(
                  text: _saving ? 'Saving...' : 'Save Changes',
                  onPressed: _saving ? null : _save,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    if (_loading) return const Center(child: CircularProgressIndicator(color: _kPurple));
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: GoogleFonts.poppins(fontSize: 14)),
            TextButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const HostQuestion('1st slot', topSpace: 10),
          _row(_s1Start, _s1End, (t) => _s1Start = t, (t) => _s1End = t),
          const HostQuestion('2nd slot'),
          _row(_s2Start, _s2End, (t) => _s2Start = t, (t) => _s2End = t),
        ],
      ),
    );
  }

  Widget _row(
    TimeOfDay? start,
    TimeOfDay? end,
    ValueChanged<TimeOfDay> setStart,
    ValueChanged<TimeOfDay> setEnd,
  ) {
    return Row(
      children: [
        Expanded(child: _timeBox(start, () => _pick(start, setStart))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('to', style: GoogleFonts.poppins(fontSize: 14, color: _kInk)),
        ),
        Expanded(child: _timeBox(end, () => _pick(end, setEnd))),
      ],
    );
  }

  Widget _timeBox(TimeOfDay? t, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _kBorder),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                t == null ? 'Select' : _fmt(t),
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: t == null ? const Color(0xFFA0A0B2) : _kInk,
                ),
              ),
            ),
            const Icon(Icons.access_time_rounded, size: 18, color: Color(0xFF6E6E82)),
          ],
        ),
      ),
    );
  }
}


********************************************************************************
================================================================================
