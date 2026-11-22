import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../services/ride_service.dart';
import '../../../../services/driver_service.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/driver_decline_reason_modal.dart';

class IncomingRideRequestDialog extends StatefulWidget {
  final String? passengerName;
  final String? passengerRating;
  final String? pickupAddress;
  final String? dropoffAddress;
  final String? offeredFare;
  final int seats;
  final String? bookingId;
  final String? rideId;
  final ValueChanged<String>? onDeclineWithReason;
  final VoidCallback? onAccepted;

  const IncomingRideRequestDialog({
    Key? key,
    this.passengerName,
    this.passengerRating,
    this.pickupAddress,
    this.dropoffAddress,
    this.offeredFare,
    this.seats = 1,
    this.bookingId,
    this.rideId,
    this.onDeclineWithReason,
    this.onAccepted,
  }) : super(key: key);

  static Future<bool?> show(
    BuildContext context, {
    required String bookingId,
    String? rideId,
    required String passengerName,
    String passengerRating = '4.9 (42 rides)',
    required String pickupAddress,
    required String dropoffAddress,
    required String offeredFare,
    int seats = 1,
    ValueChanged<String>? onDeclineWithReason,
    VoidCallback? onAccepted,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => IncomingRideRequestDialog(
        bookingId: bookingId,
        rideId: rideId,
        passengerName: passengerName,
        passengerRating: passengerRating,
        pickupAddress: pickupAddress,
        dropoffAddress: dropoffAddress,
        offeredFare: offeredFare,
        seats: seats,
        onDeclineWithReason: onDeclineWithReason,
        onAccepted: onAccepted,
      ),
    );
  }

  @override
  State<IncomingRideRequestDialog> createState() => _IncomingRideRequestDialogState();
}

class _IncomingRideRequestDialogState extends State<IncomingRideRequestDialog> {
  bool _isActioning = false;

  Future<void> _handleAccept() async {
    setState(() => _isActioning = true);
    if (widget.bookingId != null && widget.bookingId!.isNotEmpty) {
      try {
        await RideService.respondToBookingRequest(
          bookingId: widget.bookingId!,
          action: 'accept',
        );
      } catch (_) {}
    }

    if (mounted) {
      setState(() => _isActioning = false);
      Navigator.pop(context, true);
      widget.onAccepted?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ride request accepted successfully!'),
          backgroundColor: Color(0xFF2E7D32),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _handleDecline() async {
    final reason = await DriverDeclineReasonModal.show(
      context,
      passengerName: widget.passengerName ?? 'Passenger',
    );

    if (reason != null && mounted) {
      setState(() => _isActioning = true);
      if (widget.bookingId != null && widget.bookingId!.isNotEmpty) {
        try {
          await DriverService.declineBookingRequest(
            bookingId: widget.bookingId!,
            reason: reason,
          );
        } catch (_) {}
      }

      if (mounted) {
        setState(() => _isActioning = false);
        Navigator.pop(context, false);
        widget.onDeclineWithReason?.call(reason);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayName = widget.passengerName?.isNotEmpty == true ? widget.passengerName! : 'Sarah Ahmed';
    final displayRating = widget.passengerRating?.isNotEmpty == true ? widget.passengerRating! : '4.9 (42 rides)';
    final displayFare = widget.offeredFare?.isNotEmpty == true ? widget.offeredFare! : '₹250';
    final displayPickup = widget.pickupAddress?.isNotEmpty == true ? widget.pickupAddress! : 'Current Route Pickup';
    final displayDropoff = widget.dropoffAddress?.isNotEmpty == true ? widget.dropoffAddress! : 'Passenger Destination';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row matching Screen 31
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accentLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'NEW RIDE REQUEST ⚡',
                    style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${widget.seats} ${widget.seats == 1 ? "seat" : "seats"}',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.error, fontSize: 11.5),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Passenger Info matching Screen 31
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.primaryBackground,
                  child: const Icon(Icons.person_rounded, color: AppColors.primary, size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, color: AppColors.accent, size: 16),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              displayRating,
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Text(
                  displayFare,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ],
            ),

            const Divider(height: 24, color: AppColors.border),

            // Pickup & Dropoff Addresses matching Screen 31
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.my_location_rounded, color: AppColors.primary, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    displayPickup,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on_rounded, color: AppColors.accent, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    displayDropoff,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Decline & Accept Action Buttons matching Screen 31
            if (_isActioning)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      text: 'Decline',
                      isOutlined: true,
                      backgroundColor: AppColors.error,
                      textColor: AppColors.error,
                      onPressed: _handleDecline,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomButton(
                      text: 'Accept Ride',
                      backgroundColor: AppColors.success,
                      onPressed: _handleAccept,
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
