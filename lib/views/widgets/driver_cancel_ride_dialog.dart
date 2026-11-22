import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class DriverCancelRideDialog extends StatefulWidget {
  final String origin;
  final String destination;
  final String date;
  final String? time;
  final String? rideId;

  const DriverCancelRideDialog({
    Key? key,
    required this.origin,
    required this.destination,
    required this.date,
    this.time,
    this.rideId,
  }) : super(key: key);

  static Future<String?> show(
    BuildContext context, {
    required String origin,
    required String destination,
    required String date,
    String? time,
    String? rideId,
  }) {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => DriverCancelRideDialog(
        origin: origin,
        destination: destination,
        date: date,
        time: time,
        rideId: rideId,
      ),
    );
  }

  @override
  State<DriverCancelRideDialog> createState() => _DriverCancelRideDialogState();
}

class _DriverCancelRideDialogState extends State<DriverCancelRideDialog> {
  final List<String> _presetReasons = [
    'Vehicle breakdown / Mechanical issue',
    'Personal emergency / Health issue',
    'Severe weather / Road blockage',
    'Schedule conflict / Accidental posting',
    'Other reason',
  ];

  late String _selectedReason;
  final TextEditingController _customReasonController = TextEditingController();
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedReason = _presetReasons.first;
  }

  @override
  void dispose() {
    _customReasonController.dispose();
    super.dispose();
  }

  void _onConfirm() {
    setState(() => _errorMessage = null);

    String finalReason = _selectedReason;
    if (_selectedReason == 'Other reason') {
      final customText = _customReasonController.text.trim();
      if (customText.isEmpty) {
        setState(() => _errorMessage = 'Please describe why you are cancelling.');
        return;
      }
      finalReason = customText;
    } else {
      final additional = _customReasonController.text.trim();
      if (additional.isNotEmpty) {
        finalReason = '$_selectedReason ($additional)';
      }
    }

    Navigator.pop(context, finalReason);
  }

  @override
  Widget build(BuildContext context) {
    final cleanOrigin = widget.origin.split(',').first.trim();
    final cleanDest = widget.destination.split(',').first.trim();
    final timeStr = widget.time != null && widget.time!.isNotEmpty ? ' at ${widget.time}' : '';

    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.cancel_rounded, color: Colors.red, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cancel Ride',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$cleanOrigin → $cleanDest • ${widget.date}$timeStr',
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w400,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Please select a reason for cancelling:',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),

              // Preset reasons
              ..._presetReasons.map((reason) {
                final isSelected = _selectedReason == reason;
                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedReason = reason;
                      _errorMessage = null;
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Icon(
                          isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                          size: 18,
                          color: isSelected ? Colors.red : Colors.grey.shade400,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            reason,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w400,
                              color: isSelected ? AppColors.textPrimary : Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),

              const SizedBox(height: 10),

              // Custom explanation / details field
              Text(
                _selectedReason == 'Other reason'
                    ? 'Specify reason (required):'
                    : 'Additional remarks (optional):',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: _selectedReason == 'Other reason' ? Colors.red : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              TextField(
                controller: _customReasonController,
                maxLines: 2,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: _selectedReason == 'Other reason'
                      ? 'e.g. Family emergency, tyre puncture...'
                      : 'Add any specific notes for passengers...',
                  hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  filled: true,
                  fillColor: const Color(0xFFF9F8FD),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: _errorMessage != null ? Colors.red : const Color(0xFFE5E2F0),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: _errorMessage != null ? Colors.red : const Color(0xFFE5E2F0),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: _errorMessage != null ? Colors.red : Colors.red,
                      width: 1.5,
                    ),
                  ),
                ),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 4),
                Text(
                  _errorMessage!,
                  style: const TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.bold),
                ),
              ],

              const SizedBox(height: 12),

              // Passenger Impact Advisory
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFFE082)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Icon(Icons.info_outline_rounded, color: Color(0xFFE65100), size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'All booked co-travelers will be notified immediately about this cancellation.',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF795548),
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text(
            'Keep Ride',
            style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
          ),
        ),
        ElevatedButton(
          onPressed: _onConfirm,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          ),
          child: const Text(
            'Confirm Cancellation',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
