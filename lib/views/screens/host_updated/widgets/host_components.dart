import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HostTopBar extends StatelessWidget {
  final String title;
  final VoidCallback onBack;

  const HostTopBar({
    super.key,
    required this.title,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: [
          InkWell(
            onTap: onBack,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Color(0xFFF5F5F7),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chevron_left_rounded,
                size: 26,
                color: Color(0xFF1E1E24),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1E1E24),
                ),
              ),
            ),
          ),
          const SizedBox(width: 40), // Keeps title centered
        ],
      ),
    );
  }
}

class HostBottomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isSecondary;

  const HostBottomButton({
    super.key,
    this.text = 'Continue',
    this.onPressed,
    this.isSecondary = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isSecondary) {
      return SizedBox(
        width: double.infinity,
        height: 52,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(0xFFE5E4ED)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF1E1E24),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF5E42C2),
          disabledBackgroundColor: const Color(0xFFE5E4ED),
          foregroundColor: Colors.white,
          disabledForegroundColor: const Color(0xFFA0A0B2),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class HostBackgroundGraphic extends StatelessWidget {
  const HostBackgroundGraphic({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
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
    );
  }
}

Future<String?> showAddUnitTypeSelectionDialog(BuildContext context) {
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        'Add Unit',
        style: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF1E1E24),
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select what type of unit or space you want to register:',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: const Color(0xFF6E6E82),
            ),
          ),
          const SizedBox(height: 20),
          _buildUnitTypeOption(
            ctx: ctx,
            title: 'Stay / Accommodation',
            subtitle: 'Rooms, suites, villas for overnight stays',
            icon: Icons.hotel_rounded,
            value: 'stay',
          ),
          const SizedBox(height: 12),
          _buildUnitTypeOption(
            ctx: ctx,
            title: 'Event Property',
            subtitle: 'Banquet halls, lawns, party & event spaces',
            icon: Icons.celebration_rounded,
            value: 'event',
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(
            'Cancel',
            style: GoogleFonts.poppins(
              color: const Color(0xFF6E6E82),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _buildUnitTypeOption({
  required BuildContext ctx,
  required String title,
  required String subtitle,
  required IconData icon,
  required String value,
}) {
  return InkWell(
    onTap: () => Navigator.pop(ctx, value),
    borderRadius: BorderRadius.circular(12),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E4ED)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF5E42C2).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF5E42C2), size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E1E24),
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: const Color(0xFF757585),
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: Color(0xFFA0A0B2)),
        ],
      ),
    ),
  );
}

