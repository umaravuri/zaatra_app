// Figma: 1:2576 (Request change)
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../models/hotel_model.dart';
import '../../../widgets/customer_booking_widgets.dart';

class StayRequestChangeScreen extends StatefulWidget {
  final Hotel? hotel;

  const StayRequestChangeScreen({super.key, this.hotel});

  @override
  State<StayRequestChangeScreen> createState() => _StayRequestChangeScreenState();
}

class _StayRequestChangeScreenState extends State<StayRequestChangeScreen> {
  final _datesCtrl = TextEditingController(text: '24 Mar - 26 Mar (2 Nights)');
  final _guestsCtrl = TextEditingController(text: '2 Adults, 1 Child');
  final _reasonCtrl = TextEditingController();
  String _selectedType = 'Change Check-in / Check-out Dates';

  @override
  void dispose() {
    _datesCtrl.dispose();
    _guestsCtrl.dispose();
    _reasonCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Change request sent to host! You will receive an update shortly.'),
        backgroundColor: AppColors.success,
      ),
    );
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomerAppBar(
        title: 'Request Change',
        subtitle: widget.hotel?.title ?? 'Modify Stay Reservation',
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'What would you like to change?',
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
                    'Change Check-in / Check-out Dates',
                    'Modify Guest Count',
                    'Upgrade Room Category',
                    'Custom Offer / Discount',
                  ].map((option) {
                    final selected = _selectedType == option;
                    return ChoiceChip(
                      label: Text(
                        option,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: selected ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                      selected: selected,
                      selectedColor: AppColors.primary,
                      backgroundColor: Colors.white,
                      side: BorderSide(
                        color: selected ? AppColors.primary : AppColors.border,
                      ),
                      onSelected: (_) => setState(() => _selectedType = option),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 18),
                CustomerFormField(
                  label: 'Preferred Dates',
                  hint: 'e.g. 24 Mar - 26 Mar',
                  controller: _datesCtrl,
                  prefixIcon: Icons.calendar_today_outlined,
                ),
                const SizedBox(height: 14),
                CustomerFormField(
                  label: 'Updated Guest Count',
                  hint: 'e.g. 2 Adults, 1 Child',
                  controller: _guestsCtrl,
                  prefixIcon: Icons.group_outlined,
                ),
                const SizedBox(height: 14),
                CustomerFormField(
                  label: 'Message to Host',
                  hint: 'Explain your request or expected budget...',
                  controller: _reasonCtrl,
                  maxLines: 4,
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(
              16,
              12,
              16,
              MediaQuery.of(context).padding.bottom + 12,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text(
                  'Send Request to Host',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
