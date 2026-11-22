import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../models/place_location_model.dart';
import '../../../../services/google_maps_service.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/location_autocomplete_picker_modal.dart';
import 'trip_preparation_drivers_screen_102.dart';

class RideSearchMapScreen extends StatefulWidget {
  final String pickup;
  final String destination;
  final String? date;
  final String? time;
  final String? passengers;

  const RideSearchMapScreen({
    super.key,
    this.pickup = '',
    this.destination = '',
    this.date,
    this.time,
    this.passengers,
  });

  @override
  State<RideSearchMapScreen> createState() => _RideSearchMapScreenState();
}

class _RideSearchMapScreenState extends State<RideSearchMapScreen> {
  late final TextEditingController _pickupController;
  late final TextEditingController _destinationController;

  String? _date;
  String? _time;
  String? _passengers;

  LocationPoint? _pickupLocation;
  LocationPoint? _destLocation;

  RouteResult? _routeResult;
  bool _isLoadingRoute = false;

  @override
  void initState() {
    super.initState();
    _pickupController = TextEditingController(text: widget.pickup);
    _destinationController = TextEditingController(text: widget.destination);
    _date = widget.date;
    _time = widget.time;
    _passengers = widget.passengers;
    if (_pickupLocation != null && _destLocation != null) {
      _fetchDirections();
    }
  }

  Future<void> _fetchDirections() async {
    final originPoint = _pickupLocation;
    if (originPoint == null || _destLocation == null) return;
    setState(() {
      _isLoadingRoute = true;
    });

    final result = await GoogleMapsService.getDirections(
      originLat: originPoint.latitude,
      originLng: originPoint.longitude,
      destLat: _destLocation!.latitude,
      destLng: _destLocation!.longitude,
    );

    if (!mounted) return;
    setState(() {
      _isLoadingRoute = false;
      if (result != null) {
        _routeResult = result;
      }
    });
  }

  Future<void> _selectPickupLocation() async {
    final picked = await LocationAutocompletePickerModal.show(
      context,
      title: 'Select Pickup Location',
      initialQuery: _pickupController.text,
    );

    if (picked != null && mounted) {
      setState(() {
        _pickupLocation = picked;
        _pickupController.text = picked.formattedAddress.isNotEmpty ? picked.formattedAddress : picked.name;
      });
      _fetchDirections();
    }
  }

  Future<void> _selectDestinationLocation() async {
    final picked = await LocationAutocompletePickerModal.show(
      context,
      title: 'Select Destination',
      initialQuery: _destinationController.text,
    );

    if (picked != null && mounted) {
      setState(() {
        _destLocation = picked;
        _destinationController.text = picked.formattedAddress.isNotEmpty ? picked.formattedAddress : picked.name;
      });
      _fetchDirections();
    }
  }

