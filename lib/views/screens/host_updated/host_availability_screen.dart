import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../services/host_api_service.dart';
import 'host_date_detail_screen.dart';
import 'host_venue_rates_view.dart';

const _purple = Color(0xFF5E42C2);
const _ink = Color(0xFF1E1E24);
const _grey = Color(0xFF757585);
const _border = Color(0xFFE5E4ED);

const _booked = Color(0xFF5E42C2);
const _offline = Color(0xFFE08A00);
const _blocked = Color(0xFFD64545);
const _available = Color(0xFF2E9E5B);

const _months = [
  'January', 'February', 'March', 'April', 'May', 'June', 'July',
  'August', 'September', 'October', 'November', 'December',
];
const _dow = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

String _dateKey(int y, int m, int d) =>
    "${m.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}";

/// Figma: frame 1228744550 (node 1:5741)
class HostAvailabilityRatesScreen extends StatefulWidget {
  const HostAvailabilityRatesScreen({super.key});

  @override
  State<HostAvailabilityRatesScreen> createState() => _HostAvailabilityRatesScreenState();
}

class _HostAvailabilityRatesScreenState extends State<HostAvailabilityRatesScreen> {
  bool _showRates = false;
  bool _loading = true;
  String? _error;
  List<String> _halls = [];
  String? _hall;
  late DateTime _month;
  Map<String, dynamic> _days = {};
  Map<String, dynamic> _summary = {};

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final res = await HostApiService.getAvailability(
      hall: _hall ?? '',
      year: _month.year,
      month: _month.month,
    );
    if (!mounted) return;
    if (res['success'] == true) {
      final halls = List<String>.from((res['halls'] as List?) ?? const []);
      setState(() {
        _halls = halls;
        _hall ??= halls.isNotEmpty ? halls.first : (res['hall'] ?? '').toString();
        _days = Map<String, dynamic>.from(res['days'] ?? {});
        _summary = Map<String, dynamic>.from(res['summary'] ?? {});
        _loading = false;
      });
    } else {
      setState(() {
        _error = (res['message'] ?? 'Could not load availability').toString();
        _loading = false;
      });
    }
  }

  void _shiftMonth(int delta) {
    setState(() => _month = DateTime(_month.year, _month.month + delta));
    _load();
  }

  void _selectHall(String h) {
    if (h == _hall) return;
    setState(() => _hall = h);
    _load();
  }

  Future<void> _openDay(int day) async {
    final hall = _hall;
    if (hall == null) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            HostDateDetailScreen(hall: hall, date: DateTime(_month.year, _month.month, day)),
      ),
    );
    if (mounted) _load();
  }

  String _slotState(int day, String slot) {
    final d = _days[_dateKey(_month.year, _month.month, day)];
    if (d is Map && d[slot] is Map) return (d[slot]['state'] ?? 'available').toString();
    return 'available';
  }

  /// booked | offline | blocked | available
  String _dayState(int day) {
    final states = [_slotState(day, 'slot1'), _slotState(day, 'slot2')];
    if (states.contains('zaatra')) return 'booked';
    if (states.contains('offline')) return 'offline';
    if (states.every((s) => s == 'blocked')) return 'blocked';
    return 'available';
  }

  Color _slotColor(int day, String slot) {
    switch (_slotState(day, slot)) {
      case 'zaatra':
        return _booked;
      case 'offline':
        return _offline;
      case 'blocked':
        return _blocked;
      default:
        return _available;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Text('Availability & Rates',
                style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600, color: _ink)),
          ),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: _switch()),
          const SizedBox(height: 12),
          Expanded(child: _showRates ? const HostVenueRatesView() : _calendarTab()),
        ],
      ),
    );
  }

  Widget _switch() {
    Widget option(String text, bool rates) {
      final selected = _showRates == rates;
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _showRates = rates),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: selected ? _purple : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(text,
                style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: selected ? Colors.white : _grey)),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F7),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(children: [option('Availability Calendar', false), option('Venue Rates', true)]),
    );
  }

  Widget _calendarTab() {
    if (_loading && _hall == null) {
      return const Center(child: CircularProgressIndicator(color: _purple));
    }
    if (_error != null && _hall == null) return _errorView();
    return RefreshIndicator(
      color: _purple,
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _halls.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final h = _halls[i];
                final sel = h == _hall;
                return ChoiceChip(
                  label: Text(h),
                  selected: sel,
                  showCheckmark: false,
                  selectedColor: _purple,
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: _border),
                  labelStyle: GoogleFonts.poppins(
                      fontSize: 13, color: sel ? Colors.white : _ink, fontWeight: FontWeight.w500),
                  onSelected: (_) => _selectHall(h),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          _monthHeader(),
          const SizedBox(height: 8),
          if (_error != null) _errorView() else _grid(),
          const SizedBox(height: 16),
          _legend(),
        ],
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

  Widget _monthHeader() => Row(
        children: [
          IconButton(
            onPressed: _loading ? null : () => _shiftMonth(-1),
            icon: const Icon(Icons.chevron_left_rounded, color: _ink),
          ),
          Expanded(
            child: Center(
              child: Text('${_months[_month.month - 1]} ${_month.year}',
                  style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: _ink)),
            ),
          ),
          IconButton(
            onPressed: _loading ? null : () => _shiftMonth(1),
            icon: const Icon(Icons.chevron_right_rounded, color: _ink),
          ),
        ],
      );

  Widget _grid() {
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final lead = DateTime(_month.year, _month.month, 1).weekday % 7; // Sunday = 0
    final cells = <Widget>[
      for (final w in _dow)
        Center(child: Text(w, style: GoogleFonts.poppins(fontSize: 12, color: _grey))),
      for (var i = 0; i < lead; i++) const SizedBox.shrink(),
      for (var d = 1; d <= daysInMonth; d++) _dayCell(d),
    ];
    return Stack(
      children: [
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
          childAspectRatio: 0.85,
          children: cells,
        ),
        if (_loading)
          Positioned.fill(
            child: Container(
              color: Colors.white.withValues(alpha: 0.6),
              child: const Center(child: CircularProgressIndicator(color: _purple)),
            ),
          ),
      ],
    );
  }

  Widget _dayCell(int day) {
    final state = _dayState(day);
    late final Color color;
    switch (state) {
      case 'booked':
        color = _booked;
        break;
      case 'offline':
        color = _offline;
        break;
      case 'blocked':
        color = _blocked;
        break;
      default:
        color = _available;
    }
    final filled = state != 'available';
    return InkWell(
      onTap: () => _openDay(day),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: filled ? 0.14 : 0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: filled ? 0.6 : 0.25)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('$day',
                style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: _ink)),
            const SizedBox(height: 3),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _dot(_slotColor(day, 'slot1')),
                const SizedBox(width: 3),
                _dot(_slotColor(day, 'slot2')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _dot(Color c) => Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(color: c, shape: BoxShape.circle),
      );

  Widget _legend() {
    String line(String key) {
      final s = _summary[key];
      final days = (s is Map ? s['days'] : null) ?? 0;
      final slots = (s is Map ? s['slots'] : null) ?? 0;
      return '$days Days / $slots slots';
    }

    Widget item(String label, String key, Color c) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: c.withValues(alpha: 0.2),
                  border: Border.all(color: c),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(label, style: GoogleFonts.poppins(fontSize: 13, color: _ink)),
              ),
              Text(line(key),
                  style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: _ink)),
            ],
          ),
        );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          item('ZAATRA Booked', 'zaatra', _booked),
          item('Offline', 'offline', _offline),
          item('Blocked', 'blocked', _blocked),
          item('Available', 'available', _available),
        ],
      ),
    );
  }
}

