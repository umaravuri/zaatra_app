import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../services/host_api_service.dart';
import 'widgets/host_components.dart';
import 'widgets/host_form_widgets.dart';

const Color _kPurple = Color(0xFF5E42C2);
const Color _kInk = Color(0xFF1E1E24);
const Color _kBorder = Color(0xFFE5E4ED);
const Color _kMuted = Color(0xFFA0A0B2);

// Starting hall for the first request; replaced by the first of res['halls']
// when the backend does not know it.
const String _kDefaultHall = 'Main Hall 1';

const List<String> _kMonths = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];
const List<String> _kMonthsShort = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];
const List<String> _kWeekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

String _iso(DateTime d) =>
    '{d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

String _short(DateTime d) => '${_kMonthsShort[d.month - 1]} ${d.day}';

/// 80000 -> '80k', 82500 -> '82.5k', 950 -> '950'.
String _k(num v) {
  if (v < 1000) return v.toInt().toString();
  final s = (v / 1000).toStringAsFixed(1);
  return '${s.endsWith('.0') ? s.substring(0, s.length - 2) : s}k';
}

/// Indian digit grouping: 1234567 -> '12,34,567'.
String _inr(int v) {
  final s = v.toString();
  if (s.length <= 3) return s;
  final head = s.substring(0, s.length - 3);
  final buf = StringBuffer();
  for (var i = 0; i < head.length; i++) {
    if (i > 0 && (head.length - i) % 2 == 0) buf.write(',');
    buf.write(head[i]);
  }
  return '{s.substring(s.length - 3)}';
}

/// Figma: frame 1228744541 (node 1:5053)
/// Figma: frame 1228744545 (node 1:5411)
class HostVenueRatesView extends StatefulWidget {
  const HostVenueRatesView({super.key});

  @override
  State<HostVenueRatesView> createState() => _HostVenueRatesViewState();
}

class _HostVenueRatesViewState extends State<HostVenueRatesView> {
  List<String> _halls = [];
  String _hall = _kDefaultHall;
  late DateTime _month;
  Map<String, dynamic> _days = {};
  bool _loading = true;
  String? _error;
  bool _saving = false;

