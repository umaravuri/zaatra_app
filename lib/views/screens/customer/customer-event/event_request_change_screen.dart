// Figma: 1:2650 (Event Request Change)
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../widgets/customer_booking_widgets.dart';

class EventRequestChangeScreen extends StatefulWidget {
  final String venueName;

  const EventRequestChangeScreen({super.key, required this.venueName});

  @override
  State<EventRequestChangeScreen> createState() => _EventRequestChangeScreenState();
}

class _EventRequestChangeScreenState extends State<EventRequestChangeScreen> {
  final _dateCtrl = TextEditingController(text: '20 Dec 2026');
  final _slotCtrl = TextEditingController(text: 'Evening Slot (06:00 PM - 12:00 AM)');
  final _guestsCtrl = TextEditingController(text: '450');
  final _notesCtrl = TextEditingController();

  @override
  void dispose() {
    _dateCtrl.dispose();
    _slotCtrl.dispose();
    _guestsCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomerAppBar(
        title: 'Request Venue Change',
        subtitle: widget.venueName,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                CustomerFormField(
                  label: 'New Preferred Event Date',
                  hint: 'e.g. 20 Dec 2026',
                  controller: _dateCtrl,
                  prefixIcon: Icons.calendar_today_outlined,
                ),
                const SizedBox(height: 14),
                CustomerFormField(
                  label: 'Preferred Time Slot',
                  hint: 'Morning / Evening / Full Day',
                  controller: _slotCtrl,
                  prefixIcon: Icons.schedule_rounded,
                ),
                const SizedBox(height: 14),
                CustomerFormField(
                  label: 'Updated Guest Count',
                  hint: 'e.g. 450',
                  controller: _guestsCtrl,
                  keyboardType: TextInputType.number,
                  prefixIcon: Icons.groups_outlined,
                ),
                const SizedBox(height: 14),
                CustomerFormField(
                  label: 'Additional Requirements / Counter-Offer',
                  hint: 'Mention stage changes, extra rooms, or budget note...',
                  controller: _notesCtrl,
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
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Event modification request sent to venue host.'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                  Navigator.pop(context, true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text(
                  'Submit Change Request',
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
