import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../services/api_service.dart';
import '../../../../services/auth_service.dart';
import '../../../widgets/custom_button.dart';
import 'driver_ride_review_screen_87.dart';

class DriverPublishRideCalendarScreen extends StatefulWidget {
  final Map<String, dynamic>? rideDetails;

  const DriverPublishRideCalendarScreen({
    super.key,
    this.rideDetails,
  });

  @override
  State<DriverPublishRideCalendarScreen> createState() => _DriverPublishRideCalendarScreenState();
}

class _DriverPublishRideCalendarScreenState extends State<DriverPublishRideCalendarScreen> {
  int _selectedSeats = 4;

  // Dropdown date state - start date
  late int _startDay;
  late int _startMonth;
  late int _startYear;

  // Dropdown date state - end date (optional for multi-day)
  late int _endDay;
  late int _endMonth;
  late int _endYear;

  // Booking mode toggle
  String _bookingMode = 'instant'; // 'instant' | 'review'

  // Ride type toggle
  String _rideType = 'shared'; // 'shared' | 'door_to_door'

  List<Map<String, dynamic>> _existingDriverRides = [];

  // Per-stop prices (editable) — built from intermediatePickups
  late List<Map<String, dynamic>> _stopPrices;

  static const List<String> _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startDay = now.day;
    _startMonth = now.month;
    _startYear = now.year;
    _endDay = now.day;
    _endMonth = now.month;
    _endYear = now.year;