  DateTime? _from, _to;
  final _slot1Ctrl = TextEditingController();
  final _slot2Ctrl = TextEditingController();
  final _stayCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
    _load();
  }

  @override
  void dispose() {
    _slot1Ctrl.dispose();
    _slot2Ctrl.dispose();
    _stayCtrl.dispose();
    super.dispose();
  }

  Future<void> _load({bool prefillStay = true}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    var res = await HostApiService.getRates(hall: _hall, year: _month.year, month: _month.month);
    if (!mounted) return;
    // Fall back to the backend's own first hall if our starting hall is unknown.
    final halls = res['halls'];
    if (res['success'] != true && halls is List && halls.isNotEmpty && !halls.contains(_hall)) {
      _hall = '${halls.first}';
      res = await HostApiService.getRates(hall: _hall, year: _month.year, month: _month.month);
      if (!mounted) return;
    }
    setState(() {
      _loading = false;
      if (res['success'] == true && res['days'] is Map) {
        _days = Map<String, dynamic>.from(res['days'] as Map);
        if (res['halls'] is List) {
          _halls = (res['halls'] as List).map((e) => '$e').toList();
        }
        if (prefillStay && res['stayRate'] != null) {
          _stayCtrl.text = '${res['stayRate']}';
        }
      } else {
        _days = {};
        _error = (res['message'] ?? 'Could not load rates').toString();
      }
    });
  }

  void _changeMonth(int delta) {
    setState(() => _month = DateTime(_month.year, _month.month + delta));
    _load(prefillStay: false);
  }

  Future<void> _pickDate(bool isFrom) async {
    final initial = (isFrom ? _from : _to) ?? _from ?? _month;
    final d = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(DateTime.now().year - 1),
      lastDate: DateTime(DateTime.now().year + 3, 12, 31),
    );
    if (d == null) return;
    setState(() => isFrom ? _from = d : _to = d);
  }

  Future<void> _apply() async {
    final from = _from, to = _to;
    if (from == null || to == null) return showHostError(context, 'Select the rate change dates');
    if (from.isAfter(to)) return showHostError(context, '"From" date cannot be after "To" date');
    final s1 = int.tryParse(_slot1Ctrl.text.trim());
    final s2 = int.tryParse(_slot2Ctrl.text.trim());
    if (s1 == null || s1 <= 0) return showHostError(context, 'Enter a valid 1st slot price');
    if (s2 == null || s2 <= 0) return showHostError(context, 'Enter a valid 2nd slot price');
    final stayText = _stayCtrl.text.trim();
    int? stay;
    if (stayText.isNotEmpty) {
      stay = int.tryParse(stayText);
      if (stay == null || stay <= 0) return showHostError(context, 'Enter a valid stay price');
    }
    setState(() => _saving = true);
    final res = await HostApiService.updateRates(
      hall: _hall,
      from: _iso(from),
      to: _iso(to),
      slot1: s1,
      slot2: s2,
      stayRate: stay,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (res['success'] != true) {
      showHostError(context, (res['message'] ?? 'Could not change rates').toString());
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const _RatesResultPage()),
    );
    if (!mounted) return;
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_halls.isNotEmpty) _hallChips(),
          const SizedBox(height: 12),
          _calendar(),
          if (_error == null) ..._form(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _hallChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final h in _halls)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(
                  h,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: h == _hall ? Colors.white : _kInk,
                  ),
                ),
                selected: h == _hall,
                showCheckmark: false,
                selectedColor: _kPurple,
                backgroundColor: Colors.white,
                side: const BorderSide(color: _kBorder),
                onSelected: (_) {
                  if (h == _hall) return;
                  setState(() => _hall = h);
                  _load();
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _calendar() {
    final first = DateTime(_month.year, _month.month, 1);
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final lead = first.weekday % 7;
    return Container(
      padding: const EdgeInsets.all(10),
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
              padding: EdgeInsets.symmetric(vertical: 50),
              child: CircularProgressIndicator(color: _kPurple),
            )
          else if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                children: [
                  Text(_error!, textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 13)),
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
              crossAxisSpacing: 2,
              childAspectRatio: 0.62,
              children: [
                for (var i = 0; i < lead; i++) const SizedBox.shrink(),
                for (var d = 1; d <= daysInMonth; d++)
                  _dayCell(DateTime(_month.year, _month.month, d)),
              ],
            ),
        ],
      ),
    );
  }

  Widget _dayCell(DateTime d) {
    final day = _days[_iso(d)];
    final s1 = day is Map && day['slot1'] is num ? _k(day['slot1'] as num) : '-';
    final s2 = day is Map && day['slot2'] is num ? _k(day['slot2'] as num) : '-';
    final small = GoogleFonts.poppins(fontSize: 9, color: _kPurple, height: 1.2);
    return Container(
      decoration: BoxDecoration(
        color: _kPurple.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${d.day}',
            style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: _kInk),
          ),
          Text(s1, style: small),
          Text(s2, style: small),
        ],
      ),
    );
  }

  List<Widget> _form() {
    final label = (_from != null && _to != null)
        ? 'Apply from ${_short(_from!)} - ${_short(_to!)}'
        : 'Apply rate change';
    return [
      const HostQuestion('Rate change from'),
      _dateField(_from, () => _pickDate(true)),
      const HostQuestion('Rate change to', topSpace: 14),
      _dateField(_to, () => _pickDate(false)),
      const HostQuestion('1st Slot', topSpace: 14),
      HostTextField(controller: _slot1Ctrl, hint: '₹ 85,000', numeric: true),
      const HostQuestion('2nd Slot', topSpace: 14),
      HostTextField(controller: _slot2Ctrl, hint: '₹ 90,000', numeric: true),
      const HostQuestion('In case of stay', topSpace: 14),
      HostTextField(
        controller: _stayCtrl,
        hint: '₹ 4,500',
        numeric: true,
        onChanged: (_) => setState(() {}),
      ),
      if (int.tryParse(_stayCtrl.text) != null && _stayCtrl.text.length > 3)
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            '₹ ${_inr(int.parse(_stayCtrl.text))}',
            style: GoogleFonts.poppins(fontSize: 12, color: _kMuted),
          ),
        ),
      const SizedBox(height: 24),
      HostBottomButton(
        text: _saving ? 'Applying...' : label,
        onPressed: _saving ? null : _apply,
      ),
    ];
  }

  Widget _dateField(DateTime? d, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E2EC)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                d == null ? 'Select date' : '${_short(d)}, ${d.year}',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: d == null ? _kMuted : _kInk,
                ),
              ),
            ),
            const Icon(Icons.calendar_today_rounded, size: 18, color: Color(0xFF6E6E82)),
          ],
        ),
      ),
    );
  }
}

class _RatesResultPage extends StatelessWidget {
  const _RatesResultPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                      'Rates changed successfully',
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
              HostBottomButton(text: 'Done', onPressed: () => Navigator.of(context).pop()),
            ],
          ),
        ),
      ),
    );
  }
}


********************************************************************************
================================================================================
