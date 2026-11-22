import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../services/driver_service.dart';

class DriverEarningsHistoryScreen extends StatefulWidget {
  final String initialFilter;

  const DriverEarningsHistoryScreen({
    super.key,
    this.initialFilter = 'this_month',
  });

  @override
  State<DriverEarningsHistoryScreen> createState() => _DriverEarningsHistoryScreenState();
}

class _DriverEarningsHistoryScreenState extends State<DriverEarningsHistoryScreen> {
  // Earnings Summary State
  String _totalEarnings = '₹0';
  String _tripsCount = '0';
  String _completedCount = '0';

  bool _isLoading = true;
  bool _isLoadingMore = false;

  // Filter State (Configurable initialFilter)
  late String _selectedFilterKey;
  late String _selectedFilterLabel;
  DateTimeRange? _customDateRange;

  // Trips List & Infinite Scroll State
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _paymentRecords = [];
  int _currentPage = 1;
  int _rowsPerPage = 10;
  int _totalPages = 1;
  int _totalEntries = 0;

  // Card Expansion & Intermediate Stops Cache
  final Set<int> _expandedTripIndices = <int>{};
  final Map<String, List<Map<String, dynamic>>> _intermediateStopsCache = {};
  final Set<String> _loadingTripIds = <String>{};

