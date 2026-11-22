import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../services/api_service.dart';
import '../../../../services/customer_notification_service.dart';
import '../customer-ride/ride_confirmed_detail_screen_112.dart';
import '../customer-stay/booking_details_screen_49.dart';

class CustomerNotificationsScreen extends StatefulWidget {
  const CustomerNotificationsScreen({super.key});

  @override
  State<CustomerNotificationsScreen> createState() => _CustomerNotificationsScreenState();
}

class _CustomerNotificationsScreenState extends State<CustomerNotificationsScreen> {
  String _selectedFilter = 'ALL';
  bool _isLoading = false;
  int _unreadCount = 0;

  final List<String> _filters = [
    'ALL',
    'rides',
    'stays',
    'confirmed',
    'unread',
    'system',
  ];

  String _getFilterLabel(String f) {
    switch (f) {
      case 'ALL':
        return 'All';
      case 'rides':
        return 'Rides';
      case 'stays':
        return 'Stays';
      case 'confirmed':
        return 'Confirmed';
      case 'unread':
        return 'Unread';
      case 'system':
        return 'System';
      default:
        return f;
    }
  }

  List<Map<String, dynamic>> _allNotifications = [];

  @override
  void initState() {
    super.initState();
    _recalculateUnreadCount();
    _fetchNotifications();
  }

  void _recalculateUnreadCount() {
    _unreadCount = _allNotifications.where((n) => n['read'] == false || n['unread'] == true).length;
  }

  Future<void> _fetchNotifications() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final phone = prefs.getString('currentPhone') ?? '';
      final userId = prefs.getString('userId') ?? '';

      final List<Map<String, dynamic>> liveList = [];

      // 1. Query Dedicated Customer Notifications API
      try {
        String? filterParam;
        String? tabParam;

        if (_selectedFilter == 'unread') {
          filterParam = 'unread';
        } else if (_selectedFilter == 'rides') {
          tabParam = 'ride';
        } else if (_selectedFilter == 'stays') {
          tabParam = 'stay';
        }

        final notifRes = await CustomerNotificationService.getCustomerNotifications(
          filter: filterParam,
          tab: tabParam,
          page: 1,
          limit: 30,
        );

        final rawNotifs = notifRes['notifications'] ?? notifRes['data'] ?? notifRes['items'];
        if (rawNotifs is List && rawNotifs.isNotEmpty) {
          for (final n in rawNotifs) {
            if (n is Map) {
              final rawStatus = (n['status'] ?? n['type'] ?? 'scheduled').toString().toLowerCase();
              final status = rawStatus.contains('deni') || rawStatus.contains('decli') || rawStatus.contains('reject')
                  ? 'denied'
                  : (rawStatus.contains('cancel') ? 'cancelled' : (rawStatus.contains('confirm') ? 'confirmed' : 'scheduled'));
              final notifId = n['notificationId']?.toString() ?? n['id']?.toString() ?? n['_id']?.toString() ?? '';
              final title = n['title']?.toString() ?? 'Notification';
              final body = n['body']?.toString() ?? n['subtitle']?.toString() ?? n['message']?.toString() ?? '';
              final subtitle = n['subtitle']?.toString() ?? body;
              final time = n['timeAgo']?.toString() ?? n['time']?.toString() ?? 'Just now';
              final category = n['category']?.toString() ?? 'Booking';
              final type = n['type']?.toString() ?? '';
              final isRead = n['read'] == true;
              final redirect = n['redirect'] is Map ? Map<String, dynamic>.from(n['redirect'] as Map) : null;
              final metadata = n['metadata'] is Map ? Map<String, dynamic>.from(n['metadata'] as Map) : null;
              final bookingId = metadata?['bookingId']?.toString() ??
                  n['bookingId']?.toString() ??
                  (redirect?['params']?['bookingId']?.toString() ?? '');

              liveList.add({
                'id': notifId,
                'notificationId': notifId,
                'title': title,
                'body': body,
                'subtitle': subtitle,
                'time': time,
                'timeAgo': time,
                'status': status,
                'category': category,
                'type': type,
                'read': isRead,
                'unread': !isRead,
                'redirect': redirect,
                'metadata': metadata,
                'bookingId': bookingId,
                'raw': n,
              });
            }
          }
        }
      } catch (_) {}

