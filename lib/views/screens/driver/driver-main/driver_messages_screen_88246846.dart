import 'package:flutter/material.dart';
import '../../../../services/driver_service.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
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
                  child: _selectedTab == 1
                      // Requests go straight to the booking requests (Booking request /
                      // Accepted / Denied); the view has its own loader and refresh.
                      ? DriverBookingRequestsView(
                          key: const ValueKey('messages_requests_view'),
                          onCountsChanged: (count) {
                            if (mounted && count != _totalRequests) {
                              setState(() => _totalRequests = count);
                            }
                          },
                        )
                      : RefreshIndicator(
                          color: const Color(0xFF5B3AA8),
                          onRefresh: _loadData,
                          child: _isLoading
                              ? const Center(child: CircularProgressIndicator(color: Color(0xFF5B3AA8)))
                              : _buildMessagesList(),
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
                  color: Colors.black.withValues(alpha: 0.02),
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

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final now = TimeOfDay.now();
    final hour = now.hourOfPeriod == 0 ? 12 : now.hourOfPeriod;
    final minute = now.minute.toString().padLeft(2, '0');
    final period = now.period == DayPeriod.am ? 'AM' : 'PM';
    final timeStr = '$hour:$minute $period';

    final message = <String, dynamic>{
      'isMe': true,
      'text': text,
      'time': timeStr,
    };

    setState(() {
      _messages.add(message);
      _textController.clear();
    });

    final convId = widget.thread['conversationId']?.toString() ?? widget.thread['id']?.toString() ?? '';
    bool sent = false;
    if (convId.isNotEmpty) {
      try {
        final res = await DriverService.replyToConversation(conversationId: convId, text: text);
        sent = res['success'] == true;
      } catch (_) {}
    }

    // If the message did not reach the server, take it back out of the chat and
    // restore the text so the driver can retry instead of believing it was sent.
    if (!sent && mounted) {
      setState(() {
        _messages.remove(message);
        _textController.text = text;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Message not sent. Please check your connection and try again.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
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
                                  color: isMe ? Colors.white.withValues(alpha: 0.7) : const Color(0xFF757575),
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