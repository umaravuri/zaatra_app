import 'package:flutter/material.dart';
import '../../services/customer_location_tracking_service.dart';

/// Top orange banner displayed 30 minutes before ride pickup if location sharing is disabled.
/// Replicates the Uber-style reference bar with crosshair target icon, text, and chevron.
class CustomerLocationSharingBanner extends StatefulWidget {
  const CustomerLocationSharingBanner({super.key});

  @override
  State<CustomerLocationSharingBanner> createState() =>
      _CustomerLocationSharingBannerState();
}

class _CustomerLocationSharingBannerState
    extends State<CustomerLocationSharingBanner> with WidgetsBindingObserver {
  final CustomerLocationTrackingService _trackingService =
      CustomerLocationTrackingService.instance;

  bool _shouldShow = false;
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _trackingService.addListener(_handleServiceUpdate);
    _evaluateVisibility();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _trackingService.removeListener(_handleServiceUpdate);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Re-evaluate whenever the user returns to the app (e.g. from System Settings)
      _evaluateVisibility();
    }
  }

  void _handleServiceUpdate() {
    if (mounted) {
      _evaluateVisibility();
    }
  }

  Future<void> _evaluateVisibility() async {
    if (_isChecking) return;
    _isChecking = true;
    try {
      final show = await _trackingService.shouldShowLocationBanner();
      if (mounted && _shouldShow != show) {
        setState(() {
          _shouldShow = show;
        });
      }
    } finally {
      _isChecking = false;
    }
  }

  Future<void> _onTapBanner() async {
    // Show confirmation dialog before prompting system permissions
    final shouldProceed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.location_on_rounded, color: Color(0xFFF57C00), size: 24),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Share Pickup Location',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
            ),
          ],
        ),
        content: const Text(
          'Your ride starts in less than 30 minutes. Enable location so your driver can navigate directly to your exact pickup spot.',
          style: TextStyle(
            fontSize: 14,
            height: 1.4,
            color: Color(0xFF64748B),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Not Now',
              style: TextStyle(
                color: Color(0xFF94A3B8),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF57C00),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Enable Location',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (shouldProceed == true) {
      final success = await _trackingService.enableLocationAndStartSharing();
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Live location sharing enabled for your driver.'),
              backgroundColor: Color(0xFF2E7D32),
              duration: Duration(seconds: 3),
            ),
          );
        }
        await _evaluateVisibility();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_shouldShow) {
      return const SizedBox.shrink();
    }

    return SafeArea(
      bottom: false,
      child: Material(
        color: const Color(0xFFF57C00),
        child: InkWell(
        onTap: _onTapBanner,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Circular GPS target icon matching reference
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.5),
                ),
                child: const Icon(
                  Icons.my_location_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              // Option 2 Banner text
              const Expanded(
                child: Text(
                  'Share location with driver. Tap here to enable',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.1,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Trailing chevron
              const Icon(
                Icons.chevron_right_rounded,
                color: Colors.white,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    ),
  );
  }
}