      // 2. Query Live Customer Bookings to append dynamic updates
      try {
        final bookingsRes = await ApiService.get('/bookings');
        final rawBookings = bookingsRes['bookings'] ?? bookingsRes['data'];
        if (rawBookings is List && rawBookings.isNotEmpty) {
          for (final b in rawBookings) {
            if (b is Map) {
              final bPhone = (b['phone'] ?? b['customerPhone'] ?? b['userPhone'] ?? '').toString();
              final bUser = (b['userId'] ?? b['customerId'] ?? b['user']?['_id'] ?? '').toString();
              final isMatch = (phone.isNotEmpty && bPhone.contains(phone)) ||
                  (userId.isNotEmpty && bUser == userId) ||
                  (phone.isEmpty && userId.isEmpty);

              if (isMatch) {
                final rawStatus = (b['status'] ?? 'scheduled').toString().toLowerCase();
                final status = rawStatus == 'denied' || rawStatus == 'declined' || rawStatus == 'rejected'
                    ? 'denied'
                    : (rawStatus == 'cancelled' ? 'cancelled' : (rawStatus.contains('confirm') ? 'confirmed' : 'scheduled'));
                final from = (b['pickupLocation'] ?? b['from'] ?? 'Pickup').toString().split(',').first;
                final to = (b['destinationLocation'] ?? b['to'] ?? 'Destination').toString().split(',').first;
                final title = status == 'denied'
                    ? 'Booking Request Denied'
                    : (status == 'cancelled' ? 'Booking Cancelled' : 'Ride Scheduled');
                final subtitle = status == 'denied'
                    ? 'Driver was unable to accept your ride from $from to $to.'
                    : (status == 'cancelled'
                        ? 'Your ride from $from to $to was cancelled.'
                        : 'Your ride from $from to $to is confirmed.');
                final bId = (b['bookingId'] ?? b['_id'] ?? b['id'] ?? '').toString();

                // Avoid duplicating if already present
                if (!liveList.any((item) => item['bookingId'] == bId)) {
                  liveList.add({
                    'id': 'booking-$bId',
                    'notificationId': 'booking-$bId',
                    'title': title,
                    'body': subtitle,
                    'subtitle': subtitle,
                    'time': b['departureTime']?.toString() ?? 'Recently',
                    'timeAgo': b['departureTime']?.toString() ?? 'Recently',
                    'status': status,
                    'category': 'Ride',
                    'type': 'booking_status',
                    'read': true,
                    'unread': false,
                    'bookingId': bId,
                    'redirect': {
                      'screen': 'TripDetailsScreen',
                      'route': '/bookings/$bId/pass',
                      'params': {'bookingId': bId},
                    },
                    'raw': b,
                  });
                }
              }
            }
          }
        }
      } catch (_) {}

