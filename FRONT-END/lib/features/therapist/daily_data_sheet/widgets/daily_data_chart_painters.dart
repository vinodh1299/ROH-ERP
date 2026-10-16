import 'dart:math';
import 'package:flutter/material.dart';

// ══════════════════════════════════════════════════════════════════════════════
// SHARED: x-axis label thinning
// ══════════════════════════════════════════════════════════════════════════════

/// Which of [count] evenly spaced points (spaced [xStep] apart) get a label so
/// that labels needing [footprint] px each never overlap. Draws every Nth
/// label, always keeps the first and last, and drops a regular label that
/// would crowd the last one. On wide charts every label is kept.
List<bool> _labelMask(int count, double xStep, double footprint) {
  if (count <= 2 || xStep <= 0) return List.filled(count, true);
  final stride = max(1, (footprint / xStep).ceil());
  if (stride == 1) return List.filled(count, true);
  final last = count - 1;
  return List.generate(
    count,
    (i) => i == 0 || i == last || (i % stride == 0 && last - i >= stride),
  );
}

/// Widest of the x-axis date labels at [style], plus a small gap.
double _maxLabelWidth(List<Map<String, dynamic>> data, TextStyle style) {
  final tp = TextPainter(textDirection: TextDirection.ltr);
  double widest = 0;
  for (final d in data) {
    tp.text = TextSpan(text: (d['date'] ?? '').toString(), style: style);
    tp.layout();
    if (tp.width > widest) widest = tp.width;
  }
  return widest + 6;
}

/// Footprint of a -45° rotated label along the x axis (roughly its height
/// times sqrt(2)), plus a small gap.
const double _rotatedLabelFootprint = 18;

/// Minimum spacing for the small value badges drawn above each point.
const double _valueBadgeFootprint = 22;

