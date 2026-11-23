import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../services/driver_service.dart';

class DriverNotificationScreen extends StatefulWidget {
  const DriverNotificationScreen({super.key});

  @override
  State<DriverNotificationScreen> createState() => _DriverNotificationScreenState();
}

class _DriverNotificationScreenState extends State<DriverNotificationScreen> {
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

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
    DriverService.markAllNotificationsAsRead();
  }

  Future<void> _fetchNotifications() async {
    setState(() {
      _isLoading = true;
    });

    final res = await DriverService.getDriverNotifications(filter: _selectedFilter);

    if (!mounted) return;

    final dynamic data = res['data'] ?? res['notifications'] ?? [];
    List<Map<String, dynamic>> loadedNotifications = [];

    if (data is List) {
      loadedNotifications = data.map((item) {
        if (item is Map<String, dynamic>) {
          final isRead = item['read'] == true;
          return {
            ...item,
            'read': isRead,
            'unread': item['unread'] == true || !isRead,
          };
        }
        return <String, dynamic>{
          'title': item.toString(),
          'subtitle': '',
          'time': 'Just now',
          'type': 'new',
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
    }

    setState(() {
      _notifications = loadedNotifications;
      _isLoading = false;
    });
  }

  void _onFilterChanged(String? newFilter) {
    if (newFilter == null || newFilter == _selectedFilter) return;
    setState(() {
      _selectedFilter = newFilter;
    });
    _fetchNotifications();
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
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 15, color: AppColors.primary),
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

            // Content Body with Pull to Refresh
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
                                      "You're all caught up! New ride bookings, confirmations, and alerts will appear here.",
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
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          itemCount: _notifications.length,
                          separatorBuilder: (context, index) => const Divider(height: 16, color: AppColors.border),
                          itemBuilder: (context, index) {
                            final notif = _notifications[index];
                            final title = notif['title']?.toString() ?? 'Notification';
                            final subtitle = notif['subtitle']?.toString() ?? notif['message']?.toString() ?? '';
                            final time = notif['time']?.toString() ?? notif['createdAt']?.toString() ?? 'Just now';
                            final type = notif['type']?.toString().toLowerCase() ?? 'new';
                            final isConfirmed = type.contains('confirm') || type.contains('accept');

                            return Row(
                              children: [
                                Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: isConfirmed ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    isConfirmed ? Icons.check_circle_outline_rounded : Icons.open_in_new_rounded,
                                    color: isConfirmed ? const Color(0xFF2E7D32) : const Color(0xFFE65100),
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        title,
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                      ),
                                      if (subtitle.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          subtitle,
                                          style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  time,
                                  style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted, fontWeight: FontWeight.w500),
                                ),
                              ],
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