import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/host_booking_model.dart';
import '../../../services/host_api_service.dart';
import 'widgets/host_components.dart';
import 'widgets/host_form_widgets.dart';

const Color _purple = Color(0xFF5E42C2);
const Color _ink = Color(0xFF1E1E24);
const Color _star = Color(0xFFF5B301);

const List<String> _criteria = [
  'Respectful Behaviour',
  'Rules & Timings',
  'Property Care',
  'Communication & Cooperation',
  'On-time Payment',
];

/// Figma: frame 1228744532 (node 1:4390)
/// Figma: frame 1228744533 (node 1:4413)
/// Figma: frame 1228744534 (node 1:4439)
/// Figma: frame 1228744535 (node 1:4465)
/// Figma: frame 1228744538 (node 1:4643)
/// Figma: frame 1228744543 (node 1:5371)
class HostRateCustomerScreen extends StatefulWidget {
  const HostRateCustomerScreen({super.key, required this.bookingId});

  final String bookingId;

  @override
  State<HostRateCustomerScreen> createState() => _HostRateCustomerScreenState();
}

class _HostRateCustomerScreenState extends State<HostRateCustomerScreen> {
  final Map<String, int> _ratings = {};
  final TextEditingController _comment = TextEditingController();
  HostBooking? _booking;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadBooking();
  }

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _loadBooking() async {
    final res = await HostApiService.getBooking(widget.bookingId);
    if (!mounted) return;
    if (res['success'] == true && res['booking'] is Map) {
      setState(() => _booking = HostBooking.fromMap(
          Map<String, dynamic>.from(res['booking'] as Map)));
    }
  }

  String get _reference => _booking?.reference ?? '';

  void _skip() {
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => _HostReviewResultScreen(submitted: false, reference: _reference),
    ));
  }

  Future<void> _submit() async {
    if (_ratings.length < _criteria.length) {
      showHostError(context, 'Please rate all the criteria');
      return;
    }
    setState(() => _submitting = true);
    final res = await HostApiService.submitCustomerReview(
      bookingId: widget.bookingId,
      ratings: Map<String, int>.from(_ratings),
      comment: _comment.text.trim(),
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (res['success'] == true) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (_) => _HostReviewResultScreen(submitted: true, reference: _reference),
      ));
    } else {
      showHostError(context, '${res['message'] ?? 'Could not submit review'}');
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
                Stack(
                  alignment: Alignment.centerRight,
                  children: [
                    HostTopBar(
                      title: 'Rate your customer',
                      onBack: () => Navigator.pop(context),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: TextButton(
                        onPressed: _submitting ? null : _skip,
                        child: Text(
                          'Skip',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: _purple,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final c in _criteria) _criterionRow(c),
                        const HostQuestion('Specify if any problem you have'),
                        HostTextField(
                          controller: _comment,
                          hint: 'Write here',
                          maxLines: 4,
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: HostBottomButton(
                    text: 'Submit Review',
                    onPressed: _submitting ? null : _submit,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _criterionRow(String criterion) {
    final value = _ratings[criterion] ?? 0;
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              criterion,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: _ink,
              ),
            ),
          ),
          for (var i = 1; i <= 5; i++)
            GestureDetector(
              onTap: () => setState(() => _ratings[criterion] = i),
              child: Padding(
                padding: const EdgeInsets.only(left: 2),
                child: Icon(
                  i <= value ? Icons.star_rounded : Icons.star_outline_rounded,
                  size: 28,
                  color: i <= value ? _star : const Color(0xFFA0A0B2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _HostReviewResultScreen extends StatelessWidget {
  const _HostReviewResultScreen({required this.submitted, required this.reference});

  final bool submitted;
  final String reference;

  @override
  Widget build(BuildContext context) {
    final title = submitted
        ? 'Your review has successfully submitted'
        : 'Your review has Cancelled';
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            const HostBackgroundGraphic(),
            Column(
              children: [
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 84,
                            height: 84,
                            decoration: BoxDecoration(
                              color: (submitted ? _purple : Colors.redAccent)
                                  .withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              submitted ? Icons.check_rounded : Icons.close_rounded,
                              size: 48,
                              color: submitted ? _purple : Colors.redAccent,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            title,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: _ink,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            reference.isEmpty
                                ? 'Booking Has Completed'
                                : 'Booking Has Completed  Reference ID : $reference',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: const Color(0xFF6E6E82),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: HostBottomButton(
                    text: 'Go To Home',
                    onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