// ══════════════════════════════════════════════════════════════════════════════
// 1. MANDING TREND LINE CHART (Prompted vs Unprompted)
// ══════════════════════════════════════════════════════════════════════════════
class MandingLineChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  const MandingLineChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(
        child: Text(
          'No manding data points recorded for this student in selected date range.',
          textAlign: TextAlign.center,
          style: TextStyle(
              color: Color(0xFF6B7280), fontSize: 13, fontFamily: 'Poppins'),
        ),
      );
    }

    return Column(
      children: [
        // Legend Row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SizedBox(
            width: double.infinity,
            child: Wrap(
              alignment: WrapAlignment.end,
              spacing: 16,
              runSpacing: 4,
              children: [
                _buildLegendChip(
                    'Unprompted (Independent)', const Color(0xFF7C3AED)),
                _buildLegendChip('Prompted', const Color(0xFFF97316)),
              ],
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 24, 20),
            child: CustomPaint(
              size: Size.infinite,
              painter: _MandingChartPainter(data),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLegendChip(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label,
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}

class _MandingChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;
  _MandingChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    const leftMargin = 36.0;
    const bottomMargin = 28.0;
    const topMargin = 16.0;
    final chartW = size.width - leftMargin;
    final chartH = size.height - bottomMargin - topMargin;

    double maxVal = 10.0;
    for (final d in data) {
      final p = (d['prompted'] as num? ?? 0).toDouble();
      final u = (d['unprompted'] as num? ?? 0).toDouble();
      if (p > maxVal) maxVal = p;
      if (u > maxVal) maxVal = u;
    }
    maxVal = (maxVal * 1.2).ceilToDouble();

    // Grid lines & Y-axis labels
    final gridPaint = Paint()
      ..color = const Color(0xFFE5E7EB)
      ..strokeWidth = 1;
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    const int steps = 4;
    for (int i = 0; i <= steps; i++) {
      final y = topMargin + chartH - (i / steps) * chartH;
      canvas.drawLine(Offset(leftMargin, y), Offset(size.width, y), gridPaint);

      final val = ((maxVal / steps) * i).round();
      textPainter.text = TextSpan(
        text: '$val',
        style: const TextStyle(fontSize: 10, color: Color(0xFF6B7280)),
      );
      textPainter.layout();
      textPainter.paint(
          canvas,
          Offset(
              leftMargin - textPainter.width - 6, y - textPainter.height / 2));
    }

    if (data.isEmpty) return;

    final xStep = data.length == 1 ? chartW / 2 : chartW / (data.length - 1);

    // X-axis labels (thinned on narrow widths so they never overlap)
    const dateStyle = TextStyle(
        fontSize: 10, color: Color(0xFF4B5563), fontWeight: FontWeight.w600);
    final labelMask =
        _labelMask(data.length, xStep, _maxLabelWidth(data, dateStyle));
    for (int i = 0; i < data.length; i++) {
      if (!labelMask[i]) continue;
      final x = leftMargin + (data.length == 1 ? chartW / 2 : i * xStep);
      final dateStr = (data[i]['date'] ?? '').toString();
      textPainter.text = TextSpan(
        text: dateStr,
        style: dateStyle,
      );
      textPainter.layout();
      textPainter.paint(canvas,
          Offset(x - textPainter.width / 2, size.height - bottomMargin + 6));
    }

    // Draw Unprompted line (Purple)
    _drawLine(
      canvas: canvas,
      color: const Color(0xFF7C3AED),
      key: 'unprompted',
      leftMargin: leftMargin,
      topMargin: topMargin,
      chartH: chartH,
      chartW: chartW,
      xStep: xStep,
      maxVal: maxVal,
    );

    // Draw Prompted line (Orange)
    _drawLine(
      canvas: canvas,
      color: const Color(0xFFF97316),
      key: 'prompted',
      leftMargin: leftMargin,
      topMargin: topMargin,
      chartH: chartH,
      chartW: chartW,
      xStep: xStep,
      maxVal: maxVal,
    );
  }

  void _drawLine({
    required Canvas canvas,
    required Color color,
    required String key,
    required double leftMargin,
    required double topMargin,
    required double chartH,
    required double chartW,
    required double xStep,
    required double maxVal,
  }) {
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final dotPaint = Paint()..color = color;
    final whitePaint = Paint()..color = Colors.white;

    final path = Path();
    final points = <Offset>[];
    final values = <num>[];

    for (int i = 0; i < data.length; i++) {
      final val = (data[i][key] as num? ?? 0);
      final x = leftMargin + (data.length == 1 ? chartW / 2 : i * xStep);
      final y = topMargin + chartH - (val / maxVal) * chartH;
      final pt = Offset(x, y);
      points.add(pt);
      values.add(val);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, linePaint);

    final valueMask = _labelMask(points.length, xStep, _valueBadgeFootprint);
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    for (int i = 0; i < points.length; i++) {
      final pt = points[i];
      canvas.drawCircle(pt, 5, dotPaint);
      canvas.drawCircle(pt, 2.5, whitePaint);
      if (!valueMask[i]) continue;

      // Value label badge
      textPainter.text = TextSpan(
        text: '${values[i]}',
        style:
            TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
      );
      textPainter.layout();
      textPainter.paint(
          canvas, Offset(pt.dx - textPainter.width / 2, pt.dy - 16));
    }
  }

  @override
  bool shouldRepaint(covariant _MandingChartPainter oldDelegate) => true;
}

// ══════════════════════════════════════════════════════════════════════════════
// 2. CUMULATIVE ACQUISITION CURVE CHART
// ══════════════════════════════════════════════════════════════════════════════
class AcquisitionLineChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  const AcquisitionLineChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(
        child: Text(
          'No cumulative target acquisition points recorded.',
          style: TextStyle(
              color: Color(0xFF6B7280), fontSize: 13, fontFamily: 'Poppins'),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 24, 20),
      child: CustomPaint(
        size: Size.infinite,
        painter: _AcquisitionChartPainter(data),
      ),
    );
  }
}

