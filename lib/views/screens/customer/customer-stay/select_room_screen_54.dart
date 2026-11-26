// Figma: 1:4343 (Choose Stay)
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/customer_static_data.dart';
import '../../../../models/hotel_model.dart';
import '../../../widgets/customer_booking_widgets.dart';
import 'stay_guest_details_screen.dart';

class SelectRoomScreen extends StatefulWidget {
  final Hotel? hotel;
  const SelectRoomScreen({super.key, this.hotel});

  @override
  State<SelectRoomScreen> createState() => _SelectRoomScreenState();
}

class _SelectRoomScreenState extends State<SelectRoomScreen> {
  int _selectedRoomIndex = 0;
  String _selectedPlan = 'Standard Rate (Free Cancellation)';

  Hotel get _activeHotel => widget.hotel ?? mockHotels[0];

  List<Map<String, dynamic>> get _roomOptions {
    if (_activeHotel.rooms.isNotEmpty) {
      return _activeHotel.rooms
          .map((r) => {
                'id': r.id,
                'title': r.title,
                'recommendedFor': 'Recommended for 2 Adults',
                'bedInfo': r.specs,
                'amenities': r.amenities.split('•').map((e) => e.trim()).toList(),
                'pricePerNight': r.pricePerNight,
                'originalPrice': (r.pricePerNight * 1.2).roundToDouble(),
                'taxes': (r.pricePerNight * 0.12).roundToDouble(),
                'freeCancellation': true,
                'image': r.image,
              })
          .toList();
    }
    return CustomerStaticData.stayRoomOptions;
  }

  @override
  Widget build(BuildContext context) {
    final rooms = _roomOptions;
    final selectedRoom = rooms[_selectedRoomIndex];
    final pricePerNight = (selectedRoom['pricePerNight'] as num).toDouble();
    final planExtra = _selectedPlan.contains('Breakfast') ? 450.0 : 0.0;
    final effectivePrice = pricePerNight + planExtra;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomerAppBar(
        title: 'Choose Stay',
        subtitle: _activeHotel.title,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Date & Guests Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBackground,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.primary),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          '22 Mar - 24 Mar (2 Nights) • 2 Guests',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      Text(
                        '${rooms.length} options',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Rate Plan Selector
                const Text(
                  'Select Rate Plan',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    'Standard Rate (Free Cancellation)',
                    'Room + Breakfast (+₹450/night)',
                  ].map((plan) {
                    final isSelected = _selectedPlan == plan;
                    return ChoiceChip(
                      label: Text(
                        plan,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: AppColors.primary,
                      backgroundColor: Colors.white,
                      side: BorderSide(
                        color: isSelected ? AppColors.primary : AppColors.border,
                      ),
                      onSelected: (_) => setState(() => _selectedPlan = plan),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 18),

                // Room Cards
                ...List.generate(rooms.length, (index) {
                  final room = rooms[index];
                  final isSelected = _selectedRoomIndex == index;
                  final amenities = (room['amenities'] as List<dynamic>).cast<String>();
                  final roomPrice = ((room['pricePerNight'] as num).toDouble() + planExtra).toInt();
                  final origPrice = (room['originalPrice'] as num).toInt();

                  return GestureDetector(
                    onTap: () => setState(() => _selectedRoomIndex = index),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : AppColors.border,
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CustomerSafeImage(
                                assetPath: room['image'].toString(),
                                width: 84,
                                height: 84,
                                borderRadius: 12,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryBackground,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        room['recommendedFor'].toString(),
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      room['title'].toString(),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      room['bedInfo'].toString(),
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: amenities
                                .map((a) => Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.inputBackground,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        a,
                                        style: const TextStyle(
                                          fontSize: 11.5,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ))
                                .toList(),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Divider(height: 1, color: AppColors.border),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        '₹ $roomPrice',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '₹ $origPrice',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: AppColors.textMuted,
                                          decoration: TextDecoration.lineThrough,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Text(
                                    'per night + taxes',
                                    style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                              ElevatedButton(
                                onPressed: () => setState(() => _selectedRoomIndex = index),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      isSelected ? AppColors.primary : AppColors.primaryBackground,
                                  foregroundColor:
                                      isSelected ? Colors.white : AppColors.primary,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: Text(
                                  isSelected ? 'Selected' : 'Select Room',
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          BookingPriceBar(
            priceText: '₹ ${effectivePrice.toInt()} / night',
            subText: selectedRoom['title'].toString(),
            buttonText: 'Reserve',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => StayGuestDetailsScreen(
                    hotel: _activeHotel,
                    roomTitle: selectedRoom['title'].toString(),
                    pricePerNight: effectivePrice,
                    ratePlan: _selectedPlan,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
