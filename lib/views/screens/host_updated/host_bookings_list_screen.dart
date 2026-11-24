import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/host_booking_model.dart';
import '../../../services/host_api_service.dart';
import 'host_book_offline_screen.dart';
import 'host_booking_details_screen.dart';

const _purple = Color(0xFF5E42C2);
const _ink = Color(0xFF1E1E24);
const _grey = Color(0xFF757585);
const _border = Color(0xFFE5E4ED);

/// Indian digit grouping, e.g. 145000 -> 1,45,000.
String formatInr(double v) {
  final s = v.round().abs().toString();
  String out;
  if (s.length <= 3) {
    out = s;
  } else {
    var head = s.substring(0, s.length - 3);
    final tail = s.substring(s.length - 3);
    final parts = <String>[];
    while (head.length > 2) {
      parts.insert(0, head.substring(head.length - 2));
      head = head.substring(0, head.length - 2);
    }
    if (head.isNotEmpty) parts.insert(0, head);
    out = '${parts.join(",")},$tail';
  }
  return v < 0 ? '-$out' : out;
}

/// Figma: frame 1228744551 (node 1:5847)
/// Figma: frame 1228744552 (node 1:5934)
/// Figma: frame 1228744553 (node 1:6021)
/// Figma: frame 1228744554 (node 1:6108)
class HostBookingsListScreen extends StatefulWidget {
  const HostBookingsListScreen({super.key});

  @override
  State<HostBookingsListScreen> createState() => _HostBookingsListScreenState();
}

class _HostBookingsListScreenState extends State<HostBookingsListScreen> {
  static const _tabs = ['active', 'upcoming', 'completed', 'cancelled'];

  String _status = 'active';
  bool _loading = true;
  String? _error;
  List<HostBooking> _bookings = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final requested = _status;
    final res = await HostApiService.getBookings(requested);
    if (!mounted || requested != _status) return;
    if (res['success'] == true) {
      final raw = (res['bookings'] as List?) ?? const [];
      _bookings = raw
          .whereType<Map>()
          .map((m) => HostBooking.fromMap(Map<String, dynamic>.from(m)))
          .toList();
    } else {
      _error = '${res['message'] ?? 'Could not load bookings'}';
    }
    setState(() => _loading = false);
  }

  void _selectTab(String s) {
    if (s == _status) return;
    setState(() {
      _status = s;
      _bookings = [];
    });
    _load();
  }

  Future<void> _bookOffline(bool isEvent) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => HostBookOfflineScreen(isEvent: isEvent)),
    );
    if (mounted) _load();
  }

  Future<void> _openDetails(HostBooking b) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => HostBookingDetailsScreen(bookingId: b.id)),
    );
    if (mounted) _load();
  }

  String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          _header(),
          _tabBar(),
          Expanded(child: _body()),
        ],
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Booking',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: _ink,
              ),
            ),
          ),
          PopupMenuButton<bool>(
            onSelected: _bookOffline,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            itemBuilder: (_) => [
              PopupMenuItem(value: false, child: Text('Stay', style: GoogleFonts.poppins())),
              PopupMenuItem(value: true, child: Text('Event', style: GoogleFonts.poppins())),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _purple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add_rounded, size: 18, color: _purple),
                  const SizedBox(width: 4),
                  Text(
                    'Book offline',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: _purple,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabBar() {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: _tabs.map((t) {
          final selected = t == _status;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(_cap(t)),
              selected: selected,
              onSelected: (_) => _selectTab(t),
              showCheckmark: false,
              selectedColor: _purple,
              backgroundColor: Colors.white,
              side: const BorderSide(color: _border),
              labelStyle: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: selected ? Colors.white : _ink,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _body() {
    if (_loading && _bookings.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: _purple));
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 14, color: _grey),
              ),
              const SizedBox(height: 12),
              OutlinedButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }
    return RefreshIndicator(
      color: _purple,
      onRefresh: _load,
      child: _bookings.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 120),
                Center(
                  child: Text(
                    'No $_status bookings',
                    style: GoogleFonts.poppins(fontSize: 15, color: _grey),
                  ),
                ),
              ],
            )
          : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: _bookings.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) => _card(_bookings[i]),
            ),
    );
  }

  String _chipText(HostBooking b) {
    if (b.status == 'active') return b.otpBadge;
    return _cap(b.status);
  }

  Color _chipColor(String status) {
    switch (status) {
      case 'cancelled':
        return const Color(0xFFD64545);
      case 'completed':
        return const Color(0xFF2E9E5B);
      case 'active':
        return const Color(0xFFE08A00);
      default:
        return _purple;
    }
  }

  Widget _card(HostBooking b) {
    final chip = _chipText(b);
    final chipColor = _chipColor(b.status);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _purple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  b.isEvent ? Icons.celebration_rounded : Icons.hotel_rounded,
                  color: _purple,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      b.propertyName,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: _ink,
                      ),
                    ),
                    Text(
                      'Confirm ID : ${b.confirmId}',
                      style: GoogleFonts.poppins(fontSize: 12, color: _grey),
                    ),
                  ],
                ),
              ),
              if (chip.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: chipColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    chip,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: chipColor,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            b.unitName,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: _ink,
            ),
          ),
          Text(b.source, style: GoogleFonts.poppins(fontSize: 12, color: _grey)),
          if (b.customerName.isNotEmpty)
            Text(
              b.customerName,
              style: GoogleFonts.poppins(fontSize: 12, color: _grey),
            ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 14,
            runSpacing: 4,
            children: [
              _money('Due ₹ :', b.due),
              _money('Paid ₹', b.paid),
              _money('Total ₹:', b.total),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.people_alt_outlined, size: 16, color: _grey),
              const SizedBox(width: 4),
              Text(
                '${b.guests} Guests',
                style: GoogleFonts.poppins(fontSize: 12, color: _grey),
              ),
              if (b.checkInLabel.isNotEmpty) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    b.checkInLabel,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(fontSize: 12, color: _grey),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 42,
            child: ElevatedButton(
              onPressed: () => _openDetails(b),
              style: ElevatedButton.styleFrom(
                backgroundColor: _purple,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                'View Details',
                style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _money(String label, double v) {
    return Text(
      '$label ${formatInr(v)}',
      style: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: _ink,
      ),
    );
  }
}


********************************************************************************
================================================================================
