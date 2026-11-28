import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../services/ride_service.dart';

/// In-app chat between the passenger and the driver of a booking.
///
/// The chat backend is not available yet (see [RideService.getDriverChat] and
/// [RideService.sendDriverChatMessage]), so this screen is fully built but sending reports a clear
/// "not available yet" message instead of pretending a message was delivered.
class RideChatScreen extends StatefulWidget {
  final String bookingId;
  final String? rideId;
  final String driverName;
  final String vehicleInfo;

  const RideChatScreen({
    super.key,
    required this.bookingId,
    this.rideId,
    this.driverName = 'Driver',
    this.vehicleInfo = '',
  });

  @override
  State<RideChatScreen> createState() => _RideChatScreenState();
}

class _RideChatScreenState extends State<RideChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];

  Timer? _refreshTimer;
  bool _isLoading = true;
  bool _isSending = false;
  bool _chatAvailable = true;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    // Pick up new messages from the driver while the screen is open.
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) => _loadMessages(silent: true));
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages({bool silent = false}) async {
    if (!silent && mounted) setState(() => _isLoading = true);

    Map<String, dynamic> res;
    try {
      res = await RideService.getDriverChat(widget.bookingId);
    } catch (_) {
      res = {'success': false};
    }
    if (!mounted) return;

    final serverMessages = res['messages'] is List
        ? (res['messages'] as List).whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList()
        : <Map<String, dynamic>>[];

    setState(() {
      _chatAvailable = res['available'] != false;
      _isLoading = false;
      if (res['success'] == true && serverMessages.isNotEmpty) {
        _messages
          ..clear()
          ..addAll(serverMessages);
      }
    });
  }

  String _timeNow() {
    final now = TimeOfDay.now();
    final hour = now.hourOfPeriod == 0 ? 12 : now.hourOfPeriod;
    final minute = now.minute.toString().padLeft(2, '0');
    return '$hour:$minute ${now.period == DayPeriod.am ? 'AM' : 'PM'}';
  }

  void _scrollToBottom() {
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

  Future<void> _send() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isSending) return;

    final message = <String, dynamic>{'isMe': true, 'text': text, 'time': _timeNow()};
    setState(() {
      _isSending = true;
      _messages.add(message);
      _textController.clear();
    });
    _scrollToBottom();

    Map<String, dynamic> res;
    try {
      res = await RideService.sendDriverChatMessage(bookingId: widget.bookingId, text: text);
    } catch (_) {
      res = {'success': false, 'message': 'Message not sent. Please check your connection and try again.'};
    }
    if (!mounted) return;

    if (res['success'] != true) {
      // Take the message back out of the chat and restore the text so nothing looks sent when it was not.
      setState(() {
        _isSending = false;
        _messages.remove(message);
        _textController.text = text;
        _textController.selection = TextSelection.collapsed(offset: text.length);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message']?.toString() ?? 'Message not sent. Please try again.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isSending = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            const CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primaryBackground,
              child: Icon(Icons.person_rounded, color: AppColors.primary),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.driverName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  if (widget.vehicleInfo.trim().isNotEmpty)
                    Text(
                      widget.vehicleInfo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (!_chatAvailable)
              Container(
                width: double.infinity,
                color: AppColors.accentLight,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: const Text(
                  'Chat with the driver is not available yet. You can still call your driver from the ride screen.',
                  style: TextStyle(fontSize: 12.5, color: AppColors.textPrimary),
                ),
              ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : _messages.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 32),
                            child: Text(
                              'No messages yet.\nSay hello to your driver.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
                            ),
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) => _buildBubble(_messages[index]),
                        ),
            ),
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildBubble(Map<String, dynamic> m) {
    final isMe = m['isMe'] == true;
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? AppColors.primary : AppColors.inputBackground,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              (m['text'] ?? '').toString(),
              style: TextStyle(fontSize: 14.5, color: isMe ? Colors.white : AppColors.textPrimary),
            ),
            const SizedBox(height: 4),
            Text(
              (m['time'] ?? '').toString(),
              style: TextStyle(fontSize: 10.5, color: isMe ? Colors.white70 : AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              minLines: 1,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
              decoration: InputDecoration(
                hintText: 'Type a message',
                filled: true,
                fillColor: AppColors.inputBackground,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            tooltip: 'Send',
            onPressed: _isSending ? null : _send,
            style: IconButton.styleFrom(backgroundColor: AppColors.primary),
            icon: _isSending
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.send_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }
}