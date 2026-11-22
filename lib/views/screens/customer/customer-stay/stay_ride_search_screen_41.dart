import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import 'stay_search_results_screen_45.dart';

class StayRideSearchScreen extends StatefulWidget {
  final String? initialDestination;
  final DateTime? initialCheckIn;
  final DateTime? initialCheckOut;

  const StayRideSearchScreen({
    Key? key,
    this.initialDestination,
    this.initialCheckIn,
    this.initialCheckOut,
  }) : super(key: key);

  @override
  State<StayRideSearchScreen> createState() => _StayRideSearchScreenState();
}

class _StayRideSearchScreenState extends State<StayRideSearchScreen> {
  late final TextEditingController _destinationController;
  late DateTime _checkInDate;
  late DateTime _checkOutDate;

  int _rooms = 4;
  int _adults = 4;
  int _childrens = 1;
  bool _travellingWithPets = false;

  @override
  void initState() {
    super.initState();
    _destinationController = TextEditingController(
      text: widget.initialDestination ?? 'Goa, India',
    );
    _checkInDate = widget.initialCheckIn ?? DateTime(2026, 8, 12);
    _checkOutDate = widget.initialCheckOut ?? DateTime(2026, 8, 15);
  }

  @override
  void dispose() {
    _destinationController.dispose();
    super.dispose();
  }

  String _formatDateRange() {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    final inDay = _checkInDate.day;
    final inMonth = months[_checkInDate.month - 1];
    final outDay = _checkOutDate.day;
    final outMonth = months[_checkOutDate.month - 1];
    final outWeekday = days[_checkOutDate.weekday - 1];

    return '$inDay $inMonth, Aug - $outWeekday $outDay $outMonth, Aug';
  }

  String _formatDateShort(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]}';
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: now.isBefore(_checkInDate) ? now : _checkInDate.subtract(const Duration(days: 30)),
      lastDate: DateTime(2028),
      initialDateRange: DateTimeRange(
        start: _checkInDate,
        end: _checkOutDate,
      ),
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
      setState(() {
        _checkInDate = picked.start;
        _checkOutDate = picked.end;
      });
    }
  }

  void _showPetsPolicyDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.pets_rounded, color: AppColors.primary),
            SizedBox(width: 8),
            Text(
              'Travelling with Pets',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Text(
          'Most Zaatra partner stays welcome domestic pets. Please ensure up-to-date vaccinations, carry pet essentials, and confirm specific pet deposits or size limitations directly with your host before arrival.',
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Understood', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _executeSearch() {
    final dest = _destinationController.text.trim();
    final queryCity = dest.isEmpty ? 'Goa, India' : dest;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StaySearchResultsScreen(
          destinationCity: queryCity,
          checkInDate: _formatDateShort(_checkInDate),
          checkOutDate: _formatDateShort(_checkOutDate),
          guestsSummary: '$_adults guest, $_childrens child, $_rooms room',
          roomsCount: _rooms,
          adultsCount: _adults,
          childrenCount: _childrens,
          hasPets: _travellingWithPets,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Stay',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        backgroundColor: AppColors.primary,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: const Color(0xFFEAE7F2)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Destination Field
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _buildCircularBadge(Icons.location_on_outlined),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Destination',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                TextField(
                                  controller: _destinationController,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                  decoration: const InputDecoration(
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                    border: InputBorder.none,
                                    hintText: 'Enter city or property',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Divider(height: 1, thickness: 1, color: Color(0xFFF0EFF5)),
                      ),

                      // 2. Dates Field (Tappable Range Picker)
                      GestureDetector(
                        onTap: _pickDateRange,
                        behavior: HitTestBehavior.opaque,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            _buildCircularBadge(Icons.calendar_month_outlined),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Dates',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatDateRange(),
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Divider(height: 1, thickness: 1, color: Color(0xFFF0EFF5)),
                      ),

                      // 3. Guests Summary Field
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _buildCircularBadge(Icons.person_outline_rounded),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Guests',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$_rooms Rooms , $_adults Adults , $_childrens childrens',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Divider(height: 1, thickness: 1, color: Color(0xFFF0EFF5)),
                      ),

                      // 4. Steppers for Rooms, Adults, Children's
                      _buildStepperRow(
                        label: 'Rooms',
                        count: _rooms,
                        onDecrement: _rooms > 1
                            ? () => setState(() => _rooms--)
                            : null,
                        onIncrement: () => setState(() => _rooms++),
                      ),
                      const SizedBox(height: 16),
                      _buildStepperRow(
                        label: 'Adults',
                        count: _adults,
                        onDecrement: _adults > 1
                            ? () => setState(() => _adults--)
                            : null,
                        onIncrement: () => setState(() => _adults++),
                      ),
                      const SizedBox(height: 16),
                      _buildStepperRow(
                        label: "Children's",
                        count: _childrens,
                        onDecrement: _childrens > 0
                            ? () => setState(() => _childrens--)
                            : null,
                        onIncrement: () => setState(() => _childrens++),
                      ),

                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Divider(height: 1, thickness: 1, color: Color(0xFFF0EFF5)),
                      ),

                      // 5. Travelling with Pets Toggle
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Travelling with pets',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Switch(
                            value: _travellingWithPets,
                            activeColor: AppColors.primary,
                            activeTrackColor: AppColors.primary.withValues(alpha: 0.35),
                            inactiveThumbColor: Colors.white,
                            inactiveTrackColor: Colors.grey.shade300,
                            onChanged: (val) {
                              setState(() => _travellingWithPets = val);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      GestureDetector(
                        onTap: _showPetsPolicyDialog,
                        child: const Text(
                          'Read more abouts travelling with animals',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom Primary Search CTA
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _executeSearch,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                  ),
                  child: const Text(
                    'Search',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircularBadge(IconData icon) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: AppColors.primaryBackground,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
      ),
      child: Center(
        child: Icon(icon, color: AppColors.primary, size: 21),
      ),
    );
  }

  Widget _buildStepperRow({
    required String label,
    required int count,
    required VoidCallback? onDecrement,
    required VoidCallback onIncrement,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        Row(
          children: [
            GestureDetector(
              onTap: onDecrement,
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: onDecrement != null ? AppColors.primary : Colors.grey.shade300,
                    width: 1.2,
                  ),
                  color: onDecrement != null ? Colors.white : Colors.grey.shade100,
                ),
                child: Center(
                  child: Icon(
                    Icons.remove,
                    size: 16,
                    color: onDecrement != null ? AppColors.primary : Colors.grey.shade400,
                  ),
                ),
              ),
            ),
            SizedBox(
              width: 36,
              child: Text(
                '$count',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            GestureDetector(
              onTap: onIncrement,
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary, width: 1.2),
                  color: Colors.white,
                ),
                child: const Center(
                  child: Icon(Icons.add, size: 16, color: AppColors.primary),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}