  @override
  void dispose() {
    _pickupController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
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
        _date = '${picked.day} ${months[picked.month - 1]} ${picked.year}';
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 30),
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
      final hour = picked.hourOfPeriod == 0 ? 12 : picked.hourOfPeriod;
      final minute = picked.minute.toString().padLeft(2, '0');
      final period = picked.period == DayPeriod.am ? 'AM' : 'PM';
      setState(() {
        _time = '${hour.toString().padLeft(2, '0')}:$minute $period';
      });
    }
  }

  void _selectPassengers(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
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
                  'Select Number of Passengers',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 14),
                ...[1, 2, 3, 4, 5, 6].map((count) {
                  final label = '$count ${count == 1 ? 'Seat' : 'Seats'}';
                  final isSelected = _passengers == label || (_passengers?.startsWith('$count ') ?? false);
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
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
                        fontSize: 15,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? AppColors.primary : AppColors.textPrimary,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle_rounded, color: AppColors.primary)
                        : null,
                    onTap: () {
                      setState(() {
                        _passengers = label;
                      });
                      Navigator.pop(ctx);
                    },
                  );
                }),
              ],
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
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Search',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        elevation: 0,
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
            Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        // Pickup Location Field
                        InkWell(
                          onTap: _selectPickupLocation,
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFAFAFA),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.location_on, color: Color(0xFF4CAF50), size: 22),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Pickup location', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                      const SizedBox(height: 2),
                                      Text(
                                        _pickupController.text.isNotEmpty ? _pickupController.text : 'Select Pickup Location',
                                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.search_rounded, size: 18, color: AppColors.textSecondary),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Destination Field
                        InkWell(
                          onTap: _selectDestinationLocation,
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFAFAFA),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.location_on, color: Color(0xFFE53935), size: 22),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Destination', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                      const SizedBox(height: 2),
                                      Text(
                                        _destinationController.text.isNotEmpty ? _destinationController.text : 'Select Destination',
                                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.search_rounded, size: 18, color: AppColors.textSecondary),
                              ],
                            ),
                          ),
                        ),

                        if (_isLoadingRoute || _routeResult != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3EDF7),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.primary.withAlpha(50)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.directions_car_rounded, color: AppColors.primary, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _isLoadingRoute
                                        ? 'Calculating route...'
                                        : '${_routeResult!.durationText} (${_routeResult!.distanceText})',
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 16),

                        // Date & Time Row
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _selectDate(context),
                                child: _buildPickerCard(title: 'Date', value: _date, placeholder: 'Date', icon: Icons.calendar_month_rounded),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _selectTime(context),
                                child: _buildPickerCard(title: 'Time', value: _time, placeholder: 'Time', icon: Icons.access_time_rounded),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Passengers Card
                        GestureDetector(
                          onTap: () => _selectPassengers(context),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFAFAFA),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Passengers', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                      const SizedBox(height: 4),
                                      Text(
                                        _passengers != null && _passengers!.isNotEmpty ? _passengers! : 'Seats',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: _passengers != null && _passengers!.isNotEmpty ? FontWeight.bold : FontWeight.normal,
                                          color: _passengers != null && _passengers!.isNotEmpty ? AppColors.textPrimary : AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.airline_seat_recline_normal_rounded, color: AppColors.textSecondary, size: 20),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 14),

                      ],
                    ),
                  ),
                ),

                // Bottom Search Ride CTA
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: CustomButton(
                    text: 'Search ride',
                    onPressed: () {
                      final pickupText = _pickupController.text.trim();
                      final destText = _destinationController.text.trim();

                      if (pickupText.isEmpty || destText.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please select pickup location and destination.'),
                            backgroundColor: Colors.redAccent,
                            duration: Duration(seconds: 2),
                          ),
                        );
                        return;
                      }

                      if (_date == null || _date!.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please select date.'),
                            backgroundColor: Colors.redAccent,
                            duration: Duration(seconds: 2),
                          ),
                        );
                        return;
                      }

                      if (_time == null || _time!.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please select time.'),
                            backgroundColor: Colors.redAccent,
                            duration: Duration(seconds: 2),
                          ),
                        );
                        return;
                      }

                      // Passengers/Seats is optional: defaults to '1 Seat' if not specified
                      final selectedPassengers = (_passengers != null && _passengers!.trim().isNotEmpty)
                          ? _passengers!.trim()
                          : '1 Seat';

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TripPreparationDriversScreen(
                            pickup: pickupText,
                            destination: destText,
                            date: _date ?? '',
                            time: _time ?? '',
                            passengers: selectedPassengers,
                            doorstepPickup: null,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPickerCard({required String title, required String? value, String placeholder = '', IconData? icon}) {
    final hasValue = value != null && value.isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                Text(
                  hasValue ? value : placeholder,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: hasValue ? FontWeight.bold : FontWeight.normal,
                    color: hasValue ? AppColors.textPrimary : AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (icon != null)
            Icon(icon, size: 16, color: AppColors.textSecondary),
        ],
      ),
    );
  }
}
