import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../services/ride_service.dart';
import 'driver_decline_reason_modal.dart';

class DriverDetourDecisionDialog extends StatefulWidget {
  final String requestId;
  final String rideId;
  final String passengerName;
  final String passengerPhone;
  final String pickupLocation;
  final String dropLocation;
  final double detourDistanceKm;
  final double detourRatePerKm;
  final String estimatedDetourTime;
  final VoidCallback? onDecisionSubmitted;

  const DriverDetourDecisionDialog({
    super.key,
    required this.requestId,
    required this.rideId,
    required this.passengerName,
    this.passengerPhone = '',
    required this.pickupLocation,
    required this.dropLocation,
    required this.detourDistanceKm,
    this.detourRatePerKm = 12.0,
    this.estimatedDetourTime = '15 mins',
    this.onDecisionSubmitted,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String requestId,
    required String rideId,
    required String passengerName,
    String passengerPhone = '',
    required String pickupLocation,
    required String dropLocation,
    required double detourDistanceKm,
    double detourRatePerKm = 12.0,
    String estimatedDetourTime = '15 mins',
    VoidCallback? onDecisionSubmitted,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => DriverDetourDecisionDialog(
        requestId: requestId,
        rideId: rideId,
        passengerName: passengerName,
        passengerPhone: passengerPhone,
        pickupLocation: pickupLocation,
        dropLocation: dropLocation,
        detourDistanceKm: detourDistanceKm,
        detourRatePerKm: detourRatePerKm,
        estimatedDetourTime: estimatedDetourTime,
        onDecisionSubmitted: onDecisionSubmitted,
      ),
    );
  }

  @override
  State<DriverDetourDecisionDialog> createState() => _DriverDetourDecisionDialogState();
}

class _DriverDetourDecisionDialogState extends State<DriverDetourDecisionDialog> {
  bool _isSubmitting = false;

  double get _calculatedExtraFare =>
      (widget.detourDistanceKm * widget.detourRatePerKm).roundToDouble();

  Future<void> _handleAccept() async {
    setState(() => _isSubmitting = true);
    try {
      final res = await RideService.respondToDetourRequest(
        requestId: widget.requestId,
        rideId: widget.rideId,
        decision: 'accept',
        extraFare: _calculatedExtraFare,
      );

      if (mounted) {
        setState(() => _isSubmitting = false);
        Navigator.pop(context, true);
        widget.onDecisionSubmitted?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.success,
            content: Text(
              res['message']?.toString() ??
                  'Detour accepted! Extra fare of ₹${_calculatedExtraFare.toInt()} added.',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to accept detour: $e')),
        );
      }
    }
  }

  Future<void> _handleDecline() async {
    final reason = await DriverDeclineReasonModal.show(
      context,
      passengerName: widget.passengerName,
      reasons: const [
        'Detour exceeds preferred driving radius',
        'Pickup location inaccessible or poor road',
        'Schedule conflict / strict arrival time',
        'Detour compensation insufficient',
        'Other reason',
      ],
    );

    if (reason == null) return; // User cancelled modal

    setState(() => _isSubmitting = true);
    try {
      final res = await RideService.respondToDetourRequest(
        requestId: widget.requestId,
        rideId: widget.rideId,
        decision: 'decline',
        reason: reason,
      );

      if (mounted) {
        setState(() => _isSubmitting = false);
        Navigator.pop(context, false);
        widget.onDecisionSubmitted?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              res['message']?.toString() ?? 'Detour request declined.',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to decline detour: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(22.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Badge & Title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDE7F6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.alt_route_rounded, size: 14, color: AppColors.primary),
                      SizedBox(width: 4),
                      Text(
                        'DOORSTEP DETOUR 📍',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '+${widget.detourDistanceKm.toStringAsFixed(1)} km',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE65100),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Passenger Info Row
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.primaryBackground,
                  child: const Icon(Icons.person_rounded, color: AppColors.primary, size: 26),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.passengerName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Doorstep Pickup / Drop Requested',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(height: 1, color: Color(0xFFEEEEEE)),
            const SizedBox(height: 14),

            // Route & Detour Breakdown Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFAFAFA),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE0E0E0)),
              ),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.radio_button_checked, size: 16, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.pickupLocation,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 7.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        width: 2,
                        height: 18,
                        color: Colors.grey[300],
                      ),
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on, size: 16, color: AppColors.error),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.dropLocation,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Extra Fare & Time Incentive Callout
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F8E9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFC5E1A5)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.currency_rupee_rounded, size: 18, color: Color(0xFF2E7D32)),
                      const SizedBox(width: 6),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Detour Extra Compensation',
                            style: TextStyle(fontSize: 11, color: Color(0xFF33691E)),
                          ),
                          Text(
                            '+₹${_calculatedExtraFare.toInt()}',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1B5E20),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.timer_outlined, size: 16, color: Color(0xFF558B2F)),
                      const SizedBox(width: 4),
                      Text(
                        '+${widget.estimatedDetourTime}',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF33691E),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            // Action Buttons
            if (_isSubmitting)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFE57373)),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _handleDecline,
                      child: const Text(
                        'Decline Detour',
                        style: TextStyle(
                          color: Color(0xFFD32F2F),
                          fontWeight: FontWeight.bold,
                          fontSize: 13.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _handleAccept,
                      child: Text(
                        'Accept (+₹${_calculatedExtraFare.toInt()})',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
