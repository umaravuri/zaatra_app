import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../services/host_api_service.dart';
import 'widgets/host_components.dart';
import 'widgets/host_form_widgets.dart';

const Color _purple = Color(0xFF5E42C2);
const Color _border = Color(0xFFE5E4ED);

/// Formats a number with Indian digit grouping, e.g. 1234567 -> 12,34,567.
String _inr(num value) {
  final n = value.round().abs();
  final s = n.toString();
  String out;
  if (s.length <= 3) {
    out = s;
  } else {
    var rest = s.substring(0, s.length - 3);
    final parts = <String>[];
    while (rest.length > 2) {
      parts.insert(0, rest.substring(rest.length - 2));
      rest = rest.substring(0, rest.length - 2);
    }
    if (rest.isNotEmpty) parts.insert(0, rest);
    out = '${parts.join(',')},${s.substring(s.length - 3)}';
  }
  return value < 0 ? '-$out' : out;
}

/// Chat with a customer, or a booking request the host can answer.
/// Figma: frame request 7 (node 1:4788)
/// Figma: frame request 8 (node 1:4839)
class HostConversationScreen extends StatefulWidget {
  const HostConversationScreen({super.key, required this.conversationId});

  final String conversationId;

  @override
  State<HostConversationScreen> createState() => _HostConversationScreenState();
}

class _HostConversationScreenState extends State<HostConversationScreen> {
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();

  Map<String, dynamic>? _conv;
  bool _loading = true;
  String? _error;
  bool _busy = false;
  bool _changed = false;

  Timer? _timer;
  int _remaining = 0;

  Map<String, dynamic>? get _request => _conv?['request'] as Map<String, dynamic>?;

  bool get _isOpen {
    final s = _request?['status'];
    return s == 'pending' || s == 'countered';
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Map<String, dynamic> _toMap(Object? c) => Map<String, dynamic>.from(c as Map);

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final res = await HostApiService.getConversation(widget.conversationId);
    if (!mounted) return;
    if (res['success'] == true) {
      _applyConversation(_toMap(res['conversation']), resetTimer: true);
      setState(() => _loading = false);
    } else {
      setState(() {
        _loading = false;
        _error = res['message']?.toString() ?? 'Could not load conversation';
      });
    }
  }

  void _applyConversation(Map<String, dynamic> conv, {bool resetTimer = false}) {
    _conv = conv;
    if (resetTimer) {
      _remaining = (_request?['expiresInSeconds'] as num?)?.toInt() ?? 0;
      _startTimer();
    }
    _scrollToEnd();
  }

