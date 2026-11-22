import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../services/driver_service.dart';
import '../../../widgets/custom_image_placeholder.dart';

class DriverRatingsReviewsScreen extends StatefulWidget {
  final String? rideId;
  final String? driverId;

  const DriverRatingsReviewsScreen({
    Key? key,
    this.rideId,
    this.driverId,
  }) : super(key: key);

  @override
  State<DriverRatingsReviewsScreen> createState() => _DriverRatingsReviewsScreenState();
}

class _DriverRatingsReviewsScreenState extends State<DriverRatingsReviewsScreen> {
  bool _isLoading = true;
  String _ratingFormatted = '4.8';
  int _totalReviews = 126;
  String _ratingSubtitle = 'Based on 126 reviews';
  List<Map<String, dynamic>> _starsBreakdownList = [];
  Map<String, dynamic>? _recentReview;

  @override
  void initState() {
    super.initState();
    _loadRatingsData();
  }

  Future<void> _loadRatingsData() async {
    setState(() => _isLoading = true);
    final res = await DriverService.getRatingsOverview(driverId: widget.driverId);
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (res['success'] == true) {
          _ratingFormatted = res['ratingFormatted']?.toString() ?? res['rating']?.toString() ?? '4.8';
          _totalReviews = (res['totalReviews'] as num?)?.toInt() ?? 126;
          _ratingSubtitle = res['ratingSubtitle']?.toString() ?? 'Based on $_totalReviews reviews';

          if (res['starsBreakdown'] is Map) {
            final breakdown = res['starsBreakdown'] as Map;
            final list = <Map<String, dynamic>>[];
            for (int s = 5; s >= 1; s--) {
              final key = s.toString();
              final item = breakdown[key] is Map ? (breakdown[key] as Map) : null;
              final count = (item?['count'] as num?)?.toInt() ?? 0;
              final pct = (item?['percentage'] as num?)?.toDouble() ?? 0.0;
              final colorHex = item?['barColor']?.toString() ?? (s >= 3 ? '#22C55E' : (s == 2 ? '#F97316' : '#EF4444'));
              final color = Color(int.parse(colorHex.replaceAll('#', '0xFF')));
              list.add({
                'stars': s,
                'ratio': pct > 0 ? (pct / 100.0) : (count / (_totalReviews > 0 ? _totalReviews : 1)),
                'count': count,
                'color': color,
              });
            }
            _starsBreakdownList = list;
          }

          if (res['recentReview'] is Map) {
            _recentReview = Map<String, dynamic>.from(res['recentReview'] as Map);
          }
        }
      });
    }
  }

  void _showAllReviewsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return FutureBuilder<Map<String, dynamic>>(
          future: DriverService.getDriverReviews(driverId: widget.driverId),
          builder: (context, snapshot) {
            final res = snapshot.data;
            final reviewsList = (res != null && res['reviews'] is List)
                ? List<Map<String, dynamic>>.from(res['reviews'] as List)
                : <Map<String, dynamic>>[];
            final headerTitle = res?['headerTitle']?.toString() ?? 'All Reviews (${reviewsList.length})';

            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.7,
              minChildSize: 0.4,
              maxChildSize: 0.9,
              builder: (_, scrollController) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
                  child: Column(
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
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            headerTitle,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                      const Divider(color: AppColors.border),
                      const SizedBox(height: 10),
                      if (snapshot.connectionState == ConnectionState.waiting)
                        const Expanded(
                          child: Center(
                            child: CircularProgressIndicator(color: AppColors.primary),
                          ),
                        )
                      else if (reviewsList.isEmpty)
                        const Expanded(
                          child: Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 40.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.rate_review_outlined, size: 48, color: Colors.grey),
                                  SizedBox(height: 12),
                                  Text(
                                    'No reviews received yet',
                                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      else
                        Expanded(
                          child: ListView.separated(
                            controller: scrollController,
                            itemCount: reviewsList.length,
                            separatorBuilder: (_, __) => const Divider(height: 24, color: AppColors.border),
                            itemBuilder: (context, idx) {
                              final rev = reviewsList[idx];
                              final revName = rev['customerName'] ?? rev['name'] ?? 'Customer';
                              final revDate = rev['date'] ?? '';
                              final revStars = (rev['rating'] ?? rev['stars'] as num?)?.toInt() ?? 5;
                              final revComment = rev['comment'] ?? '';

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const CustomImagePlaceholder(
                                        width: 40,
                                        height: 40,
                                        icon: Icons.person_rounded,
                                        borderRadius: BorderRadius.all(Radius.circular(20)),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              revName.toString(),
                                              style: const TextStyle(
                                                fontSize: 14.5,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.textPrimary,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              revDate.toString(),
                                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Row(
                                        children: List.generate(
                                          revStars,
                                          (_) => const Icon(Icons.star_rounded, color: Color(0xFFFFB800), size: 16),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    '“ $revComment “',
                                    style: const TextStyle(fontSize: 13.5, color: AppColors.textSecondary, height: 1.4),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final breakdownList = _starsBreakdownList.isNotEmpty
        ? _starsBreakdownList
        : [
            {'stars': 5, 'ratio': 0.0, 'count': 0, 'color': const Color(0xFF22C55E)},
            {'stars': 4, 'ratio': 0.0, 'count': 0, 'color': const Color(0xFF22C55E)},
            {'stars': 3, 'ratio': 0.0, 'count': 0, 'color': const Color(0xFF22C55E)},
            {'stars': 2, 'ratio': 0.0, 'count': 0, 'color': const Color(0xFFF97316)},
            {'stars': 1, 'ratio': 0.0, 'count': 0, 'color': const Color(0xFFEF4444)},
          ];

    final hasRecentReview = _recentReview != null;
    final recentName = _recentReview?['customerName']?.toString() ?? 'Customer';
    final recentDate = _recentReview?['date']?.toString() ?? '';
    final recentStars = (_recentReview?['rating'] as num?)?.toInt() ?? 5;
    final recentComment = _recentReview?['comment']?.toString() ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Ratings',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
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
            if (_isLoading)
              const Center(child: CircularProgressIndicator(color: AppColors.primary))
            else
              SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    // Overall Rating Number Header matching 113.png
                    Text(
                      _ratingFormatted,
                      style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                    ),

                    const SizedBox(height: 6),

                    // 5 Gold Stars Row matching 113.png
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return const Icon(Icons.star_rounded, color: Color(0xFFFFB800), size: 24);
                      }),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      _ratingSubtitle,
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),

                    const SizedBox(height: 28),

                    // Rating Progress Bars List matching 113.png
                    Column(
                      children: breakdownList.map((item) {
                        final stars = item['stars'] as int;
                        final ratio = (item['ratio'] as num).toDouble();
                        final count = item['count'] as int;
                        final barColor = (item['color'] as Color?) ?? (stars >= 3 ? const Color(0xFF22C55E) : (stars == 2 ? const Color(0xFFF97316) : const Color(0xFFEF4444)));

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 30,
                                child: Row(
                                  children: [
                                    Text('$stars', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.star_rounded, size: 14, color: AppColors.textPrimary),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: LinearProgressIndicator(
                                    value: ratio.clamp(0.0, 1.0),
                                    minHeight: 8,
                                    backgroundColor: const Color(0xFFF3EDF7),
                                    color: barColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              SizedBox(
                                width: 30,
                                child: Text(
                                  '$count',
                                  textAlign: TextAlign.end,
                                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 32),

                    // Customer Review Card Container
                    if (hasRecentReview)
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const CustomImagePlaceholder(
                                  width: 44,
                                  height: 44,
                                  icon: Icons.person_rounded,
                                  borderRadius: BorderRadius.all(Radius.circular(22)),
                                ),
                                const SizedBox(width: 14),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(recentName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                                    const SizedBox(height: 2),
                                    Text(recentDate, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: List.generate(recentStars, (index) {
                                        return const Icon(Icons.star_rounded, color: Color(0xFFFFB800), size: 14);
                                      }),
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),
                            const Divider(color: AppColors.border),
                            const SizedBox(height: 12),

                            Text(
                              '“ $recentComment “',
                              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4),
                            ),

                            const SizedBox(height: 16),
                            const Divider(color: AppColors.border),
                            const SizedBox(height: 10),

                            Center(
                              child: TextButton(
                                onPressed: _showAllReviewsSheet,
                                child: const Text(
                                  'View all reviews',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.star_outline_rounded, size: 36, color: Colors.grey),
                              SizedBox(height: 8),
                              Text(
                                'No reviews yet',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Customer feedback will appear here once trips are completed.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
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
