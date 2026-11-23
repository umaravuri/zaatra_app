import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../services/driver_service.dart';
import '../../../widgets/driver_detour_decision_dialog.dart';

class DriverNotificationsScreen extends StatefulWidget {
  const DriverNotificationsScreen({super.key});

  @override
  State<DriverNotificationsScreen> createState() => _DriverNotificationsScreenState();
}

class _DriverNotificationsScreenState extends State<DriverNotificationsScreen> {
  String _selectedFilter = 'ALL';
  bool _isLoading = false;
  List<Map<String, dynamic>> _notifications = [];

  final List<String> _filters = [
    'ALL',
    'read',
    'unread',
  ];

  String _getFilterLabel(String f) {
    switch (f) {
      case 'ALL':
        return 'All';
      case 'read':
        return 'Read';
      case 'unread':
        return 'Unread';
      default:
        return f;
    }
  }

  Future<void> _markAllAsRead() async {
    setState(() {
      for (final n in _notifications) {
        n['read'] = true;
        n['unread'] = false;
      }
    });
    await DriverService.markAllNotificationsAsRead();
  }

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() {
      _isLoading = true;
    });

    final res = await DriverService.getDriverNotifications(filter: _selectedFilter);

    if (!mounted) return;

    final dynamic data = res['notifications'] ?? res['items'] ?? res['data'] ?? [];
    List<dynamic> rawList = [];
    if (data is List) {
      rawList = data;
    } else if (data is Map) {
      if (data['notifications'] is List) {
        rawList = data['notifications'] as List;
      } else if (data['items'] is List) {
        rawList = data['items'] as List;
      }
    }

    List<Map<String, dynamic>> loadedNotifications = rawList.map((item) {
      if (item is Map) {
        final m = Map<String, dynamic>.from(item);
        final title = m['title'] ?? m['subject'] ?? 'Notification';
        final subtitle = m['subtitle'] ?? m['message'] ?? m['body'] ?? m['description'] ?? '';
        final time = m['time'] ?? m['timeAgo'] ?? m['createdAt'] ?? 'Just now';
        final type = (m['type'] ?? m['category'] ?? 'system').toString();
        final id = (m['id'] ?? m['_id'] ?? m['bookingId'] ?? 'notif_${m.hashCode}').toString();
        final isRead = m['read'] == true;
        return <String, dynamic>{
          'id': id,
          'title': title,
          'subtitle': subtitle,
          'time': time,
          'type': type,
          'category': m['category'] ?? 'General Update',
          'read': isRead,
          'unread': m['unread'] == true || !isRead,
        };
      }
      return <String, dynamic>{
        'id': 'notif_${item.hashCode}',
        'title': item.toString(),
        'subtitle': '',
        'time': 'Just now',
        'type': 'system',
        'category': 'General Update',
        'read': true,
        'unread': false,
      };
    }).toList();

    // Local filtering fallback if filter is not ALL
    if (_selectedFilter != 'ALL') {
      final f = _selectedFilter.toLowerCase();
      loadedNotifications = loadedNotifications.where((n) {
        final isRead = n['read'] == true;
        final isUnread = n['unread'] == true || !isRead;

        if (f == 'read') return isRead && !isUnread;
        if (f == 'unread') return isUnread;
        return true;
      }).toList();
    }

    setState(() {
      _notifications = loadedNotifications;
      _isLoading = false;
    });
  }

  void _onFilterChanged(String? val) {
    if (val == null || val == _selectedFilter) return;
    setState(() => _selectedFilter = val);
    _fetchNotifications();
  }

  Future<void> _markItemAsRead(Map<String, dynamic> notif) async {
    final id = notif['id']?.toString() ?? '';
    if (notif['unread'] == true || notif['read'] == false) {
      setState(() {
        notif['unread'] = false;
        notif['read'] = true;
      });
      if (id.isNotEmpty) {
        await DriverService.markNotificationAsRead(id);
      }
    }
  }

  void _showNotificationDetail(Map<String, dynamic> notif) {
    _markItemAsRead(notif);

    // If this notification is a detour / doorstep request, open the detour decision dialog!
    final type = (notif['type']?.toString() ?? notif['category']?.toString() ?? '').toLowerCase();
    if (type.contains('detour') || type.contains('doorstep')) {
      final reqId = notif['requestId'] ?? notif['bookingId'] ?? notif['id'] ?? '';
      final rId = notif['rideId'] ?? '';
      final pName = notif['passengerName'] ?? notif['customerName'] ?? 'Passenger';
      final from = notif['from'] ?? notif['pickup'] ?? 'Scheduled Route';
      final to = notif['to'] ?? notif['destination'] ?? 'Doorstep Location';
      final detourKm = (notif['detourKm'] ?? notif['detourDistance'] as num?)?.toDouble() ?? 12.0;

      DriverDetourDecisionDialog.show(
        context,
        requestId: reqId.toString(),
        rideId: rId.toString(),
        passengerName: pName.toString(),
        pickupLocation: from.toString(),
        dropLocation: to.toString(),
        detourDistanceKm: detourKm,
        onDecisionSubmitted: _fetchNotifications,
      );
      return;
    }

    final title = notif['title']?.toString() ?? 'Notification';
    final subtitle = notif['subtitle']?.toString() ?? notif['body']?.toString() ?? notif['message']?.toString() ?? '';
    final time = notif['time']?.toString() ?? notif['timeAgo']?.toString() ?? 'Recently';
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
              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  subtitle,
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

  _NotificationStyleInfo _getIconAndColor(Map<String, dynamic> notif) {
    final type = (notif['type']?.toString() ?? notif['iconType']?.toString() ?? '').toLowerCase();

    if (type.contains('payout') || type.contains('earn') || type.contains('fuel')) {
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
    } else if (type.contains('safety') || type.contains('policy') || type.contains('license') || type.contains('insurance')) {
      return const _NotificationStyleInfo(
        icon: Icons.verified_user_rounded,
        iconColor: Color(0xFF673AB7),
        bgColor: Color(0xFFF3E5F5),
      );
    } else if (type.contains('confirm') || type.contains('accept')) {
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
          'Notification',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3EDF7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedFilter,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary, size: 15),
                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.primary),
                    items: _filters.map((filter) {
                      return DropdownMenuItem<String>(
                        value: filter,
                        child: Text(
                          _getFilterLabel(filter),
                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.primary),
                        ),
                      );
                    }).toList(),
                    onChanged: _onFilterChanged,
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
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Bottom Background Graphic matching 13.png
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
                  : _notifications.isEmpty
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
                                  const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 40),
                                    child: Text(
                                      "You're all caught up! System updates, payouts, ratings and announcements will appear here.",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
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
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
                          itemCount: _notifications.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final notif = _notifications[index];
                            final title = notif['title']?.toString() ?? 'Notification';
                            final subtitle = notif['subtitle']?.toString() ?? notif['body']?.toString() ?? notif['message']?.toString() ?? '';
                            final time = notif['time']?.toString() ?? notif['timeAgo']?.toString() ?? 'Just now';
                            final isUnread = notif['unread'] == true || notif['read'] == false;
                            final styleInfo = _getIconAndColor(notif);

                            return InkWell(
                              onTap: () => _showNotificationDetail(notif),
                              borderRadius: BorderRadius.circular(12),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isUnread ? const Color(0xFFFAF7FE) : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isUnread ? AppColors.primary.withValues(alpha: 0.3) : AppColors.border,
                                    width: isUnread ? 1.2 : 1.0,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.03),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Circular category icon
                                    Container(
                                      padding: const EdgeInsets.all(7),
                                      decoration: BoxDecoration(
                                        color: styleInfo.bgColor,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        styleInfo.icon,
                                        color: styleInfo.iconColor,
                                        size: 16,
                                      ),
                                    ),
                                    const SizedBox(width: 10),

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
                                                    fontSize: 13,
                                                    fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                                                    color: AppColors.textPrimary,
                                                  ),
                                                ),
                                              ),
                                              if (isUnread) ...[
                                                const SizedBox(width: 6),
                                                Container(
                                                  width: 7,
                                                  height: 7,
                                                  decoration: const BoxDecoration(
                                                    color: AppColors.primary,
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                          if (subtitle.isNotEmpty) ...[
                                            const SizedBox(height: 3),
                                            Text(
                                              subtitle,
                                              style: const TextStyle(
                                                fontSize: 11.5,
                                                color: AppColors.textSecondary,
                                                height: 1.3,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                          const SizedBox(height: 6),
                                          Text(
                                            time,
                                            style: const TextStyle(
                                              fontSize: 10.5,
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