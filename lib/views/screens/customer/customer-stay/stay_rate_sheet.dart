// Figma: 1:1859 (Rate your stay)
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../widgets/customer_booking_widgets.dart';

class StayRateSheet extends StatefulWidget {
  final String propertyName;

  const StayRateSheet({super.key, required this.propertyName});

  static Future<void> show(BuildContext context, {required String propertyName}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => StayRateSheet(propertyName: propertyName),
    );
  }

  @override
  State<StayRateSheet> createState() => _StayRateSheetState();
}

class _StayRateSheetState extends State<StayRateSheet> {
  int _cleanliness = 5;
  int _comfort = 5;
  int _amenities = 4;
  int _location = 5;
  int _staff = 5;
  int _value = 4;
  String _travelerType = 'Family';
  final _reviewCtrl = TextEditingController();

  @override
  void dispose() {
    _reviewCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        14,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Rate Your Stay at ${widget.propertyName}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Share your experience across each category',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 14),
            StarRatingRow(
              label: 'Cleanliness',
              rating: _cleanliness,
              onChanged: (v) => setState(() => _cleanliness = v),
            ),
            StarRatingRow(
              label: 'Comfort',
              rating: _comfort,
              onChanged: (v) => setState(() => _comfort = v),
            ),
            StarRatingRow(
              label: 'Amenities',
              rating: _amenities,
              onChanged: (v) => setState(() => _amenities = v),
            ),
            StarRatingRow(
              label: 'Location',
              rating: _location,
              onChanged: (v) => setState(() => _location = v),
            ),
            StarRatingRow(
              label: 'Staff & Hospitality',
              rating: _staff,
              onChanged: (v) => setState(() => _staff = v),
            ),
            StarRatingRow(
              label: 'Value for Money',
              rating: _value,
              onChanged: (v) => setState(() => _value = v),
            ),
            const SizedBox(height: 14),
            const Text(
              'Traveler Type',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: ['Solo', 'Couple', 'Family', 'Business'].map((t) {
                final selected = _travelerType == t;
                return ChoiceChip(
                  label: Text(
                    t,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: selected ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  selected: selected,
                  selectedColor: AppColors.primary,
                  backgroundColor: AppColors.inputBackground,
                  onSelected: (_) => setState(() => _travelerType = t),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
            CustomerFormField(
              label: 'Write a short review',
              hint: 'What did you enjoy most about your stay?',
              controller: _reviewCtrl,
              maxLines: 3,
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Thank you! Your stay review has been submitted.'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text(
                  'Submit Review',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