  @override
  void initState() {
    super.initState();
    _selectedFilterKey = widget.initialFilter;
    switch (_selectedFilterKey) {
      case 'all':
        _selectedFilterLabel = 'All';
        break;
      case 'today':
        _selectedFilterLabel = 'Today';
        break;
      case 'yesterday':
        _selectedFilterLabel = 'Yesterday';
        break;
      case 'this_week':
        _selectedFilterLabel = 'This Week';
        break;
      case 'this_month':
      default:
        _selectedFilterKey = 'this_month';
        _selectedFilterLabel = 'This Month';
        break;
    }

    _scrollController.addListener(_onScroll);
    _fetchFuelShareData(filterKey: _selectedFilterKey);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.position.pixels;
      if (currentScroll >= maxScroll - 160) {
        if (!_isLoading && !_isLoadingMore && _currentPage < _totalPages) {
          _fetchFuelShareData(page: _currentPage + 1, isLoadMore: true);
        }
      }
    }
  }

  String _formatDateToYMD(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return 'm-$d';
  }

  Future<void> _fetchFuelShareData({
    int? page,
    int? limit,
    String? filterKey,
    DateTimeRange? customRange,
    bool isLoadMore = false,
  }) async {
    if (isLoadMore) {
      setState(() => _isLoadingMore = true);
    } else {
      setState(() => _isLoading = true);
    }

    final activeFilter = filterKey ?? _selectedFilterKey;
    final activePage = page ?? (isLoadMore ? _currentPage + 1 : 1);
    final activeLimit = limit ?? _rowsPerPage;

    String? startStr;
    String? endStr;

    if (activeFilter == 'custom') {
      final range = customRange ?? _customDateRange;
      if (range != null) {
        startStr = _formatDateToYMD(range.start);
        endStr = _formatDateToYMD(range.end);
      }
    }

    try {
      final res = await DriverService.getFuelShareHistory(
        filter: activeFilter,
        startDate: startStr,
        endDate: endStr,
        page: activePage,
        limit: activeLimit,
      );

      if (res['success'] == true || res['data'] != null || res['records'] != null || res['trips'] != null) {
        final data = res['data'] is Map<String, dynamic> ? res['data'] as Map<String, dynamic> : res;

        // 1. Total Earnings
        final rawEarnings = data['totalEarnings'] ?? data['totalFuelShare'] ?? data['formattedTotalEarnings'] ?? data['earnings'];
        if (rawEarnings != null) {
          final earningsStr = rawEarnings.toString();
          _totalEarnings = earningsStr.startsWith('₹') ? earningsStr : '₹$earningsStr';
        }

        // 2. Summary Counts
        final rawTrips = data['totalTrips'] ?? data['tripsCount'] ?? data['trips'] ?? data['totalCount'];
        if (rawTrips != null && rawTrips is! List) {
          _tripsCount = rawTrips.toString();
        }

        final rawCompleted = data['completedTrips'] ?? data['completedCount'] ?? data['completed'];
        if (rawCompleted != null && rawCompleted is! List) {
          _completedCount = rawCompleted.toString();
        }

        // 3. Records List
        final rawList = data['records'] ?? data['trips'] ?? data['items'] ?? data['fuelShareRecords'] ?? (data['data'] is List ? data['data'] : null);
        List<Map<String, dynamic>> newItems = [];
        if (rawList is List) {
          newItems = List<Map<String, dynamic>>.from(
            rawList.map((item) => Map<String, dynamic>.from(item as Map)),
          );
        }

        // 4. Pagination Metadata
        _currentPage = (data['page'] ?? data['currentPage'] ?? activePage) as int;
        _rowsPerPage = (data['limit'] ?? data['perPage'] ?? activeLimit) as int;
        _totalEntries = (data['totalEntries'] ?? data['total'] ?? data['count'] ?? (_paymentRecords.length + newItems.length)) as int;
        _totalPages = (data['totalPages'] ?? data['pages'] ?? ((_totalEntries / _rowsPerPage).ceil().clamp(1, 999))) as int;

        if (isLoadMore) {
          _paymentRecords.addAll(newItems);
        } else {
          _paymentRecords = newItems;
        }
      }
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
          _selectedFilterKey = activeFilter;
          if (customRange != null) {
            _customDateRange = customRange;
          }
        });
      }
    }
  }

  Future<void> _selectCustomDateRange() async {
    final now = DateTime.now();
    final initialRange = _customDateRange ??
        DateTimeRange(
          start: DateTime(now.year, now.month, 1),
          end: now,
        );

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      initialDateRange: initialRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final label = '${picked.start.month} - ${picked.end.month}';
      setState(() {
        _selectedFilterKey = 'custom';
        _selectedFilterLabel = label;
        _customDateRange = picked;
        _currentPage = 1;
      });
      _fetchFuelShareData(filterKey: 'custom', customRange: picked, page: 1);
    }
  }

  void _onFilterSelected(String filterKey) {
    if (filterKey == 'custom') {
      _selectCustomDateRange();
      return;
    }

    String label = 'This Month';
    switch (filterKey) {
      case 'all':
        label = 'All';
        break;
      case 'today':
        label = 'Today';
        break;
      case 'yesterday':
        label = 'Yesterday';
        break;
      case 'this_week':
        label = 'This Week';
        break;
      case 'this_month':
      default:
        label = 'This Month';
        break;
    }

    setState(() {
      _selectedFilterKey = filterKey;
      _selectedFilterLabel = label;
      _currentPage = 1;
    });

    _fetchFuelShareData(filterKey: filterKey, page: 1);
  }

  PopupMenuItem<String> _buildPopupMenuItem(String value, String label, {IconData? icon}) {
    final isSelected = _selectedFilterKey == value;
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: isSelected ? AppColors.primary : AppColors.textSecondary),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
          ),
          if (isSelected) const Icon(Icons.check_rounded, size: 18, color: AppColors.primary),
        ],
      ),
    );
  }

  String _formatTripDate(dynamic rawDate) {
    if (rawDate == null) return '17 Aug 2026';
    final s = rawDate.toString().trim();
    if (s.isEmpty || s == '-') return '17 Aug 2026';

    // If it has comma with time like "28 Nov 2026, 12:00 AM", extract just the date portion
    String datePart = s;
    if (s.contains(',')) {
      final parts = s.split(',');
      if (parts.length >= 2 && (parts[1].toUpperCase().contains('AM') || parts[1].toUpperCase().contains('PM') || parts[1].contains(':'))) {
        datePart = parts[0].trim();
      }
    }

    try {
      final dt = DateTime.tryParse(s) ?? DateTime.tryParse(datePart);
      if (dt != null) {
        const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
      }
    } catch (_) {}
    return datePart;
  }

  String _formatTime(dynamic rawTime, String fallback) {
    if (rawTime == null) return fallback;
    final s = rawTime.toString().trim();
    if (s.isEmpty || s == '-') return fallback;
    return s;
  }

  String _formatAmount(dynamic rawAmount) {
    if (rawAmount == null) return '580';
    final s = rawAmount.toString().replaceAll('₹', '').replaceAll(',', '').trim();
    final numVal = double.tryParse(s);
    if (numVal != null) {
      return numVal.toStringAsFixed(0);
    }
    return s.isNotEmpty ? s : '580';
  }

  Widget _buildRouteConnector() {
    return SizedBox(
      width: 50,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 4,
            height: 4,
            decoration: const BoxDecoration(
              color: Color(0xFF9E9E9E),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 3),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final boxWidth = constraints.constrainWidth();
                const dashWidth = 3.0;
                const dashSpace = 2.0;
                final dashCount = (boxWidth / (dashWidth + dashSpace)).floor().clamp(1, 15);
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(dashCount, (_) {
                    return const SizedBox(
                      width: dashWidth,
                      height: 1.5,
                      child: DecoratedBox(
                        decoration: BoxDecoration(color: Color(0xFFBDBDBD)),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
          const SizedBox(width: 3),
          Container(
            width: 4,
            height: 4,
            decoration: const BoxDecoration(
              color: Color(0xFF9E9E9E),
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }

  String _calculateDuration(String departureTime, String arrivalTime, [dynamic rawDuration]) {
    if (rawDuration != null && rawDuration.toString().trim().isNotEmpty) {
      return rawDuration.toString().trim();
    }
    try {
      final s = departureTime.replaceAll(' ', '').toUpperCase();
      final e = arrivalTime.replaceAll(' ', '').toUpperCase();

      int parseMinutes(String timeStr) {
        final isPM = timeStr.contains('PM');
        final isAM = timeStr.contains('AM');
        final clean = timeStr.replaceAll('AM', '').replaceAll('PM', '');
        final parts = clean.split(':');
        if (parts.length >= 2) {
          int h = int.parse(parts[0]);
          int m = int.parse(parts[1]);
          if (isPM && h < 12) h += 12;
          if (isAM && h == 12) h = 0;
          return h * 60 + m;
        }
        return 0;
      }

      final startMins = parseMinutes(s);
      final endMins = parseMinutes(e);
      int diff = endMins - startMins;
      if (diff < 0) diff += 24 * 60;
      if (diff > 0) {
        final hrs = diff ~/ 60;
        final mins = diff % 60;
        if (hrs > 0 && mins > 0) return '${hrs}h ${mins}m';
        if (hrs > 0) return '${hrs}h';
        return '${mins}m';
      }
    } catch (_) {}
    return '5h 30m';
  }

  Future<void> _fetchTripStops(String rideId) async {
    if (rideId.isEmpty || _intermediateStopsCache.containsKey(rideId) || _loadingTripIds.contains(rideId)) {
      return;
    }

    setState(() {
      _loadingTripIds.add(rideId);
    });

    try {
      final res = await DriverService.getTripDetailForFuelShare(rideId: rideId);
      final data = res['data'] ?? res['ride'] ?? res;
      final rawStops = data['stops'] ?? data['intermediateStops'] ?? data['waypoints'] ?? [];
      final stopsList = <Map<String, dynamic>>[];

      if (rawStops is List) {
        for (final st in rawStops) {
          if (st is Map) {
            final name = (st['name'] ?? st['title'] ?? st['location'] ?? st['address'] ?? '').toString();
            final time = (st['time'] ?? st['departureTime'] ?? st['arrivalTime'] ?? '').toString();
            final type = (st['type'] ?? 'intermediate').toString();
            if (name.isNotEmpty) {
              stopsList.add({
                'name': name,
                'time': time,
                'type': type,
              });
            }
          } else if (st is String && st.isNotEmpty) {
            stopsList.add({
              'name': st,
              'time': '',
              'type': 'intermediate',
            });
          }
        }
      }

      if (mounted) {
        setState(() {
          _intermediateStopsCache[rideId] = stopsList;
          _loadingTripIds.remove(rideId);
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loadingTripIds.remove(rideId);
        });
      }
    }
  }

  Widget _buildVerticalTimeline({
    required String origin,
    required String departureTime,
    required String destination,
    required String arrivalTime,
    required List<Map<String, dynamic>> stops,
    required bool isLoadingStops,
  }) {
    return Column(
      children: [
        // 1. Origin / Pickup Location
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 2,
                  height: 28,
                  color: const Color(0xFFCBD5E1),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Pickup Location',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                      Text(
                        departureTime,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF616161),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    origin,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF212121),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        // 2. Intermediate Pickups / Stops
        if (isLoadingStops) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFA000),
                      shape: BoxShape.circle,
                    ),
                  ),
                  Container(
                    width: 2,
                    height: 24,
                    color: const Color(0xFFCBD5E1),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF5B3AA8)),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Loading intermediate stops...',
                        style: TextStyle(fontSize: 12, color: Color(0xFF757575)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ] else if (stops.isNotEmpty) ...[
          for (int i = 0; i < stops.length; i++) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFA000),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFFA000).withValues(alpha: 0.3),
                            blurRadius: 3,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 2,
                      height: 28,
                      color: const Color(0xFFCBD5E1),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Intermediate Pickup #${i + 1}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFE65100),
                            ),
                          ),
                          if ((stops[i]['time'] ?? '').toString().isNotEmpty)
                            Text(
                              stops[i]['time'].toString(),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF616161),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        stops[i]['name'] ?? stops[i]['title'] ?? 'Intermediate Stop',
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF333333),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ] else ...[
          Row(
            children: [
              Container(
                margin: const EdgeInsets.only(left: 6),
                width: 2,
                height: 24,
                color: const Color(0xFFCBD5E1),
              ),
              const SizedBox(width: 18),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Direct Route • No intermediate stops',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontStyle: FontStyle.italic,
                    color: Color(0xFF757575),
                  ),
                ),
              ),
            ],
          ),
        ],

        // 3. Destination Drop-off Stop
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: const Color(0xFF5B3AA8),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF5B3AA8).withValues(alpha: 0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
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
                      const Text(
                        'Destination',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF5B3AA8),
                        ),
                      ),
                      Text(
                        arrivalTime,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF616161),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    destination,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF212121),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildExpandedTripDetails({
    required String origin,
    required String departureTime,
    required String destination,
    required String arrivalTime,
    required String amount,
    required List<Map<String, dynamic>> stops,
    required bool isLoadingStops,
    required String duration,
    required Map<String, dynamic> row,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 24, thickness: 1, color: Color(0xFFEEEEEE)),

        // Section Title: Detailed Route & Pickups
        const Row(
          children: [
            Icon(Icons.alt_route_rounded, size: 16, color: Color(0xFF5B3AA8)),
            SizedBox(width: 6),
            Text(
              'Trip Route & Pickups',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E1E24),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Timeline: Origin -> Intermediate Stops -> Destination
        _buildVerticalTimeline(
          origin: origin,
          departureTime: departureTime,
          destination: destination,
          arrivalTime: arrivalTime,
          stops: stops,
          isLoadingStops: isLoadingStops,
        ),

        const SizedBox(height: 18),

        // Trip Timings Box
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF7F5FC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFEDE7F6)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.access_time_rounded, size: 16, color: Color(0xFF5B3AA8)),
                  const SizedBox(width: 6),
                  Text(
                    'Duration: $duration',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4A4458),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Completed ✅',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Money Made from Trip (Fuel Share Card)
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFF1F8E9), Color(0xFFE8F5E9)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFC8E6C9), width: 1.2),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: Color(0xFF2E7D32),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Money Made from Ride',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B5E20),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Net fuel share earnings credited',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF388E3C),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '₹$amount',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1B5E20),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTripRow(Map<String, dynamic> row, int index) {
    final tripNum = index + 1;
    final isExpanded = _expandedTripIndices.contains(index);

    final rawDate = row['startDate'] ?? row['departureDate'] ?? row['date'] ?? row['createdAt'];
    final formattedDate = _formatTripDate(rawDate);

    final rawAmount = row['amount'] ?? row['price'] ?? row['fare'] ?? row['fuelShare'] ?? row['totalAmount'];
    final amount = _formatAmount(rawAmount);

    final origin = (row['origin'] ?? row['from'] ?? row['startLocation'] ?? row['pickup'] ?? '').toString();
    final departureTime = _formatTime(row['departureTime'] ?? row['startTime'] ?? row['time'], '--');

    final destination = (row['destination'] ?? row['to'] ?? row['dropLocation'] ?? row['drop'] ?? '').toString();
    final arrivalTime = _formatTime(row['completedDate'] ?? row['arrivalTime'] ?? row['endTime'], '--');

    final rideId = (row['id'] ?? row['_id'] ?? row['rideId'] ?? row['bookingId'] ?? '').toString();

    // Extract stops: from row or from cache
    List<Map<String, dynamic>> stops = [];
    if (row['intermediateStops'] is List && (row['intermediateStops'] as List).isNotEmpty) {
      stops = List<Map<String, dynamic>>.from(
        (row['intermediateStops'] as List).map((s) => s is Map ? Map<String, dynamic>.from(s) : {'name': s.toString()}),
      );
    } else if (row['stops'] is List && (row['stops'] as List).isNotEmpty) {
      stops = List<Map<String, dynamic>>.from(
        (row['stops'] as List).map((s) => s is Map ? Map<String, dynamic>.from(s) : {'name': s.toString()}),
      );
    } else if (_intermediateStopsCache.containsKey(rideId)) {
      stops = _intermediateStopsCache[rideId]!;
    }

    final isLoadingStops = _loadingTripIds.contains(rideId);
    final duration = _calculateDuration(departureTime, arrivalTime, row['duration']);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              if (isExpanded) {
                _expandedTripIndices.remove(index);
              } else {
                _expandedTripIndices.add(index);
              }
            });

            if (!isExpanded && stops.isEmpty && rideId.isNotEmpty) {
              _fetchTripStops(rideId);
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isExpanded ? const Color(0xFFFAF9FD) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isExpanded ? const Color(0xFF5B3AA8).withValues(alpha: 0.35) : const Color(0xFFEEEEEE),
                width: isExpanded ? 1.4 : 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: isExpanded
                      ? const Color(0xFF5B3AA8).withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.02),
                  blurRadius: isExpanded ? 10 : 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header Row with Trip #, Date, Amount, and Chevron toggle
                Row(
                  children: [
                    Text(
                      'Trip #$tripNum',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFF26B27),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '•',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[400],
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        formattedDate,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF757575),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '₹$amount',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E1E24),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isExpanded ? const Color(0xFFEDE7F6) : const Color(0xFFF5F5F5),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                        size: 18,
                        color: isExpanded ? const Color(0xFF5B3AA8) : const Color(0xFF757575),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Collapsed Compact Route Summary
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Origin
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            origin,
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF424242),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            departureTime,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: Color(0xFF757575),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Route Connector: • - - - - •
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: _buildRouteConnector(),
                    ),

                    // Destination
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            destination,
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF424242),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            arrivalTime,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: Color(0xFF757575),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Animated Expanded Content
                AnimatedCrossFade(
                  firstChild: const SizedBox.shrink(),
                  secondChild: isExpanded
                      ? _buildExpandedTripDetails(
                          origin: origin,
                          departureTime: departureTime,
                          destination: destination,
                          arrivalTime: arrivalTime,
                          amount: amount,
                          stops: stops,
                          isLoadingStops: isLoadingStops,
                          duration: duration,
                          row: row,
                        )
                      : const SizedBox.shrink(),
                  crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 250),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Fuel Share',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Theme(
                data: Theme.of(context).copyWith(
                  cardColor: Colors.white,
                  popupMenuTheme: const PopupMenuThemeData(
                    color: Colors.white,
                    surfaceTintColor: Colors.transparent,
                  ),
                ),
                child: PopupMenuButton<String>(
                  initialValue: _selectedFilterKey,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onSelected: _onFilterSelected,
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                    _buildPopupMenuItem('all', 'All', icon: Icons.all_inclusive_rounded),
                    _buildPopupMenuItem('this_month', 'This Month'),
                    _buildPopupMenuItem('this_week', 'This Week'),
                    _buildPopupMenuItem('today', 'Today'),
                    _buildPopupMenuItem('yesterday', 'Yesterday'),
                    const PopupMenuDivider(height: 1),
                    _buildPopupMenuItem('custom', 'Custom Range', icon: Icons.calendar_month_rounded),
                  ],
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3EDF7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.tune_rounded, size: 16, color: AppColors.primary),
                        const SizedBox(width: 5),
                        Text(
                          _selectedFilterLabel,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: AppColors.primary),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Bottom Background Graphic
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

            RefreshIndicator(
              onRefresh: () => _fetchFuelShareData(page: 1),
              color: AppColors.primary,
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_isLoading) ...[
                      const LinearProgressIndicator(
                        minHeight: 2,
                        color: AppColors.primary,
                        backgroundColor: Color(0xFFF3EDF7),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // 1. Purple Header Banner Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: const BoxDecoration(
                              color: Color(0xFFFFB300),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.monetization_on_rounded, color: Colors.white, size: 28),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Total Earnings', style: TextStyle(color: Colors.white70, fontSize: 13)),
                              const SizedBox(height: 4),
                              Text(
                                _totalEarnings,
                                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 2. Trips & Completed Cards Row
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF7F5FE),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Trips', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                    const SizedBox(height: 4),
                                    Text(_tripsCount, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                                  ],
                                ),
                                const Icon(Icons.two_wheeler_rounded, color: AppColors.primary, size: 26),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF7F5FE),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Completed', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                    const SizedBox(height: 4),
                                    Text(_completedCount, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                                  ],
                                ),
                                const Icon(Icons.check_circle_rounded, color: Color(0xFF4CAF50), size: 26),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),

                    // 3. Section Title matching screenshot
                    const Text(
                      'Trip Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E1E24),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // 4. Trip Details List
                    if (_paymentRecords.isEmpty && !_isLoading)
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                        alignment: Alignment.center,
                        child: const Column(
                          children: [
                            Icon(Icons.route_rounded, size: 48, color: AppColors.textMuted),
                            SizedBox(height: 12),
                            Text(
                              'No trips recorded yet',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Completed rides will appear here in your Trip Details.',
                              style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    else
                      ...List.generate(
                        _paymentRecords.length,
                        (index) => _buildTripRow(_paymentRecords[index], index),
                      ),

                    // Infinite Scroll Loading Spinner
                    if (_isLoadingMore)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}