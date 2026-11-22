import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RevenueWaveChart extends StatefulWidget {
  final String period;
  final ValueChanged<String>? onPeriodChanged;
  final List<String>? labels;
  final List<num>? data;
  final String currency;

  const RevenueWaveChart({
    super.key,
    this.period = 'This Month',
    this.onPeriodChanged,
    this.labels,
    this.data,
    this.currency = '₹',
  });

  @override
  State<RevenueWaveChart> createState() => _RevenueWaveChartState();
}

class _RevenueWaveChartState extends State<RevenueWaveChart> {
  late String _selectedPeriod;

  final List<String> _periodOptions = [
    'This Week',
    'This Month',
    'Last 6 Months',
    'This Year',
  ];

  @override
  void initState() {
    super.initState();
    _selectedPeriod = widget.period;
  }

  @override
  void didUpdateWidget(covariant RevenueWaveChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.period != oldWidget.period) {
      setState(() {
        _selectedPeriod = widget.period;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveLabels = (widget.labels != null && widget.labels!.isNotEmpty)
        ? widget.labels!
        : const ['1 May', '7 May', '14 May', '21 May', '31 May'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title and Dropdown Filter Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Revenue overview',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E1E24),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF2EFFD),
                borderRadius: BorderRadius.circular(20),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _periodOptions.contains(_selectedPeriod)
                      ? _selectedPeriod
                      : _periodOptions[1],
                  isDense: true,
                  icon: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Color(0xFF5E42C2),
                    size: 18,
                  ),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF5E42C2),
                  ),
                  items: _periodOptions.map((opt) {
                    return DropdownMenuItem<String>(
                      value: opt,
                      child: Text(opt),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedPeriod = val);
                      widget.onPeriodChanged?.call(val);
                    }
                  },
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Wave Chart Area
        SizedBox(
          height: 160,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Y-Axis Labels
              SizedBox(
                width: 44,
                height: 130,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAxisLabel('160k'),
                    _buildAxisLabel('120k'),
                    _buildAxisLabel('80k'),
                    _buildAxisLabel('40k'),
                  ],
                ),
              ),
              // Chart Canvas
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: CustomPaint(
                        size: const Size(double.infinity, 125),
                        painter: _SmoothRevenueWavePainter(dataPoints: widget.data),
                      ),
                    ),
                    const SizedBox(height: 6),
                    // X-Axis Labels
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: effectiveLabels
                          .map((label) => _buildAxisLabel(label))
                          .toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAxisLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        color: const Color(0xFF888899),
      ),
    );
  }
}

class _SmoothRevenueWavePainter extends CustomPainter {
  final List<num>? dataPoints;

  _SmoothRevenueWavePainter({this.dataPoints});

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    // Gradient fill paint
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF5E42C2).withValues(alpha: 0.45),
          const Color(0xFF8E71ED).withValues(alpha: 0.20),
          Colors.white.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, width, height))
      ..style = PaintingStyle.fill;

    // Stroke paint for chart line
    final linePaint = Paint()
      ..color = const Color(0xFF5E42C2)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();

    if (dataPoints != null && dataPoints!.length >= 2) {
      final pts = dataPoints!;
      final maxVal = pts.reduce((a, b) => a > b ? a : b).toDouble();
      final effectiveMax = maxVal > 0 ? maxVal * 1.15 : 100.0;

      final stepX = width / (pts.length - 1);
      final points = <Offset>[];

      for (int i = 0; i < pts.length; i++) {
        final x = i * stepX;
        final normalized = (pts[i].toDouble() / effectiveMax).clamp(0.05, 0.95);
        final y = height * (1.0 - normalized);
        points.add(Offset(x, y));
      }

      path.moveTo(points[0].dx, points[0].dy);
      for (int i = 0; i < points.length - 1; i++) {
        final p0 = points[i];
        final p1 = points[i + 1];
        final controlPoint1 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p0.dy);
        final controlPoint2 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p1.dy);
        path.cubicTo(
          controlPoint1.dx,
          controlPoint1.dy,
          controlPoint2.dx,
          controlPoint2.dy,
          p1.dx,
          p1.dy,
        );
      }

      // Draw stroke first
      canvas.drawPath(path, linePaint);

      // Now close fill
      final fillPath = Path.from(path);
      fillPath.lineTo(width, height);
      fillPath.lineTo(0, height);
      fillPath.close();
      canvas.drawPath(fillPath, fillPaint);
      return;
    }

    // Default curve when no data points provided
    path.moveTo(0, height * 0.72);

    path.cubicTo(
      width * 0.12, height * 0.65,
      width * 0.18, height * 0.42,
      width * 0.25, height * 0.42,
    );

    path.cubicTo(
      width * 0.32, height * 0.42,
      width * 0.38, height * 0.60,
      width * 0.46, height * 0.60,
    );

    path.cubicTo(
      width * 0.54, height * 0.60,
      width * 0.58, height * 0.32,
      width * 0.68, height * 0.32,
    );

    path.cubicTo(
      width * 0.76, height * 0.32,
      width * 0.79, height * 0.46,
      width * 0.84, height * 0.46,
    );

    path.cubicTo(
      width * 0.90, height * 0.46,
      width * 0.94, height * 0.20,
      width, height * 0.18,
    );

    final fillPath = Path.from(path);
    fillPath.lineTo(width, height);
    fillPath.lineTo(0, height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _SmoothRevenueWavePainter oldDelegate) {
    return oldDelegate.dataPoints != dataPoints;
  }
}
