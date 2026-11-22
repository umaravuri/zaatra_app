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
import 'active_ride_card.dart';
import 'cancelled_ride_card.dart';

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

  // Matches the 5 tabs in Figma (88246763-67)
  final List<String> _tabs = const [
    'Upcoming',
    'Completed',
    'Active',
    'Pending',
    'Cancelled',
  ];

  bool _isLoading = true;
  List<CustomerBookingItem> _allBookings = [];
  final Map<String, List<CustomerBookingItem>> _buckets = {};

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
          _buckets.clear();
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

  /// Buckets by [CustomerBookingItem.state] (derived once from the raw API status).
  /// Bookings with an unrecognised status stay visible under Upcoming.
  List<CustomerBookingItem> _getBookingsForTab(String tab) {
    return _buckets.putIfAbsent(tab, () {
      return _allBookings.where((booking) {
        switch (tab) {
          case 'Active':
            return booking.state == BookingState.active;
          case 'Completed':
            return booking.state == BookingState.completed;
          case 'Pending':
            return booking.state == BookingState.pending;
          case 'Cancelled':
            return booking.state == BookingState.cancelled;
          case 'Upcoming':
          default:
            return booking.state == BookingState.upcoming || booking.state == BookingState.unknown;
        }
      }).toList();
    });
  }

  Future<void> _onBookingTapped(CustomerBookingItem booking) async {
    if (booking.category == 'Ride') {
      final changed = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => RideConfirmedDetailScreen112(
            bookingId: booking.refId,
            bookingData: booking.rawJson,
            state: booking.state,
          ),
        ),
      );
      // Cancelled / rated from the detail screen: reload so the tab buckets update.
      if (changed == true && mounted) _fetchAllBookings();
    } else if (booking.category == 'Heritage Sites') {
      _showBookingSummarySheet(booking);
    } else {
      // Stay / Banquet Halls
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CustomerBookingDetailsScreen(booking: booking),
        ),
      );
    }
  }

  /// Heritage bookings have no dedicated detail screen; show their own summary
  /// instead of dropping the user into the generic heritage catalog.
  void _showBookingSummarySheet(CustomerBookingItem booking) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(booking.title,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const SizedBox(height: 6),
            Text(booking.subtitle, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            Text('Status: ${booking.status}',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: booking.statusColor)),
            if (booking.refId.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text('Booking ID: ${booking.refId}',
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            ],
            const SizedBox(height: 6),
            Text('Amount: ${booking.price}',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const HeritagePlacesScreen()),
                  );
                },
                child: const Text('Explore more heritage places'),
              ),
            ),
          ],
        ),
      ),
    );
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
          if (booking.state == BookingState.active && booking.category.toLowerCase() == 'ride') {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: ActiveRideCard(
                booking: booking,
                onViewDetails: () => _onBookingTapped(booking),
              ),
            );
          }
          if (booking.state == BookingState.cancelled) {
            if (booking.category.toLowerCase() == 'ride') {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: CancelledRideCard(
                  booking: booking,
                  onViewDetails: () => _onBookingTapped(booking),
                ),
              );
            }
            return _buildCancelledCard(booking);
          }
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
      case 'Cancelled':
        return Icons.cancel_outlined;
      default:
        return Icons.event_note_outlined;
    }
  }

  /// Cancelled booking card (Figma 88246766): optional "Auto-Cancelled" label,
  /// paid amount, refund status and an outlined View Details button.
  Widget _buildCancelledCard(CustomerBookingItem booking) {
    final raw = booking.rawJson;
    final rawStatus = (raw['status'] ?? '').toString().toLowerCase();
    final isAuto = rawStatus.contains('auto') || raw['autoCancelled'] == true;
    final refundText = (raw['refundMessage'] ?? raw['refundStatus'] ?? raw['refundNote'] ?? '').toString().trim();
    final hasPrice = booking.price.isNotEmpty && booking.price != '—';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isAuto) ...[
            const Text('Auto-Cancelled',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 10),
          ],
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
                    Text(booking.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary)),
                    const SizedBox(height: 4),
                    Text(booking.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
          if (hasPrice) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F8F0),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('Paid ${booking.price}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.success)),
            ),
          ],
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 10),
          const Text('Refund status',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: AppColors.primary)),
          const SizedBox(height: 4),
          Text(
            refundText.isNotEmpty
                ? refundText
                : 'Any refund is credited to your original payment method as per the cancellation policy.',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 42,
            child: OutlinedButton(
              onPressed: () => _onBookingTapped(booking),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('View Details',
                  style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary)),
            ),
          ),
        ],
      ),
    );
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
                booking.state == BookingState.completed) ...[
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  InkWell(
                    onTap: () {
                      CustomerRateRideSheet.show(
                        context,
                        // rawJson carries rideId / driverId, which the sheet needs to load and submit the rating.
                        bookingData: booking.rawJson,
                        bookingId: booking.refId,
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
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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