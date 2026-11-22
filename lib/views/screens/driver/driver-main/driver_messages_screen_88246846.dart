import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../services/driver_service.dart';
import '../../../../services/ride_service.dart';
import '../../../widgets/driver_decline_reason_modal.dart';
import 'driver_booking_requests_screen_99.dart';

class DriverMessagesScreen88246846 extends StatefulWidget {
  final int initialTabIndex;

  const DriverMessagesScreen88246846({
    super.key,
    this.initialTabIndex = 0,
  });

  @override
  State<DriverMessagesScreen88246846> createState() => _DriverMessagesScreen88246846State();
}

class _DriverMessagesScreen88246846State extends State<DriverMessagesScreen88246846> {
  late int _selectedTab; // 0: Messages, 1: Requests
  bool _isLoading = false;

  int _totalUnreadMessages = 0;
  int _totalRequests = 0;

  List<Map<String, dynamic>> _messages = [];
  List<Map<String, dynamic>> _requests = [];

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTabIndex;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final activeTabStr = _selectedTab == 0 ? 'messages' : 'requests';
      final tabRes = await DriverService.getDriverMessagesTab(tab: activeTabStr);

      final counts = tabRes['counts'] is Map ? (tabRes['counts'] as Map<String, dynamic>) : null;

      final messagesList = tabRes['messages'] is List
          ? List<Map<String, dynamic>>.from(tabRes['messages'])
          : <Map<String, dynamic>>[];
      final requestsList = tabRes['requests'] is List
          ? List<Map<String, dynamic>>.from(tabRes['requests'])
          : <Map<String, dynamic>>[];

      if (messagesList.isEmpty && requestsList.isEmpty) {
        final messagesRes = await DriverService.getDriverMessages();
        final requestsRes = await DriverService.getDriverRequests();
        if (mounted) {
          setState(() {
            _messages = List<Map<String, dynamic>>.from(messagesRes['messages'] ?? []);
            _totalUnreadMessages = messagesRes['totalUnread'] ??
                _messages.fold<int>(0, (sum, m) => sum + ((m['unreadCount'] as int?) ?? 0));
            _requests = List<Map<String, dynamic>>.from(requestsRes['requests'] ?? []);
            _totalRequests = requestsRes['totalRequests'] ?? _requests.length;
            _isLoading = false;
          });
          return;
        }
      }

      if (mounted) {
        setState(() {
          if (messagesList.isNotEmpty || _selectedTab == 0) {
            _messages = messagesList;
          }
          if (requestsList.isNotEmpty || _selectedTab == 1) {
            _requests = requestsList;
          }

          if (counts != null) {
            _totalUnreadMessages = (counts['unreadMessages'] as num?)?.toInt() ??
                _messages.fold<int>(0, (sum, m) => sum + ((m['unreadCount'] as int?) ?? 0));
            _totalRequests = (counts['requests'] as num?)?.toInt() ?? _requests.length;
          } else {
            _totalUnreadMessages = _messages.fold<int>(0, (sum, m) => sum + ((m['unreadCount'] as int?) ?? 0));
            _totalRequests = _requests.length;
          }

          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _respondToRequest({
    required Map<String, dynamic> request,
    required String action, // 'accept' or 'decline'
    String? reason,
  }) async {
    final bookingId = (request['bookingId'] ?? request['id'] ?? request['_id'] ?? '').toString();
    final name = (request['passengerName'] ?? request['customerName'] ?? request['name'] ?? 'Passenger').toString();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Text(action == 'accept' ? 'Accepting request...' : 'Declining request...'),
          ],
        ),
        duration: const Duration(seconds: 1),
      ),
    );

    try {
      final res = await RideService.respondToBookingRequest(
        bookingId: bookingId,
        action: action,
        reason: reason,
      );

      if (action == 'decline' && bookingId.isNotEmpty) {
        try {
          final prefs = await SharedPreferences.getInstance();
          final declinedList = prefs.getStringList('driver_declined_booking_ids') ?? [];
          if (!declinedList.contains(bookingId)) {
            declinedList.add(bookingId);
            await prefs.setStringList('driver_declined_booking_ids', declinedList);
          }
        } catch (_) {}
      }

      if (mounted) {
        if (res['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                action == 'accept'
                    ? 'Accepted ride request from $name!'
                    : 'Declined ride request from $name.',
              ),
              backgroundColor: action == 'accept' ? const Color(0xFF2E7D32) : const Color(0xFFE53935),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(res['message'] ?? 'Action completed.'),
            ),
          );
        }
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _showDeclineReasonDialog(Map<String, dynamic> request) async {
    final name = (request['passengerName'] ?? request['customerName'] ?? request['name'] ?? 'Passenger').toString();

    final result = await DriverDeclineReasonModal.show(
      context,
      passengerName: name,
    );

    if (result != null && result.isNotEmpty) {
      _respondToRequest(request: request, action: 'decline', reason: result);
    }
  }