    _buildStopPrices();
    _loadExistingDriverRides();
  }

  void _buildStopPrices() {
    final picks = widget.rideDetails?['intermediatePickups'];
    if (picks is List && picks.isNotEmpty) {
      _stopPrices = picks.map<Map<String, dynamic>>((p) {
        final loc = (p['location'] ?? p['name'] ?? '').toString();
        final price = (p['price'] is num) ? (p['price'] as num).toInt() : 750;
        return {'location': loc, 'price': price};
      }).toList();
    } else {
      // Build from selectedCities if no structured intermediatePickups
      final cities = List<String>.from(widget.rideDetails?['selectedCities'] ?? []);
      final pickup = widget.rideDetails?['pickupLocation'] ?? '';
      final dest = widget.rideDetails?['destinationLocation'] ?? '';
      _stopPrices = [
        if (pickup.isNotEmpty) {'location': pickup, 'price': 850},
        ...cities.map((c) => {'location': c, 'price': 750}),
        if (dest.isNotEmpty) {'location': dest, 'price': 850},
      ];
    }
    // Ensure at least origin + destination if stops list is empty
    if (_stopPrices.isEmpty) {
      final pickup = widget.rideDetails?['pickupLocation'] ?? 'Origin';
      final dest = widget.rideDetails?['destinationLocation'] ?? 'Destination';
      _stopPrices = [
        {'location': pickup, 'price': 850},
        {'location': dest, 'price': 850},
      ];
    }
  }

  Future<void> _loadExistingDriverRides() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final user = await AuthService.getCurrentUser();
      final phone = prefs.getString('currentPhone') ?? user?['phone']?.toString() ?? '';
      final cleanDigits = phone.replaceAll(RegExp(r'[^0-9]'), '');

      final res = await ApiService.get('/rides');
      if (res['success'] == true && res['rides'] is List) {
        final allRides = List<Map<String, dynamic>>.from(res['rides']);
        final filtered = allRides.where((r) {
          final driverPhone = (r['driverPhone'] ?? r['phone'] ?? '').toString().replaceAll(RegExp(r'[^0-9]'), '');
          if (cleanDigits.isNotEmpty && driverPhone.isNotEmpty) {
            return driverPhone.contains(cleanDigits) || cleanDigits.contains(driverPhone);
          }
          return true;
        }).toList();
        if (mounted) {
          setState(() {
            _existingDriverRides = filtered;
          });
        }
      }
    } catch (_) {}
  }

  int _daysInMonth(int year, int month) => DateTime(year, month + 1, 0).day;

  void _clampDay(String which) {
    if (which == 'start') {
      final max = _daysInMonth(_startYear, _startMonth);
      if (_startDay > max) setState(() => _startDay = max);
    } else {
      final max = _daysInMonth(_endYear, _endMonth);
      if (_endDay > max) setState(() => _endDay = max);
    }
  }

  DateTime get _startDate => DateTime(_startYear, _startMonth, _startDay);
  DateTime get _endDate => DateTime(_endYear, _endMonth, _endDay);

  void _handleNext() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final maxDate = today.add(const Duration(days: 30));

    if (_startDate.isBefore(today)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Start date cannot be in the past.'),
          backgroundColor: Colors.redAccent,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (_startDate.isAfter(maxDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rides can only be scheduled within the next 30 days.'),
          backgroundColor: Colors.redAccent,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    // Duplicate ride check
    Map<String, dynamic>? duplicateRide;
    for (final ride in _existingDriverRides) {
      final status = (ride['status']?.toString().toLowerCase()) ?? '';
      if (['cancelled', 'completed', 'finished', 'rejected'].contains(status)) continue;

      DateTime? rideDate;
      if (ride['departs'] != null) {
        rideDate = DateTime.tryParse(ride['departs'].toString());
      }
      if (rideDate == null && ride['departureDate'] != null) {
        final parts = ride['departureDate'].toString().split(RegExp(r'[\s\-/]+'));
        if (parts.length >= 3) {
          final d = int.tryParse(parts[0]);
          final m = int.tryParse(parts[1]);
          final y = int.tryParse(parts[2]);
          if (d != null && m != null && y != null) {
            rideDate = DateTime(y, m, d);
          }
        }
      }
      if (rideDate != null &&
          rideDate.year == _startDate.year &&
          rideDate.month == _startDate.month &&
          rideDate.day == _startDate.day) {
        duplicateRide = ride;
        break;
      }
    }

    if (duplicateRide != null) {
      final pickup = (duplicateRide['pickupLocation'] ?? duplicateRide['from'] ?? 'Origin').toString().split(',').first;
      final dest = (duplicateRide['destinationLocation'] ?? duplicateRide['to'] ?? 'Destination').toString().split(',').first;
      _showDuplicateRideDialog(
        dateStr: '${_startDate.day} ${_monthNames[_startDate.month - 1]} ${_startDate.year}',
        routeSummary: '$pickup → $dest',
      );
    } else {
      _navigateToReview();
    }
  }

  void _showDuplicateRideDialog({required String dateStr, required String routeSummary}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.amber.shade50, shape: BoxShape.circle),
              child: Icon(Icons.warning_amber_rounded, color: Colors.amber.shade800, size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('Ride Already Scheduled',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('You already have a ride scheduled on $dateStr:',
                style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, height: 1.4)),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF3EDF7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.directions_car_rounded, color: AppColors.primary, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(routeSummary,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text('Are you sure you want to publish another ride on the same date?',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.3)),
          ],
        ),
        actionsPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Change Date',
                      style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _navigateToReview();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Proceed Anyway',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _navigateToReview() {
    final updatedDetails = Map<String, dynamic>.from(widget.rideDetails ?? {});
    updatedDetails['seats'] = _selectedSeats;
    updatedDetails['departs'] = _startDate.toIso8601String();
    updatedDetails['departureDate'] = '${_startDate.day} - ${_startDate.month} - ${_startDate.year}';
    updatedDetails['departureEndDate'] = '${_endDate.day} - ${_endDate.month} - ${_endDate.year}';
    updatedDetails['bookingMode'] = _bookingMode;
    updatedDetails['rideType'] = _rideType;
    updatedDetails['pricePerSeat'] = _stopPrices.isNotEmpty ? _stopPrices[0]['price'] : 850;
    updatedDetails['intermediatePickups'] = _stopPrices;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DriverRideReviewScreen(rideDetails: updatedDetails),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final years = [now.year, now.year + 1];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Date & Settings',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: IgnorePointer(
                child: Image.asset(
                  'assets/images/image 31.png',
                  fit: BoxFit.fitWidth,
                  alignment: Alignment.bottomCenter,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ),
            SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Start Date ──────────────────────────────────
                  const Text('Start Date',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  const SizedBox(height: 10),
                  _buildDateDropdowns(
                    day: _startDay,
                    month: _startMonth,
                    year: _startYear,
                    years: years,
                    minDate: DateTime(now.year, now.month, now.day),
                    onDayChanged: (v) => setState(() { _startDay = v!; }),
                    onMonthChanged: (v) { setState(() { _startMonth = v!; }); _clampDay('start'); },
                    onYearChanged: (v) { setState(() { _startYear = v!; }); _clampDay('start'); },
                  ),

                  const SizedBox(height: 20),

                  // ── End Date ────────────────────────────────────
                  const Text('End Date',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  const SizedBox(height: 10),
                  _buildDateDropdowns(
                    day: _endDay,
                    month: _endMonth,
                    year: _endYear,
                    years: years,
                    minDate: _startDate,
                    onDayChanged: (v) => setState(() { _endDay = v!; }),
                    onMonthChanged: (v) { setState(() { _endMonth = v!; }); _clampDay('end'); },
                    onYearChanged: (v) { setState(() { _endYear = v!; }); _clampDay('end'); },
                  ),

                  const SizedBox(height: 24),

                  // ── Available Passenger Seats ───────────────────
                  const Text('Available Passenger Seats',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      ...List.generate(_selectedSeats, (_) => Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: _buildPassengerIcon(),
                      )),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3EDF7),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            InkWell(
                              onTap: () { if (_selectedSeats > 1) setState(() => _selectedSeats--); },
                              child: const Icon(Icons.remove, size: 18, color: AppColors.primary),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Text('$_selectedSeats',
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary)),
                            ),
                            InkWell(
                              onTap: () { if (_selectedSeats < 6) setState(() => _selectedSeats++); },
                              child: const Icon(Icons.add, size: 18, color: AppColors.primary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ── Instructions ────────────────────────────────
                  const Text('Instructions',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  const SizedBox(height: 8),
                  const Text('• Prefer max 2 members in back seats',
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),

                  const SizedBox(height: 20),

                  // ── Booking Mode Toggle ─────────────────────────
                  _buildToggleRow(
                    label: 'Booking',
                    option1Label: 'Instant booking',
                    option1Value: 'instant',
                    option2Label: 'Review every request',
                    option2Value: 'review',
                    selectedValue: _bookingMode,
                    onChanged: (val) => setState(() => _bookingMode = val),
                  ),

                  const SizedBox(height: 14),

                  // ── Ride Type Toggle ────────────────────────────
                  _buildToggleRow(
                    label: 'Ride Type',
                    option1Label: 'Shared Ride',
                    option1Value: 'shared',
                    option2Label: 'Accept Door to Door',
                    option2Value: 'door_to_door',
                    selectedValue: _rideType,
                    onChanged: (val) => setState(() => _rideType = val),
                  ),

                  const SizedBox(height: 24),

                  // ── Prices List ─────────────────────────────────
                  const Text('Prices List (Auto-Calculated by Distance)',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  const SizedBox(height: 12),

                  ...List.generate(_stopPrices.length, (i) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _buildPriceTile(i),
                    );
                  }),

                  const SizedBox(height: 8),
                  const Center(
                    child: Text(
                      'Prices are auto calculated and adjusted to nearby highway toll rates',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w500),
                    ),
                  ),

                  const SizedBox(height: 28),

                  CustomButton(
                    text: 'Next',
                    onPressed: _handleNext,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateDropdowns({
    required int day,
    required int month,
    required int year,
    required List<int> years,
    required DateTime minDate,
    required ValueChanged<int?> onDayChanged,
    required ValueChanged<int?> onMonthChanged,
    required ValueChanged<int?> onYearChanged,
  }) {
    final daysInThisMonth = _daysInMonth(year, month);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF3EDF7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          // Day
          Expanded(
            child: _buildDropdown<int>(
              value: day,
              items: List.generate(daysInThisMonth, (i) => i + 1),
              label: (v) => v.toString().padLeft(2, '0'),
              onChanged: onDayChanged,
              hint: 'DD',
            ),
          ),
          const SizedBox(width: 10),
          // Month
          Expanded(
            flex: 2,
            child: _buildDropdown<int>(
              value: month,
              items: List.generate(12, (i) => i + 1),
              label: (v) => _monthNames[v - 1],
              onChanged: onMonthChanged,
              hint: 'Month',
            ),
          ),
          const SizedBox(width: 10),
          // Year
          Expanded(
            child: _buildDropdown<int>(
              value: year,
              items: years,
              label: (v) => v.toString(),
              onChanged: onYearChanged,
              hint: 'YYYY',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown<T>({
    required T value,
    required List<T> items,
    required String Function(T) label,
    required ValueChanged<T?> onChanged,
    required String hint,
  }) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<T>(
        value: value,
        isDense: true,
        isExpanded: true,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        dropdownColor: Colors.white,
        borderRadius: BorderRadius.circular(12),
        icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: AppColors.primary),
        hint: Text(hint, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        items: items.map((item) => DropdownMenuItem<T>(
          value: item,
          child: Text(label(item), style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
        )).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildToggleRow({
    required String label,
    required String option1Label,
    required String option1Value,
    required String option2Label,
    required String option2Value,
    required String selectedValue,
    required ValueChanged<String> onChanged,
  }) {
    return Row(
      children: [
        _buildToggleOption(
          label: option1Label,
          value: option1Value,
          selected: selectedValue == option1Value,
          onTap: () => onChanged(option1Value),
        ),
        const SizedBox(width: 12),
        _buildToggleOption(
          label: option2Label,
          value: option2Value,
          selected: selectedValue == option2Value,
          onTap: () => onChanged(option2Value),
        ),
      ],
    );
  }

  Widget _buildToggleOption({
    required String label,
    required String value,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary.withValues(alpha: 0.08) : const Color(0xFFF3EDF7),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? AppColors.primary : AppColors.border,
                    width: 2,
                  ),
                ),
                child: selected
                    ? Center(
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                    color: selected ? AppColors.primary : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriceTile(int index) {
    final stop = _stopPrices[index];
    final location = stop['location'] as String? ?? '';
    final price = stop['price'] as int? ?? 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF3EDF7),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 18),
              const SizedBox(width: 10),
              SizedBox(
                width: 140,
                child: Text(
                  location,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Row(
            children: [
              InkWell(
                onTap: () {
                  if (price > 50) {
                    setState(() => _stopPrices[index]['price'] = price - 50);
                  }
                },
                child: const Icon(Icons.remove_circle_outline_rounded, size: 20, color: AppColors.primary),
              ),
              const SizedBox(width: 8),
              Text(
                '₹$price',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () {
                  setState(() => _stopPrices[index]['price'] = price + 50);
                },
                child: const Icon(Icons.add_circle_outline_rounded, size: 20, color: AppColors.primary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPassengerIcon() {
    return Container(
      width: 38,
      height: 38,
      decoration: const BoxDecoration(
        color: AppColors.primaryBackground,
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.person_rounded, color: AppColors.primary, size: 22),
    );
  }
}