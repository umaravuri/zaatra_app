import 'api_service.dart';

class CustomerNotificationService {
  /// Fetch Customer Notifications (GET /api/notifications/customer or GET /api/notifications)
  /// Optional parameters: filter ('unread'), tab ('ride', 'stay'), page, limit
  static Future<Map<String, dynamic>> getCustomerNotifications({
    String? filter,
    String? tab,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final qp = <String>[];
      if (filter != null && filter.isNotEmpty && filter.toLowerCase() != 'all') {
        qp.add('filter=${Uri.encodeComponent(filter.toLowerCase())}');
      }
      if (tab != null && tab.isNotEmpty) {
        qp.add('tab=${Uri.encodeComponent(tab.toLowerCase())}');
      }
      qp.add('page=$page');
      qp.add('limit=$limit');

      final queryString = '?${qp.join('&')}';

      // 1. Try dedicated customer route
      var res = await ApiService.get('/notifications/customer$queryString');
      if (res['success'] == true && res['notifications'] != null) {
        return res;
      }

      // 2. Fallback to universal notifications route
      res = await ApiService.get('/notifications$queryString');
      return res;
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to fetch customer notifications: $e',
        'notifications': [],
        'count': 0,
        'unreadCount': 0,
      };
    }
  }

  /// Mark all notifications as read (PUT /api/notifications/mark-read)
  static Future<Map<String, dynamic>> markAllAsRead() async {
    try {
      var res = await ApiService.put('/notifications/mark-read', {});
      if (res['success'] == true) {
        return res;
      }
      // Fallback if scoped endpoint exists
      res = await ApiService.put('/notifications/customer/mark-read', {});
      return res;
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to mark notifications as read: $e',
      };
    }
  }

  /// Mark a single notification as read
  static Future<Map<String, dynamic>> markNotificationAsRead(String notificationId) async {
    try {
      var res = await ApiService.patch('/notifications/$notificationId/read', {});
      if (res['success'] == true) return res;

      res = await ApiService.put('/notifications/mark-read', {'id': notificationId});
      return res;
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to mark notification as read: $e',
      };
    }
  }

  /// Check active unread notification count
  static Future<int> getUnreadCount() async {
    try {
      final res = await getCustomerNotifications(filter: 'unread', limit: 1);
      if (res['unreadCount'] is int) {
        return res['unreadCount'] as int;
      }
      if (res['unreadCount'] != null) {
        return int.tryParse(res['unreadCount'].toString()) ?? 0;
      }
      final notifs = res['notifications'];
      if (notifs is List) {
        return notifs.where((n) => n is Map && (n['read'] == false || n['unread'] == true)).length;
      }
      return 0;
    } catch (_) {
      return 0;
    }
  }
}
