import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/navigation/app_navigator.dart';
import '../../../../services/api_service.dart';
import '../../../../services/driver_service.dart';
import 'driver_booking_requests_screen_99.dart';
import 'driver_messages_screen_88246846.dart';
import 'driver_notifications_screen_13.dart';
import 'driver_ratings_reviews_screen_113.dart';
import 'driver_earnings_history_screen_82.dart';
import 'driver_my_ride_screen_30.dart';
import 'driver_profile_settings_screen_87.dart';
import 'driver_ride_review_screen_87.dart';
import 'driver_ride_management_screen_98.dart';
import 'driver_ride_start_details_screen_88.dart';
import 'driver_support_help_screen_86.dart';
import 'driver_trip_shared_screen_94.dart';
import 'incoming_ride_request_dialog_31.dart';
import '../driver-onboarding/driver_vehicle_info_screen_35.dart';

class DriverHomeDashboardScreen83 extends StatefulWidget {
  static const String routeName = AppRoutes.driverHome;
  final String? driverName;

  const DriverHomeDashboardScreen83({
    super.key,
    this.driverName,
  });

  @override
  State<DriverHomeDashboardScreen83> createState() =>
      _DriverHomeDashboardScreen83State();
}

class _DriverHomeDashboardScreen83State
    extends State<DriverHomeDashboardScreen83> with WidgetsBindingObserver {
  String _name = 'Driver';
  String _driverPhone = '';
  // A driver starts active (online); the server value or their last saved choice overrides this.
  bool _isOnline = true;
  bool _isTogglingOnline = false;
  bool _appInForeground = true;
  int _currentNavIndex = 0;
  int _unreadNotificationCount = 0;
  Timer? _notificationPollTimer;

  // Profile Photo State (Fetched dynamically from GET APIs)
  String? _profileImageUrl;
  Uint8List? _profileImageBytes;

  // Dynamic Driver Statistics (clean zero state for first-time login)
  String _ridesCount = '0';
  String _coTravelers = '0';
  String _totalKm = '0';
  String _rating = 'New';

  // Dynamic Summaries
  String _todayComplete = '0';
  String _todayUpcoming = '0';
  String _todayFuelShare = '₹0';
  String _monthlyCompleted = '0';
  String _monthlyFuelShare = '₹0';

  // Dynamic Upcoming Ride State
  String _upcomingOrigin = '-';
  String _upcomingOriginTime = '-';
  String _upcomingDestination = '-';
  String _upcomingDestinationTime = '-';
  String _upcomingDateStr = '-';
  String _upcomingRideId = '';
  bool _hasUpcomingRide = false;

  // Active incoming booking tracking
  final Set<String> _seenIncomingBookingIds = {};
  bool _isCheckingIncomingAlerts = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadDriverProfile();
    _startNotificationPolling();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _notificationPollTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final inForeground = state == AppLifecycleState.resumed;
    if (inForeground == _appInForeground) return;
    _appInForeground = inForeground;
    if (inForeground && mounted) {
      // Catch up straight away after coming back to the app.
      _fetchUnreadNotificationCount();
      _checkIncomingRideRequests();
    }
  }

  void _startNotificationPolling() {
    _notificationPollTimer?.cancel();
    _notificationPollTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted || !_appInForeground) return;
      _fetchUnreadNotificationCount();
      _checkIncomingRideRequests();
    });
  }

  Future<void> _checkIncomingRideRequests() async {
    if (_isCheckingIncomingAlerts || !mounted) return;
    // Requests are shown whether the driver is active or inactive; only skip while the app is in the background.
    if (!_appInForeground) return;
    // Never open a request dialog on top of another screen (an active trip, PIN entry, ...).
    if (!(ModalRoute.of(context)?.isCurrent ?? true)) return;
    _isCheckingIncomingAlerts = true;
    bool shownDialog = false;

    try {
      final res =
          await DriverService.getDriverBookingRequests(tab: 'booking_requests');
      if (!mounted) return;

      final dynamic data = res['requests'] ?? res['items'] ?? res['data'] ?? [];
      List<dynamic> list = [];
      if (data is List) {
        list = data;
      } else if (data is Map && data['items'] is List) {
        list = data['items'] as List;
      }

      for (final item in list) {
        if (item is Map) {
          final bId =
              (item['bookingId'] ?? item['_id'] ?? item['id'] ?? '').toString();
          final status = (item['status'] ?? '').toString().toLowerCase();

          // Only alert for pending, unprompted requests
          if (bId.isNotEmpty &&
              (status.isEmpty || status == 'pending') &&
              !_seenIncomingBookingIds.contains(bId)) {
            _seenIncomingBookingIds.add(bId);

            final pName = (item['passengerName'] ??
                    item['customerName'] ??
                    'Passenger')
                .toString();
            final pickup = (item['pickup'] ?? item['from'] ?? '')
                .toString();
            final drop = (item['destination'] ?? item['to'] ?? '')
                .toString();
            final fare =
                item['formattedAmount'] ?? item['offeredPrice'] ?? '';
            final seats = (item['seats'] as num?)?.toInt() ?? 1;

            if (mounted) {
              shownDialog = true;
              final answer = await IncomingRideRequestDialog.show(
                context,
                bookingId: bId,
                rideId: item['rideId']?.toString(),
                passengerName: pName,
                pickupAddress: pickup,
                dropoffAddress: drop,
                offeredFare: fare.toString(),
                seats: seats,
                onAccepted: () {
                  _fetchUnreadNotificationCount();
                  _loadDriverProfile();
                },
              );
              if (answer == null) {
                // Dismissed without answering: alert again later instead of losing the request.
                Future.delayed(const Duration(minutes: 5), () {
                  _seenIncomingBookingIds.remove(bId);
                });
              }
            }
            break; // Show one modal at a time
          }
        }
      }
    } catch (_) {
    } finally {
      _isCheckingIncomingAlerts = false;
    }

    // Queue: once a dialog is closed, look for the next pending request.
    if (shownDialog && mounted) {
      Future.microtask(_checkIncomingRideRequests);
    }
  }

  Future<void> _fetchUnreadNotificationCount() async {
    try {
      final count = await DriverService.getUnreadNotificationCount();
      if (mounted) {
        setState(() {
          _unreadNotificationCount = count;
        });
      }
    } catch (_) {}
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String _formatImageUrl(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    final cleanBase = ApiService.baseUrl.replaceAll('/api', '');
    final cleanPath = url.startsWith('/') ? url : '/$url';
    return 'cleanPath';
  }

  bool _matchesCurrentPhone(dynamic phoneVal, String cleanDigits) {
    if (phoneVal == null || cleanDigits.isEmpty) return false;
    final digits = phoneVal.toString().replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return false;
    return digits == cleanDigits ||
        (digits.length >= 10 &&
            cleanDigits.length >= 10 &&
            digits.endsWith(cleanDigits));
  }

  void _parseAndSetAvatar(dynamic photoData) {
    if (photoData == null) return;
    final photoStr = photoData.toString().trim();
    if (photoStr.isEmpty) return;

    if (photoStr.startsWith('data:image') || photoStr.length > 300) {
      try {
        final base64Content =
            photoStr.contains(',') ? photoStr.split(',').last : photoStr;
        _profileImageBytes = base64Decode(base64Content);
        _profileImageUrl = null;
        return;
      } catch (_) {}
    }
    _profileImageUrl = photoStr;
  }

  Future<void> _loadDriverProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentPhone = prefs.getString('currentPhone') ?? '';
      final cleanDigits = currentPhone.replaceAll(RegExp(r'[^0-9]'), '');
      _driverPhone = currentPhone;

      // Load persistent online toggle state
      if (prefs.containsKey('driver_online_state_$cleanDigits')) {
        _isOnline = prefs.getBool('driver_online_state_$cleanDigits') ?? true;
      } else if (prefs.containsKey('driver_online_state')) {
        _isOnline = prefs.getBool('driver_online_state') ?? true;
      }

      // Load name fallback
      final savedName = prefs.getString('user_name_$cleanDigits') ??
          prefs.getString('currentUserName') ??
          '';
      if (widget.driverName != null && widget.driverName!.isNotEmpty) {
        _name = widget.driverName!;
      } else if (savedName.isNotEmpty) {
        _name = savedName;
      }

      // Load saved avatar cache
      final savedAvatarBase64 =
          prefs.getString('driver_avatar_base64_$cleanDigits') ??
              prefs.getString('user_avatar_base64_$cleanDigits');
      if (savedAvatarBase64 != null && savedAvatarBase64.isNotEmpty) {
        try {
          _profileImageBytes = base64Decode(savedAvatarBase64);
        } catch (_) {}
      }
      final savedPhoto = prefs.getString('driver_photo_$cleanDigits') ??
          prefs.getString('profile_image_$cleanDigits') ??
          prefs.getString('current_user_avatar');
      if (savedPhoto != null &&
          savedPhoto.isNotEmpty &&
          _profileImageBytes == null) {
        _profileImageUrl = savedPhoto;
      }

      // 🚀 1. Fetch live Dashboard Summary API (GET /api/drivers/dashboard-summary)
      final summaryResult =
          await DriverService.getDashboardSummary(phone: currentPhone);
      if (summaryResult['success'] == true) {
        final summaryProfile = summaryResult['driverProfile'] is Map
            ? (summaryResult['driverProfile'] as Map)
            : null;
        final summaryPhone = summaryProfile?['phone'] ??
            summaryProfile?['phoneNumber'] ??
            summaryResult['phone'];
        final String? summaryDriverId = summaryResult['driverId']?.toString() ??
            summaryProfile?['driverId']?.toString();

        // Guard against backend mock fallback (e.g. seeded driver D-101 / Madhav with phone 7417417417)
        final bool isMadhavSeed = (summaryDriverId == 'D-101' ||
                summaryProfile?['name']?.toString().toLowerCase() ==
                    'madhav') &&
            cleanDigits != '7417417417';
        final bool summaryMatchesDriver = !isMadhavSeed &&
            (cleanDigits.isEmpty ||
                summaryPhone == null ||
                _matchesCurrentPhone(summaryPhone, cleanDigits));

        if (summaryMatchesDriver) {
          // Cache driverId if provided
          if (summaryDriverId != null && summaryDriverId.isNotEmpty) {
            await prefs.setString('driverId', summaryDriverId);
            if (cleanDigits.isNotEmpty) {
              await prefs.setString('driver_id_$cleanDigits', summaryDriverId);
            }
          }

          // Driver Profile & Avatar
          if (summaryProfile != null) {
            if (summaryProfile['name'] != null &&
                summaryProfile['name'].toString().isNotEmpty) {
              _name = summaryProfile['name'].toString();
            }
            if (summaryProfile['isOnline'] != null) {
              _isOnline = summaryProfile['isOnline'] == true;
            }
            final photo = summaryProfile['driverPhoto'] ??
                summaryProfile['profilePicture'] ??
                summaryProfile['avatar'] ??
                summaryProfile['photo'] ??
                summaryProfile['profilePhoto'] ??
                summaryProfile['image'] ??
                summaryProfile['profileImage'];
            if (photo != null) {
              _parseAndSetAvatar(photo);
            }
          }

          // Stats (Rides, Co-Travelers, KM, Ratings)
          if (summaryResult['stats'] is Map) {
            final stats = summaryResult['stats'] as Map;
            if (stats['rides'] != null) _ridesCount = stats['rides'].toString();
            if (stats['coTravelers'] != null)
              _coTravelers = stats['coTravelers'].toString();
            if (stats['km'] != null) _totalKm = stats['km'].toString();
            if (stats['ratings'] != null) _rating = stats['ratings'].toString();
          }

          // Upcoming Ride
          if (summaryResult['upcomingRide'] is Map) {
            final upcoming = summaryResult['upcomingRide'] as Map;
            final bool hasRide = upcoming['hasUpcomingRide'] == true ||
                (upcoming['pickupLocation'] != null &&
                    upcoming['destinationLocation'] != null) ||
                (upcoming['origin'] != null && upcoming['destination'] != null);

            if (hasRide) {
              _upcomingOrigin = upcoming['origin']?.toString() ??
                  upcoming['pickupLocation']?.toString() ??
                  upcoming['from']?.toString() ??
                  '-';
              _upcomingOriginTime =
                  upcoming['departureTime']?.toString() ?? '-';
              _upcomingDestination = upcoming['destination']?.toString() ??
                  upcoming['destinationLocation']?.toString() ??
                  upcoming['to']?.toString() ??
                  '-';
              _upcomingDestinationTime =
                  upcoming['arrivalTime']?.toString() ?? '-';
              _upcomingDateStr = upcoming['dateDisplay']?.toString() ??
                  upcoming['date']?.toString() ??
                  '-';
              _upcomingRideId = upcoming['rideId']?.toString() ?? '';
              _hasUpcomingRide = true;
            } else {
              _hasUpcomingRide = false;
            }
          }

          // Today's Summary
          if (summaryResult['todaySummary'] is Map) {
            final today = summaryResult['todaySummary'] as Map;
            if (today['complete'] != null)
              _todayComplete = today['complete'].toString();
            if (today['upcoming'] != null)
              _todayUpcoming = today['upcoming'].toString();
            if (today['formattedFuelShare'] != null) {
              _todayFuelShare = today['formattedFuelShare'].toString();
            } else if (today['fuelShare'] != null) {
              _todayFuelShare = today['fuelShare'].toString();
            }
          }

          // Monthly Summary
          if (summaryResult['monthlySummary'] is Map) {
            final monthly = summaryResult['monthlySummary'] as Map;
            if (monthly['completed'] != null)
              _monthlyCompleted = monthly['completed'].toString();
            if (monthly['formattedFuelShare'] != null) {
              _monthlyFuelShare = monthly['formattedFuelShare'].toString();
            } else if (monthly['fuelShare'] != null) {
              _monthlyFuelShare = monthly['fuelShare'].toString();
            }
          }
        }
      }

      // 🚀 2. Fetch live Personal Info (GET /api/drivers/profile/personal) for latest photo
      try {
        final personalRes =
            await DriverService.getPersonalInfo(phone: currentPhone);
        if (personalRes['success'] == true) {
          final p = personalRes['personalInformation'] ??
              personalRes['data'] ??
              personalRes;
          if (p is Map) {
            final pPhone = p['phoneNumber'] ?? p['phone'] ?? p['mobileNumber'];
            final bool pMatches = cleanDigits.isEmpty ||
                (pPhone != null && _matchesCurrentPhone(pPhone, cleanDigits));
            final bool isMadhavSeed =
                (p['fullName']?.toString().toLowerCase() == 'madhav' ||
                        p['name']?.toString().toLowerCase() == 'madhav') &&
                    cleanDigits != '7417417417';

            if (pMatches && !isMadhavSeed) {
              if (p['fullName'] != null &&
                  p['fullName'].toString().isNotEmpty) {
                _name = p['fullName'].toString();
              }
              final pPhoto = p['driverPhoto'] ??
                  p['profilePicture'] ??
                  p['avatar'] ??
                  p['photo'] ??
                  p['image'] ??
                  p['profileImage'];
              if (pPhoto != null) {
                _parseAndSetAvatar(pPhoto);
              }
            }
          }
        }
      } catch (_) {}

      // 🚀 3. Check Upcoming Rides list if upcoming ride was not in summary
      if (!_hasUpcomingRide) {
        final resolvedDriverId = await DriverService.resolveCurrentDriverId();
        final upcomingListResult =
            await DriverService.getUpcomingRides(driverId: resolvedDriverId);
        if (upcomingListResult['success'] == true &&
            upcomingListResult['upcomingRides'] is List &&
            (upcomingListResult['upcomingRides'] as List).isNotEmpty) {
          final candidateRide =
              (upcomingListResult['upcomingRides'] as List).first as Map;
          final rideDriverPhone =
              candidateRide['driverPhone'] ?? candidateRide['phone'];
          final rideDriverId = candidateRide['driverId']?.toString();
          final bool rideMatches = (rideDriverPhone != null &&
                  _matchesCurrentPhone(rideDriverPhone, cleanDigits)) ||
              (rideDriverId != null && rideDriverId == resolvedDriverId) ||
              cleanDigits.isEmpty;

          if (rideMatches) {
            _upcomingOrigin = candidateRide['from']?.toString() ??
                candidateRide['origin']?.toString() ??
                '-';
            _upcomingDestination = candidateRide['to']?.toString() ??
                candidateRide['destination']?.toString() ??
                '-';
            _upcomingOriginTime =
                candidateRide['departureTime']?.toString() ?? '-';
            _upcomingDestinationTime =
                candidateRide['arrivalTime']?.toString() ?? '-';
            _upcomingRideId = candidateRide['rideId']?.toString() ?? '';
            _upcomingDateStr = candidateRide['date']?.toString() ?? '-';
            _hasUpcomingRide = true;
          }
        }
      }

      // 🚀 4. Fallback to Driver Approval profile for name & photo
      if (cleanDigits.isNotEmpty) {
        final statusResult =
            await DriverService.getDriverApprovalStatus(phone: cleanDigits);
        if (statusResult['success'] == true && statusResult['driver'] != null) {
          final driver = statusResult['driver'];
          final dPhone = driver['phone'] ?? driver['phoneNumber'];
          final bool dMatches = cleanDigits.isEmpty ||
              (dPhone != null && _matchesCurrentPhone(dPhone, cleanDigits));
          final bool isMadhavSeed =
              (driver['name']?.toString().toLowerCase() == 'madhav') &&
                  cleanDigits != '7417417417';

          if (dMatches && !isMadhavSeed) {
            if (driver['name'] != null &&
                driver['name'].toString().isNotEmpty) {
              _name = driver['name'].toString();
            }
            final dPhoto = driver['driverPhoto'] ??
                driver['profilePicture'] ??
                driver['avatar'] ??
                driver['photo'] ??
                driver['image'];
            if (dPhoto != null &&
                _profileImageUrl == null &&
                _profileImageBytes == null) {
              _parseAndSetAvatar(dPhoto);
            }
          }
        }
      }

      if (_name.trim().isEmpty) {
        _name = 'Driver';
      }
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() {});
      }
      _fetchUnreadNotificationCount();
    }
  }

  void _toggleOnlineStatus() async {
    if (_isTogglingOnline) return;
    _isTogglingOnline = true;

    final previousState = _isOnline;
    final targetState = !previousState;
    setState(() {
      _isOnline = targetState;
    });

    // Call Driver Availability Switch API (PATCH/POST /api/drivers/availability)
    Map<String, dynamic> switchResult;
    try {
      switchResult = await DriverService.switchAvailability(
        isOnline: targetState,
        phone: _driverPhone,
      );
    } catch (_) {
      switchResult = {
        'success': false,
        'message': 'Could not change your status. Please check your connection and try again.',
      };
    }

    if (!mounted) {
      _isTogglingOnline = false;
      return;
    }

    if (switchResult['success'] != true) {
      // The server did not accept the change: go back to the real status and say so.
      setState(() {
        _isOnline = previousState;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            switchResult['message']?.toString() ?? 'Could not change your status. Please try again.',
          ),
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 3),
        ),
      );
      _isTogglingOnline = false;
      return;
    }

    if (switchResult['isOnline'] != null) {
      setState(() {
        _isOnline = switchResult['isOnline'] == true;
      });
    } else if (switchResult['availabilityStatus'] != null) {
      setState(() {
        _isOnline =
            switchResult['availabilityStatus'].toString().toUpperCase() == 'ON';
      });
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final cleanDigits = _driverPhone.replaceAll(RegExp(r'[^0-9]'), '');
      await prefs.setBool('driver_online_state_$cleanDigits', _isOnline);
      await prefs.setBool('driver_online_state', _isOnline);
    } catch (_) {}

    if (mounted) {
      final bannerMsg = switchResult['message']?.toString() ??
          (_isOnline ? 'You are now Online' : 'You are now Offline');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(bannerMsg),
          backgroundColor:
              _isOnline ? const Color(0xFF2E7D32) : Colors.grey[800],
          duration: const Duration(seconds: 2),
        ),
      );
    }

    if (_isOnline) {
      // Pick up requests that arrived while offline.
      _checkIncomingRideRequests();
    }
    _isTogglingOnline = false;
  }

  Future<void> _handlePostRideTapped() async {
    // 1. If status is OFF, show red error message at the bottom asking driver to turn status On
    if (!_isOnline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Please turn your status 'On' from the top of the screen to post a ride.",
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          backgroundColor: Color(0xFFD32F2F),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    // 2. If status is active (ON), verify vehicle registration & proceed
    await _verifyAndProceedToPostRide();
  }

  Future<void> _verifyAndProceedToPostRide() async {
    // Show loading indicator while verifying with backend API
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );

    Map<String, dynamic> verifyRes;
    bool verifyFailed = false;
    try {
      verifyRes = await DriverService.verifyPostRideEligibility();
    } catch (_) {
      verifyRes = {};
      verifyFailed = true;
    }

    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop(); // Dismiss loading (always, even on failure)

    if (verifyFailed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not verify your vehicle details. Please check your connection and try again.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final canPostRide = verifyRes['canPostRide'] == true;

    if (canPostRide) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const DriverMyRideScreen()),
      );
    } else {
      final popup = verifyRes['popup'] is Map
          ? (verifyRes['popup'] as Map<String, dynamic>)
          : null;
      final btnLower = (popup?['buttonText'] ?? '').toString().toLowerCase();
      final titleLower = (popup?['title'] ?? '').toString().toLowerCase();
      final descLower = (popup?['description'] ?? '').toString().toLowerCase();
      final isAvailabilityPopup = btnLower.contains('availability') ||
          btnLower.contains('turn on') ||
          titleLower.contains('availability') ||
          titleLower.contains('status') ||
          descLower.contains('availability');

      if (isAvailabilityPopup) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Please turn your status 'On' from the top of the screen to post a ride.",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            backgroundColor: Color(0xFFD32F2F),
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        _showRegisterVehiclePopup(popup);
      }
    }
  }

  void _showRegisterVehiclePopup([Map<String, dynamic>? popup]) {
    final title = popup?['title']?.toString() ?? 'Vehicle Not Registered';
    final description = popup?['description']?.toString() ??
        'You need to register your vehicle before you can post a ride.';
    final buttonText = popup?['buttonText']?.toString() ?? 'Register Vehicle';
    final cancelText = popup?['cancelText']?.toString() ?? 'Cancel';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(
                color: Color(0xFFF3EDF7),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.directions_car_rounded,
                color: AppColors.primary,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E1E2D),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF7A7A8C),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DriverVehicleInfoScreen(
                        redirectToPostRide: true,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  buttonText,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                cancelText,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF7A7A8C),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onBottomNavTapped(int index) {
    if (index == _currentNavIndex && index != 0) return;

    if (index == 0) {
      setState(() => _currentNavIndex = 0);
    } else if (index == 1) {
      // My Ride / Ride Management
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => const DriverRideManagementScreen()),
      );
    } else if (index == 2) {
      // Post Ride with vehicle verification
      _handlePostRideTapped();
    } else if (index == 3) {
      // Messages Screen (88246846.png)
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => const DriverMessagesScreen88246846()),
      ).then((_) => _fetchUnreadNotificationCount());
    } else if (index == 4) {
      // Profile
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => const DriverProfileSettingsScreen()),
      ).then((_) => _loadDriverProfile());
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppNavigator.buildRootExitGuard(
      context: context,
      homeName: 'Driver Dashboard',
      child: Scaffold(
        backgroundColor: const Color(0xFFFAF9FD),
        body: Stack(
          children: [
            // Scrollable Dashboard Body with Pull-To-Refresh
            Positioned.fill(
              child: RefreshIndicator(
                onRefresh: _loadDriverProfile,
                color: AppColors.primary,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Scenic Header with Overlapping Floating Metrics Card
                      _buildHeaderSection(),

                      const SizedBox(height: 14),

                      // Categories (My Ride, Supports, Notification, Earnings)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Categories',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 14),
                            _buildCategoriesRow(),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Upcoming Ride Card
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Upcoming Ride',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 14),
                            _buildUpcomingRideCard(),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Today Summary
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Today summery',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 14),
                            _buildTodaySummaryRow(),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Monthly Summary
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Monthly summary',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 14),
                            _buildMonthlySummaryRow(),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom Navigation Bar with 8px padding on all four sides
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: _buildBottomNavigationBar(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 1. Scenic City Backdrop Header with Zaatra Brand Badge & Online Switch
  Widget _buildHeaderSection() {
    return SizedBox(
      width: double.infinity,
      height: 230,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Scenic city skyline backdrop from Figma (Rectangle 54.png)
          SizedBox(
            width: double.infinity,
            height: 185,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'assets/images/Rectangle 54.png',
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                  errorBuilder: (_, __, ___) => Image.asset(
                    'assets/images/driver_dashboard_header_bg.png',
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                    errorBuilder: (_, __, ___) => Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFE8DDFF), Color(0xFFF5F0FF)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ),
                ),
                // Soft gradient overlay to fade into page background at bottom
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.08),
                          Colors.white.withValues(alpha: 0.0),
                          const Color(0xFFFAF9FD).withValues(alpha: 0.90),
                        ],
                        stops: const [0.0, 0.55, 1.0],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Content Row: Zaatra Badge, Greeting/Name, and Online Pill
          Positioned(
            left: 20,
            right: 20,
            top: 48,
            child: Row(
              children: [
                // Circular White Container with Zaatra Logo
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              const DriverProfileSettingsScreen()),
                    ).then((_) => _loadDriverProfile());
                  },
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(4),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/zaatra_logo_badge.png',
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => _buildAvatarImage(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Greeting & Driver Name
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _getGreeting(),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF1E1B1E),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E1B1E),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Modern Online / Offline Toggle Pill matching Screen 83
                GestureDetector(
                  onTap: _toggleOnlineStatus,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _isOnline
                          ? const Color(0xFFF1FFEF)
                          : const Color(0xFFEEEEEE),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _isOnline ? 'ON' : 'OFF',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _isOnline
                                ? const Color(0xFF477F17)
                                : const Color(0xFF757575),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: _isOnline
                                ? const Color(0xFF65BB1B)
                                : const Color(0xFF9E9E9E),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: (_isOnline
                                        ? const Color(0xFF65BB1B)
                                        : Colors.black26)
                                    .withValues(alpha: 0.4),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Floating Summary Metrics Card overlapping the header backdrop
          Positioned(
            left: 20,
            right: 20,
            bottom: 0,
            child: _buildTopMetricsCard(),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarImage() {
    if (_profileImageBytes != null) {
      return Image.memory(
        _profileImageBytes!,
        width: 48,
        height: 48,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildAvatarFallback(),
      );
    }

    if (_profileImageUrl != null && _profileImageUrl!.isNotEmpty) {
      return Image.network(
        _formatImageUrl(_profileImageUrl!),
        width: 48,
        height: 48,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildAvatarFallback(),
      );
    }

    return _buildAvatarFallback();
  }

  Widget _buildAvatarFallback() {
    final initials = _getInitials(_name);
    return Container(
      width: 48,
      height: 48,
      color: const Color(0xFFF3EDF7),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _getInitials(String name) {
    if (name.trim().isEmpty || name == 'Driver') return 'D';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }

  // 2. Dynamic Top Metric Statistics Card
  Widget _buildTopMetricsCard() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildMetricColumn(
              imageAsset: 'assets/images/ant-design_car-filled.png',
              fallbackIcon: Icons.directions_car_rounded,
              value: _ridesCount,
              label: 'My Rides'),
          _buildVerticalDivider(),
          _buildMetricColumn(
              imageAsset: 'assets/images/fa7-solid_user-group.png',
              fallbackIcon: Icons.groups_rounded,
              value: _coTravelers,
              label: 'Co-travelers'),
          _buildVerticalDivider(),
          _buildMetricColumn(
              imageAsset: 'assets/images/fa6-solid_map-location-dot.png',
              fallbackIcon: Icons.location_on_rounded,
              value: _totalKm,
              label: 'KM'),
          _buildVerticalDivider(),
          _buildMetricColumn(
            imageAsset: 'assets/images/ant-design_star-filled.png',
            fallbackIcon: Icons.star_rounded,
            value: _rating,
            label: 'Ratings',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const DriverRatingsReviewsScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMetricColumn({
    required String imageAsset,
    required IconData fallbackIcon,
    required String value,
    required String label,
    VoidCallback? onTap,
  }) {
    final col = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          imageAsset,
          width: 16,
          height: 16,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) =>
              Icon(fallbackIcon, size: 16, color: AppColors.primary),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E1B1E),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );

    return Expanded(
      child: onTap != null
          ? InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: col,
              ),
            )
          : col,
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      height: 34,
      width: 1,
      color: const Color(0xFFF0EBF8),
    );
  }

  // 3. 4 Category Quick Action Buttons with 3D Assets
  Widget _buildCategoriesRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCategoryCard(
          label: 'My Rides',
          assetPath: 'assets/images/driver_cat_my_rides.png',
          bgColor: AppColors.primaryBackground,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const DriverRideManagementScreen()),
            );
          },
        ),
        _buildCategoryCard(
          label: 'Support',
          assetPath: 'assets/images/driver_cat_support.png',
          bgColor: AppColors.primaryBackground,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const DriverSupportHelpScreen()),
            );
          },
        ),
        _buildCategoryCard(
          label: 'Notifications',
          assetPath: 'assets/images/driver_cat_notifications.png',
          bgColor: AppColors.primaryBackground,
          badgeCount: _unreadNotificationCount,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const DriverNotificationsScreen()),
            ).then((_) => _fetchUnreadNotificationCount());
          },
        ),
        _buildCategoryCard(
          label: 'Earnings\nFuel Share',
          assetPath: 'assets/images/driver_cat_earnings.png',
          bgColor: AppColors.primaryBackground,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const DriverEarningsHistoryScreen()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCategoryCard({
    required String label,
    required String assetPath,
    required Color bgColor,
    required VoidCallback onTap,
    int badgeCount = 0,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 76,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 67,
                  height: 67,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Image.asset(
                      assetPath,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(Icons.circle,
                          color: AppColors.primary, size: 24),
                    ),
                  ),
                ),
                if (badgeCount > 0)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: _buildBadgeBubble(badgeCount),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: label.contains('\n') ? 2 : 1,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF414141),
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadgeBubble(int count) {
    final displayStr = count > 9 ? '9+' : count.toString();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
      decoration: BoxDecoration(
        color: const Color(0xFFE53935),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Center(
        child: Text(
          displayStr,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            height: 1.0,
          ),
        ),
      ),
    );
  }

  // 4. Upcoming Ride Card matching Screen 83
  // 4. Upcoming Ride Card matching Screen 83
  Widget _buildUpcomingRideCard() {
    if (!_hasUpcomingRide) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFD6C7FF), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.primaryBackground,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.directions_car_filled_rounded,
                color: AppColors.primary,
                size: 26,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'No Upcoming Rides Scheduled',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E1B1E),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'You have no active or scheduled rides at the moment.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                height: 1.3,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _handlePostRideTapped,
              icon: const Icon(Icons.add_rounded,
                  size: 18, color: AppColors.primary),
              label: const Text(
                'Post New Ride',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primary, width: 1.2),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFD6C7FF), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Date Badge Pill
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.primaryBackground,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(
                _upcomingDateStr,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF414141),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),

          const SizedBox(height: 18),

          // Route with dotted line
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Origin
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _upcomingOrigin.split(',').first,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF5A5566),
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _upcomingOriginTime,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Center Dotted Line Indicator
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        color: Color(0xFF9E9E9E),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 3.0),
                      child: Text(
                        '- - - - - -',
                        style: TextStyle(
                          color: Color(0xFFB0A9BD),
                          fontSize: 11,
                          letterSpacing: 2.0,
                        ),
                      ),
                    ),
                    Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        color: Color(0xFF9E9E9E),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              ),

              // Destination
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _upcomingDestination.split(',').first,
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF5A5566),
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _upcomingDestinationTime,
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Action Buttons: Dual distinct styling (Filled lavender + Filled solid purple)
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DriverTripSharedScreen(
                          rideId: _upcomingRideId.isNotEmpty
                              ? _upcomingRideId
                              : null,
                          stage: 'before_ride',
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                    backgroundColor: AppColors.primaryBackground,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'View & Share trip card',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF414141),
                      ),
                      maxLines: 1,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DriverRideStartDetailsScreen(
                          rideId: _upcomingRideId,
                          origin: _upcomingOrigin,
                          destination: _upcomingDestination,
                          totalDistance: '$_totalKm KM',
                          rideData: {
                            'status': 'upcoming',
                            'from': _upcomingOrigin,
                            'to': _upcomingDestination,
                            'rideId': _upcomingRideId,
                          },
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                    backgroundColor: AppColors.primary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'View & Start Ride',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 5. Today Summary Row (Dynamic & Clickable with Custom Waves)
  Widget _buildTodaySummaryRow() {
    return SizedBox(
      height: 80,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Completed
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const DriverRideManagementScreen(initialTabIndex: 2),
                  ),
                );
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  color: AppColors.primaryBackground,
                  child: Stack(
                    children: [
                      // Bottom wave graphic (Vector 6 complete)
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Image.asset(
                          'assets/images/Vector 6 complete.png',
                          fit: BoxFit.fill,
                          height: 29,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset(
                              'assets/images/Group 1171276727.png',
                              width: 24,
                              height: 24,
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _todayComplete,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Complete',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // 2. Upcoming / Active
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const DriverRideManagementScreen(initialTabIndex: 1),
                  ),
                );
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  color: const Color(0xFFF1F5FE),
                  child: Stack(
                    children: [
                      // Bottom wave graphic (Vector 7 upcoming)
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Image.asset(
                          'assets/images/Vector 7 upcoming.png',
                          fit: BoxFit.fill,
                          height: 29,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: const BoxDecoration(
                                color: Color(0xFFD6EBFF),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.access_time_rounded,
                                color: Color(0xFF1E88E5),
                                size: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _todayUpcoming,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0288D1),
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Upcoming',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF0288D1),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // 3. Fuel Share
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DriverEarningsHistoryScreen(
                        initialFilter: 'Today'),
                  ),
                );
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  color: const Color(0xFFF0FBF2),
                  child: Stack(
                    children: [
                      // Bottom wave graphic (Vector 8 fuel share)
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Image.asset(
                          'assets/images/Vector 8 fuel share.png',
                          fit: BoxFit.fill,
                          height: 29,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset(
                              'assets/images/Group 1171276725.png',
                              width: 24,
                              height: 24,
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _todayFuelShare.startsWith('₹')
                                  ? _todayFuelShare
                                  : '₹$_todayFuelShare',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2E7D32),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Fuel Share',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2E7D32),
                              ),
                              maxLines: 1,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 6. Monthly Summary Row (Dynamic & Clickable with Signal Bar Trend Icons)
  Widget _buildMonthlySummaryRow() {
    return Row(
      children: [
        // 1. Monthly Completed
        Expanded(
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      const DriverRideManagementScreen(initialTabIndex: 2),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF9F7FE),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFF0EBF8)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Image.asset(
                    'assets/images/Group 1171276727.png',
                    width: 24,
                    height: 24,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _monthlyCompleted,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF6C51D1),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        const FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Completed',
                            maxLines: 1,
                            softWrap: false,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF6C51D1),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  Image.asset(
                    'assets/images/fa6-solid_signal.png',
                    width: 20,
                    height: 16,
                    fit: BoxFit.contain,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        // 2. Monthly Fuel Share
        Expanded(
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DriverEarningsHistoryScreen(
                      initialFilter: 'Monthly'),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF4FBF6),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE0F5E6)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Image.asset(
                    'assets/images/Group 1171276725.png',
                    width: 24,
                    height: 24,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _monthlyFuelShare.replaceAll('₹', ''),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2E7D32),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        const FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Fuel Share',
                            maxLines: 1,
                            softWrap: false,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  Image.asset(
                    'assets/images/fa6-solid_signal-1.png',
                    width: 20,
                    height: 16,
                    fit: BoxFit.contain,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // 7. Clean 5-Tab Flat Bottom Navigation Bar matching Screen 83
  Widget _buildBottomNavigationBar() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // 1. Home (Active)
              _buildNavItem(
                icon: Icons.home_rounded,
                label: 'Home',
                isSelected: _currentNavIndex == 0,
                onTap: () => _onBottomNavTapped(0),
              ),

              // 2. My Ride
              _buildNavItem(
                icon: Icons.directions_car_outlined,
                label: 'My Ride',
                isSelected: _currentNavIndex == 1,
                onTap: () => _onBottomNavTapped(1),
              ),

              // 3. Post Ride
              _buildNavItem(
                icon: Icons.add_box_outlined,
                label: 'Post Ride',
                isSelected: _currentNavIndex == 2,
                onTap: () => _onBottomNavTapped(2),
              ),

              // 4. Messages
              _buildNavItem(
                icon: Icons.chat_bubble_outline_rounded,
                label: 'Messages',
                isSelected: _currentNavIndex == 3,
                onTap: () => _onBottomNavTapped(3),
              ),

              // 5. Profile
              _buildNavItem(
                icon: Icons.person_outline_rounded,
                label: 'Profile',
                isSelected: _currentNavIndex == 4,
                onTap: () => _onBottomNavTapped(4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : const Color(0xFF666666),
              size: 22,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? AppColors.primary : const Color(0xFF666666),
              ),
            ),
            if (isSelected)
              Container(
                margin: const EdgeInsets.only(top: 3),
                width: 18,
                height: 3,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

typedef DriverHomeDashboardScreen = DriverHomeDashboardScreen83;