class _AcquisitionChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;
  _AcquisitionChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    const leftMargin = 36.0;
    const bottomMargin = 28.0;
    const topMargin = 16.0;
    final chartW = size.width - leftMargin;
    final chartH = size.height - bottomMargin - topMargin;

    double maxVal = 4.0;
    for (final d in data) {
      final c = (d['count'] as num? ?? 0).toDouble();
      if (c > maxVal) maxVal = c;
    }
    // Round up to a multiple of the 4 grid steps so labels are whole numbers.
    maxVal = ((maxVal * 1.25) / 4).ceilToDouble() * 4;

    final gridPaint = Paint()
      ..color = const Color(0xFFE5E7EB)
      ..strokeWidth = 1;
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    const int steps = 4;
    for (int i = 0; i <= steps; i++) {
      final y = topMargin + chartH - (i / steps) * chartH;
      canvas.drawLine(Offset(leftMargin, y), Offset(size.width, y), gridPaint);

      final val = ((maxVal / steps) * i).round();
      textPainter.text = TextSpan(
        text: '$val',
        style: const TextStyle(fontSize: 10, color: Color(0xFF6B7280)),
      );
      textPainter.layout();
      textPainter.paint(
          canvas,
          Offset(
              leftMargin - textPainter.width - 6, y - textPainter.height / 2));
    }

    if (data.isEmpty) return;
    final xStep = data.length == 1 ? chartW / 2 : chartW / (data.length - 1);

    // X-axis dates (thinned on narrow widths so they never overlap)
    const dateStyle = TextStyle(
        fontSize: 10, color: Color(0xFF4B5563), fontWeight: FontWeight.w600);
    final labelMask =
        _labelMask(data.length, xStep, _maxLabelWidth(data, dateStyle));
    for (int i = 0; i < data.length; i++) {
      if (!labelMask[i]) continue;
      final x = leftMargin + (data.length == 1 ? chartW / 2 : i * xStep);
      final dateStr = (data[i]['date'] ?? '').toString();
      textPainter.text = TextSpan(
        text: dateStr,
        style: dateStyle,
      );
      textPainter.layout();
      textPainter.paint(canvas,
          Offset(x - textPainter.width / 2, size.height - bottomMargin + 6));
    }

    // Cumulative Line & Area fill
    final linePaint = Paint()
      ..color = const Color(0xFF9333EA)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF9333EA).withValues(alpha: 0.25),
          const Color(0xFF9333EA).withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(leftMargin, topMargin, chartW, chartH));

    final path = Path();
    final fillPath = Path();
    final points = <Offset>[];
    final values = <num>[];

    for (int i = 0; i < data.length; i++) {
      final val = (data[i]['count'] as num? ?? 0);
      final x = leftMargin + (data.length == 1 ? chartW / 2 : i * xStep);
      final y = topMargin + chartH - (val / maxVal) * chartH;
      final pt = Offset(x, y);
      points.add(pt);
      values.add(val);
      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, topMargin + chartH);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    if (points.isNotEmpty) {
      fillPath.lineTo(points.last.dx, topMargin + chartH);
      fillPath.close();
      canvas.drawPath(fillPath, fillPaint);
      canvas.drawPath(path, linePaint);
    }

    final dotPaint = Paint()..color = const Color(0xFF7E22CE);
    final whitePaint = Paint()..color = Colors.white;

    final valueMask = _labelMask(points.length, xStep, _valueBadgeFootprint);
    for (int i = 0; i < points.length; i++) {
      final pt = points[i];
      canvas.drawCircle(pt, 5, dotPaint);
      canvas.drawCircle(pt, 2.5, whitePaint);
      if (!valueMask[i]) continue;

      textPainter.text = TextSpan(
        text: '${values[i]}',
        style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Color(0xFF7E22CE)),
      );
      textPainter.layout();
      textPainter.paint(
          canvas, Offset(pt.dx - textPainter.width / 2, pt.dy - 16));
    }
  }

  @override
  bool shouldRepaint(covariant _AcquisitionChartPainter oldDelegate) => true;
}

// ══════════════════════════════════════════════════════════════════════════════
// 3. PROBLEM BEHAVIOUR DURATION LINE CHART (matches THERAPIST BRP-3.png)
// ══════════════════════════════════════════════════════════════════════════════
class PbDurationLineChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  const PbDurationLineChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(
        child: Text(
          'No duration trend points recorded for this student.',
          style: TextStyle(
              color: Color(0xFF6B7280), fontSize: 13, fontFamily: 'Poppins'),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 24, 28),
      child: CustomPaint(
        size: Size.infinite,
        painter: _PbDurationChartPainter(data),
      ),
    );
  }
}

