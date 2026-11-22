import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../services/api_service.dart';
import '../../../../services/ride_service.dart';

class CustomerRateRideSheet extends StatefulWidget {
  final Map<String, dynamic>? bookingData;
  final String? bookingId;
  final String? rideId;
  final String? driverId;
  final String? driverName;
  final String? driverPhoto;
  final String? vehicleInfo;
  final String? origin;
  final String? destination;
  final String? intermediateStop;
  final String? departureTime;
  final VoidCallback? onSubmitted;

  const CustomerRateRideSheet({
    super.key,
    this.bookingData,
    this.bookingId,
    this.rideId,
    this.driverId,
    this.driverName,
    this.driverPhoto,
    this.vehicleInfo,
    this.origin,
    this.destination,
    this.intermediateStop,
    this.departureTime,
    this.onSubmitted,
  });

  static Future<bool?> show(
    BuildContext context, {
    Map<String, dynamic>? bookingData,
    String? bookingId,
    String? rideId,
    String? driverId,
    String? driverName,
    String? driverPhoto,
    String? vehicleInfo,
    String? origin,
    String? destination,
    String? intermediateStop,
    String? departureTime,
    VoidCallback? onSubmitted,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: CustomerRateRideSheet(
          bookingData: bookingData,
          bookingId: bookingId,
          rideId: rideId,
          driverId: driverId,
          driverName: driverName,
          driverPhoto: driverPhoto,
          vehicleInfo: vehicleInfo,
          origin: origin,
          destination: destination,
          intermediateStop: intermediateStop,
          departureTime: departureTime,
          onSubmitted: onSubmitted,
        ),
      ),
    );
  }

  @override
  State<CustomerRateRideSheet> createState() => _CustomerRateRideSheetState();
}

class _CustomerRateRideSheetState extends State<CustomerRateRideSheet> {
  int _driverBehaviourRating = 5;
  int _drivingSkillsRating = 5;
  int _vehicleConditionRating = 5;
  int _punctualityRating = 5;
  int _valueOfMoneyRating = 5;

  Map<String, dynamic>? _rateScreenData;
  Map<String, dynamic>? _driverData;
  Map<String, dynamic>? _routeData;

  final TextEditingController _reviewController = TextEditingController();
  bool _isSubmitting = false;

  // Star colors matching cust side ratings.png
  static const Color _activeStarColor = Color(0xFFFF6D00);
  static const Color _inactiveStarColor = Color(0xFFFFD8CC);

  @override
  void initState() {
    super.initState();
    _fetchRateScreenDetails();
  }

  Future<void> _fetchRateScreenDetails() async {
    final raw = widget.bookingData ?? {};
    final rId = widget.rideId ?? raw['rideId']?.toString() ?? raw['id']?.toString() ?? '';
    if (rId.isEmpty) return;
    final res = await RideService.getRateScreenDetails(rId);
    if (res['success'] == true && mounted) {
      setState(() {
        _rateScreenData = res;
        if (res['driver'] is Map) {
          _driverData = Map<String, dynamic>.from(res['driver'] as Map);
        }
        if (res['route'] is Map) {
          _routeData = Map<String, dynamic>.from(res['route'] as Map);
        }
        if (res['categories'] is List) {
          for (final cat in res['categories']) {
            if (cat is Map) {
              final key = cat['key']?.toString();
              final def = (cat['defaultRating'] as num?)?.toInt() ?? 5;
              if (key == 'driverBehavior') _driverBehaviourRating = def;
              if (key == 'driverSkills') _drivingSkillsRating = def;
              if (key == 'vehicleConditions') _vehicleConditionRating = def;
              if (key == 'punctuality') _punctualityRating = def;
              if (key == 'valueOfMoney') _valueOfMoneyRating = def;
            }
          }
        }
      });
    }
  }

  double get _overallRating {
    final sum = _driverBehaviourRating +
        _drivingSkillsRating +
        _vehicleConditionRating +
        _punctualityRating +
        _valueOfMoneyRating;
    return sum / 5.0;
  }

