import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../models/customer_booking_model.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/custom_image_placeholder.dart';
// import 'booking_invoice_screen_50.dart';
import '../customer-common/help_support_screen_48.dart';

class CustomerBookingDetailsScreen extends StatelessWidget {
  /// When provided, the screen shows this real booking (no invented values).
  /// Without it the legacy sample receipt is shown for flows that still use it.
  final CustomerBookingItem? booking;

  const CustomerBookingDetailsScreen({Key? key, this.booking}) : super(key: key);

  String _raw(List<String> keys) {
    final json = booking?.rawJson ?? const <String, dynamic>{};
    for (final k in keys) {
      final v = json[k]?.toString().trim() ?? '';
      if (v.isNotEmpty) return v;
    }
    return '';
  }

  Widget _buildBookingSummary(BuildContext context) {
    final b = booking!;
    final checkIn = _raw(['checkIn', 'checkInDate']);
    final checkOut = _raw(['checkOut', 'checkOutDate']);
    final guests = _raw(['guests', 'capacity']);
    final rooms = _raw(['rooms', 'roomCount']);
    final location = _raw(['location', 'city', 'address']);
    final rows = <MapEntry<String, String>>[
      if (b.refId.isNotEmpty) MapEntry('Booking ID', b.refId),
      if (location.isNotEmpty) MapEntry('Location', location),
      if (checkIn.isNotEmpty) MapEntry('Check - in', checkIn),
      if (checkOut.isNotEmpty) MapEntry('Check - out', checkOut),
      if (rooms.isNotEmpty) MapEntry('Rooms', rooms),
      if (guests.isNotEmpty) MapEntry('Guests', guests),
      MapEntry('Amount', b.price),
    ];
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Booking Details',
            style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
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
                      Expanded(
                        child: Text(b.title,
                            style: const TextStyle(
                                fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: b.statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(b.status,
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: b.statusColor)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(b.subtitle, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  const SizedBox(height: 16),
                  const Divider(color: AppColors.border),
                  const SizedBox(height: 12),
                  for (final r in rows) ...[
                    _buildPriceRow(r.key, r.value),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            CustomButton(
              text: 'Support',
              isOutlined: true,
              backgroundColor: Colors.white,
              textColor: AppColors.primary,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HelpSupportScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (booking != null) return _buildBookingSummary(context);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Booking Details',
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
            Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Card matching 49.png
                      Row(
                        children: [
                          const CustomImagePlaceholder(
                            width: 80,
                            height: 80,
                            icon: Icons.villa_rounded,
                            borderRadius: BorderRadius.all(Radius.circular(16)),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Sun set beach villa',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                ),
                                const SizedBox(height: 4),
                                const Text('Baga Beach', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                                const SizedBox(height: 6),
                                Row(
                                  children: const [
                                    Icon(Icons.star_rounded, color: Color(0xFFFFB800), size: 18),
                                    SizedBox(width: 4),
                                    Text('4.7', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),
                      const Divider(color: AppColors.border),
                      const SizedBox(height: 16),

                      // Check-in / Check-out Timeline Row matching 49.png
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text('Check - in', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                              SizedBox(height: 4),
                              Text('20 May . 2024', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                            ],
                          ),
                          const Text('• • • • • • • • •', style: TextStyle(color: AppColors.border, fontSize: 16)),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: const [
                              Text('Check - Out', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                              SizedBox(height: 4),
                              Text('22 May . 2024', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),
                      const Divider(color: AppColors.border),
                      const SizedBox(height: 16),

                      // Price Breakdown Rows matching 49.png
                      _buildPriceRow('Deluxe Room\n₹5,000 x 3 nights', '₹15,100'),
                      const SizedBox(height: 14),
                      _buildPriceRow('Cleaning Fee', '₹600'),
                      const SizedBox(height: 14),
                      _buildPriceRow('Services Fee', '₹600'),

                      const SizedBox(height: 20),
                      const Divider(color: AppColors.border),
                      const SizedBox(height: 16),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Text('Total', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                          Text('₹16700', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Action Buttons matching 49.png
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  CustomButton(
                    text: 'Download Invoice',
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Invoice download is temporarily unavailable')),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  CustomButton(
                    text: 'Support',
                    isOutlined: true,
                    backgroundColor: Colors.white,
                    textColor: AppColors.primary,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const HelpSupportScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, String price) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.3)),
        Text(price, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
      ],
    );
  }
}