import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/navigation/app_navigator.dart';
import '../../../models/host_updated_property_draft_model.dart';
import '../../../services/auth_service.dart';
import '../../../services/host_api_service.dart';
import 'widgets/revenue_wave_chart.dart';
import 'host_screen_5_property_type.dart';
import 'host_bookings_list_screen.dart';
import 'host_availability_screen.dart';
import 'host_messages_screen.dart';
import 'host_profile_screen.dart';

/// Figma: frame 1228744522 (node 1:3449)
class HostDashboardScreen extends StatefulWidget {
  static const String routeName = AppRoutes.hostHome;
  final String? userName;

  const HostDashboardScreen({
    super.key,
    this.userName,
  });

  @override
  State<HostDashboardScreen> createState() => _HostDashboardScreenState();
}

class _HostDashboardScreenState extends State<HostDashboardScreen> {
  int _currentIndex = 0;
  String _hostName = 'Manohar';
  bool _isLoading = false;
  String _selectedPeriod = 'this_month';
  String _greeting = 'Hello, Manohar 👋';
  String _subGreeting = 'Good Morning !';
  String? _avatarUrl;
  String _totalEarningsFormatted = '₹ 1,24,256';
  String _totalEarningsGrowth = '+12.9% This Month';
  String _occupancyFormatted = '78%';
  String _occupancyGrowth = '+8% this month';
  String _propertyCount = '06';
  String _activeBookingsCount = '12';
  String _upcomingBookingsCount = '5';
  String _reviewsRating = '4.8';
  List<String> _chartLabels = const ['1 May', '7 May', '14 May', '21 May', '31 May'];
  List<num> _chartData = const [40000, 75000, 95000, 125000, 160000];
  String _chartCurrency = '₹';
  List<Map<String, dynamic>> _recentBookings = [];

  @override
  void initState() {
    super.initState();
    _resolveHostName();
    _fetchDashboard();
  }

  void _resolveHostName() async {
    if (widget.userName != null && widget.userName!.trim().isNotEmpty) {
      if (mounted) setState(() => _hostName = widget.userName!.trim());
      return;
    }
    final name = await AuthService.getUserName();
    if (name.isNotEmpty && mounted) {
      setState(() => _hostName = name);
    }
  }

