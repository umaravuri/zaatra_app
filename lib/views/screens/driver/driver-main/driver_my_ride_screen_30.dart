import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../models/place_location_model.dart';
import '../../../../services/api_service.dart';
import '../../../../services/auth_service.dart';
import '../../../../services/google_maps_service.dart';
import '../../../../services/ride_service.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/location_autocomplete_picker_modal.dart';
import '../../../widgets/route_map_webview.dart';
import 'driver_intermediate_pickups_screen.dart';

class DriverMyRideScreen extends StatefulWidget {
  const DriverMyRideScreen({super.key});

  @override
  State<DriverMyRideScreen> createState() => _DriverMyRideScreenState();
}

class _DriverMyRideScreenState extends State<DriverMyRideScreen> {
  LocationPoint? _pickupLocation;
  LocationPoint? _destLocation;

  RouteResult? _routeResult;
  bool _isLoadingRoute = false;
  int _selectedRouteIndex = 0;

  DateTime? _selectedDateTime;
  String? _date;
  String? _time;
  String? _seats;
  
  // Pricing State
  final TextEditingController _basePriceController = TextEditingController(text: '10');
  double _calculatedPricePerSeat = 0;
  double _tripDistanceKm = 0;
  bool _isCalculatingPrice = false;
  Timer? _debounceTimer;

  String _luggage = '1 Medium Bag';
  List<Map<String, dynamic>> _existingDriverRides = [];

  @override
  void initState() {
    super.initState();
    _loadExistingDriverRides();
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

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _basePriceController.dispose();
    super.dispose();
  }

  Future<void> _recalculateBackendPrice() async {
    final basePrice = double.tryParse(_basePriceController.text.trim()) ?? 0.0;
    if (_tripDistanceKm <= 0 || basePrice <= 0) {
      if (mounted) {
        setState(() {
          _calculatedPricePerSeat = 0;
        });
      }
      return;
    }

    setState(() {
      _isCalculatingPrice = true;
    });

    final res = await RideService.calculatePricePerSeat(
      distanceKm: _tripDistanceKm,
      basePricePerKm: basePrice,
      from: _pickupLocation?.name,
      to: _destLocation?.name,
    );

    if (!mounted) return;
    setState(() {
      _isCalculatingPrice = false;
      if (res['success'] == true && res['pricePerSeat'] != null) {
        _calculatedPricePerSeat = (res['pricePerSeat'] as num).toDouble();
      } else {
        _calculatedPricePerSeat = (_tripDistanceKm * basePrice).roundToDouble();
      }
    });
  }

