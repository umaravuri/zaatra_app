import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// One stop in a route timeline (time | marker | station).
///
/// Every tile uses the same fixed geometry so the car, the line, the dots, the
/// times and the station names line up across all stops (Figma frame 88):
/// a 72px time column, a 20px marker column and the station name filling the rest.
class RouteTimelineTile extends StatelessWidget {
  static const String carAsset = 'assets/images/glyphs-poly_car-wash.png';
  static const double _slot = 18; // height of the car / dot slot, matches the text line
  static const Color _grey = Color(0xFFE0E0E0);

  final String time;
  final String station;
  final bool isStart;
  final bool isLast;

  const RouteTimelineTile({
    super.key,
    required this.time,
    required this.station,
    required this.isStart,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 72,
            // Align first: the row stretches its children, which would otherwise
            // override the fixed slot height and push the time off the marker line.
            child: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                height: _slot,
                child: Center(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      time,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.normal,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            width: 20,
            child: Column(
              children: [
                SizedBox(
                  height: _slot,
                  child: Center(
                    child: isStart
                        ? Image.asset(
                            carAsset,
                            width: 20,
                            height: 17,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.directions_car_rounded, color: Colors.redAccent, size: 18),
                          )
                        : Container(
                            width: 12,
                            height: 12,
                            decoration: const BoxDecoration(color: _grey, shape: BoxShape.circle),
                          ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(width: 1.5, color: _grey),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: _slot),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    station,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.normal,
                      color: AppColors.textPrimary,
                      height: 1.25,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}