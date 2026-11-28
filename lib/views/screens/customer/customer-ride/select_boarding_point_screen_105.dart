import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../models/ride_booking_model.dart';
import '../../../../services/ride_service.dart';
import '../../../widgets/route_map_webview.dart';
import 'passenger_details_screen_107.dart';

/// Screen 105: Select Boarding Point (intermediate pickup selection)
class SelectBoardingPointScreen105 extends StatefulWidget {
  final RideBookingSession session;
  final RideDriver driver;
  final double initialFare;

  const SelectBoardingPointScreen105({
    super.key,
    required this.session,
    required this.driver,
    required this.initialFare,
  });

  @override
  State<SelectBoardingPointScreen105> createState() =>
      _SelectBoardingPointScreen105State();
}

class _SelectBoardingPointScreen105State
    extends State<SelectBoardingPointScreen105> {
  bool _isLoading = true;
  bool _isContinuing = false;
  int _selectedIndex = 0;
  List<Map<String, String>> _boardingPoints = [];

  @override
  void initState() {
    super.initState();
    _loadBoardingPoints();
  }

  Future<void> _loadBoardingPoints() async {
    final driver = widget.driver;
    final rideId = driver.id.trim();
    List<Map<String, String>> loaded = [];

    if (rideId.isNotEmpty) {
      final res = await RideService.getBoardingPoints(rideId);
      if (res['success'] == true) {
        final rawList = res['boardingPoints'] ??
            res['points'] ??
            res['stops'] ??
            res['data']?['boardingPoints'] ??
            res['data'];
        if (rawList is List) {
          for (final item in rawList) {
            if (item is Map) {
              final name = (item['name'] ??
                      item['location'] ??
                      item['stopName'] ??
                      item['address'] ??
                      item['title'] ??
                      '')
                  .toString()
                  .trim();
              final time = (item['time'] ??
                      item['departureTime'] ??
                      item['eta'] ??
                      item['pickupTime'] ??
                      '')
                  .toString()
                  .trim();
              if (name.isNotEmpty) {
                loaded.add({'name': name, 'time': time});
              }
            } else if (item != null && item.toString().trim().isNotEmpty) {
              loaded.add({'name': item.toString().trim(), 'time': ''});
            }
          }
        }
      }
    }

    if (loaded.isEmpty) {
      final originName = (driver.pickupPoint.isNotEmpty
              ? driver.pickupPoint
              : widget.session.pickup)
          .split(',')
          .first
          .trim();
      final depTime = driver.departureTime.trim();
      if (originName.isNotEmpty) {
        loaded.add({'name': originName, 'time': depTime});
      }
      for (final via in driver.viaLocations) {
        final cleanVia = via.split(',').first.trim();
        if (cleanVia.isNotEmpty &&
            !loaded.any((e) => e['name']?.toLowerCase() == cleanVia.toLowerCase())) {
          loaded.add({'name': cleanVia, 'time': depTime});
        }
      }
    }

    if (!mounted) return;
    setState(() {
      _boardingPoints = loaded;
      _isLoading = false;
    });
  }

  Future<void> _onContinue() async {
    if (_isContinuing) return;
    setState(() => _isContinuing = true);

    final selectedPoint = _boardingPoints.isNotEmpty
        ? _boardingPoints[_selectedIndex]['name'] ?? widget.session.pickup
        : widget.session.pickup;
    final effectiveDrop = widget.driver.destinationPoint.isNotEmpty
        ? widget.driver.destinationPoint
        : widget.session.destination;
    final isDoorToDoor =
        widget.driver.rideType == 'door_to_door' || widget.driver.isWholeCarOnly;

    double finalAmount = widget.initialFare > 0
        ? widget.initialFare
        : (widget.session.totalAmount > 0
            ? widget.session.totalAmount
            : widget.driver.pricePerSeat);
    FareQuoteResult? activeQuote;
    String? activeQuoteId;

    if (widget.driver.id.isNotEmpty) {
      try {
        final quoteRes = await RideService.quoteFare(
          rideId: widget.driver.id,
          pickupName: selectedPoint,
          dropoffName: effectiveDrop,
          seatsCount: widget.session.seatsCount > 0 ? widget.session.seatsCount : 1,
          isDoorstepPickup: isDoorToDoor,
          isDoorstepDrop: isDoorToDoor,
        );
        if (quoteRes['success'] == true) {
          final q = FareQuoteResult.fromJson(quoteRes);
          activeQuote = q;
          activeQuoteId = q.quoteId;
          if (q.totalPayableAmount > 0) {
            finalAmount = q.totalPayableAmount;
          }
        }
      } catch (_) {}
    }

    final updatedSession = widget.session.copyWith(
      driver: widget.driver,
      boardingPoint: selectedPoint,
      pickup: selectedPoint,
      destination: effectiveDrop,
      isDoorstepPickup: isDoorToDoor,
      totalAmount: finalAmount,
      quoteId: activeQuoteId,
      fareQuote: activeQuote,
    );

    if (!mounted) return;
    setState(() => _isContinuing = false);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PassengerDetailsScreen(session: updatedSession),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final origin = widget.driver.pickupPoint.isNotEmpty
        ? widget.driver.pickupPoint
        : widget.session.pickup;
    final dest = widget.driver.destinationPoint.isNotEmpty
        ? widget.driver.destinationPoint
        : widget.session.destination;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Select boarding point',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top Route Map Card matching Screen 105
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: RouteMapWebView(
                pickup: origin,
                destination: dest,
                rideId: widget.driver.id,
                height: 250,
                borderRadius: 16,
                interactive: true,
              ),
            ),

            // Boarding Points Radio List
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    )
                  : _boardingPoints.isEmpty
                      ? const Center(
                          child: Text(
                            'No boarding points available for this ride.',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: _boardingPoints.length,
                          separatorBuilder: (_, __) => const Divider(
                            height: 1,
                            color: Color(0xFFEEEEEE),
                          ),
                          itemBuilder: (context, index) {
                            final pt = _boardingPoints[index];
                            final isSelected = index == _selectedIndex;
                            final name = pt['name'] ?? '';
                            final time = pt['time'] ?? '';

                            return InkWell(
                              onTap: () => setState(() => _selectedIndex = index),
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 22,
                                      height: 22,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isSelected
                                              ? AppColors.primary
                                              : const Color(0xFFBDBDBD),
                                          width: isSelected ? 6 : 2.5,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Text(
                                        name,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: isSelected
                                              ? FontWeight.w600
                                              : FontWeight.w500,
                                          color: AppColors.textPrimary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (time.isNotEmpty) ...[
                                      const SizedBox(width: 12),
                                      Text(
                                        time,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),

            // Bottom Book Whole Car / Book a Seat Button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isContinuing ? null : _onContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isContinuing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          (widget.driver.rideType == 'door_to_door' ||
                                  widget.driver.isWholeCarOnly)
                              ? 'Book Whole Car'
                              : 'Book a Seat',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
