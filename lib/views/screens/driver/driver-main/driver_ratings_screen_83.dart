import 'package:flutter/material.dart';
import 'driver_ratings_reviews_screen_113.dart';

class DriverRatingsScreen extends StatelessWidget {
  final String? rideId;
  final String? driverId;

  const DriverRatingsScreen({Key? key, this.rideId, this.driverId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DriverRatingsReviewsScreen(
      rideId: rideId,
      driverId: driverId,
    );
  }
}
