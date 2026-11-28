import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/navigation/app_navigator.dart';
import '../../../../services/ride_service.dart';
import '../../../widgets/custom_button.dart';
import 'driver_trip_shared_screen_94.dart';

class TripCompletedSummaryScreen extends StatefulWidget {
  final String? rideId;
  final String? origin;
  final String? destination;
  final String? dateDisplay;
  final String? fuelSaved;
  final String? paymentMode;
  final String? coTravelers;
  final Map<String, dynamic>? summaryData;

  const TripCompletedSummaryScreen({
    super.key,
    this.rideId,
    this.origin,
    this.destination,
    this.dateDisplay,
    this.fuelSaved,
    this.paymentMode,
    this.coTravelers,
    this.summaryData,
  });

  @override
  State<TripCompletedSummaryScreen> createState() =>
      _TripCompletedSummaryScreenState();
}

class _TripCompletedSummaryScreenState
    extends State<TripCompletedSummaryScreen> {
  Map<String, dynamic> _data = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.summaryData != null) {
      _data = Map<String, dynamic>.from(widget.summaryData!);
    }
    _fetchOnTripSummaryIfNeeded();
  }

  Future<void> _fetchOnTripSummaryIfNeeded() async {
    final rId = (widget.rideId ?? _data['rideId'] ?? '').toString().trim();
    if (rId.isEmpty) return;

    if (_data.isEmpty) {
      setState(() => _isLoading = true);
    }

    final res = await RideService.getOnTripSummary(rideId: rId);
    if (!mounted) return;
    if (res['success'] == true || res['isCompleted'] == true || res['rideId'] != null) {
      setState(() {
        _data = {
          ..._data,
          ...res,
        };
        _isLoading = false;
      });
    } else if (_isLoading) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    final nestedSummary = data['summary'] is Map ? data['summary'] as Map : const {};

    final appBarTitle = (data['headerTitle'] ??
            data['screenTitle'] ??
            data['title'] ??
            'On Trip')
        .toString();

    final fromLoc = (data['fromCity'] ??
            widget.origin ??
            data['origin'] ??
            nestedSummary['origin'] ??
            data['pickupLocation'] ??
            data['pickup'] ??
            data['from'] ??
            'Origin')
        .toString()
        .split(',')
        .first
        .trim();

    final toLoc = (data['toCity'] ??
            widget.destination ??
            data['destination'] ??
            nestedSummary['destination'] ??
            data['dropLocation'] ??
            data['drop'] ??
            data['to'] ??
            'Destination')
        .toString()
        .split(',')
        .first
        .trim();

    final date = (data['dateDisplay'] ??
            data['formattedDate'] ??
            data['date'] ??
            widget.dateDisplay ??
            data['time'] ??
            'Trip Completed')
        .toString();

    final rawFuel = (data['totalFuelSavedFormatted'] ??
            data['formattedTotalFuelSaved'] ??
            data['formattedFuelSaved'] ??
            nestedSummary['formattedFuelShare'] ??
            data['totalFuelSaved'] ??
            data['fuelSaved'] ??
            widget.fuelSaved ??
            data['fuelContribution'] ??
            data['price'] ??
            '--')
        .toString();
    final fuel = (rawFuel == '--' || rawFuel.startsWith('₹'))
        ? rawFuel
        : '₹ $rawFuel';

    final mode = (data['paidBy'] ??
            data['paymentMethod'] ??
            nestedSummary['paymentMode'] ??
            widget.paymentMode ??
            '--')
        .toString();

    final travelers = (data['coTravelersCount'] ??
            data['coTravelers'] ??
            data['totalPassengers'] ??
            nestedSummary['totalPassengersBoarded'] ??
            widget.coTravelers ??
            '--')
        .toString();

    final congrats = data['congratulations'] is Map
        ? data['congratulations'] as Map
        : const {};
    final congratsTitle =
        (congrats['title'] ?? 'Congratulations!').toString();
    final congratsSubtitle = (congrats['subtitle'] ??
            congrats['message'] ??
            'your trip has been completed successfully')
        .toString();

    final actions =
        data['actions'] is Map ? data['actions'] as Map : const {};
    final shareAction = actions['viewShareTripCard'] is Map
        ? actions['viewShareTripCard'] as Map
        : const {};
    final goHomeAction =
        actions['goHome'] is Map ? actions['goHome'] as Map : const {};
    final shareLabel =
        (shareAction['label'] ?? shareAction['text'] ?? 'View share trip card')
            .toString();
    final goHomeLabel =
        (goHomeAction['label'] ?? goHomeAction['text'] ?? 'Go Home')
            .toString();
    final shareStage = (shareAction['stage'] ?? 'summary').toString();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          appBarTitle,
          style: const TextStyle(
              fontWeight: FontWeight.bold, color: AppColors.textPrimary),
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
              const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            else
              SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Column(
                  children: [
                    const SizedBox(height: 20),

                    // Confetti & Green Check Circle Hero graphic matching Image 1
                    Center(
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                                color: const Color(0xFF4CAF50).withAlpha(50),
                                blurRadius: 30,
                                spreadRadius: 10),
                          ],
                        ),
                        child: const Icon(Icons.check_rounded,
                            color: Color(0xFF2E7D32), size: 70),
                      ),
                    ),

                    const SizedBox(height: 36),

                    // Route & Date Header matching Image 1
                    Row(
                      children: [
                        Flexible(
                          child: Text(fromLoc,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary)),
                        ),
                        const SizedBox(width: 12),
                        const Icon(Icons.arrow_forward_rounded,
                            size: 16, color: AppColors.textMuted),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Text(toLoc,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(date,
                          style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500)),
                    ),

                    const SizedBox(height: 24),
                    const Divider(height: 1, color: AppColors.border),
                    const SizedBox(height: 16),

                    // Financial Breakdown Table matching Image 1
                    _buildSummaryRow('Total Fuel Saved', fuel, isBold: true),
                    const SizedBox(height: 16),
                    const Divider(height: 1, color: AppColors.border),
                    const SizedBox(height: 16),
                    _buildSummaryRow('Paid By', mode),
                    const SizedBox(height: 16),
                    const Divider(height: 1, color: AppColors.border),
                    const SizedBox(height: 16),
                    _buildSummaryRow('Co-travelers', travelers),
                    const SizedBox(height: 16),
                    const Divider(height: 1, color: AppColors.border),

                    const SizedBox(height: 32),

                    // Congratulations Banner matching Image 1
                    Text(
                      congratsTitle,
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      congratsSubtitle,
                      style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 40),

                    // View Share Trip Card / Earnings Button
                    CustomButton(
                      text: shareLabel,
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DriverTripSharedScreen(
                              rideId: widget.rideId ?? _data['rideId']?.toString(),
                              stage: shareStage,
                              tripData: _data,
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 16),

                    // Go Home Text Button matching Image 1
                    TextButton(
                      onPressed: () {
                        AppNavigator.returnToDriverHome(context);
                      },
                      child: Text(
                        goHomeLabel,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary),
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

  Widget _buildSummaryRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500)),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
