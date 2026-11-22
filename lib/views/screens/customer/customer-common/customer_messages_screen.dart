import 'package:flutter/material.dart';

/// Customer Messages screen (Figma 88246824).
///
/// Layout mirrors the driver Messages screen: an "All" / "Requests" pill toggle
/// over a list of conversation cards, and a bottom-sheet chat per conversation.
///
/// UI only for now: no customer messages API is documented, so [_loadThreads]
/// returns an empty list (empty state). It is the single place to wire the
/// real conversations in later. Thread maps use the same keys as the driver
/// screen: participantName/name, initials, lastMessage, time, unreadCount, id.
class CustomerMessagesScreen extends StatefulWidget {
  const CustomerMessagesScreen({super.key});

  @override
  State<CustomerMessagesScreen> createState() => _CustomerMessagesScreenState();
}

// Exact Figma values for this screen.
const Color _kPurple = Color(0xFF5C40C4);
const Color _kToggleTrack = Color(0xFFEFEAFF);
const Color _kAvatarBg = Color(0xFFEFEAFF);
const Color _kTime = Color(0xFF5D5D5D);
const Color _kPreview = Color(0xFF6E6E6E);

class _CustomerMessagesScreenState extends State<CustomerMessagesScreen> {
  int _selectedTab = 0; // 0: All, 1: Requests
  bool _isLoading = false;

  List<Map<String, dynamic>> _all = [];
  List<Map<String, dynamic>> _requests = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// TODO: wire the customer conversations API here. Return one map per
  /// conversation using the keys documented on [CustomerMessagesScreen].
  Future<List<Map<String, dynamic>>> _loadThreads() async {
    return <Map<String, dynamic>>[];
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final threads = await _loadThreads();
      if (!mounted) return;
      setState(() {
        _all = threads;
        // Requests have no design or data source yet.
        _requests = <Map<String, dynamic>>[];
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openChat(Map<String, dynamic> thread) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CustomerChatSheet(thread: thread),
    );
    if (mounted) _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Messages',
          style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.w500, color: Colors.black),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Bottom watermark illustration (20% opacity in Figma).
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: IgnorePointer(
                child: Opacity(
                  opacity: 0.2,
                  child: Image.asset(
                    'assets/images/image 31.png',
                    fit: BoxFit.fitWidth,
                    alignment: Alignment.bottomCenter,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
            Column(
              children: [
                const SizedBox(height: 12),
                _buildToggle(),
                const SizedBox(height: 16),
                Expanded(
                  child: RefreshIndicator(
                    color: _kPurple,
                    onRefresh: _loadData,
                    child: _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(color: _kPurple))
                        : _selectedTab == 0
                            ? _buildThreadList(_all)
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

  // Figma: track 377x36, radius 12, #EFEAFF; selected pill #5C40C4, radius 12;
  // labels 12px (selected: medium white, other: regular black).
  Widget _buildToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Container(
        height: 36,
        decoration: BoxDecoration(
          color: _kToggleTrack,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            _toggleTab(index: 0, label: 'All (${_all.length})'),
            _toggleTab(index: 1, label: 'Requests (${_requests.length})'),
          ],
        ),
      ),
    );
  }

  Widget _toggleTab({required int index, required String label}) {
    final selected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (_selectedTab != index) setState(() => _selectedTab = index);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? _kPurple : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
              color: selected ? Colors.white : Colors.black,
            ),
          ),
        ),
      ),
    );
  }

  Widget _emptyState({required String title, required String subtitle}) {
    // ListView so pull-to-refresh also works on the empty state.
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        Icon(Icons.chat_bubble_outline_rounded,
            size: 54, color: Colors.grey.shade400),
        const SizedBox(height: 12),
        Center(
          child: Text(title,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E1B1E))),
        ),
        const SizedBox(height: 4),
        Center(
          child: Text(subtitle,
              style: const TextStyle(fontSize: 12, color: Color(0xFF757575))),
        ),
      ],
    );
  }

  Widget _buildRequestsList() {
    if (_requests.isEmpty) {
      return _emptyState(
        title: 'No Requests',
        subtitle: 'Requests will appear here',
      );
    }
    return _buildThreadList(_requests);
  }

  Widget _buildThreadList(List<Map<String, dynamic>> threads) {
    if (threads.isEmpty) {
      return _emptyState(
        title: 'No Messages Yet',
        subtitle: 'New messages and inquiries will appear here',
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      itemCount: threads.length,
      separatorBuilder: (_, __) => const SizedBox(height: 15),
      itemBuilder: (context, index) => _buildThreadCard(threads[index]),
    );
  }

  // Figma card: 91px tall, white, radius 12, shadow 0 0 2px #5C40C4.
  // Avatar 40 at (14, 9); name 16 at x=65; time 12 top-right; preview 14 below
  // the name; unread badge 15x15 radius 3 centred under the time.
  Widget _buildThreadCard(Map<String, dynamic> thread) {
    final name = (thread['participantName'] ??
            thread['name'] ??
            thread['senderName'] ??
            'User')
        .toString();
    final initials = (thread['initials'] ??
            (name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'U'))
        .toString();
    final preview = (thread['lastMessage'] ?? '').toString();
    final time = (thread['time'] ?? thread['timestamp'] ?? '').toString();
    final unread = (thread['unreadBadge'] as int?) ??
        ((thread['unreadCount'] as int?) ?? 0);

    return GestureDetector(
      onTap: () => _openChat(thread),
      child: Container(
        height: 91,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [BoxShadow(color: _kPurple, blurRadius: 2)],
        ),
        child: Stack(
          children: [
            Positioned(
              left: 14,
              top: 9,
              child: Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: _kAvatarBg,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  initials,
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: _kPurple),
                ),
              ),
            ),
            Positioned(
              left: 65,
              top: 9,
              right: 80,
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 16, color: Colors.black),
              ),
            ),
            Positioned(
              left: 65,
              top: 40,
              right: 80,
              child: Text(
                preview,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14, color: _kPreview),
              ),
            ),
            Positioned(
              right: 9,
              top: 9,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    time,
                    style: const TextStyle(fontSize: 12, color: _kTime),
                  ),
                  const SizedBox(height: 3),
                  if (unread > 0)
                    Container(
                      width: 15,
                      height: 15,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _kPurple,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        '$unread',
                        style: const TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w500,
                            color: Colors.white),
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

