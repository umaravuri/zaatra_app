import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../services/host_api_service.dart';
import 'host_conversation_screen.dart';

/// Messages tab body: switch between all conversations and booking requests.
/// Figma: frame 1228744539 (node 1:4700)
/// Figma: frame 1228744549 (node 1:5698)
class HostMessagesScreen extends StatefulWidget {
  const HostMessagesScreen({super.key});

  @override
  State<HostMessagesScreen> createState() => _HostMessagesScreenState();
}

class _HostMessagesScreenState extends State<HostMessagesScreen> {
  static const Color _purple = Color(0xFF5E42C2);
  static const Color _border = Color(0xFFE5E4ED);

  String _filter = 'all';
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _items = [];
  int _allCount = 0;
  int _requestsCount = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    final res = await HostApiService.getConversations(_filter);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res['success'] == true) {
        _error = null;
        _items = (res['conversations'] as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        _allCount = (res['allCount'] as num?)?.toInt() ?? 0;
        _requestsCount = (res['requestsCount'] as num?)?.toInt() ?? 0;
      } else {
        _error = res['message']?.toString() ?? 'Could not load messages';
      }
    });
  }

  void _setFilter(String f) {
    if (f == _filter) return;
    _filter = f;
    _load();
  }

  Future<void> _open(Map<String, dynamic> c) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HostConversationScreen(conversationId: c['id'].toString()),
      ),
    );
    if (mounted) _load(silent: true);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Text(
              'Messages',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _segment('All ($_allCount)', _filter == 'all', () => _setFilter('all')),
                const SizedBox(width: 10),
                _segment('Requests ($_requestsCount)', _filter == 'requests',
                    () => _setFilter('requests')),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(child: _body()),
        ],
      ),
    );
  }

  Widget _segment(String label, bool selected, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? _purple : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? _purple : _border),
          ),
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: selected ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }

  Widget _body() {
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
    return RefreshIndicator(
      color: _purple,
      onRefresh: () => _load(silent: true),
      child: _items.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 120),
                Center(
                  child: Text('No messages',
                      style: GoogleFonts.poppins(fontSize: 14, color: Colors.black54)),
                ),
              ],
            )
          : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              itemCount: _items.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, i) => _card(_items[i]),
            ),
    );
  }

  Widget _card(Map<String, dynamic> c) {
    final unread = (c['unread'] as num?)?.toInt() ?? 0;
    return InkWell(
      onTap: () => _open(c),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: _purple.withValues(alpha: 0.12),
              child: Text(
                (c['initials'] ?? '').toString(),
                style: GoogleFonts.poppins(
                    fontSize: 14, fontWeight: FontWeight.w600, color: _purple),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (c['name'] ?? '').toString(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    (c['lastMessage'] ?? '').toString(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(fontSize: 13, color: Colors.black54),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  (c['time'] ?? '').toString(),
                  style: GoogleFonts.poppins(fontSize: 11, color: Colors.black45),
                ),
                const SizedBox(height: 6),
                if (unread > 0)
                  Container(
                    constraints: const BoxConstraints(minWidth: 20),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _purple,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$unread',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                          fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


********************************************************************************
================================================================================