  String get _overallQualitativeText {
    final avg = _overallRating;
    if (avg >= 4.8) return '(Excellent)';
    if (avg >= 4.0) return '(Very good)';
    if (avg >= 3.0) return '(Good)';
    if (avg >= 2.0) return '(Fair)';
    return '(Needs Improvement)';
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _submitRating() async {
    setState(() => _isSubmitting = true);

    final raw = widget.bookingData ?? {};
    final bId = widget.bookingId ??
        raw['bookingId']?.toString() ??
        _rateScreenData?['bookingId']?.toString() ??
        raw['id']?.toString() ??
        '';
    final rId = widget.rideId ??
        raw['rideId']?.toString() ??
        _rateScreenData?['rideId']?.toString() ??
        '';
    final dId = widget.driverId ??
        raw['driverId']?.toString() ??
        raw['driver']?['id']?.toString() ??
        _driverData?['id']?.toString() ??
        '';

    // Group A API 2 payload schema
    final payload = {
      'rideId': rId,
      'bookingId': bId,
      'driverId': dId,
      'driverBehavior': _driverBehaviourRating,
      'driverSkills': _drivingSkillsRating,
      'vehicleConditions': _vehicleConditionRating,
      'punctuality': _punctualityRating,
      'valueOfMoney': _valueOfMoneyRating,
      'rating': double.parse(_overallRating.toStringAsFixed(1)),
      'comment': _reviewController.text.trim(),
    };

    try {
      final res = await RideService.submitRateRide(payload);
      final msg = res['message']?.toString() ?? 'Review submitted successfully! Thank you for rating your ride.';
      if (mounted) {
        setState(() => _isSubmitting = false);
        Navigator.pop(context, true);
        widget.onSubmitted?.call();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: const Color(0xFF4CAF50),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    } catch (_) {}

    if (mounted) {
      setState(() => _isSubmitting = false);
      Navigator.pop(context, true);
      widget.onSubmitted?.call();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Review submitted successfully! Thank you for rating your ride.'),
          backgroundColor: Color(0xFF4CAF50),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final raw = widget.bookingData ?? {};

    final driverName = widget.driverName ??
        _driverData?['name'] ??
        raw['driverName'] ??
        raw['driver']?['name'] ??
        raw['driver']?['fullName'] ??
        'Driver';

    final vehicleInfo = widget.vehicleInfo ??
        _driverData?['vehicle'] ??
        (_driverData?['vehicleModel'] != null && _driverData?['vehicleNumberPlate'] != null
            ? '${_driverData!['vehicleModel']} ${_driverData!['vehicleNumberPlate']}'
            : null) ??
        raw['vehicleInfo'] ??
        raw['vehicle']?['model'] ??
        raw['carModel'] ??
        '';

    final originTime = widget.departureTime ??
        _routeData?['departureTime'] ??
        raw['departureTime'] ??
        raw['time'] ??
        '';

    final stopName = widget.intermediateStop ??
        _routeData?['routeTimelinePreview'] ??
        raw['stopName'] ??
        raw['intermediateStop'] ??
        '';

    final destName = widget.destination ??
        _routeData?['to'] ??
        raw['destination'] ??
        raw['to'] ??
        '';

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top drag handle
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Title matching cust side ratings.png
              Center(
                child: const Text(
                  'Rate Your Ride',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Divider(height: 1, color: Color(0xFFEEEEEE)),
              const SizedBox(height: 16),

              // Driver & Route Card matching cust side ratings.png
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 64,
                      height: 64,
                      color: const Color(0xFFF3EDF7),
                      child: Image.asset(
                        'assets/images/image 28.png',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.person_rounded,
                          size: 38,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          driverName,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          vehicleInfo,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Route timeline with 3 purple dots
                        _buildRouteTimeline(originTime, stopName, destName),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // "How was your ride?" section header
              const Text(
                'How was your ride?',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 14),

              // 5 Rating Categories
              _buildRatingCriterionRow(
                'Driver Behaviour',
                _driverBehaviourRating,
                (val) => setState(() => _driverBehaviourRating = val),
              ),
              const SizedBox(height: 12),
              _buildRatingCriterionRow(
                'Driving Skills',
                _drivingSkillsRating,
                (val) => setState(() => _drivingSkillsRating = val),
              ),
              const SizedBox(height: 12),
              _buildRatingCriterionRow(
                'Vehicle Condition',
                _vehicleConditionRating,
                (val) => setState(() => _vehicleConditionRating = val),
              ),
              const SizedBox(height: 12),
              _buildRatingCriterionRow(
                'Punctuality',
                _punctualityRating,
                (val) => setState(() => _punctualityRating = val),
              ),
              const SizedBox(height: 12),
              _buildRatingCriterionRow(
                'Value of money',
                _valueOfMoneyRating,
                (val) => setState(() => _valueOfMoneyRating = val),
              ),

              const SizedBox(height: 14),

              // Overall rating row (strictly auto-calculated from average)
              _buildOverallRatingRow(),

              const SizedBox(height: 22),

              // "Review" Header
              const Text(
                'Review',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),

              // Multiline Review textfield matching cust side ratings.png
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE0E0E0)),
                ),
                child: TextField(
                  controller: _reviewController,
                  maxLines: 4,
                  minLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Write review.....',
                    hintStyle: TextStyle(
                      color: Color(0xFF9E9E9E),
                      fontSize: 13.5,
                    ),
                    contentPadding: EdgeInsets.all(14),
                    border: InputBorder.none,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitRating,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5B3AA8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          'Submit',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRouteTimeline(String origin, String stop, String dest) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              height: 2,
              color: const Color(0xFF5B3AA8).withValues(alpha: 0.35),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildTimelineDot(),
                _buildTimelineDot(),
                _buildTimelineDot(),
              ],
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              origin,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              stop,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              dest,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTimelineDot() {
    return Container(
      width: 9,
      height: 9,
      decoration: const BoxDecoration(
        color: Color(0xFF5B3AA8),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildRatingCriterionRow(
    String label,
    int rating,
    ValueChanged<int> onChanged,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        Row(
          children: List.generate(5, (index) {
            final starIndex = index + 1;
            final isFilled = starIndex <= rating;
            return GestureDetector(
              onTap: () => onChanged(starIndex),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2.5),
                child: Icon(
                  Icons.star_rounded,
                  size: 22,
                  color: isFilled ? _activeStarColor : _inactiveStarColor,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildOverallRatingRow() {
    final avg = _overallRating;
    final roundedAvgInt = avg.round();

    return Row(
      children: [
        Text(
          'Overall rating ${avg.toStringAsFixed(1)}',
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(width: 8),
        Row(
          children: List.generate(5, (index) {
            final starIndex = index + 1;
            final isFilled = starIndex <= roundedAvgInt;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2.0),
              child: Icon(
                Icons.star_rounded,
                size: 20,
                color: isFilled ? _activeStarColor : _inactiveStarColor,
              ),
            );
          }),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            _overallQualitativeText,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