class _PbDurationChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;
  _PbDurationChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    const leftMargin = 36.0;
    const bottomMargin = 34.0;
    const topMargin = 16.0;
    final chartW = size.width - leftMargin;
    final chartH = size.height - bottomMargin - topMargin;

    double maxVal = 5.0;
    for (final d in data) {
      final dur = (d['duration'] as num? ?? 0).toDouble();
      if (dur > maxVal) maxVal = dur;
    }
    // Round up to a multiple of the 7 grid steps so labels are whole numbers.
    maxVal = ((maxVal * 1.15) / 7).ceilToDouble() * 7;

    final gridPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 1;
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    // 7 horizontal steps
    const int steps = 7;
    for (int i = 0; i <= steps; i++) {
      final y = topMargin + chartH - (i / steps) * chartH;
      canvas.drawLine(Offset(leftMargin, y), Offset(size.width, y), gridPaint);

      final val = ((maxVal / steps) * i).round();
      textPainter.text = TextSpan(
        text: '$val',
        style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
      );
      textPainter.layout();
      textPainter.paint(
          canvas,
          Offset(
              leftMargin - textPainter.width - 6, y - textPainter.height / 2));
    }

    if (data.isEmpty) return;
    final xStep = data.length == 1 ? chartW / 2 : chartW / (data.length - 1);

    // X-axis rotated dates (thinned on narrow widths so they never overlap)
    final labelMask = _labelMask(data.length, xStep, _rotatedLabelFootprint);
    for (int i = 0; i < data.length; i++) {
      if (!labelMask[i]) continue;
      final x = leftMargin + (data.length == 1 ? chartW / 2 : i * xStep);
      final dateStr = (data[i]['date'] ?? '').toString();
      textPainter.text = TextSpan(
        text: dateStr,
        style: const TextStyle(
            fontSize: 9, color: Color(0xFF475569), fontWeight: FontWeight.w500),
      );
      textPainter.layout();

      canvas.save();
      canvas.translate(x, size.height - bottomMargin + 4);
      canvas.rotate(-pi / 4);
      textPainter.paint(canvas, Offset(-textPainter.width, 0));
      canvas.restore();
    }

    // Line Paint in Brick Red (as in BRP-3.png)
    final linePaint = Paint()
      ..color = const Color(0xFFB91C1C)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final dotPaint = Paint()..color = const Color(0xFFB91C1C);
    final whitePaint = Paint()..color = Colors.white;

    final path = Path();
    final points = <Offset>[];
    final values = <num>[];

    for (int i = 0; i < data.length; i++) {
      final val = (data[i]['duration'] as num? ?? 0);
      final x = leftMargin + (data.length == 1 ? chartW / 2 : i * xStep);
      final y = topMargin + chartH - (val / maxVal) * chartH;
      final pt = Offset(x, y);
      points.add(pt);
      values.add(val);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, linePaint);

    final valueMask = _labelMask(points.length, xStep, _valueBadgeFootprint);
    for (int i = 0; i < points.length; i++) {
      final pt = points[i];
      canvas.drawCircle(pt, 4.5, dotPaint);
      canvas.drawCircle(pt, 2, whitePaint);
      if (!valueMask[i]) continue;

      textPainter.text = TextSpan(
        text: '${values[i]}',
        style: const TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.bold,
            color: Color(0xFFB91C1C)),
      );
      textPainter.layout();
      textPainter.paint(
          canvas, Offset(pt.dx - textPainter.width / 2, pt.dy - 14));
    }
  }

  @override
  bool shouldRepaint(covariant _PbDurationChartPainter oldDelegate) => true;
}

// ══════════════════════════════════════════════════════════════════════════════
// 4. MULTI-BEHAVIOR FREQUENCY LINE CHART (matches THERAPIST BRP-4.png)
// ══════════════════════════════════════════════════════════════════════════════