  Future<void> _fetchDashboard([String period = 'this_month']) async {
    setState(() => _isLoading = true);
    final res = await HostApiService.getDashboard(period: period);
    if (!mounted) return;

    if (res['success'] == true && res['dashboard'] is Map) {
      final d = res['dashboard'] as Map<String, dynamic>;
      final host = d['host'] is Map ? d['host'] as Map<String, dynamic> : {};
      final kpis = d['kpis'] is Map ? d['kpis'] as Map<String, dynamic> : {};
      final updates = d['recentUpdates'] is Map ? d['recentUpdates'] as Map<String, dynamic> : {};
      final revenue = d['revenueOverview'] is Map ? d['revenueOverview'] as Map<String, dynamic> : {};
      final chart = revenue['chart'] is Map ? revenue['chart'] as Map<String, dynamic> : {};
      final bookings = d['recentBookings'] is List
          ? (d['recentBookings'] as List).cast<Map<String, dynamic>>()
          : <Map<String, dynamic>>[];

      setState(() {
        _isLoading = false;
        if (host['name'] != null && (widget.userName == null || widget.userName!.isEmpty)) {
          _hostName = host['name'].toString();
        }
        if (host['greeting'] != null) {
          _greeting = host['greeting'].toString();
        } else {
          _greeting = 'Hello, $_hostName 👋';
        }
        if (host['subGreeting'] != null) _subGreeting = host['subGreeting'].toString();
        if (host['avatar'] != null) _avatarUrl = host['avatar'].toString();

        if (kpis['totalEarnings'] is Map) {
          _totalEarningsFormatted = kpis['totalEarnings']['formatted'] ?? _totalEarningsFormatted;
          _totalEarningsGrowth = kpis['totalEarnings']['growthBadge'] ?? _totalEarningsGrowth;
        }
        if (kpis['occupancy'] is Map) {
          _occupancyFormatted = kpis['occupancy']['formatted'] ?? _occupancyFormatted;
          _occupancyGrowth = kpis['occupancy']['growthBadge'] ?? _occupancyGrowth;
        }

        if (updates['propertyCount'] != null) {
          final count = updates['propertyCount'].toString();
          _propertyCount = count.length == 1 ? '0$count' : count;
        }
        if (updates['activeBookingsCount'] != null) {
          _activeBookingsCount = updates['activeBookingsCount'].toString();
        }
        if (updates['upcomingBookingsCount'] != null) {
          _upcomingBookingsCount = updates['upcomingBookingsCount'].toString();
        }
        if (updates['rating'] != null) {
          _reviewsRating = updates['rating'].toString();
        }

        if (chart['labels'] is List) {
          _chartLabels = (chart['labels'] as List).map((e) => e.toString()).toList();
        }
        if (chart['data'] is List) {
          _chartData = (chart['data'] as List).map((e) => (e is num ? e : 0)).toList();
        }
        if (chart['currency'] != null) {
          _chartCurrency = chart['currency'].toString();
        }

        _recentBookings = bookings;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  void _onPeriodChanged(String periodLabel) {
    String apiPeriod = 'this_month';
    if (periodLabel.toLowerCase().contains('week')) {
      apiPeriod = 'this_week';
    } else if (periodLabel.toLowerCase().contains('year')) {
      apiPeriod = 'this_year';
    }
    setState(() => _selectedPeriod = apiPeriod);
    _fetchDashboard(apiPeriod);
  }

  Future<void> _handleNavigateToPropertyWizard() async {
    // Check if there is an active draft (API 7)
    final draftRes = await HostApiService.getActiveDraft();
    if (!mounted) return;

    if (draftRes['hasActiveDraft'] == true && draftRes['draft'] != null) {
      final draftData = draftRes['draft'] as Map<String, dynamic>;
      final draftTitle = draftData['title'] ?? draftData['propertyName'] ?? 'Unfinished Property';
      final step = draftData['onboardingStep'] ?? draftData['step'] ?? 2;

      final choice = await showModalBottomSheet<String>(
        context: context,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (ctx) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2EFFD),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.edit_note_rounded, color: Color(0xFF5E42C2), size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Resume Listing Draft?',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1E1E24),
                          ),
                        ),
                        Text(
                          '$draftTitle (Step $step)',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: const Color(0xFF757585),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'You have an unfinished property draft saved. Would you like to continue from where you left off or start a new listing?',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: const Color(0xFF555566),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: const BorderSide(color: Color(0xFFE5E4ED)),
                      ),
                      onPressed: () => Navigator.pop(ctx, 'new'),
                      child: Text(
                        'Start Fresh',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF555566),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5E42C2),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      onPressed: () => Navigator.pop(ctx, 'resume'),
                      child: Text(
                        'Resume Draft',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      );

      if (!mounted) return;
      if (choice == 'resume') {
        final draftObj = HostUpdatedPropertyDraft.fromMap(draftData);
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => HostScreen5PropertyType(draft: draftObj)),
        );
        _fetchDashboard(_selectedPeriod);
        return;
      }
    }

