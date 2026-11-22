import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../models/hotel_model.dart';

class SelectRoomScreen extends StatelessWidget {
  final Hotel? hotel;
  const SelectRoomScreen({super.key, this.hotel});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(hotel?.name ?? 'Select Room'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Text(
          'Select Room Screen (Screen 54)\nProperty: ${hotel?.name ?? "N/A"}',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