/// Line colours for the behaviours of the multi-behaviour chart, by index.
const List<Color> pbBehaviorPalette = [
  Color(0xFF2563EB),
  Color(0xFFDC2626),
  Color(0xFF16A34A),
  Color(0xFF7C3AED),
  Color(0xFF0891B2),
  Color(0xFFEA580C),
  Color(0xFF0284C7),
  Color(0xFF991B1B),
  Color(0xFF4D7C0F),
];

Color pbBehaviorColor(int index) =>
    pbBehaviorPalette[index % pbBehaviorPalette.length];

/// One line per entry of [behaviors]; each [data] point holds 'date' plus a
/// count under each behaviour name.
class PbMultiBehaviorLineChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  final List<String> behaviors;
  const PbMultiBehaviorLineChart(
      {super.key, required this.data, required this.behaviors});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty || behaviors.isEmpty) {
      return const Center(
        child: Text(
          'No behaviour counts recorded for this student.',
          textAlign: TextAlign.center,
          style: TextStyle(
              color: Color(0xFF6B7280), fontSize: 13, fontFamily: 'Poppins'),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 24, 28),
      child: CustomPaint(
        size: Size.infinite,
        painter: _PbMultiBehaviorChartPainter(data, behaviors),
      ),
    );
  }
}

class _PbMultiBehaviorChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;
  final List<String> behaviors;
  _PbMultiBehaviorChartPainter(this.data, this.behaviors);

  @override
  void paint(Canvas canvas, Size size) {
    const leftMargin = 32.0;
    const bottomMargin = 34.0;
    const topMargin = 16.0;
    final chartW = size.width - leftMargin;
    final chartH = size.height - bottomMargin - topMargin;

    double maxVal = 4.0;
    for (final d in data) {
      for (final k in behaviors) {
        final val = (d[k] as num? ?? 0).toDouble();
        if (val > maxVal) maxVal = val;
      }
    }
    // Whole-number steps so every grid line has an integer label.
    const int steps = 4;
    maxVal = ((maxVal * 1.15) / steps).ceilToDouble() * steps;

    final gridPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 1;
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (int i = 0; i <= steps; i++) {
      final y = topMargin + chartH - (i / steps) * chartH;
      canvas.drawLine(Offset(leftMargin, y), Offset(size.width, y), gridPaint);

      textPainter.text = TextSpan(
        text: '${(maxVal / steps * i).round()}',
        style: const TextStyle(fontSize: 9.5, color: Color(0xFF64748B)),
      );
      textPainter.layout();
      textPainter.paint(
          canvas,
          Offset(
              leftMargin - textPainter.width - 6, y - textPainter.height / 2));
    }

    if (data.isEmpty) return;
    final xStep = data.length == 1 ? chartW / 2 : chartW / (data.length - 1);

    // X-axis dates (thinned on narrow widths so they never overlap)
    final labelMask = _labelMask(data.length, xStep, _rotatedLabelFootprint);
    for (int i = 0; i < data.length; i++) {
      if (!labelMask[i]) continue;
      final x = leftMargin + (data.length == 1 ? chartW / 2 : i * xStep);
      final dateStr = (data[i]['date'] ?? '').toString();
      textPainter.text = TextSpan(
        text: dateStr,
        style: const TextStyle(fontSize: 8.5, color: Color(0xFF475569)),
      );
      textPainter.layout();

      canvas.save();
      canvas.translate(x, size.height - bottomMargin + 4);
      canvas.rotate(-pi / 4);
      textPainter.paint(canvas, Offset(-textPainter.width, 0));
      canvas.restore();
    }

    // One line per behaviour, coloured by its index in [behaviors].
    for (int b = 0; b < behaviors.length; b++) {
      final bName = behaviors[b];
      final color = pbBehaviorColor(b);

      final linePaint = Paint()
        ..color = color
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      final dotPaint = Paint()..color = color;

      final path = Path();
      for (int i = 0; i < data.length; i++) {
        final val = (data[i][bName] as num? ?? 0);
        final x = leftMargin + (data.length == 1 ? chartW / 2 : i * xStep);
        final y = topMargin + chartH - (val / maxVal) * chartH;
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
        canvas.drawCircle(Offset(x, y), 3.5, dotPaint);
      }
      canvas.drawPath(path, linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _PbMultiBehaviorChartPainter oldDelegate) =>
      true;
}
