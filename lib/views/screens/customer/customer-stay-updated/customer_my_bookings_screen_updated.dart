import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../models/hotel_model.dart';
// import 'booking_details_host_pending_screen_updated.dart';
// import 'rate_stay_screen_updated.dart';
// import 'stay_host_chat_screen_updated.dart';
// import 'stay_request_change_screen_updated.dart';
// import 'stay_search_results_screen_updated.dart';

class CustomerMyBookingsScreenUpdated extends StatefulWidget {
  final int initialTabIndex;

  const CustomerMyBookingsScreenUpdated({
    super.key,
    this.initialTabIndex = 0,
  });

  @override
  State<CustomerMyBookingsScreenUpdated> createState() =>
      _CustomerMyBookingsScreenUpdatedState();
}

class _CustomerMyBookingsScreenUpdatedState
    extends State<CustomerMyBookingsScreenUpdated> {
  late int _selectedTab;
  final List<String> _tabs = [
    'Upcoming',
    'Completed',
    'Active',
    'Pending',
    'Cancelled',
  ];

  // Active Pending Host Countdown Timer (08:34 = 514s)
  Timer? _pendingCountdownTimer;
  int _pendingSecondsRemaining = 8 * 60 + 34;

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTabIndex;
    _startPendingTimer();
  }

  void _startPendingTimer() {
    _pendingCountdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_pendingSecondsRemaining > 0) {
        if (mounted) {
          setState(() {
            _pendingSecondsRemaining--;
          });
        }
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _pendingCountdownTimer?.cancel();
    super.dispose();
  }

  String get _formattedPendingTime {
    final m = _pendingSecondsRemaining ~/ 60;
    final s = _pendingSecondsRemaining % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9FD),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // 1. Purple Header Bar with Back Button matching 88246763.png
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 50, 16, 18),
              decoration: const BoxDecoration(
                color: Color(0xFF5B3AA8),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'My Booking',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48), // Balance leading back button
                ],
              ),
            ),

            const SizedBox(height: 14),

            // 2. Horizontal Scrollable Pill Tabs (Upcoming, Completed, Active, Pending, Cancelled)
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _tabs.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final isSelected = _selectedTab == index;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedTab = index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF5B3AA8) : const Color(0xFFEDE7F6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _tabs[index],
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : const Color(0xFF1E1B1E),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 12),

            // 3. Tab Body View
            Expanded(
              child: IndexedStack(
                index: _selectedTab,
                children: [
                  _buildUpcomingTab(),
                  _buildCompletedTab(),
                  _buildActiveTab(),
                  _buildPendingTab(),
                  _buildCancelledTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // TAB 1: UPCOMING (88246765.png)
  // ==========================================
  Widget _buildUpcomingTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
      children: [
        // Hotel Upcoming Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFEDE7F6), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF5B3AA8).withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Image & Details + Share
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.asset(
                      'assets/images/sample_property_1.png',
                      width: 105,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 105,
                        height: 100,
                        color: const Color(0xFFEDE7F6),
                        child: const Icon(Icons.apartment_rounded, color: Color(0xFF5B3AA8), size: 36),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Expanded(
                              child: Text(
                                'The Grand hotel',
                                style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.bold, color: Color(0xFF1E1B1E)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.share_outlined, size: 20, color: Color(0xFF1E1B1E)),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Sharing booking details...')),
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        const Text('Goa, India', style: TextStyle(fontSize: 12, color: Color(0xFF757575))),
                        const SizedBox(height: 4),
                        const Text('14 Aug - 15 Aug (1 night )', style: TextStyle(fontSize: 12, color: Color(0xFF757575))),
                        const SizedBox(height: 2),
                        const Text('4 rooms, 4 adults, 0 children\'s.', style: TextStyle(fontSize: 11.5, color: Color(0xFF757575))),
                        const SizedBox(height: 4),
                        const Text.rich(
                          TextSpan(
                            text: 'Conformed , ',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFE65100)),
                            children: [
                              TextSpan(text: 'Resort', style: TextStyle(color: Color(0xFF1E1B1E))),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Badges Row: ₹ 2500 Paid & Booking ID : 5879458
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F8F0),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        '₹ 2500 Paid',
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F8F0),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Booking ID : 5879458',
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Venue Balance Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F8F0),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFC8E6C9)),
                ),
                child: const Text(
                  'Balance Amount Pay At venue: ₹1500',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                ),
              ),

              const SizedBox(height: 12),

              // View Booking Button (Dark Green)
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Booking details are temporarily unavailable')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('View Booking', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // Ride Upcoming Card matching 88246765.png
        _buildRideUpcomingCard(),
      ],
    );
  }

  Widget _buildRideUpcomingCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEDE7F6), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5B3AA8).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Driver info row + Share icon
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.asset(
                  'assets/images/image 27.png',
                  width: 58,
                  height: 58,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const CircleAvatar(radius: 29, backgroundColor: Color(0xFFEDE7F6)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Ravi kumar', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E1B1E))),
                    const SizedBox(height: 2),
                    const Text('Swift Dizzier , 99 Trips , TS13GF2026', style: TextStyle(fontSize: 11, color: Color(0xFF757575))),
                    const SizedBox(height: 4),
                    Row(
                      children: const [
                        Icon(Icons.star_rounded, color: Color(0xFFFFB800), size: 16),
                        SizedBox(width: 3),
                        Text('4.9', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E1B1E))),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.share_outlined, size: 20, color: Color(0xFF1E1B1E)),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sharing ride details...')));
                },
              ),
            ],
          ),

          const SizedBox(height: 8),
          const Text('Cost Per Seat ₹ 250', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF1E1B1E))),

          const SizedBox(height: 12),

          // Route Timeline Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Madhapur', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E1B1E))),
                  SizedBox(height: 2),
                  Text('20 May . 2024', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E1B1E))),
                  SizedBox(height: 2),
                  Text('11 : 00 AM', style: TextStyle(fontSize: 11.5, color: Color(0xFF757575))),
                ],
              ),
              const Padding(
                padding: EdgeInsets.only(top: 10),
                child: Text('- - - - - - - - - -', style: TextStyle(color: Color(0xFFBDBDBD), fontWeight: FontWeight.bold)),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: const [
                  Text('Secundrabad', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E1B1E))),
                  SizedBox(height: 2),
                  Text('22 May . 2024', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E1B1E))),
                  SizedBox(height: 2),
                  Text('10 : 00 PM', style: TextStyle(fontSize: 11.5, color: Color(0xFF757575))),
                ],
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Seat Indicator Row
          Row(
            children: [
              _buildSeatBox(isOccupied: true),
              const SizedBox(width: 8),
              _buildSeatBox(isOccupied: true),
              const SizedBox(width: 8),
              _buildSeatBox(isOccupied: true),
              const SizedBox(width: 8),
              _buildSeatBox(isOccupied: false),
              const SizedBox(width: 10),
              const Text('Avaible one seat', style: TextStyle(fontSize: 12, color: Color(0xFF757575))),
            ],
          ),

          const SizedBox(height: 14),

          // PIN Pill
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFF3EDF7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text('PIN : 5456', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF5B3AA8))),
          ),

          const SizedBox(height: 12),

          // View Booking Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Opening Ride Booking Pass (PIN 5456)...')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5B3AA8),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('View booking', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
            ),
          ),

          const SizedBox(height: 8),
          const Center(
            child: Text('Status : Ride Conform', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF1E1B1E))),
          ),
        ],
      ),
    );
  }

  Widget _buildSeatBox({required bool isOccupied}) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: isOccupied ? const Color(0xFFEDE7F6) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isOccupied ? Colors.transparent : const Color(0xFF4CAF50), width: 1.5),
      ),
      child: Center(
        child: Icon(
          Icons.person_outline_rounded,
          size: 18,
          color: isOccupied ? const Color(0xFF1E1B1E) : Colors.transparent,
        ),
      ),
    );
  }

  // ==========================================
  // TAB 2: COMPLETED (88246763.png)
  // ==========================================
  Widget _buildCompletedTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
      children: [
        _buildCompletedHotelCard('The Grand hotel', 'Hyderabad, India', '14 Aug - 15 Aug (1 night )', '42000'),
        const SizedBox(height: 16),
        _buildCompletedHotelCard('The Grand hotel', 'Hyderabad, India', '14 Aug - 15 Aug (1 night )', '42000'),
      ],
    );
  }

  Widget _buildCompletedHotelCard(String title, String location, String dates, String price) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEDE7F6), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5B3AA8).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.asset(
                  'assets/images/sample_property_1.png',
                  width: 100,
                  height: 90,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(width: 100, height: 90, color: const Color(0xFFEDE7F6)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.bold, color: Color(0xFF1E1B1E))),
                    const SizedBox(height: 2),
                    Text(location, style: const TextStyle(fontSize: 12, color: Color(0xFF757575))),
                    const SizedBox(height: 4),
                    Text(dates, style: const TextStyle(fontSize: 12, color: Color(0xFF757575))),
                    const SizedBox(height: 4),
                    Text('Stay ₹$price,', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E1B1E))),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // 3 Action Buttons matching 88246763.png: Re-booking, Rate, View Details
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Re-booking is temporarily unavailable')),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE8F8F0),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: EdgeInsets.zero,
                    ),
                    child: const Text('Re-booking', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Rating is temporarily unavailable')),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFF3E0),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: EdgeInsets.zero,
                    ),
                    child: const Text('Rate', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFE65100))),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Booking details are temporarily unavailable')),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF3EDF7),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: EdgeInsets.zero,
                    ),
                    child: const Text('View Details', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF5B3AA8))),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 3: ACTIVE (88246764.png)
  // ==========================================
  Widget _buildActiveTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
      children: [
        // 1. Live GPS Tracking Card matching 88246764.png
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFEDE7F6), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF5B3AA8).withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Live Map Preview with Route
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: double.infinity,
                  height: 180,
                  color: const Color(0xFFF1F8E9),
                  child: Stack(
                    children: [
                      // Simulated map roads & route line
                      Center(
                        child: Icon(Icons.map_rounded, size: 80, color: Colors.green.shade100),
                      ),
                      Positioned(
                        top: 20,
                        left: 40,
                        child: const Icon(Icons.location_on, color: Color(0xFF5B3AA8), size: 28),
                      ),
                      Positioned(
                        bottom: 24,
                        right: 40,
                        child: const Icon(Icons.location_on, color: Colors.redAccent, size: 28),
                      ),
                      Positioned(
                        top: 50,
                        left: 90,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.directions_car_rounded, color: Colors.white, size: 14),
                              SizedBox(width: 4),
                              Text('Reached in 6 mins', style: TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // Driver Row
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.asset(
                      'assets/images/image 27.png',
                      width: 58,
                      height: 58,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const CircleAvatar(radius: 29, backgroundColor: Color(0xFFEDE7F6)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Ravi kumar', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E1B1E))),
                        const SizedBox(height: 2),
                        const Text('Swift Dizzier , 99 Trips , TS13GF2026', style: TextStyle(fontSize: 11, color: Color(0xFF757575))),
                        const SizedBox(height: 4),
                        Row(
                          children: const [
                            Icon(Icons.star_rounded, color: Color(0xFFFFB800), size: 16),
                            SizedBox(width: 3),
                            Text('4.9', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E1B1E))),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 6),
              const Text('Cost Per Seat ₹ 250', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF1E1B1E))),

              const SizedBox(height: 12),

              // Solid Purple PIN Pill matching 88246864.png
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 11),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFF5B3AA8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('PIN : 5456', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
              ),

              const SizedBox(height: 12),

              // Destination & EAT Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text('Destination', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E1B1E))),
                  Text('- - - - - - - - - -', style: TextStyle(color: Color(0xFF5B3AA8), fontWeight: FontWeight.bold)),
                  Text('EAT', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E1B1E))),
                ],
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text('Madhapur', style: TextStyle(fontSize: 12, color: Color(0xFF757575))),
                  Text('Time : 10:00 AM', style: TextStyle(fontSize: 12, color: Color(0xFF757575))),
                ],
              ),

              const SizedBox(height: 16),

              // Heritage Promo Card matching 88246864.png
              _buildHeritagePromoCard(),

              const SizedBox(height: 18),

              // Near by Heritages List
              const Text('Near by Heritages', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: Color(0xFF1E1B1E))),
              const SizedBox(height: 8),
              _buildNearBySectionHeader('Arriving Soon . stay need hyderabad', '10 Stay', 'Arrived in 74 mins'),
              const SizedBox(height: 8),
              _buildNearByItem('The Mount Hotel', 'Gandhana Fort', '4.9', '1,500'),
              _buildNearByItem('The Mount Hotel', 'Gandhana Fort', '4.9', '1,500'),
              _buildNearByItem('The Mount Hotel', 'Gandhana Fort', '4.9', '1,500'),

              const SizedBox(height: 18),

              // Near by Banquet Halls List
              const Text('Near by Banquet Halls', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: Color(0xFF1E1B1E))),
              const SizedBox(height: 8),
              _buildNearBySectionHeader('Arriving Soon . stay need hyderabad', '10 Events halls', 'Arrived in 74 mins'),
              const SizedBox(height: 8),
              _buildNearByItem('The Mount Hotel', 'Gandhana Fort', '4.9', '1,500', isBanquet: true),
              _buildNearByItem('The Mount Hotel', 'Gandhana Fort', '4.9', '1,500', isBanquet: true),
              _buildNearByItem('The Mount Hotel', 'Gandhana Fort', '4.9', '1,500', isBanquet: true),

              const SizedBox(height: 18),

              // Live stops timeline matching 88246864.png
              const Text('Live stops', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: Color(0xFF1E1B1E))),
              const SizedBox(height: 12),
              _buildLiveStop('9 : 00', 'Madhapur', isCar: true),
              _buildLiveStop('10 : 00', 'Ameerpet'),
              _buildLiveStop('12 : 00', 'Begumpet'),
              _buildLiveStop('01 : 00', 'Secundrabad', isLast: true),

              const SizedBox(height: 18),

              // Call & Message Buttons matching 88246864.png
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Calling Driver Ravi kumar (+91 98765 43210)...')));
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF5B3AA8)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Call To Driver', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF5B3AA8))),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Host messaging is temporarily unavailable')),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5B3AA8),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Message', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 22),

        // 2. Active Hotels & Banquet Halls Section matching 88246864.png
        const Text('Active Hotels & Banquet halls', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E1B1E))),
        const SizedBox(height: 12),

        // Active Hotel Card
        _buildActiveHotelCard(),

        const SizedBox(height: 16),

        // Active Banquet Card
        _buildActiveBanquetCard(),
      ],
    );
  }

  Widget _buildHeritagePromoCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF9FD),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDE7F6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  'assets/images/customer_dashboard_heritage_sample.png',
                  width: 90,
                  height: 70,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(width: 90, height: 70, color: const Color(0xFFEDE7F6)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Heritage near by . 12 Km', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E1B1E))),
                    SizedBox(height: 2),
                    Text('Gandhana Fort', style: TextStyle(fontSize: 11, color: Color(0xFF757575))),
                    Text('Kakatiya free . 13th c . free entry', style: TextStyle(fontSize: 10.5, color: Color(0xFF757575))),
                    Text('Open : 8 AM - 6 PM', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF1E1B1E))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text('900 Years old fort about the godavari valley open', style: TextStyle(fontSize: 11, color: Color(0xFF757575))),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 38,
            child: OutlinedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Opening Gandhana Fort Heritage details...')));
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFEDE7F6)),
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('View On Zaatra', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E1B1E))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNearBySectionHeader(String title, String count, String time) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF9FD),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              'assets/images/sample_property_1.png',
              width: 50,
              height: 40,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(width: 50, height: 40, color: const Color(0xFFEDE7F6)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF1E1B1E))),
                Text('$count  $time', style: const TextStyle(fontSize: 10.5, color: Color(0xFF757575))),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEDE7F6),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Booking Now', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF5B3AA8))),
          ),
        ],
      ),
    );
  }

  Widget _buildNearByItem(String title, String loc, String rating, String price, {bool isBanquet = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              isBanquet ? 'assets/images/event_unit_banquet_sample.png' : 'assets/images/sample_property_2.png',
              width: 54,
              height: 50,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(width: 54, height: 50, color: const Color(0xFFEDE7F6)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E1B1E))),
                Text(loc, style: const TextStyle(fontSize: 11, color: Color(0xFF757575))),
                Row(
                  children: [
                    const Icon(Icons.star_rounded, color: Color(0xFFFFB800), size: 14),
                    const SizedBox(width: 2),
                    Text(rating, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
          Text('₹$price / per night', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF1E1B1E))),
        ],
      ),
    );
  }

  Widget _buildLiveStop(String time, String stop, {bool isCar = false, bool isLast = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 50,
          child: Text(time, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E1B1E))),
        ),
        Column(
          children: [
            if (isCar)
              const Icon(Icons.directions_car_rounded, size: 16, color: Color(0xFF5B3AA8))
            else
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Color(0xFFBDBDBD),
                  shape: BoxShape.circle,
                ),
              ),
            if (!isLast)
              Container(
                width: 2,
                height: 24,
                color: const Color(0xFFE0E0E0),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(stop, style: TextStyle(fontSize: 12.5, fontWeight: isCar ? FontWeight.bold : FontWeight.w500, color: const Color(0xFF1E1B1E))),
        ),
      ],
    );
  }

  Widget _buildActiveHotelCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEDE7F6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  'assets/images/sample_property_1.png',
                  width: 90,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(width: 90, height: 80, color: const Color(0xFFEDE7F6)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('The Grand hotel', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold)),
                    SizedBox(height: 2),
                    Text('Goa, India', style: TextStyle(fontSize: 11.5, color: Color(0xFF757575))),
                    Text('14 Aug - 15 Aug (1 night )', style: TextStyle(fontSize: 11.5, color: Color(0xFF757575))),
                    Text('4 rooms, 4 adults, 0 children\'s.', style: TextStyle(fontSize: 11, color: Color(0xFF757575))),
                    SizedBox(height: 2),
                    Text('Conformed , Resort', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFFE65100))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: const Color(0xFFE8F8F0), borderRadius: BorderRadius.circular(8)),
                  child: const Text('₹ 2500 Paid', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: const Color(0xFFE8F8F0), borderRadius: BorderRadius.circular(8)),
                  child: const Text('Booking ID : 5879458', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Booking details are temporarily unavailable')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('View Details', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveBanquetCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEDE7F6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.asset(
              'assets/images/event_unit_banquet_sample.png',
              width: double.infinity,
              height: 120,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(width: double.infinity, height: 120, color: const Color(0xFFEDE7F6)),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('Goa, India', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              Text('Banquet hall', style: TextStyle(fontSize: 11, color: Color(0xFF757575))),
            ],
          ),
          const SizedBox(height: 4),
          const Text('Marriage in 28 th May , 200 members', style: TextStyle(fontSize: 11.5, color: Color(0xFF757575))),
          const Text('Morning 7:00 -13:00', style: TextStyle(fontSize: 11.5, color: Color(0xFF757575))),
          const Text('2 Ac rooms, 4 deluxe rooms', style: TextStyle(fontSize: 11.5, color: Color(0xFF757575))),
          const SizedBox(height: 4),
          const Text('Amount : ₹85,120 Pay at venue', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF1E1B1E))),
          const SizedBox(height: 10),
          Row(
            children: [
              const Expanded(
                child: Text('Booking ID : 2112', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
              ),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                ),
                child: const Text('View Details', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 4: PENDING (88246767.png)
  // ==========================================
  Widget _buildPendingTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
      children: [
        // 1. Pending Stay with Countdown Timer Card matching 88246767.png
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFEDE7F6)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'assets/images/sample_property_1.png',
                      width: 90,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(width: 90, height: 80, color: const Color(0xFFEDE7F6)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('The Ocean view', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold)),
                            Text('Pending', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFD32F2F))),
                          ],
                        ),
                        SizedBox(height: 2),
                        Text('Goa, India', style: TextStyle(fontSize: 11.5, color: Color(0xFF757575))),
                        Text('14 Aug - 15 Aug (1 night )', style: TextStyle(fontSize: 11.5, color: Color(0xFF757575))),
                        Text('4 rooms, 4 adults, 0 children\'s.', style: TextStyle(fontSize: 11, color: Color(0xFF757575))),
                        SizedBox(height: 2),
                        Text('Amount : ₹5,120', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E1B1E))),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                alignment: Alignment.center,
                decoration: BoxDecoration(color: const Color(0xFFE8F8F0), borderRadius: BorderRadius.circular(10)),
                child: const Text('View details', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
              ),
              const SizedBox(height: 12),
              // Host Info with Countdown
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Host info', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF5B3AA8))),
                  Text('Remain time $_formattedPendingTime', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFD32F2F))),
                ],
              ),
              const SizedBox(height: 4),
              const Text('Your Request is send to host we will notify you soon as host respond', style: TextStyle(fontSize: 11, color: Color(0xFF757575))),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Booking details are temporarily unavailable')),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF5B3AA8)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('View Details', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF5B3AA8))),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Edit details is temporarily unavailable')),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF5B3AA8)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Edit details', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF5B3AA8))),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Host messaging is temporarily unavailable')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5B3AA8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Message to host', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // 2. Accepted Stay Proposal Card matching 88246767.png
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFEDE7F6)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'assets/images/sample_property_1.png',
                      width: 90,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(width: 90, height: 80, color: const Color(0xFFEDE7F6)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('The Ocean view', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold)),
                            Text('Accepted', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
                          ],
                        ),
                        SizedBox(height: 2),
                        Text('Goa, India', style: TextStyle(fontSize: 11.5, color: Color(0xFF757575))),
                        Text('Marriage , 800 Guests', style: TextStyle(fontSize: 11.5, color: Color(0xFF757575))),
                        Text('2 Ac rooms , 4 Deluxe rooms', style: TextStyle(fontSize: 11, color: Color(0xFF757575))),
                        SizedBox(height: 2),
                        Text('Amount : ₹95,120', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E1B1E))),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                alignment: Alignment.center,
                decoration: BoxDecoration(color: const Color(0xFFE8F8F0), borderRadius: BorderRadius.circular(10)),
                child: const Text('View details', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
              ),
              const SizedBox(height: 10),
              const Text('Host info', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF5B3AA8))),
              const SizedBox(height: 2),
              const Text('Your Request is send to host we will notify you soon as host respond', style: TextStyle(fontSize: 11, color: Color(0xFF757575))),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 42,
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF5B3AA8)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Continue', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF5B3AA8))),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Host messaging is temporarily unavailable')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5B3AA8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Message to host', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // 3. Pending Ride Card matching 88246767.png
        _buildPendingRideCard(),
      ],
    );
  }

  Widget _buildPendingRideCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEDE7F6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.asset(
                  'assets/images/image 27.png',
                  width: 54,
                  height: 54,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const CircleAvatar(radius: 27, backgroundColor: Color(0xFFEDE7F6)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Ravi kumar', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E1B1E))),
                    const SizedBox(height: 2),
                    const Text('Swift Dizzier , 99 Trips , TS13GF2026', style: TextStyle(fontSize: 11, color: Color(0xFF757575))),
                    const SizedBox(height: 4),
                    Row(
                      children: const [
                        Icon(Icons.star_rounded, color: Color(0xFFFFB800), size: 16),
                        SizedBox(width: 3),
                        Text('4.9', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
              const Text('Pending', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFD32F2F))),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 38,
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF5B3AA8)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('View Details', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF5B3AA8))),
            ),
          ),
          const SizedBox(height: 8),
          const Text('Cost Per Seat ₹ 250', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('Madhapur\n20 May . 2024\n11 : 00 AM', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              Text('- - - - - - - -', style: TextStyle(color: Color(0xFFBDBDBD))),
              Text('Secundrabad\n22 May . 2024\n10 : 00 PM', textAlign: TextAlign.end, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildSeatBox(isOccupied: true),
              const SizedBox(width: 6),
              _buildSeatBox(isOccupied: true),
              const SizedBox(width: 6),
              _buildSeatBox(isOccupied: true),
              const SizedBox(width: 6),
              _buildSeatBox(isOccupied: false),
              const SizedBox(width: 10),
              const Text('Avaible one seat', style: TextStyle(fontSize: 12, color: Color(0xFF757575))),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Driver messaging is temporarily unavailable')),
                );
              },
              icon: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white, size: 18),
              label: const Text('Message to driver', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5B3AA8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 5: CANCELLED (88246766.png)
  // ==========================================
  Widget _buildCancelledTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
      children: [
        _buildCancelledHotelCard('The Grand hotel', 'Goa, India', '14 Aug - 15 Aug (1 night )', '4 rooms, 4 adults, 0 children\'s.', 'Change the plan', '24,520', false),
        const SizedBox(height: 16),
        _buildCancelledHotelCard('The Grand hotel', 'Goa, India', '14 Aug - 15 Aug (1 night )', '4 rooms, 4 adults, 0 children\'s.', 'Change the plan', '24,520', true),
        const SizedBox(height: 16),
        _buildCancelledRideCard(),
      ],
    );
  }

  Widget _buildCancelledHotelCard(String title, String loc, String dates, String specs, String reason, String paid, bool isAutoCancelled) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEDE7F6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isAutoCancelled) ...[
            const Text('Auto-Cancelled', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFD32F2F))),
            const SizedBox(height: 8),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  'assets/images/sample_property_1.png',
                  width: 90,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(width: 90, height: 80, color: const Color(0xFFEDE7F6)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(loc, style: const TextStyle(fontSize: 11.5, color: Color(0xFF757575))),
                    Text(dates, style: const TextStyle(fontSize: 11.5, color: Color(0xFF757575))),
                    Text(specs, style: const TextStyle(fontSize: 11, color: Color(0xFF757575))),
                    const SizedBox(height: 2),
                    Text('Region : $reason', style: const TextStyle(fontSize: 11.5, color: Color(0xFF757575))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            alignment: Alignment.center,
            decoration: BoxDecoration(color: const Color(0xFFE8F8F0), borderRadius: BorderRadius.circular(10)),
            child: Text('Paid ₹$paid', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
          ),
          const SizedBox(height: 8),
          const Text('Refund status', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF5B3AA8))),
          const SizedBox(height: 2),
          Text('Refund ₹$paid on 13 Nov 2026 was credited', style: const TextStyle(fontSize: 11, color: Color(0xFF757575))),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 40,
            child: OutlinedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Refund of ₹$paid credited to original payment source.')));
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF5B3AA8)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('View Details', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF5B3AA8))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCancelledRideCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEDE7F6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Auto-Cancelled', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFD32F2F))),
          const SizedBox(height: 8),
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.asset(
                  'assets/images/image 27.png',
                  width: 54,
                  height: 54,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const CircleAvatar(radius: 27, backgroundColor: Color(0xFFEDE7F6)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Ravi kumar', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E1B1E))),
                    const SizedBox(height: 2),
                    const Text('Swift Dizzier , 99 Trips , TS13GF2026', style: TextStyle(fontSize: 11, color: Color(0xFF757575))),
                    const SizedBox(height: 4),
                    Row(
                      children: const [
                        Icon(Icons.star_rounded, color: Color(0xFFFFB800), size: 16),
                        SizedBox(width: 3),
                        Text('4.9', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text('Cost Per Seat ₹ 250', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('Madhapur\n20 May . 2024\n11 : 00 AM', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              Text('- - - - - - - -', style: TextStyle(color: Color(0xFFBDBDBD))),
              Text('Secundrabad\n22 May . 2024\n10 : 00 PM', textAlign: TextAlign.end, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 40,
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF5B3AA8)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('View Details', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF5B3AA8))),
            ),
          ),
        ],
      ),
    );
  }
}
