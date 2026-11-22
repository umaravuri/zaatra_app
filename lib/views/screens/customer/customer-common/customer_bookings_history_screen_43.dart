import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/navigation/app_navigator.dart';
import '../../../../models/customer_booking_model.dart';
import '../../../../services/booking_service.dart';
import '../customer-stay/booking_details_screen_49.dart';
import '../customer-stay/customer_home_screen_38.dart';
import '../customer-stay/heritage_places_screen.dart';
import '../customer-ride/customer_rate_ride_sheet.dart';
import '../customer-ride/ride_confirmed_detail_screen_112.dart';

class CustomerBookingsHistoryScreen extends StatefulWidget {
  final String? initialCategory;
  final String? initialTab;

  const CustomerBookingsHistoryScreen({
    super.key,
    this.initialCategory,
    this.initialTab,
  });

  @override
  State<CustomerBookingsHistoryScreen> createState() => _CustomerBookingsHistoryScreenState();
}

class _CustomerBookingsHistoryScreenState extends State<CustomerBookingsHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // The 4 requested fields
  final List<String> _tabs = const [
    'Upcoming',
    'Completed',
    'Active',
    'Pending',
  ];

  bool _isLoading = true;
  List<CustomerBookingItem> _allBookings = [];

  @override
  void initState() {
    super.initState();

    int initialIndex = 0;
    final target = (widget.initialTab ?? widget.initialCategory ?? '').toLowerCase();
    if (target.isNotEmpty) {
      final idx = _tabs.indexWhere((t) => t.toLowerCase() == target);
      if (idx != -1) initialIndex = idx;
    }

    _tabController = TabController(
      length: _tabs.length,
      vsync: this,
      initialIndex: initialIndex,
    );

    _fetchAllBookings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchAllBookings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final items = await BookingService.getAllCustomerBookings();
      if (mounted) {
        setState(() {
          _allBookings = items;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<CustomerBookingItem> _getBookingsForTab(String tab) {
    return _allBookings.where((booking) {
      final s = booking.status.toLowerCase();
      final rawS = (booking.rawJson['status'] ?? '').toString().toLowerCase();
      final statusBadge = (booking.statusBadge?['text'] ?? '').toString().toLowerCase();
      final text = '$s $rawS $statusBadge';

      switch (tab) {
        case 'Active':
          return text.contains('active') ||
              text.contains('ongoing') ||
              text.contains('in_progress') ||
              text.contains('in progress') ||
              text.contains('started') ||
              text.contains('live');

        case 'Completed':
          return text.contains('complete') ||
              text.contains('finished') ||
              text.contains('ended') ||
              text.contains('done');

        case 'Pending':
          return text.contains('pending') ||
              text.contains('requested') ||
              text.contains('awaiting') ||
              text.contains('waiting') ||
              text.contains('denied') ||
              text.contains('cancelled') ||
              text.contains('decline') ||
              text.contains('reject');

        case 'Upcoming':
        default:
          if (text.contains('complete') ||
              text.contains('finished') ||
              text.contains('ended') ||
              text.contains('done')) {
            return false;
          }
          if (text.contains('active') ||
              text.contains('started') ||
              text.contains('in_progress') ||
              text.contains('ongoing')) {
            return false;
          }
          if (text.contains('pending') ||
              text.contains('waiting') ||
              text.contains('requested') ||
              text.contains('denied') ||
              text.contains('cancel') ||
              text.contains('decline') ||
              text.contains('reject')) {
            return false;
          }
          return true; // Default fallback for scheduled / confirmed bookings
      }
    }).toList();
  }

  void _onBookingTapped(CustomerBookingItem booking) {
    if (booking.category == 'Ride') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RideConfirmedDetailScreen112(
            bookingId: booking.id.isNotEmpty ? booking.id : booking.bookingId,
            bookingData: booking.rawJson,
          ),
        ),
      );
    } else if (booking.category == 'Stay') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const CustomerBookingDetailsScreen(),
        ),
      );
    } else if (booking.category == 'Heritage Sites') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const HeritagePlacesScreen(),
        ),
      );
    } else {
      // Banquet Halls
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const CustomerBookingDetailsScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'My Bookings',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
            tooltip: 'Refresh',
            onPressed: _fetchAllBookings,
          ),
          IconButton(
            icon: const Icon(Icons.home_rounded, color: AppColors.primary),
            tooltip: 'Home',
            onPressed: () {
              AppNavigator.returnToCustomerHome(context);
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelPadding: const EdgeInsets.symmetric(horizontal: 16),
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              unselectedLabelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              tabs: _tabs.map((tab) {
                final count = _getBookingsForTab(tab).length;
                return Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(tab),
                      if (count > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$count',
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppColors.primary),
                  SizedBox(height: 16),
                  Text(
                    'Loading bookings...',
                    style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                  ),
                ],
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: _tabs.map((tab) {
                return _buildTabContent(tab);
              }).toList(),
            ),
    );
  }

  Widget _buildTabContent(String tab) {
    final bookings = _getBookingsForTab(tab);

    if (bookings.isEmpty) {
      return RefreshIndicator(
        onRefresh: _fetchAllBookings,
        color: AppColors.primary,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(32),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.15),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getTabEmptyIcon(tab),
                      size: 56,
                      color: AppColors.primary.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'No $tab Bookings',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You do not have any $tab bookings at the moment.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      AppNavigator.returnToCustomerHome(context);
                    },
                    icon: const Icon(Icons.explore_outlined, size: 18, color: Colors.white),
                    label: const Text(
                      'Explore & Book',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchAllBookings,
      color: AppColors.primary,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        itemCount: bookings.length,
        itemBuilder: (context, index) {
          final booking = bookings[index];
          return _buildBookingCard(booking, tab: tab);
        },
      ),
    );
  }

  IconData _getTabEmptyIcon(String tab) {
    switch (tab) {
      case 'Active':
        return Icons.play_circle_outline_rounded;
      case 'Upcoming':
        return Icons.event_available_rounded;
      case 'Completed':
        return Icons.task_alt_rounded;
      case 'Pending':
        return Icons.hourglass_empty_rounded;
      default:
        return Icons.event_note_outlined;
    }
  }

  Widget _buildBookingCard(CustomerBookingItem booking, {required String tab}) {
    return InkWell(
      onTap: () => _onBookingTapped(booking),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    booking.type,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: booking.statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    booking.status,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      color: booking.statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3EDF7),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(booking.icon, color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        booking.subtitle,
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  booking.price,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            if (booking.boardingPin.isNotEmpty || booking.seatNumber.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (booking.boardingPin.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: Text(
                        'PIN: ${booking.boardingPin}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1D4ED8),
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  if (booking.seatNumber.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Seats: ${booking.seatNumber}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF4B5563),
                        ),
                      ),
                    ),
                ],
              ),
            ],
            if (booking.category.toLowerCase() == 'ride' &&
                (tab == 'Completed' || booking.status.toLowerCase().contains('complete'))) ...[
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  InkWell(
                    onTap: () {
                      CustomerRateRideSheet.show(
                        context,
                        bookingId: booking.bookingId,
                        destination: booking.destinationLocation.isNotEmpty
                            ? booking.destinationLocation.split(',').first
                            : 'Destination',
                        departureTime: booking.departureTime.isNotEmpty
                            ? booking.departureTime
                            : 'Scheduled',
                      );
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3EDF7),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.star_rounded, size: 15, color: Color(0xFFFF6D00)),
                          SizedBox(width: 4),
                          Text(
                            'Rate Ride',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