  void _onBasePriceChanged(String val) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _recalculateBackendPrice();
    });
  }

  void _onRouteSelected(int index) {
    if (_routeResult == null || index >= _routeResult!.candidateRoutes.length) return;
    final r = _routeResult!.candidateRoutes[index];
    setState(() {
      _selectedRouteIndex = index;
      if (r.distanceMeters > 0) {
        _tripDistanceKm = r.distanceMeters / 1000.0;
      } else {
        _tripDistanceKm = double.tryParse(r.distanceText.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
      }
    });
    if (_tripDistanceKm > 0) {
      _recalculateBackendPrice();
    }
  }

  Future<void> _fetchDirections() async {
    if (_pickupLocation == null || _destLocation == null) return;

    setState(() {
      _isLoadingRoute = true;
    });

    RouteResult? result;
    if (_pickupLocation!.latitude != 0.0 && _destLocation!.latitude != 0.0) {
      result = await GoogleMapsService.getDirections(
        originLat: _pickupLocation!.latitude,
        originLng: _pickupLocation!.longitude,
        destLat: _destLocation!.latitude,
        destLng: _destLocation!.longitude,
      );
    }

    if (result == null || result.candidateRoutes.isEmpty) {
      final fromStr = _pickupLocation!.formattedAddress.isNotEmpty ? _pickupLocation!.formattedAddress : _pickupLocation!.name;
      final toStr = _destLocation!.formattedAddress.isNotEmpty ? _destLocation!.formattedAddress : _destLocation!.name;
      result = await GoogleMapsService.getDirectionsByAddress(
        origin: fromStr,
        destination: toStr,
      );
    }

    if (!mounted) return;
    setState(() {
      _isLoadingRoute = false;
      if (result != null) {
        _routeResult = result;
        if (_selectedRouteIndex >= result.candidateRoutes.length) {
          _selectedRouteIndex = 0;
        }

        final activeCandidate = (result.candidateRoutes.isNotEmpty && _selectedRouteIndex < result.candidateRoutes.length)
            ? result.candidateRoutes[_selectedRouteIndex]
            : null;

        if (activeCandidate != null && activeCandidate.distanceMeters > 0) {
          _tripDistanceKm = (activeCandidate.distanceMeters / 1000.0);
        } else if (result.distanceMeters > 0) {
          _tripDistanceKm = (result.distanceMeters / 1000.0);
        } else {
          _tripDistanceKm = double.tryParse(result.distanceText.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
        }
      }
    });

    if (result != null && _tripDistanceKm > 0) {
      _recalculateBackendPrice();
    }
  }

  Future<void> _selectPickup() async {
    final picked = await LocationAutocompletePickerModal.show(
      context,
      title: 'Select Pickup Location',
      initialQuery: _pickupLocation?.name ?? '',
    );

    if (picked != null && mounted) {
      setState(() {
        _pickupLocation = picked;
      });
      _fetchDirections();
    }
  }

  Future<void> _selectDestination() async {
    final picked = await LocationAutocompletePickerModal.show(
      context,
      title: 'Select Destination',
      initialQuery: _destLocation?.name ?? '',
    );

    if (picked != null && mounted) {
      setState(() {
        _destLocation = picked;
      });
      _fetchDirections();
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final maxDate = today.add(const Duration(days: 30));

    DateTime initial = _selectedDateTime ?? today;
    if (initial.isBefore(today)) {
      initial = today;
    } else if (initial.isAfter(maxDate)) {
      initial = maxDate;
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: today,
      lastDate: maxDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      setState(() {
        _selectedDateTime = picked;
        _date = '${picked.day} ${months[picked.month - 1]} ${picked.year}';
      });

      // A time chosen earlier (e.g. 9 AM for tomorrow) must not survive a
      // switch to today if it is already in the past.
      final existing = _parseTimeString(_time);
      if (existing != null && _isPastTimeToday(existing)) {
        setState(() => _time = null);
        _showPastTimeMessage();
      }
    }
  }

  // ── Start-time validation (no past times on today's date) ──────────────────

  /// Parses the stored "hh:mm AM/PM" string back into a [TimeOfDay].
  TimeOfDay? _parseTimeString(String? value) {
    if (value == null) return null;
    final m = RegExp(r'^\s*(\d{1,2}):(\d{2})\s*(AM|PM)\s*$', caseSensitive: false)
        .firstMatch(value);
    if (m == null) return null;
    var hour = int.parse(m.group(1)!) % 12;
    if (m.group(3)!.toUpperCase() == 'PM') hour += 12;
    return TimeOfDay(hour: hour, minute: int.parse(m.group(2)!));
  }

  bool _isSelectedDateToday() {
    final d = _selectedDateTime;
    if (d == null) return false;
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  /// True when the selected date is today and [t] is earlier than the current
  /// minute. The current minute itself is still allowed.
  bool _isPastTimeToday(TimeOfDay t) {
    if (!_isSelectedDateToday()) return false;
    final now = DateTime.now();
    final nowMinutes = now.hour * 60 + now.minute;
    return t.hour * 60 + t.minute < nowMinutes;
  }

  void _showPastTimeMessage() {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Please select a time later than the current time.'),
          backgroundColor: Colors.redAccent,
          duration: Duration(seconds: 2),
        ),
      );
  }

  Future<void> _selectTime(BuildContext context) async {
    // On today's date start the picker at the current time, otherwise at 3 PM.
    final now = TimeOfDay.now();
    final initial =
        _isSelectedDateToday() ? now : const TimeOfDay(hour: 15, minute: 0);

    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      if (_isPastTimeToday(picked)) {
        // Reject the past time and let the driver choose again.
        _showPastTimeMessage();
        if (mounted) await _selectTime(this.context);
        return;
      }
      final hour = picked.hourOfPeriod == 0 ? 12 : picked.hourOfPeriod;
      final minute = picked.minute.toString().padLeft(2, '0');
      final period = picked.period == DayPeriod.am ? 'AM' : 'PM';
      setState(() {
        _time = 'minute $period';
      });
    }
  }

  void _selectSeats(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Select Available Seats',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 14),
                  ...[1, 2, 3, 4, 5, 6].map((count) {
                    final label = '$count ${count == 1 ? 'Seat' : 'Seats'}';
                    final isSelected = _seats == label;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      visualDensity: const VisualDensity(vertical: -1),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : AppColors.inputBackground,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.airline_seat_recline_normal_rounded, size: 20, color: isSelected ? Colors.white : AppColors.textSecondary),
                      ),
                      title: Text(
                        label,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.normal,
                          color: isSelected ? AppColors.primary : AppColors.textPrimary,
                        ),
                      ),
                      trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: AppColors.primary) : null,
                      onTap: () {
                        setState(() {
                          _seats = label;
                        });
                        Navigator.pop(ctx);
                      },
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _selectLuggage(BuildContext context) {
    final options = ['No Luggage', '1 Small Bag', '1 Medium Bag', '2 Bags (Medium)', 'Heavy / Large Luggage'];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Select Luggage Policy',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 14),
                  ...options.map((item) {
                    final isSelected = _luggage == item;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      visualDensity: const VisualDensity(vertical: -1),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : AppColors.inputBackground,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.luggage_rounded, size: 20, color: isSelected ? Colors.white : AppColors.textSecondary),
                      ),
                      title: Text(
                        item,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.normal,
                          color: isSelected ? AppColors.primary : AppColors.textPrimary,
                        ),
                      ),
                      trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: AppColors.primary) : null,
                      onTap: () {
                        setState(() {
                          _luggage = item;
                        });
                        Navigator.pop(ctx);
                      },
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Post Ride',
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
            // Bottom Background Graphic
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
                children: [
                  // Pickup Location Card
                  InkWell(
                    onTap: _selectPickup,
                    borderRadius: BorderRadius.circular(14),
                    child: _buildLocationCard(
                      label: 'Pickup location',
                      address: _pickupLocation != null
                          ? (_pickupLocation!.formattedAddress.isNotEmpty ? _pickupLocation!.formattedAddress : _pickupLocation!.name)
                          : null,
                      placeholder: 'Select pickup location',
                      iconColor: const Color(0xFF4CAF50),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Destination Card
                  InkWell(
                    onTap: _selectDestination,
                    borderRadius: BorderRadius.circular(14),
                    child: _buildLocationCard(
                      label: 'Destination',
                      address: _destLocation != null
                          ? (_destLocation!.formattedAddress.isNotEmpty ? _destLocation!.formattedAddress : _destLocation!.name)
                          : null,
                      placeholder: 'Select destination',
                      iconColor: const Color(0xFFE53935),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Route Map Container with Live Interactive Google Map & Alternatives
                  if (_pickupLocation != null && _destLocation != null) ...[
                    RouteMapWebView(
                      pickup: _pickupLocation!.name,
                      destination: _destLocation!.name,
                      pickupPoint: _pickupLocation,
                      destPoint: _destLocation,
                      candidateRoutes: _routeResult?.candidateRoutes ?? const [],
                      height: 200,
                      borderRadius: 18,
                      interactive: true,
                      selectedRouteIndex: _selectedRouteIndex,
                      onRouteSelected: _onRouteSelected,
                    ),
                    if (_isLoadingRoute)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 4),
                        child: LinearProgressIndicator(color: AppColors.primary, minHeight: 2),
                      ),
                    if (_routeResult != null && _routeResult!.candidateRoutes.length > 1) ...[
                      const SizedBox(height: 10),
                      // Alternative Routes Selector Cards
                      Row(
                        children: List.generate(_routeResult!.candidateRoutes.length, (idx) {
                          final r = _routeResult!.candidateRoutes[idx];
                          final isSelected = _selectedRouteIndex == idx;
                          final label = r.summary.isNotEmpty ? r.summary : 'Route ${idx + 1}';
                          return Expanded(
                            child: GestureDetector(
                              onTap: () => _onRouteSelected(idx),
                              child: Container(
                                margin: EdgeInsets.only(left: idx == 0 ? 0 : 8),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSelected ? const Color(0xFFEFF6FF) : const Color(0xFFFAFAFA),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected ? AppColors.primary : AppColors.border,
                                    width: isSelected ? 1.5 : 1.0,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 14,
                                          height: 14,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: isSelected ? AppColors.primary : AppColors.border,
                                              width: 1.5,
                                            ),
                                          ),
                                          child: isSelected
                                              ? Center(
                                                  child: Container(
                                                    width: 6,
                                                    height: 6,
                                                    decoration: const BoxDecoration(
                                                      color: AppColors.primary,
                                                      shape: BoxShape.circle,
                                                    ),
                                                  ),
                                                )
                                              : null,
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            label,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.normal,
                                              color: isSelected ? AppColors.primary : AppColors.textPrimary,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (r.isRecommended)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFDCFCE7),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: const Text(
                                              'Best',
                                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.normal, color: Color(0xFF15803D)),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      '${r.durationText} • ${r.distanceText}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.normal,
                                        color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  ] else ...[
                    // Placeholder when locations are not yet picked
                    Container(
                      height: 180,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8DEF8),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Center(
                        child: Text(
                          'Select pickup & destination to view map',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: AppColors.textSecondary),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Date & Time Row (Select Date & Start Time)
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _selectDate(context),
                          child: _buildInfoCard('Select Date', _date, placeholder: 'Date', icon: Icons.calendar_month_rounded),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _selectTime(context),
                          child: _buildInfoCard('Start Time', _time, placeholder: 'Time', icon: Icons.access_time_rounded),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Available Seats & Luggage Row
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _selectSeats(context),
                          child: _buildInfoCard('Available Seats', _seats, placeholder: 'Seats', icon: Icons.airline_seat_recline_normal_rounded),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _selectLuggage(context),
                          child: _buildInfoCard('Luggage', _luggage, placeholder: 'Luggage', icon: Icons.luggage_rounded),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // 💰 Pricing Row: Base Price / km / seat & Calculated Price per Seat
                  Row(
                    children: [
                      // Base Price per km per seat Input Card
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFAFAFA),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Base Price / km / seat',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Text('₹ ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: AppColors.textPrimary)),
                                  Expanded(
                                    child: TextField(
                                      controller: _basePriceController,
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                                      onChanged: _onBasePriceChanged,
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: AppColors.textPrimary),
                                      decoration: const InputDecoration(
                                        border: InputBorder.none,
                                        isDense: true,
                                        contentPadding: EdgeInsets.symmetric(vertical: 2),
                                        hintText: '10',
                                        hintStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: AppColors.textSecondary),
                                      ),
                                    ),
                                  ),
                                  const Text('/ km', style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.normal)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Price per Seat Display Card (Backend Calculated with subtext)
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9F7FC),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Price per Seat',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary),
                              ),
                              const SizedBox(height: 3),
                              _isCalculatingPrice
                                  ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                                    )
                                  : Text(
                                      '₹ ${_calculatedPricePerSeat > 0 ? _calculatedPricePerSeat.toStringAsFixed(0) : '0'}',
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: AppColors.primary),
                                    ),
                              const SizedBox(height: 2),
                              Text(
                                _tripDistanceKm > 0 && (double.tryParse(_basePriceController.text.trim()) ?? 0) > 0
                                    ? '${_tripDistanceKm.toStringAsFixed(_tripDistanceKm.truncateToDouble() == _tripDistanceKm ? 0 : 1)} kms x ${_basePriceController.text.trim()}rs'
                                    : '-- kms x -- rs',
                                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.normal),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Next Button
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

  void _handleNext() {
    if (_pickupLocation == null || _destLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select both pickup location and destination.'),
          backgroundColor: Colors.redAccent,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Pickup and destination must be different places.
    final pickupPoint = _pickupLocation!;
    final destPoint = _destLocation!;
    final samePlaceId = (pickupPoint.placeId ?? '').isNotEmpty &&
        pickupPoint.placeId == destPoint.placeId;
    final sameAddress = pickupPoint.formattedAddress.trim().isNotEmpty &&
        pickupPoint.formattedAddress.trim().toLowerCase() ==
            destPoint.formattedAddress.trim().toLowerCase();
    if (samePlaceId || sameAddress) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pickup and destination cannot be the same place.'),
          backgroundColor: Colors.redAccent,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (_date == null || _selectedDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select date.'),
          backgroundColor: Colors.redAccent,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final maxAllowedDate = today.add(const Duration(days: 30));
    final selectedDateOnly = DateTime(_selectedDateTime!.year, _selectedDateTime!.month, _selectedDateTime!.day);
    if (selectedDateOnly.isBefore(today) || selectedDateOnly.isAfter(maxAllowedDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rides can only be scheduled within the next 30 days.'),
          backgroundColor: Colors.redAccent,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    if (_time == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select start time.'),
          backgroundColor: Colors.redAccent,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final chosenTime = _parseTimeString(_time);
    if (chosenTime != null && _isPastTimeToday(chosenTime)) {
      _showPastTimeMessage();
      return;
    }

    if (_seats == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select available seats.'),
          backgroundColor: Colors.redAccent,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final basePrice = double.tryParse(_basePriceController.text.trim()) ?? 0;
    if (_basePriceController.text.trim().isEmpty || basePrice <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid base price per km.'),
          backgroundColor: Colors.redAccent,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }


    // Check duplicate ride date
    Map<String, dynamic>? duplicateRide;
    for (final ride in _existingDriverRides) {
      final status = (ride['status']?.toString().toLowerCase()) ?? '';
      if (status == 'cancelled' || status == 'completed' || status == 'finished' || status == 'rejected') {
        continue;
      }

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

      if (rideDate != null && _selectedDateTime != null) {
        if (rideDate.year == _selectedDateTime!.year &&
            rideDate.month == _selectedDateTime!.month &&
            rideDate.day == _selectedDateTime!.day) {
          duplicateRide = ride;
          break;
        }
      }
    }

    if (duplicateRide != null) {
      final pickup = (duplicateRide['pickupLocation'] ?? duplicateRide['from'] ?? 'Origin').toString().split(',').first;
      final destination = (duplicateRide['destinationLocation'] ?? duplicateRide['to'] ?? 'Destination').toString().split(',').first;
      final time = duplicateRide['departureTime'] ?? '';

      _showDuplicateRideDialog(
        dateStr: _date ?? '',
        routeSummary: '$pickup ➔ ${time.isNotEmpty ? " ($time)" : ""}',
      );
    } else {
      _navigateToIntermediatePickups();
    }
  }

  void _showDuplicateRideDialog({
    required String dateStr,
    required String routeSummary,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.warning_amber_rounded, color: Colors.amber.shade800, size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Ride Already Scheduled',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You already have a ride scheduled on $dateStr:',
              style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, height: 1.4),
            ),
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
                    child: Text(
                      routeSummary,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Are you sure you want to publish another ride on the same date?',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.3),
            ),
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
                  child: const Text('Change Date', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _navigateToIntermediatePickups();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Proceed Anyway', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _navigateToIntermediatePickups() {
    final basePrice = double.tryParse(_basePriceController.text.trim()) ?? 10.0;
    final finalPricePerSeat = _calculatedPricePerSeat > 0
        ? _calculatedPricePerSeat
        : ((_tripDistanceKm > 0 ? _tripDistanceKm : 10.0) * basePrice).roundToDouble();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DriverIntermediatePickupsScreen(
          pickup: _pickupLocation,
          destination: _destLocation,
          route: _routeResult,
          date: _date,
          selectedDateTime: _selectedDateTime,
          time: _time,
          seats: _seats,
          fare: '₹ ${finalPricePerSeat.toStringAsFixed(0)}',
          luggage: _luggage,
          basePricePerKm: basePrice,
          pricePerSeat: finalPricePerSeat,
        ),
      ),
    );
  }


  Widget _buildLocationCard({
    required String label,
    required String? address,
    required String placeholder,
    required Color iconColor,
  }) {
    final bool isSelected = address != null && address.isNotEmpty;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(Icons.location_on_rounded, color: iconColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFFA1A1A1))),
                const SizedBox(height: 4),
                Text(
                  isSelected ? address : placeholder,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.normal,
                    color: isSelected ? Colors.black : AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const Icon(Icons.search_rounded, size: 18, color: AppColors.textSecondary),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String label, String? value, {String placeholder = '', bool isFullWidth = false, IconData? icon}) {
    final hasValue = value != null && value.isNotEmpty;
    return Container(
      width: isFullWidth ? double.infinity : null,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFFA1A1A1))),
                const SizedBox(height: 4),
                Text(
                  hasValue ? value : placeholder,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.normal,
                    color: hasValue ? Colors.black : AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (icon != null)
            Icon(icon, size: 18, color: AppColors.textSecondary),
        ],
      ),
    );
  }
}