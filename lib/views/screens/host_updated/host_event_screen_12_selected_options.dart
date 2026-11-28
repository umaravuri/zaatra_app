import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/host_updated_property_draft_model.dart';
import 'widgets/host_components.dart';
import 'host_event_screen_12_venue_details.dart';

/// Figma: frame 1228744517 (node 1:2718)
class HostEventScreen12SelectedOptions extends StatefulWidget {
  final HostUpdatedPropertyDraft draft;
  final Map<String, dynamic> eventData;

  const HostEventScreen12SelectedOptions({
    super.key,
    required this.draft,
    required this.eventData,
  });

  @override
  State<HostEventScreen12SelectedOptions> createState() =>
      _HostEventScreen12SelectedOptionsState();
}

class _HostEventScreen12SelectedOptionsState
    extends State<HostEventScreen12SelectedOptions> {
  void _onConfirmAndSave() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HostEventScreen12VenueDetails(
          draft: widget.draft,
          eventData: widget.eventData,
        ),
      ),
    );

    if (result != null && result is HostUpdatedPropertyDraft && mounted) {
      Navigator.pop(context, result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            const HostBackgroundGraphic(),
            Column(
              children: [
                HostTopBar(
                  title: 'Selected Options',
                  onBack: () => Navigator.pop(context),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'You have selected',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1E1E24),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildSummaryRows(),
                        const SizedBox(height: 24),
                        Text(
                          'Is this correct?',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF1E1E24),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 44,
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: Color(0xFF5E42C2)),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  onPressed: () => Navigator.pop(context),
                                  child: Text(
                                    'Edit',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF5E42C2),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: SizedBox(
                                height: 44,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF5E42C2),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  onPressed: _onConfirmAndSave,
                                  child: Text(
                                    'Confirm and save',
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRows() {
    final categoriesMap = widget.eventData['eventCategories'] as Map? ?? {};

    final displayRows = [
      {'name': 'Wedding day marriage', 'total': 9, 'key': '1. Wedding and marriage'},
      {'name': 'Pre wedding events', 'total': 5, 'key': '2. Pre - Wedding Events'},
      {'name': 'Life time Ceremony', 'total': 7, 'key': '3. Life stage Ceremonies'},
      {'name': 'Birthday & Anniversary', 'total': 6, 'key': '4. Birthday and Anniversary'},
      {'name': 'Family and Social Events', 'total': 6, 'key': '5. Family and Social Events'},
      {'name': 'Funeral and memorial', 'total': 4, 'key': '6. Funeral and memorial'},
      {'name': 'Religious gathering', 'total': 7, 'key': '7. Religious Gathering'},
      {'name': 'Corporate and professionals', 'total': 9, 'key': '8. Corporate and Professionals'},
      {'name': 'Entertainment and Culture', 'total': 7, 'key': '9. Entertainment and Culture'},
      {'name': 'Other', 'total': 3, 'key': '10. Other'},
    ];

    return Column(
      children: displayRows.map((row) {
        final key = row['key'] as String;
        final name = row['name'] as String;
        final totals = widget.eventData['eventCategoryTotals'] as Map? ?? {};
        final total = (totals[key] as int?) ?? (row['total'] as int);

        final selectedList = categoriesMap[key] as List? ?? [];
        final count = selectedList.length;

        String status;
        if (count == 0) {
          status = 'Not Accepted';
        } else if (count == total) {
          status = 'All $total Events';
        } else {
          status = '$count out of $total events';
        }

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            children: [
              Expanded(
                flex: 5,
                child: Text(
                  name,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: const Color(0xFF333340),
                  ),
                ),
              ),
              const Text(' - ', style: TextStyle(color: Color(0xFF757585))),
              Expanded(
                flex: 4,
                child: Text(
                  status,
                  textAlign: TextAlign.end,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: status == 'Not Accepted'
                        ? const Color(0xFF8E8E9F)
                        : const Color(0xFF1E1E24),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