      if (mounted) {
        setState(() {
          _allNotifications = liveList;
          _recalculateUnreadCount();
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _markAllAsRead() async {
    setState(() {
      for (final n in _allNotifications) {
        n['read'] = true;
        n['unread'] = false;
      }
      _unreadCount = 0;
    });

    await CustomerNotificationService.markAllAsRead();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All notifications marked as read'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  List<Map<String, dynamic>> get _filteredNotifications {
    if (_selectedFilter == 'ALL') {
      return _allNotifications;
    }
    final target = _selectedFilter.toLowerCase();
    return _allNotifications.where((n) {
      final cat = (n['category']?.toString() ?? '').toLowerCase();
      final type = (n['type']?.toString() ?? '').toLowerCase();
      final title = (n['title']?.toString() ?? '').toLowerCase();
      final status = (n['status']?.toString() ?? '').toLowerCase();
      final isUnread = n['read'] == false || n['unread'] == true;

      if (target == 'rides') {
        return cat.contains('ride') || type.contains('ride') || title.contains('ride');
      }
      if (target == 'stays') {
        return cat.contains('stay') || cat.contains('hotel') || type.contains('stay') || title.contains('stay');
      }
      if (target == 'confirmed') {
        return status.contains('confirm') || status.contains('scheduled') || title.contains('confirmed') || title.contains('scheduled');
      }
      if (target == 'unread') {
        return isUnread;
      }
      if (target == 'system') {
        return cat.contains('system') || type.contains('system') || cat.contains('heritage') || cat.contains('banquet');
      }
      return true;
    }).toList();
  }

  _NotificationStyleInfo _getIconAndColor(Map<String, dynamic> notif) {
    final cat = (notif['category']?.toString() ?? '').toLowerCase();
    final type = (notif['type']?.toString() ?? '').toLowerCase();
    final title = (notif['title']?.toString() ?? '').toLowerCase();
    final status = (notif['status']?.toString() ?? '').toLowerCase();

    if (cat.contains('stay') || cat.contains('hotel') || type.contains('stay') || title.contains('stay') || title.contains('resort')) {
      return const _NotificationStyleInfo(
        icon: Icons.hotel_rounded,
        iconColor: Color(0xFFE65100),
        bgColor: Color(0xFFFFF3E0),
      );
    } else if (type.contains('payout') || type.contains('refund') || type.contains('wallet') || type.contains('pay') || title.contains('refund')) {
      return const _NotificationStyleInfo(
        icon: Icons.account_balance_wallet_rounded,
        iconColor: Color(0xFF2E7D32),
        bgColor: Color(0xFFE8F5E9),
      );
    } else if (type.contains('rating') || type.contains('star') || type.contains('review')) {
      return const _NotificationStyleInfo(
        icon: Icons.star_rounded,
        iconColor: Color(0xFFFFA000),
        bgColor: Color(0xFFFFF8E1),
      );
    } else if (status.contains('deni') || status.contains('decli') || status.contains('reject') || status.contains('cancel') || title.contains('denied') || title.contains('cancelled')) {
      return const _NotificationStyleInfo(
        icon: Icons.cancel_outlined,
        iconColor: Color(0xFFD32F2F),
        bgColor: Color(0xFFFFEBEE),
      );
    } else if (cat.contains('ride') || type.contains('ride') || title.contains('ride') || cat.contains('booking')) {
      return const _NotificationStyleInfo(
        icon: Icons.directions_car_filled_rounded,
        iconColor: Color(0xFF5B3AA8),
        bgColor: Color(0xFFEDE7F6),
      );
    } else if (status.contains('confirm') || status.contains('scheduled') || title.contains('confirmed') || title.contains('scheduled')) {
      return const _NotificationStyleInfo(
        icon: Icons.check_circle_outline_rounded,
        iconColor: Color(0xFF4CAF50),
        bgColor: Color(0xFFE8F5E9),
      );
    } else {
      return const _NotificationStyleInfo(
        icon: Icons.campaign_rounded,
        iconColor: Color(0xFF0288D1),
        bgColor: Color(0xFFE1F5FE),
      );
    }
  }

  void _showNotificationDetail(Map<String, dynamic> notif) {
    final notifId = (notif['notificationId'] ?? notif['id'] ?? '').toString();
    if (notif['read'] == false || notif['unread'] == true) {
      setState(() {
        notif['unread'] = false;
        notif['read'] = true;
        _recalculateUnreadCount();
      });
      if (notifId.isNotEmpty) {
        CustomerNotificationService.markNotificationAsRead(notifId);
      }
    }

    final title = notif['title']?.toString() ?? 'Notification';
    final body = notif['body']?.toString() ?? notif['subtitle']?.toString() ?? notif['message']?.toString() ?? '';
    final time = notif['timeAgo']?.toString() ?? notif['time']?.toString() ?? 'Recently';
    final category = notif['category']?.toString() ?? 'General Update';
    final styleInfo = _getIconAndColor(notif);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.white,
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: styleInfo.bgColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(styleInfo.icon, color: styleInfo.iconColor, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3EDF7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            category,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          time,
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              if (body.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  body,
                  style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.45),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5B3AA8),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Dismiss', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  void _handleNotificationTap(Map<String, dynamic> notif) {
    final notifId = (notif['notificationId'] ?? notif['id'] ?? '').toString();
    if (notif['read'] == false || notif['unread'] == true) {
      setState(() {
        notif['read'] = true;
        notif['unread'] = false;
        _recalculateUnreadCount();
      });
      if (notifId.isNotEmpty) {
        CustomerNotificationService.markNotificationAsRead(notifId);
      }
    }

    final redirect = notif['redirect'];
    String bookingId = notif['bookingId']?.toString() ?? '';
    String screen = '';
    String route = '';

    if (redirect is Map) {
      screen = redirect['screen']?.toString() ?? '';
      route = redirect['route']?.toString() ?? '';
      if (redirect['params'] is Map) {
        final params = redirect['params'] as Map;
        bookingId = params['bookingId']?.toString() ?? params['id']?.toString() ?? bookingId;
      }
    }

    // Direct routing if bookingId or pass/confirmation screen specified
    if (bookingId.isNotEmpty || screen == 'TripDetailsScreen' || route.contains('/pass') || route.contains('/confirmation')) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RideConfirmedDetailScreen112(
            bookingId: bookingId,
            bookingData: notif['raw'] is Map<String, dynamic> ? notif['raw'] as Map<String, dynamic> : notif,
          ),
        ),
      );
      return;
    }

    final category = notif['category']?.toString().toLowerCase() ?? '';
    if (category.contains('stay') || category.contains('hotel')) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const CustomerBookingDetailsScreen(),
        ),
      );
      return;
    }

    // Otherwise show detail bottom sheet
    _showNotificationDetail(notif);
  }

  @override
  Widget build(BuildContext context) {
    final items = _filteredNotifications;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Notification',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        actions: [
          if (_unreadCount > 0)
            IconButton(
              icon: const Icon(Icons.done_all_rounded, color: AppColors.primary, size: 22),
              tooltip: 'Mark all as read',
              onPressed: _markAllAsRead,
            ),
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3EDF7),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedFilter,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary, size: 18),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary),
                    items: _filters.map((filter) {
                      return DropdownMenuItem<String>(
                        value: filter,
                        child: Text(_getFilterLabel(filter)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val == null || val == _selectedFilter) return;
                      setState(() => _selectedFilter = val);
                      _fetchNotifications();
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // "Mark all as read" Sub-Header Banner if unread notifications exist
            if (_unreadCount > 0)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: const BoxDecoration(
                  color: Color(0xFFFAF7FE),
                  border: Border(bottom: BorderSide(color: Color(0xFFEDE7F6))),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$_unreadCount unread notification${_unreadCount > 1 ? 's' : ''}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    InkWell(
                      onTap: _markAllAsRead,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.done_all_rounded, size: 16, color: AppColors.primary),
                            SizedBox(width: 5),
                            Text(
                              'Mark all as read',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Bottom Background Graphic matching image 31.png
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
                  RefreshIndicator(
                    onRefresh: _fetchNotifications,
                    color: AppColors.primary,
                    child: _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(color: AppColors.primary),
                          )
                        : items.isEmpty
                            ? ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                children: [
                                  SizedBox(height: MediaQuery.of(context).size.height * 0.22),
                                  Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(20),
                                          decoration: const BoxDecoration(
                                            color: Color(0xFFF3EDF7),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.notifications_none_rounded,
                                            size: 48,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                        const SizedBox(height: 18),
                                        const Text(
                                          'No notifications yet',
                                          style: TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 40),
                                          child: Text(
                                            _selectedFilter == 'ALL'
                                                ? "You're all caught up! Updates, ride bookings, and announcements will appear here."
                                                : "No ${_getFilterLabel(_selectedFilter)} notifications found.",
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: AppColors.textSecondary,
                                              height: 1.4,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              )
                            : ListView.separated(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14),
                                itemCount: items.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  final notif = items[index];
                                  final title = notif['title']?.toString() ?? 'Notification';
                                  final subtitle = notif['subtitle']?.toString() ?? notif['body']?.toString() ?? notif['message']?.toString() ?? '';
                                  final time = notif['timeAgo']?.toString() ?? notif['time']?.toString() ?? 'Just now';
                                  final isUnread = notif['unread'] == true || notif['read'] == false;
                                  final styleInfo = _getIconAndColor(notif);

                                  return InkWell(
                                    onTap: () => _handleNotificationTap(notif),
                                    borderRadius: BorderRadius.circular(18),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: isUnread ? const Color(0xFFFAF7FE) : Colors.white,
                                        borderRadius: BorderRadius.circular(18),
                                        border: Border.all(
                                          color: isUnread ? AppColors.primary.withValues(alpha: 0.3) : AppColors.border,
                                          width: isUnread ? 1.4 : 1.0,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.03),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Circular category icon
                                          Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: styleInfo.bgColor,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              styleInfo.icon,
                                              color: styleInfo.iconColor,
                                              size: 20,
                                            ),
                                          ),
                                          const SizedBox(width: 14),

                                          // Content text
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        title,
                                                        style: TextStyle(
                                                          fontSize: 14.5,
                                                          fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                                                          color: AppColors.textPrimary,
                                                        ),
                                                      ),
                                                    ),
                                                    if (isUnread) ...[
                                                      const SizedBox(width: 6),
                                                      Container(
                                                        width: 8,
                                                        height: 8,
                                                        decoration: const BoxDecoration(
                                                          color: AppColors.primary,
                                                          shape: BoxShape.circle,
                                                        ),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                                if (subtitle.isNotEmpty) ...[
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    subtitle,
                                                    style: const TextStyle(
                                                      fontSize: 12.5,
                                                      color: AppColors.textSecondary,
                                                      height: 1.35,
                                                    ),
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ],
                                                const SizedBox(height: 8),
                                                Text(
                                                  time,
                                                  style: const TextStyle(
                                                    fontSize: 11.5,
                                                    color: AppColors.textMuted,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationStyleInfo {
  final IconData icon;
  final Color iconColor;
  final Color bgColor;

  const _NotificationStyleInfo({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
  });
}