/// Chat bottom sheet for one conversation. Sending is local only until the
/// customer messages API is wired in.
class _CustomerChatSheet extends StatefulWidget {
  final Map<String, dynamic> thread;

  const _CustomerChatSheet({required this.thread});

  @override
  State<_CustomerChatSheet> createState() => _CustomerChatSheetState();
}

class _CustomerChatSheetState extends State<_CustomerChatSheet> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];

  @override
  void initState() {
    super.initState();
    final rawHistory = widget.thread['chatHistory'];
    final initialMsg = (widget.thread['lastMessage'] ?? '').toString().trim();

    if (rawHistory is List && rawHistory.isNotEmpty) {
      for (final m in rawHistory) {
        if (m is Map) {
          _messages.add({
            'isMe': m['isMe'] == true || m['sender'] == 'customer',
            'text': m['text'] ?? m['message'] ?? m['content'] ?? '',
            'time': m['time'] ?? m['timestamp'] ?? '',
          });
        }
      }
    } else if (initialMsg.isNotEmpty) {
      _messages.add({
        'isMe': false,
        'text': initialMsg,
        'time': (widget.thread['time'] ?? widget.thread['timestamp'] ?? '')
            .toString(),
      });
    }
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final now = TimeOfDay.now();
    final hour = now.hourOfPeriod == 0 ? 12 : now.hourOfPeriod;
    final minute = now.minute.toString().padLeft(2, '0');
    final period = now.period == DayPeriod.am ? 'AM' : 'PM';

    setState(() {
      _messages.add({'isMe': true, 'text': text, 'time': 'minute $period'});
      _textController.clear();
    });

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
    final name = (widget.thread['participantName'] ??
            widget.thread['name'] ??
            widget.thread['senderName'] ??
            'Chat')
        .toString();
    final initials = (widget.thread['initials'] ??
            (name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'U'))
        .toString();

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: _kToggleTrack)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: _kAvatarBg,
                  child: Text(initials,
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: _kPurple)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Colors.black),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Color(0xFF757575)),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Bubbles
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chat_bubble_outline_rounded,
                              size: 48, color: Colors.grey.shade300),
                          const SizedBox(height: 10),
                          Text(
                            'Start a conversation with $name',
                            style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500),
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
                        alignment:
                            isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.75),
                          decoration: BoxDecoration(
                            color: isMe ? _kPurple : _kToggleTrack,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(16),
                              topRight: const Radius.circular(16),
                              bottomLeft: Radius.circular(isMe ? 16 : 4),
                              bottomRight: Radius.circular(isMe ? 4 : 16),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: isMe
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                            children: [
                              Text(
                                (msg['text'] ?? '').toString(),
                                style: TextStyle(
                                    fontSize: 13,
                                    color: isMe ? Colors.white : Colors.black),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                (msg['time'] ?? '').toString(),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isMe
                                      ? Colors.white.withValues(alpha: 0.7)
                                      : _kTime,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Input bar
          Container(
            padding: EdgeInsets.only(
              left: 14,
              right: 14,
              top: 10,
              bottom: 10 + MediaQuery.of(context).viewInsets.bottom,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: _kToggleTrack)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: _kToggleTrack,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _textController,
                      decoration: const InputDecoration(
                        hintText: 'Type your message...',
                        hintStyle:
                            TextStyle(fontSize: 13, color: Color(0xFF9E9E9E)),
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  radius: 20,
                  backgroundColor: _kPurple,
                  child: IconButton(
                    icon: const Icon(Icons.send_rounded,
                        color: Colors.white, size: 18),
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