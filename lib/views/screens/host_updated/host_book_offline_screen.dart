import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/utils/host_validators.dart';
import '../../../services/host_api_service.dart';
import 'widgets/host_form_widgets.dart';

const Color _purple = Color(0xFF5E42C2);
const Color _ink = Color(0xFF1E1E24);
const Color _border = Color(0xFFE2E2EC);

// UI options from the design.
const List<String> _halls = ['Hall A', 'Hall B', 'Lawn', 'Main hall'];
const List<String> _roomTypes = ['Standard room', 'Deluxe room', 'Suite'];
const List<String> _eventTypes = [
  'Birthday',
  'Reception',
  'Wedding',
  'Engagement',
  'Corporate',
  'Other',
];
const List<List<String>> _slots = [
  ['1st slot', '06:00 AM', '01:00 PM'],
  ['2nd slot', '02:00 PM', '11:00 PM'],
];
const List<String> _methods = ['Cash', 'UPI', 'Other'];
const List<String> _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String _dateText(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';

String _timeText(DateTime d) {
  final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final m = d.minute.toString().padLeft(2, '0');
  return 'm ${d.hour < 12 ? 'AM' : 'PM'}';
}

/// Figma: frame 1228744536 (node 1:4490)
/// Figma: frame 1228744548 (node 1:5570)
class HostBookOfflineScreen extends StatefulWidget {
  const HostBookOfflineScreen({super.key, required this.isEvent, this.initialDate});

  final bool isEvent;

  /// Pre-selects the event date (used when booking from the availability calendar).
  final DateTime? initialDate;

  @override
  State<HostBookOfflineScreen> createState() => _HostBookOfflineScreenState();
}

class _HostBookOfflineScreenState extends State<HostBookOfflineScreen> {
  final _name = TextEditingController();
  final _mobile = TextEditingController();
  final _total = TextEditingController();
  final _advance = TextEditingController();
  final _reference = TextEditingController();
  final _guests = TextEditingController();
  final _veg = TextEditingController();
  final _nonVeg = TextEditingController();

  @override
  void initState() {
    super.initState();
    _eventDate = widget.initialDate;
  }

  // Stay
  DateTime? _checkIn;
  DateTime? _checkOut;
  String _roomType = _roomTypes.first;
  int _rooms = 1;
  int _children = 0;
  int _adults = 1;

  // Event
  String _hall = '';
  DateTime? _eventDate;
  int _slot = 0;
  String _eventType = _eventTypes.first;

  String _method = _methods.first;
  bool _submitting = false;

  @override
  void dispose() {
    for (final c in [_name, _mobile, _total, _advance, _reference, _guests, _veg, _nonVeg]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<DateTime?> _pickDate(DateTime? current) {
    final now = DateTime.now();
    return showDatePicker(
      context: context,
      initialDate: current ?? now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 3),
    );
  }

  Future<void> _pickDateTime({required bool checkIn}) async {
    final current = checkIn ? _checkIn : _checkOut;
    final date = await _pickDate(current);
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current ?? DateTime.now()),
    );
    if (time == null) return;
    final value = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    setState(() => checkIn ? _checkIn = value : _checkOut = value);
  }

  Future<void> _pickEventDate() async {
    final date = await _pickDate(_eventDate);
    if (date != null) setState(() => _eventDate = date);
  }

  int _int(TextEditingController c) => int.tryParse(c.text.trim()) ?? 0;

  double _amount(TextEditingController c) =>
      double.tryParse(c.text.replaceAll(',', '').trim()) ?? 0;

  String? _validate() {
    if (widget.isEvent) {
      if (_hall.isEmpty) return 'Please select a hall';
      if (_eventDate == null) return 'Please select the event date';
      if (_int(_guests) <= 0) return 'Enter the number of guests';
    } else {
      if (_checkIn == null) return 'Please select the check-in date and time';
      if (_checkOut == null) return 'Please select the check-out date and time';
      if (!_checkOut!.isAfter(_checkIn!)) return 'Check-out must be after check-in';
    }
    final error = HostValidators.required(_name.text, 'Customer name') ??
        HostValidators.mobile(_mobile.text) ??
        HostValidators.amount(_total.text, 'total amount');
    if (error != null) return error;
    if (_amount(_advance) > _amount(_total)) {
      return 'Advance cannot be more than the total';
    }
    return null;
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final error = _validate();
    if (error != null) {
      showHostError(context, error);
      return;
    }
    final String startText;
    final String endText;
    final String unitName;
    final int guests;
    if (widget.isEvent) {
      final slot = _slots[_slot];
      startText = '${_dateText(_eventDate!)} , ${slot[1]}';
      endText = '${_dateText(_eventDate!)} , ${slot[2]}';
      unitName = _hall;
      guests = _int(_guests);
    } else {
      startText = '${_dateText(_checkIn!)} , ${_timeText(_checkIn!)}';
      endText = '${_dateText(_checkOut!)} , ${_timeText(_checkOut!)}';
      unitName = _rooms > 1 ? '$_roomType x $_rooms' : _roomType;
      guests = _adults + _children;
    }
    setState(() => _submitting = true);
    final res = await HostApiService.createOfflineBooking({
      'kind': widget.isEvent ? 'event' : 'stay',
      'unitName': unitName,
      'customerName': _name.text.trim(),
      'mobile': _mobile.text.trim(),
      'guests': guests,
      'eventType': widget.isEvent ? _eventType : '',
      'bookingDate': _dateText(DateTime.now()),
      'startText': startText,
      'endText': endText,
      'total': _amount(_total),
      'advance': _amount(_advance),
      'advanceMethod': _method,
      if (_reference.text.trim().isNotEmpty) 'referenceNumber': _reference.text.trim(),
    });
    if (!mounted) return;
    setState(() => _submitting = false);
    if (res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Booking added')));
      Navigator.pop(context, true);
    } else {
      showHostError(context, '${res['message'] ?? 'Could not add booking'}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEvent = widget.isEvent;
    return HostFormPage(
      title: isEvent ? 'Book Offline (Event)' : 'Book Offline (Stay)',
      buttonText: isEvent ? 'Book' : 'Continue',
      onContinue: _submit,
      children: [
        if (isEvent) ..._eventFields() else ..._stayFields(),
        const HostQuestion('Customer Name'),
        HostTextField(controller: _name, hint: 'Enter customer name'),
        const HostQuestion('Mobile Number'),
        HostTextField(controller: _mobile, hint: 'Enter mobile number', numeric: true),
        const HostQuestion('Total'),
        HostTextField(
          controller: _total,
          hint: 'Total amount',
          numeric: true,
          onChanged: (_) => setState(() {}),
        ),
        const HostQuestion('Advance'),
        Wrap(
          spacing: 16,
          children: [
            for (final m in _methods)
              SizedBox(
                width: 90,
                child: HostRadioRow(
                  title: m,
                  selected: _method == m,
                  onTap: () => setState(() => _method = m),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        HostTextField(
          controller: _advance,
          hint: 'Advance amount',
          numeric: true,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 10),
        HostTextField(controller: _reference, hint: 'Reference number (optional)'),
        const SizedBox(height: 12),
        _label('Balance due: ${_balance()}'),
      ],
    );
  }

  String _balance() {
    final due = _amount(_total) - _amount(_advance);
    return due <= 0 ? '0' : due.toStringAsFixed(due == due.roundToDouble() ? 0 : 2);
  }

  List<Widget> _stayFields() => [
        const HostQuestion('Stay Date'),
        Row(
          children: [
            Expanded(
              child: _pickerBox(
                'Check-in',
                _checkIn == null ? '' : '${_dateText(_checkIn!)}\n${_timeText(_checkIn!)}',
                () => _pickDateTime(checkIn: true),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _pickerBox(
                'Check-out',
                _checkOut == null ? '' : '${_dateText(_checkOut!)}\n${_timeText(_checkOut!)}',
                () => _pickDateTime(checkIn: false),
              ),
            ),
          ],
        ),
        const HostQuestion('Room type'),
        _dropdown(_roomType, _roomTypes, (v) => setState(() => _roomType = v)),
        const HostQuestion('Number of rooms'),
        _stepper('Add Rooms +', _rooms, 1, (v) => setState(() => _rooms = v)),
        const HostQuestion('Guests'),
        _stepper('Adults', _adults, 1, (v) => setState(() => _adults = v)),
        const SizedBox(height: 8),
        _stepper('Children', _children, 0, (v) => setState(() => _children = v)),
      ];

  List<Widget> _eventFields() => [
        const HostQuestion('Select Hall'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final h in _halls)
              ChoiceChip(
                label: Text(h, style: GoogleFonts.poppins(fontSize: 13)),
                selected: _hall == h,
                selectedColor: _purple.withValues(alpha: 0.15),
                onSelected: (_) => setState(() => _hall = h),
              ),
          ],
        ),
        const HostQuestion('Event Date'),
        _pickerBox('Select date', _eventDate == null ? '' : _dateText(_eventDate!), _pickEventDate),
        const HostQuestion('Select Slot'),
        for (var i = 0; i < _slots.length; i++)
          HostRadioRow(
            title: '${_slots[i][0]} ${_slots[i][1]} - ${_slots[i][2]}',
            selected: _slot == i,
            onTap: () => setState(() => _slot = i),
          ),
        const HostQuestion('Event Type'),
        _dropdown(_eventType, _eventTypes, (v) => setState(() => _eventType = v)),
        const HostQuestion('Guests'),
        HostTextField(controller: _guests, hint: 'Number of guests', numeric: true),
        const HostQuestion('Veg Plate'),
        HostTextField(controller: _veg, hint: 'Veg plate count', numeric: true),
        const HostQuestion('Non-veg Plate'),
        HostTextField(controller: _nonVeg, hint: 'Non-veg plate count', numeric: true),
      ];

  Widget _label(String text) => Text(
        text,
        style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF6E6E82)),
      );

  Widget _pickerBox(String hint, String value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: _border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          value.isEmpty ? hint : value,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: value.isEmpty ? const Color(0xFFA0A0B2) : _ink,
          ),
        ),
      ),
    );
  }

  Widget _dropdown(String value, List<String> items, ValueChanged<String> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          items: [
            for (final i in items)
              DropdownMenuItem(
                value: i,
                child: Text(i, style: GoogleFonts.poppins(fontSize: 14, color: _ink)),
              ),
          ],
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }

  Widget _stepper(String label, int value, int min, ValueChanged<int> onChanged) {
    return Row(
      children: [
        Expanded(
          child: Text(label, style: GoogleFonts.poppins(fontSize: 14, color: _ink)),
        ),
        IconButton(
          onPressed: value > min ? () => onChanged(value - 1) : null,
          icon: const Icon(Icons.remove_circle_outline_rounded),
          color: _purple,
        ),
        SizedBox(
          width: 28,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
        IconButton(
          onPressed: () => onChanged(value + 1),
          icon: const Icon(Icons.add_circle_outline_rounded),
          color: _purple,
        ),
      ],
    );
  }
}


********************************************************************************
================================================================================