  void _startTimer() {
    _timer?.cancel();
    if (!_isOpen || _remaining <= 0) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() {
        _remaining--;
        if (_remaining <= 0 || !_isOpen) t.cancel();
      });
    });
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  String _mmss(int secs) {
    final s = secs < 0 ? 0 : secs;
    return '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';
  }

  // ---------------------------------------------------------------- actions

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _busy) return;
    setState(() => _busy = true);
    final res = await HostApiService.sendMessage(
      conversationId: widget.conversationId,
      text: text,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (res['success'] == true) {
      _input.clear();
      _changed = true;
      setState(() {
        final conv = res['conversation'];
        if (conv != null) {
          _applyConversation(_toMap(conv));
        }
      });
    } else {
      showHostError(context, res['message']?.toString() ?? 'Could not send message');
    }
  }

  Future<bool> _confirm(String title, String body, String yes) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Text(body, style: GoogleFonts.poppins(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.black54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(yes, style: GoogleFonts.poppins(color: _purple)),
          ),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _respond(String action) async {
    if (_busy) return;
    final accept = action == 'accept';
    final ok = await _confirm(
      accept ? 'Accept request' : 'Decline request',
      accept
          ? 'Do you want to accept this booking request?'
          : 'Do you want to decline this booking request?',
      accept ? 'Accept' : 'Decline',
    );
    if (!ok || !mounted) return;
    setState(() => _busy = true);
    final res = await HostApiService.respondToRequest(
      conversationId: widget.conversationId,
      action: action,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (res['success'] == true) {
      _changed = true;
      setState(() {
        final conv = res['conversation'];
        if (conv != null) _applyConversation(_toMap(conv));
        _timer?.cancel();
      });
      if (accept) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request accepted. It is now in your Upcoming bookings.'),
          ),
        );
      }
    } else {
      showHostError(context, res['message']?.toString() ?? 'Could not update request');
    }
  }

  Future<void> _counter() async {
    final req = _request;
    if (req == null || _busy) return;
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _CounterOfferSheet(
        details: _toMap(req['details']),
        price: (req['price'] as num?) ?? 0,
        taxes: (req['taxes'] as num?) ?? 0,
      ),
    );
    if (result == null || !mounted) return;
    setState(() => _busy = true);
    final res = await HostApiService.sendCounterOffer(
      conversationId: widget.conversationId,
      details: result['details'] as Map<String, dynamic>,
      price: result['price'] as num,
      taxes: result['taxes'] as num,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (res['success'] == true) {
      _changed = true;
      setState(() {
        final conv = res['conversation'];
        if (conv != null) _applyConversation(_toMap(conv));
      });
    } else {
      showHostError(context, res['message']?.toString() ?? 'Could not send counter offer');
    }
  }

  // ------------------------------------------------------------------ build

  @override
  Widget build(BuildContext context) {
    final title = (_conv?['name'] ?? '').toString();
    final req = _request;
    final String barTitle;
    if (req == null) {
      barTitle = title;
    } else if (req['kind'] == 'event') {
      barTitle = _eventTitle(req, title);
    } else {
      barTitle = 'Request';
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.pop(context, _changed);
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              HostTopBar(
                title: barTitle,
                onBack: () => Navigator.pop(context, _changed),
              ),
              Expanded(child: _content()),
            ],
          ),
        ),
      ),
    );
  }

  String _eventTitle(Map<String, dynamic> req, String fallback) {
    final details = req['details'] as Map?;
    final hall = details?['Hall']?.toString();
    return (hall == null || hall.isEmpty) ? fallback : hall;
  }

  Widget _content() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: _purple));
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(_error!,
                  textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 14)),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _load,
              style: ElevatedButton.styleFrom(backgroundColor: _purple),
              child: Text('Retry', style: GoogleFonts.poppins(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    final req = _request;
    final messages = (_conv?['messages'] as List? ?? []).map(_toMap).toList();
    final children = <Widget>[];

    if (req != null) {
      if (_isOpen) {
        children.add(_banner());
        children.add(const SizedBox(height: 12));
      }
      children.add(Text(
        'Customer : ${_conv?['name'] ?? ''}',
        style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
      ));
      children.add(const SizedBox(height: 10));
      children.add(_requestBubble(req));
      if (_isOpen) {
        children.add(const SizedBox(height: 10));
        children.add(_actions());
      }
      children.add(const SizedBox(height: 16));
    }

    for (final m in messages) {
      // For requests the details bubble already shows the first customer note.
      children.add(_messageBubble(m));
    }

    return Column(
      children: [
        Expanded(
          child: ListView(
            controller: _scroll,
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            children: children,
          ),
        ),
        _inputBar(),
      ],
    );
  }

  Widget _banner() {
    final expired = _remaining <= 0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _purple.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        expired
            ? 'This request has expired'
            : 'Reply within ${_mmss(_remaining)} to avoid cancellation',
        style: GoogleFonts.poppins(
            fontSize: 13, fontWeight: FontWeight.w500, color: _purple),
      ),
    );
  }

  Widget _requestBubble(Map<String, dynamic> req) {
    final details = _toMap(req['details']);
    final price = (req['price'] as num?) ?? 0;
    final taxes = (req['taxes'] as num?) ?? 0;
    final isEvent = req['kind'] == 'event';
    final priceLine = isEvent
        ? '₹${_inr(price)} + ₹${_inr(taxes)} taxes and charges'
        : 'Rs. ${_inr(price)}+₹${_inr(taxes)} Taxes and charges';
    final lines = <String>[
      for (final e in details.entries) '${e.key} : ${e.value}',
      priceLine,
    ];
    final style = GoogleFonts.poppins(fontSize: 13, color: Colors.white, height: 1.5);
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _purple,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final l in lines) Text(l, style: style),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                _firstMessageTime(),
                style: GoogleFonts.poppins(
                    fontSize: 10, color: Colors.white.withValues(alpha: 0.8)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _firstMessageTime() {
    final msgs = _conv?['messages'] as List? ?? [];
    if (msgs.isEmpty) return (_conv?['time'] ?? '').toString();
    return ((msgs.first as Map)['time'] ?? '').toString();
  }

  Widget _actions() {
    final enabled = _remaining > 0 && !_busy;
    return Align(
      alignment: Alignment.centerRight,
      child: Wrap(
        spacing: 8,
        children: [
          _pill('Accept', true, enabled ? () => _respond('accept') : null),
          _pill('Counter offer', false, enabled ? _counter : null),
          _pill('Decline', false, enabled ? () => _respond('decline') : null),
        ],
      ),
    );
  }

  Widget _pill(String label, bool filled, VoidCallback? onTap) {
    final disabled = onTap == null;
    final color = disabled ? Colors.black26 : _purple;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: filled ? color : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: filled ? Colors.white : color,
          ),
        ),
      ),
    );
  }

  Widget _messageBubble(Map<String, dynamic> m) {
    final from = m['from'];
    final text = (m['text'] ?? '').toString();
    final time = (m['time'] ?? '').toString();

    if (from == 'system') {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(text,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54)),
          ),
        ),
      );
    }

    final mine = from == 'host';
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: mine ? _purple : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: mine ? null : Border.all(color: _border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              text,
              style: GoogleFonts.poppins(
                  fontSize: 13, color: mine ? Colors.white : Colors.black87),
            ),
            const SizedBox(height: 2),
            Text(
              time,
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: mine ? Colors.white.withValues(alpha: 0.8) : Colors.black45,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _inputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _input,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
              style: GoogleFonts.poppins(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Type a message....',
                hintStyle: GoogleFonts.poppins(fontSize: 14, color: Colors.black38),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: _border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: _purple),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          InkWell(
            onTap: _send,
            customBorder: const CircleBorder(),
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(color: _purple, shape: BoxShape.circle),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet with an editable copy of the request details.
class _CounterOfferSheet extends StatefulWidget {
  const _CounterOfferSheet({
    required this.details,
    required this.price,
    required this.taxes,
  });

  final Map<String, dynamic> details;
  final num price;
  final num taxes;

  @override
  State<_CounterOfferSheet> createState() => _CounterOfferSheetState();
}

class _CounterOfferSheetState extends State<_CounterOfferSheet> {
  late final Map<String, TextEditingController> _fields;
  late final TextEditingController _price;
  late final TextEditingController _taxes;

  @override
  void initState() {
    super.initState();
    _fields = {
      for (final e in widget.details.entries)
        e.key: TextEditingController(text: '${e.value}'),
    };
    _price = TextEditingController(text: widget.price.toString());
    _taxes = TextEditingController(text: widget.taxes.toString());
  }

  @override
  void dispose() {
    for (final c in _fields.values) {
      c.dispose();
    }
    _price.dispose();
    _taxes.dispose();
    super.dispose();
  }

  void _submit() {
    final price = num.tryParse(_price.text.trim());
    final taxes = num.tryParse(_taxes.text.trim());
    if (price == null || price < 0) {
      showHostError(context, 'Enter a valid price');
      return;
    }
    if (taxes == null || taxes < 0) {
      showHostError(context, 'Enter valid taxes');
      return;
    }
    Navigator.pop(context, <String, dynamic>{
      'details': <String, dynamic>{
        for (final e in _fields.entries) e.key: e.value.text.trim(),
      },
      'price': price,
      'taxes': taxes,
    });
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 6),
        child: Text(text,
            style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500)),
      );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Counter offer',
                  style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
              for (final e in _fields.entries) ...[
                _label(e.key),
                HostTextField(controller: e.value, hint: e.key),
              ],
              _label('Price'),
              HostTextField(controller: _price, hint: 'Price', numeric: true),
              _label('Taxes and charges'),
              HostTextField(controller: _taxes, hint: 'Taxes', numeric: true),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _purple,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                  child: Text('Send',
                      style: GoogleFonts.poppins(
                          color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

