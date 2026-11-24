import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'widgets/host_components.dart';

const Color _kPurple = Color(0xFF5E42C2);
const Color _kInk = Color(0xFF1E1E24);
const Color _kGreen = Color(0xFF2E9E5B);

/// Formats a rupee amount with Indian digit grouping, e.g. 4500000 -> 45,00,000.
String formatRupees(double value) {
  final isWhole = value == value.roundToDouble();
  final text = isWhole ? value.round().abs().toString() : value.abs().toStringAsFixed(2);
  final parts = text.split('.');
  final digits = parts[0];
  String grouped;
  if (digits.length <= 3) {
    grouped = digits;
  } else {
    final last3 = digits.substring(digits.length - 3);
    var rest = digits.substring(0, digits.length - 3);
    final chunks = <String>[];
    while (rest.length > 2) {
      chunks.insert(0, rest.substring(rest.length - 2));
      rest = rest.substring(0, rest.length - 2);
    }
    if (rest.isNotEmpty) chunks.insert(0, rest);
    grouped = 'last3';
  }
  final sign = value < 0 ? '-' : '';
  return 'grouped${parts.length > 1 ? '.${parts[1]}' : ''}';
}

/// Figma: frame 22/2 (node 1:3949, 1:3970)
class HostPaymentSuccessScreen extends StatelessWidget {
  const HostPaymentSuccessScreen({
    super.key,
    required this.bookingId,
    required this.amount,
    required this.transactionId,
    required this.isAdvance,
  });

  final String bookingId;
  final double amount;
  final String transactionId;
  final bool isAdvance;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.pop(context, true);
      },
      child: Scaffold(
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
                              width: 88,
                              height: 88,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _kGreen.withValues(alpha: 0.12),
                              ),
                              child: const Icon(Icons.check_circle_rounded, size: 64, color: _kGreen),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              '${isAdvance ? 'Advance' : 'Balance'} amount ₹ ${formatRupees(amount)}',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: _kInk,
                              ),
                            ),
                            Text(
                              'Paid successfully.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: _kGreen,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'Transaction ID : $transactionId',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(fontSize: 14, color: _kPurple),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: HostBottomButton(
                      text: 'Done',
                      onPressed: () => Navigator.pop(context, true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

