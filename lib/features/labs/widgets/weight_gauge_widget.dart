import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;

/// A horizontal gauge widget that visualizes weight zones using CustomPainter.
///
/// Shows zones: underweight (blue), normal (green), overweight (yellow), obese (red).
/// Displays a current weight marker and labels for min/max range.
class WeightGaugeWidget extends StatelessWidget {
  const WeightGaugeWidget({
    super.key,
    required this.currentWeight,
    required this.minIdeal,
    required this.maxIdeal,
  });

  final double currentWeight;
  final double minIdeal;
  final double maxIdeal;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textColor = colorScheme.onSurface;

    // Calculate display range: extend beyond ideal range
    final range = maxIdeal - minIdeal;
    final gaugeMin = (minIdeal - range * 0.5).clamp(0.0, double.infinity);
    final gaugeMax = maxIdeal + range * 0.5;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 70,
          child: CustomPaint(
            painter: _WeightGaugePainter(
              currentWeight: currentWeight,
              minIdeal: minIdeal,
              maxIdeal: maxIdeal,
              gaugeMin: gaugeMin,
              gaugeMax: gaugeMax,
              textColor: textColor,
              brightness: Theme.of(context).brightness,
            ),
            size: const Size(double.infinity, 70),
          ),
        ),
        const SizedBox(height: 8),
        // Legend
        Wrap(
          spacing: 16,
          runSpacing: 4,
          children: [
            _legendItem(context, const Color(0xFF42A5F5), 'weight_guide.status_underweight'.tr()),
            _legendItem(context, const Color(0xFF66BB6A), 'weight_guide.status_normal'.tr()),
            _legendItem(context, const Color(0xFFFFCA28), 'weight_guide.status_overweight'.tr()),
            _legendItem(context, const Color(0xFFEF5350), 'weight_guide.status_obese'.tr()),
          ],
        ),
      ],
    );
  }

  Widget _legendItem(BuildContext context, Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
        ),
      ],
    );
  }
}

class _WeightGaugePainter extends CustomPainter {
  _WeightGaugePainter({
    required this.currentWeight,
    required this.minIdeal,
    required this.maxIdeal,
    required this.gaugeMin,
    required this.gaugeMax,
    required this.textColor,
    required this.brightness,
  });

  final double currentWeight;
  final double minIdeal;
  final double maxIdeal;
  final double gaugeMin;
  final double gaugeMax;
  final Color textColor;
  final Brightness brightness;

  static const Color underweightColor = Color(0xFF42A5F5);
  static const Color normalColor = Color(0xFF66BB6A);
  static const Color overweightColor = Color(0xFFFFCA28);
  static const Color obeseColor = Color(0xFFEF5350);

  @override
  void paint(Canvas canvas, Size size) {
    final barHeight = 20.0;
    final barTop = 28.0;
    final barY = barTop;
    final totalRange = gaugeMax - gaugeMin;
    if (totalRange <= 0) return;

    final barRect = Rect.fromLTWH(0, barY, size.width, barHeight);
    final barRRect = RRect.fromRectAndRadius(barRect, const Radius.circular(10));

    // Draw background
    final bgPaint = Paint()
      ..color = (brightness == Brightness.dark)
          ? const Color(0xFF333333)
          : const Color(0xFFE0E0E0);
    canvas.drawRRect(barRRect, bgPaint);

    // Clip to rounded bar
    canvas.save();
    canvas.clipRRect(barRRect);

    // Zone boundaries
    final obeseThreshold = maxIdeal * 1.2;

    // Draw zones
    _drawZone(canvas, size, barY, barHeight, gaugeMin, minIdeal, underweightColor, totalRange);
    _drawZone(canvas, size, barY, barHeight, minIdeal, maxIdeal, normalColor, totalRange);
    _drawZone(canvas, size, barY, barHeight, maxIdeal, obeseThreshold.clamp(maxIdeal, gaugeMax), overweightColor, totalRange);
    _drawZone(canvas, size, barY, barHeight, obeseThreshold.clamp(maxIdeal, gaugeMax), gaugeMax, obeseColor, totalRange);

    canvas.restore();

    // Draw min/max labels below the bar
    final labelStyle = TextStyle(
      color: textColor.withOpacity(0.6),
      fontSize: 10,
    );

    _drawLabel(canvas, size, '${minIdeal.toStringAsFixed(1)}',
        _xForWeight(minIdeal, size.width, totalRange), barY + barHeight + 4, labelStyle);
    _drawLabel(canvas, size, '${maxIdeal.toStringAsFixed(1)}',
        _xForWeight(maxIdeal, size.width, totalRange), barY + barHeight + 4, labelStyle);

    // Draw current weight marker
    final markerX = _xForWeight(
      currentWeight.clamp(gaugeMin, gaugeMax),
      size.width,
      totalRange,
    );

    // Marker triangle
    final markerPaint = Paint()
      ..color = textColor
      ..style = PaintingStyle.fill;

    final trianglePath = Path()
      ..moveTo(markerX, barY - 2)
      ..lineTo(markerX - 6, barY - 12)
      ..lineTo(markerX + 6, barY - 12)
      ..close();
    canvas.drawPath(trianglePath, markerPaint);

    // Marker line through bar
    final linePaint = Paint()
      ..color = textColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(markerX, barY),
      Offset(markerX, barY + barHeight),
      linePaint,
    );

    // Current weight label above marker
    final weightLabel = '${currentWeight.toStringAsFixed(1)} kg';
    final weightStyle = TextStyle(
      color: textColor,
      fontSize: 11,
      fontWeight: FontWeight.w700,
    );
    final tp = TextPainter(
      text: TextSpan(text: weightLabel, style: weightStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    final labelX = (markerX - tp.width / 2).clamp(0.0, size.width - tp.width);
    tp.paint(canvas, Offset(labelX, barY - 26));
  }

  void _drawZone(Canvas canvas, Size size, double barY, double barHeight,
      double from, double to, Color color, double totalRange) {
    if (to <= from) return;
    final left = _xForWeight(from, size.width, totalRange);
    final right = _xForWeight(to, size.width, totalRange);
    final paint = Paint()..color = color;
    canvas.drawRect(Rect.fromLTWH(left, barY, right - left, barHeight), paint);
  }

  double _xForWeight(double weight, double width, double totalRange) {
    return ((weight - gaugeMin) / totalRange) * width;
  }

  void _drawLabel(Canvas canvas, Size size, String text, double x, double y,
      TextStyle style) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    final labelX = (x - tp.width / 2).clamp(0.0, size.width - tp.width);
    tp.paint(canvas, Offset(labelX, y));
  }

  @override
  bool shouldRepaint(covariant _WeightGaugePainter oldDelegate) {
    return currentWeight != oldDelegate.currentWeight ||
        minIdeal != oldDelegate.minIdeal ||
        maxIdeal != oldDelegate.maxIdeal ||
        brightness != oldDelegate.brightness;
  }
}