    // Start fresh
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const HostScreen5PropertyType()),
    );
    if (mounted) {
      _fetchDashboard(_selectedPeriod);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppNavigator.buildRootExitGuard(
      context: context,
      homeName: 'Host Dashboard',
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Bottom Watermark Background Graphic (image 31.png)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: IgnorePointer(
                  child: Image.asset(
                    'assets/images/image 31.png',
                    fit: BoxFit.fitWidth,
                    alignment: Alignment.bottomCenter,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ),

              // Multi-Tab Body
              IndexedStack(
                index: _currentIndex,
                children: [
                  _buildHomeTab(context),
                  const HostBookingsListScreen(),
                  const HostAvailabilityRatesScreen(),
                  const HostMessagesScreen(),
                  HostProfileScreen(
                    userName: _hostName,
                    onManageListings: _handleNavigateToPropertyWizard,
                  ),
                ],
              ),
            ],
          ),
        ),
        bottomNavigationBar: _buildCustomBottomNav(),
      ),
    );
  }

  Widget _buildHomeTab(BuildContext context) {
    return RefreshIndicator(
      color: const Color(0xFF5E42C2),
      onRefresh: () => _fetchDashboard(_selectedPeriod),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Top Header Row
            _buildHeader(),
            if (_isLoading) ...[
              const SizedBox(height: 8),
              const LinearProgressIndicator(color: Color(0xFF5E42C2), minHeight: 2),
            ],
            const SizedBox(height: 20),

            // 2. High-Contrast Stat Cards (Earnings & Occupancy)
            _buildStatsCards(),
            const SizedBox(height: 24),

            // 3. Recent Update Section
            _buildRecentUpdatesSection(),
            const SizedBox(height: 26),

            // 4. Revenue Overview Area Chart
            RevenueWaveChart(
              period: _selectedPeriod == 'this_year'
                  ? 'This Year'
                  : (_selectedPeriod == 'this_week' ? 'This Week' : 'This Month'),
              labels: _chartLabels,
              data: _chartData,
              currency: _chartCurrency,
              onPeriodChanged: _onPeriodChanged,
            ),
            const SizedBox(height: 24),

            // 5. Recent Bookings Section
            _buildRecentBookingsSection(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            // Circular Avatar
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE5E4ED), width: 1.5),
              ),
              child: ClipOval(
                child: _avatarUrl != null && _avatarUrl!.startsWith('http')
                    ? Image.network(
                        _avatarUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildFallbackAvatar(),
                      )
                    : Image.asset(
                        'assets/images/host_avatar_sample.png',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildFallbackAvatar(),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _subGreeting,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF757585),
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  _greeting.isNotEmpty ? _greeting : 'Hello, $_hostName 👋',
                  style: GoogleFonts.poppins(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E1E24),
                  ),
                ),
              ],
            ),
          ],
        ),

        // Notification Bell with Unread Badge
        InkWell(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No new notifications.')),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: Stack(
              children: [
                const Icon(
                  Icons.notifications_none_rounded,
                  color: Color(0xFF1E1E24),
                  size: 28,
                ),
                Positioned(
                  right: 2,
                  top: 2,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE53935),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFallbackAvatar() {
    return Container(
      color: const Color(0xFF5E42C2),
      alignment: Alignment.center,
      child: Text(
        _hostName.isNotEmpty ? _hostName[0].toUpperCase() : 'H',
        style: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildStatsCards() {
    return Row(
      children: [
        // Total Earnings Card (Mint green)
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF7EE),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Earnings',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF555566),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _totalEarningsFormatted,
                  style: GoogleFonts.poppins(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF00A86B),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _totalEarningsGrowth,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF00A86B),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 14),

        // Occupancy Card (Lavender)
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF2EFFD),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Occupancy',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF555566),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _occupancyFormatted,
                  style: GoogleFonts.poppins(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF5E42C2),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _occupancyGrowth,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF5E42C2),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentUpdatesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Update',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1E1E24),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildUpdateBadge(
              icon: Icons.home_rounded,
              label: 'Property',
              value: _propertyCount,
              onTap: _handleNavigateToPropertyWizard,
            ),
            _buildUpdateBadge(
              icon: Icons.calendar_today_rounded,
              label: 'Active\nBookings',
              value: _activeBookingsCount,
              onTap: () => setState(() => _currentIndex = 1),
            ),
            _buildUpdateBadge(
              icon: Icons.event_available_rounded,
              label: 'Upcoming\nBooking',
              value: _upcomingBookingsCount,
              onTap: () => setState(() => _currentIndex = 1),
            ),
            _buildUpdateBadge(
              icon: Icons.star_rounded,
              label: 'Reviews',
              value: _reviewsRating,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HostRatingsReviewsScreen()),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUpdateBadge({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFF2EFFD),
              border: Border.all(color: const Color(0xFFE5E4ED)),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF5E42C2),
              size: 26,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 32,
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF555566),
                height: 1.25,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF5E42C2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentBookingsSection() {
    final list = _recentBookings;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Bookings',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1E1E24),
          ),
        ),
        const SizedBox(height: 12),
        if (list.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'No recent bookings',
              style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF757585)),
            ),
          )
        else
          ...list.map((booking) => _buildBookingCard(booking)),
      ],
    );
  }

  String _formatInr(num v) {
    // Indian digit grouping: 1,24,256
    final s = v.round().toString();
    if (s.length <= 3) return s;
    final last3 = s.substring(s.length - 3);
    var rest = s.substring(0, s.length - 3);
    final parts = <String>[];
    while (rest.length > 2) {
      parts.insert(0, rest.substring(rest.length - 2));
      rest = rest.substring(0, rest.length - 2);
    }
    if (rest.isNotEmpty) parts.insert(0, rest);
    return 'last3';
  }

  Widget _buildBookingCard(Map<String, dynamic> booking) {
    final isEvent = booking['type']?.toString() == 'event';
    final title = (booking['title'] ?? booking['propertyName'] ?? 'Property').toString();
    final details = booking['details'] is List
        ? (booking['details'] as List).map((e) => e.toString()).toList()
        : <String>[];
    final currency = (booking['currency'] ?? '₹').toString();
    final amount = booking['amount'] as num?;
    final taxes = booking['taxes'] as num?;
    final status = (booking['status'] ?? '').toString();
    final countdown = (booking['countdown'] ?? '').toString();
    final isConfirmed = status.toLowerCase() == 'conform' || status.toLowerCase() == 'confirmed';

    String priceText = '';
    if (amount != null) {
      priceText = '$currency ${_formatInr(amount)}';
      if (taxes != null) priceText += ' + ${_formatInr(taxes)} Taxes and charges';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E4ED)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 70,
              height: 70,
              color: const Color(0xFFF2EFFD),
              child: Icon(
                isEvent ? Icons.celebration_rounded : Icons.villa_rounded,
                color: const Color(0xFF5E42C2),
                size: 34,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1E1E24),
                        ),
                      ),
                    ),
                    if (status.isNotEmpty)
                      Text(
                        status,
                        style: GoogleFonts.poppins(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: isConfirmed ? const Color(0xFF2E7D32) : const Color(0xFFE65100),
                        ),
                      ),
                  ],
                ),
                if (countdown.isNotEmpty)
                  Text(
                    countdown,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFE65100),
                    ),
                  ),
                for (final line in details)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      line,
                      style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        color: const Color(0xFF757585),
                        height: 1.25,
                      ),
                    ),
                  ),
                if (priceText.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    priceText,
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E1E24),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFF0F0F5), width: 1.0),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
            index: 0,
            icon: Icons.home_rounded,
            label: 'Home',
          ),
          _buildNavItem(
            index: 1,
            icon: Icons.calendar_month_rounded,
            label: 'Booking',
          ),
          _buildNavItem(
            index: 2,
            icon: Icons.event_available_rounded,
            label: 'Availability\n& rate',
          ),
          _buildNavItem(
            index: 3,
            icon: Icons.chat_bubble_outline_rounded,
            label: 'Messages',
          ),
          _buildNavItem(
            index: 4,
            icon: Icons.person_outline_rounded,
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _currentIndex == index;

    return InkWell(
      onTap: () {
        setState(() => _currentIndex = index);
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected ? const Color(0xFF5E42C2) : const Color(0xFFA0A0B2),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 10.5,
                height: 1.1,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? const Color(0xFF5E42C2) : const Color(0xFF757585),
              ),
            ),
            const SizedBox(height: 4),
            // Purple underline indicator for active tab
            Container(
              height: 2.5,
              width: 20,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF5E42C2) : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Lightweight Placeholder Tabs ──────────────────────────────────────────────
class HostRatingsReviewsScreen extends StatelessWidget {
  const HostRatingsReviewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Host Ratings & Reviews'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text(
            'No host reviews yet',
            style: TextStyle(color: Colors.grey, fontSize: 15),
          ),
        ),
      ),
    );
  }
}


********************************************************************************
================================================================================