  void _openChatConversation(Map<String, dynamic> thread) async {
    final convId = thread['conversationId']?.toString() ?? thread['id']?.toString() ?? '';
    if (convId.isNotEmpty) {
      DriverService.markConversationAsRead(convId);
    }
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ChatDetailBottomSheet(thread: thread),
    );
    if (mounted) {
      _loadData();
    }
  }

  void _openRequestAction(Map<String, dynamic> request) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text((request['passengerName'] ?? request['customerName'] ?? 'Ride Request').toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Route: ${request['route'] ?? ((request['from'] != null && request['to'] != null) ? "${request['from']} ➔ ${request['to']}" : "")}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('Time: ${request['time'] ?? request['departureTime'] ?? "Today"}', style: const TextStyle(fontSize: 12, color: Color(0xFF757575))),
            const SizedBox(height: 4),
            Text('Seats: ${request['seats'] ?? request['seatsBooked'] ?? 1} seat(s)', style: const TextStyle(fontSize: 12, color: Color(0xFF757575))),
            const SizedBox(height: 4),
            Text('Offered Fare: ${request['offeredPrice'] ?? request['totalAmount'] ?? "₹ 250"}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF5B3AA8))),
            if (request['note'] != null && request['note'].toString().isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3EDF7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('Note: "${request['note']}"', style: const TextStyle(fontSize: 11.5, fontStyle: FontStyle.italic)),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _showDeclineReasonDialog(request);
            },
            child: const Text('Decline', style: TextStyle(color: Color(0xFFE53935))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _respondToRequest(request: request, action: 'accept');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5B3AA8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Accept Request', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1E1B1E), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Messages',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E1B1E),
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Subtle watermark background illustration at bottom
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: IgnorePointer(
                child: Opacity(
                  opacity: 0.18,
                  child: Image.asset(
                    'assets/images/image 31.png',
                    fit: BoxFit.fitWidth,
                    alignment: Alignment.bottomCenter,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ),
            ),

            // Content column
            Column(
              children: [
                const SizedBox(height: 8),

                // Top Segmented Pill Toggle matching 88246846.png
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    height: 48,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDE7F6),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        // 1. Messages Tab Pill
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              if (_selectedTab != 0) {
                                setState(() => _selectedTab = 0);
                                _loadData();
                              }
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: _selectedTab == 0 ? const Color(0xFF5B3AA8) : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Messages ($_totalUnreadMessages)',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.bold,
                                  color: _selectedTab == 0 ? Colors.white : const Color(0xFF4A4458),
                                ),
                              ),
                            ),
                          ),
                        ),

                        // 2. Requests Tab Pill
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              if (_selectedTab != 1) {
                                setState(() => _selectedTab = 1);
                                _loadData();
                              }
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: _selectedTab == 1 ? const Color(0xFF5B3AA8) : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Requests ($_totalRequests)',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.bold,
                                  color: _selectedTab == 1 ? Colors.white : const Color(0xFF4A4458),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // Active Tab Content List
                Expanded(
                  child: RefreshIndicator(
                    color: const Color(0xFF5B3AA8),
                    onRefresh: _loadData,
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator(color: Color(0xFF5B3AA8)))
                        : _selectedTab == 0
                            ? _buildMessagesList()
                            : _buildRequestsList(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessagesList() {
    if (_messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline_rounded, size: 54, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            const Text('No Messages Yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E1B1E))),
            const SizedBox(height: 4),
            const Text('New messages and inquiries will appear here', style: TextStyle(fontSize: 12, color: Color(0xFF757575))),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      itemCount: _messages.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final thread = _messages[index];
        final senderName = thread['participantName']?.toString() ??
            thread['name']?.toString() ??
            thread['senderName']?.toString() ??
            'User';
        final initials = thread['initials']?.toString() ?? (senderName.isNotEmpty ? senderName.substring(0, 1) : 'U');
        final lastMessage = thread['lastMessage']?.toString() ?? '';
        final timestamp = thread['time']?.toString() ?? thread['timestamp']?.toString() ?? '10:30 AM';
        final unreadCount = (thread['unreadBadge'] as int?) ?? ((thread['unreadCount'] as int?) ?? 0);

        return InkWell(
          onTap: () => _openChatConversation(thread),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFEDE7F6), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Avatar Circle with Initials matching 88246846.png
                CircleAvatar(
                  radius: 22,
                  backgroundColor: const Color(0xFFEDE7F6),
                  child: Text(
                    initials,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF5B3AA8),
                    ),
                  ),
                ),

                const SizedBox(width: 14),

                // Center Info: Sender Name & Last Message Snippet
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        senderName,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E1B1E),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        lastMessage,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF757575),
                          fontWeight: FontWeight.w400,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 10),

                // Right Column: Time & Unread Badge
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      timestamp,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF757575),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 5),
                    if (unreadCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF5B3AA8),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '$unreadCount',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      )
                    else
                      const SizedBox(height: 18),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRequestsList() {
    if (_requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 54, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            const Text('No Pending Requests', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E1B1E))),
            const SizedBox(height: 4),
            const Text('New passenger booking requests will appear here', style: TextStyle(fontSize: 12, color: Color(0xFF757575))),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DriverBookingRequestsScreen(initialTabIndex: 0),
                  ),
                );
                if (mounted) _loadData();
              },
              icon: const Icon(Icons.history_rounded, size: 16, color: Color(0xFF5B3AA8)),
              label: const Text('View All Request History', style: TextStyle(color: Color(0xFF5B3AA8), fontSize: 13, fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFEDE7F6), width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_requests.length} Pending Request${_requests.length == 1 ? '' : 's'}',
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF757575)),
              ),
              InkWell(
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DriverBookingRequestsScreen(initialTabIndex: 0),
                    ),
                  );
                  if (mounted) _loadData();
                },
                borderRadius: BorderRadius.circular(8),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('History', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF5B3AA8))),
                      SizedBox(width: 2),
                      Icon(Icons.arrow_forward_ios_rounded, size: 11, color: Color(0xFF5B3AA8)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            itemCount: _requests.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final req = _requests[index];
              final name = (req['passengerName'] ?? req['customerName'] ?? req['name'] ?? req['userName'] ?? 'Passenger').toString();
              final initials = req['initials']?.toString() ?? (name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'P');
              final from = (req['from'] ?? req['pickup'] ?? req['pickupLocation'] ?? req['origin'] ?? '').toString();
              final to = (req['to'] ?? req['destination'] ?? req['destinationLocation'] ?? '').toString();
              final route = req['route']?.toString() ?? (from.isNotEmpty && to.isNotEmpty ? '$from ➔ $to' : 'Pickup ➔ Destination');
              final time = (req['time'] ?? req['departureTime'] ?? req['createdAt'] ?? 'Today').toString();
              final seats = req['seats'] ?? req['seatsBooked'] ?? req['seatsCount'] ?? 1;
              final rawPrice = (req['offeredPrice'] ?? req['fare'] ?? req['totalAmount'] ?? req['amount'] ?? 250).toString();
              final price = rawPrice.startsWith('₹') ? rawPrice : '₹ $rawPrice';

              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFEDE7F6), width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: const Color(0xFFEDE7F6),
                          child: Text(
                            initials,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF5B3AA8)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: Color(0xFF1E1B1E))),
                              Text(time, style: const TextStyle(fontSize: 11.5, color: Color(0xFF757575))),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEDE7F6),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            price,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF5B3AA8)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.route_rounded, size: 14, color: Color(0xFF5B3AA8)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(route, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF1E1B1E))),
                        ),
                        Text('$seats Seat(s)', style: const TextStyle(fontSize: 12, color: Color(0xFF757575))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _showDeclineReasonDialog(req),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFFE0E0E0)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                            child: const Text('Decline', style: TextStyle(color: Color(0xFF757575), fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _openRequestAction(req),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF5B3AA8),
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                            child: const Text('View & Accept', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ChatDetailBottomSheet extends StatefulWidget {
  final Map<String, dynamic> thread;

  const _ChatDetailBottomSheet({required this.thread});

  @override
  State<_ChatDetailBottomSheet> createState() => _ChatDetailBottomSheetState();
}

class _ChatDetailBottomSheetState extends State<_ChatDetailBottomSheet> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _messages = [];

  @override
  void initState() {
    super.initState();
    final convId = widget.thread['conversationId']?.toString() ?? widget.thread['id']?.toString() ?? '';
    final initialMsg = widget.thread['lastMessage']?.toString() ?? '';
    final rawHistory = widget.thread['chatHistory'];

    _messages = [];
    if (rawHistory is List && rawHistory.isNotEmpty) {
      for (final m in rawHistory) {
        if (m is Map) {
          _messages.add({
            'isMe': m['isMe'] == true || m['sender'] == 'driver',
            'text': m['text'] ?? m['message'] ?? m['content'] ?? '',
            'time': m['time'] ?? m['timestamp'] ?? '',
          });
        }
      }
    } else if (initialMsg.trim().isNotEmpty) {
      _messages.add({
        'isMe': false,
        'text': initialMsg.trim(),
        'time': widget.thread['time']?.toString() ?? widget.thread['timestamp']?.toString() ?? 'Recently',
      });
    }

    if (convId.isNotEmpty) {
      _fetchThreadHistory(convId);
      DriverService.markConversationAsRead(convId);
    }
  }

  Future<void> _fetchThreadHistory(String convId) async {
    try {
      final res = await DriverService.getConversationMessages(convId);
      if (res['success'] == true && res['messages'] is List && mounted) {
        final list = res['messages'] as List;
        if (list.isNotEmpty) {
          setState(() {
            _messages = list.map<Map<String, dynamic>>((m) {
              final map = m is Map ? m : <String, dynamic>{};
              return {
                'isMe': map['isMe'] == true || map['sender'] == 'driver',
                'text': map['text'] ?? map['message'] ?? map['content'] ?? '',
                'time': map['time'] ?? map['timestamp'] ?? '',
              };
            }).toList();
          });
        }
      }
    } catch (_) {}
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final now = TimeOfDay.now();
    final hour = now.hourOfPeriod == 0 ? 12 : now.hourOfPeriod;
    final minute = now.minute.toString().padLeft(2, '0');
    final period = now.period == DayPeriod.am ? 'AM' : 'PM';
    final timeStr = '$hour:$minute $period';

    setState(() {
      _messages.add({
        'isMe': true,
        'text': text,
        'time': timeStr,
      });
      _textController.clear();
    });

    final convId = widget.thread['conversationId']?.toString() ?? widget.thread['id']?.toString() ?? '';
    if (convId.isNotEmpty) {
      DriverService.replyToConversation(conversationId: convId, text: text);
    }

    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final senderName = widget.thread['senderName']?.toString() ?? 'Chat';
    final initials = widget.thread['initials']?.toString() ?? 'U';

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFEDE7F6))),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xFFEDE7F6),
                  child: Text(
                    initials,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF5B3AA8)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(senderName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E1B1E))),
                      const Text('Online • Usually replies instantly', style: TextStyle(fontSize: 11, color: Color(0xFF4CAF50))),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Color(0xFF757575)),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Message Bubbles
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chat_bubble_outline_rounded, size: 48, color: Colors.grey.shade300),
                          const SizedBox(height: 10),
                          Text(
                            'Start a conversation with $senderName',
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Type a message below to send directly to the passenger',
                            style: TextStyle(fontSize: 11.5, color: Colors.grey.shade400),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      final isMe = msg['isMe'] == true;

                      return Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                          decoration: BoxDecoration(
                            color: isMe ? const Color(0xFF5B3AA8) : const Color(0xFFF3EDF7),
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(16),
                              topRight: const Radius.circular(16),
                              bottomLeft: Radius.circular(isMe ? 16 : 4),
                              bottomRight: Radius.circular(isMe ? 4 : 16),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                            children: [
                              Text(
                                msg['text'] ?? '',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isMe ? Colors.white : const Color(0xFF1E1B1E),
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                msg['time'] ?? '',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isMe ? Colors.white.withOpacity(0.7) : const Color(0xFF757575),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Bottom Input Bar
          Container(
            padding: EdgeInsets.only(
              left: 14,
              right: 14,
              top: 10,
              bottom: 10 + MediaQuery.of(context).viewInsets.bottom,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFEDE7F6))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3EDF7),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _textController,
                      decoration: const InputDecoration(
                        hintText: 'Type your message...',
                        hintStyle: TextStyle(fontSize: 13, color: Color(0xFF9E9E9E)),
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFF5B3AA8),
                  child: IconButton(
                    icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
