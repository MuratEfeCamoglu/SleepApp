import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:uyku/core/theme/app_motion.dart';
import 'package:uyku/core/theme/app_radius.dart';
import 'package:uyku/core/theme/app_shadows.dart';
import 'package:uyku/core/theme/app_sizes.dart';
import 'package:uyku/core/theme/app_spacing.dart';
import 'package:uyku/core/theme/app_theme.dart';

@immutable
class FanSlice {
  const FanSlice({
    required this.label,
    required this.value,
    required this.color,
    required this.tooltip,
  });

  final String label;
  final double value;
  final Color color;

  /// Seçilince gösterilen metin ("Dinlendirici · 11 gece").
  final String tooltip;
}

/// Yelpaze grafiği (CLAUDE.md §7.2). Merkez alt ortadadır; dilimler −150°'den
/// −30°'ye değerle orantılı açılır. Geometri 342×234 tasarım kutusunda
/// hesaplanır ve genişliğe ölçeklenir.
class SleepQualityFanChart extends StatelessWidget {
  const SleepQualityFanChart({
    required this.slices,
    required this.selected,
    required this.onSelect,
    required this.centerValue,
    required this.centerLabel,
    required this.semanticLabel,
    this.sweepAngle = 120,
    super.key,
  });

  final List<FanSlice> slices;
  final int? selected;
  final ValueChanged<int?> onSelect;
  final String centerValue;
  final String centerLabel;
  final String semanticLabel;

  /// Derece.
  final double sweepAngle;

  static const double _w = AppSizes.fanWidth;
  static const double _h = AppSizes.fanHeight;
  static const Offset _center = Offset(_w / 2, _h);
  static const _radius = 180.0;
  static const _hole = 70.0;
  static const _pop = 8.0;
  static const _tipGap = 14.0;
  static const _tipMinX = 64.0;
  static const double _tipMaxX = _w - _tipMinX;

  static double get _startAngle => -150 * math.pi / 180;

  double get _total => slices.fold(0, (s, e) => s + e.value);

  (double, double) _angles(int index) {
    final sweep = sweepAngle * math.pi / 180;
    var a = _startAngle;
    for (var i = 0; i < index; i++) {
      a += _total == 0 ? 0 : sweep * slices[i].value / _total;
    }
    final end = a + (_total == 0 ? 0 : sweep * slices[index].value / _total);
    return (a, end);
  }

  int? _hit(Offset local, double scale) {
    final p = local / scale - _center;
    final r = p.distance;
    if (r < _hole || r > _radius + _pop) return null;
    final angle = math.atan2(p.dy, p.dx);
    for (var i = 0; i < slices.length; i++) {
      final (a0, a1) = _angles(i);
      if (angle >= a0 && angle <= a1) return i;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.text;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = math.min(constraints.maxWidth, _w);
        final scale = width / _w;
        final tip = selected == null ? null : _tooltipAnchor(selected!);
        return Semantics(
          label: semanticLabel,
          image: true,
          child: SizedBox(
            width: width,
            height: _h * scale,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapUp: (d) {
                    final hit = _hit(d.localPosition, scale);
                    onSelect(hit == null || hit == selected ? null : hit);
                  },
                  child: TweenAnimationBuilder<double>(
                    key: ValueKey(selected),
                    tween: Tween(begin: 0, end: 1),
                    duration: AppMotion.reduced(context)
                        ? Duration.zero
                        : AppMotion.sliceSelect,
                    curve: AppMotion.sliceCurve,
                    builder: (context, t, _) => CustomPaint(
                      size: Size(width, _h * scale),
                      painter: _FanPainter(
                        chart: this,
                        scale: scale,
                        pop: t,
                        background: colors.background,
                        valueStyle: text.fanValue.copyWith(
                          color: colors.textPrimary,
                        ),
                        labelStyle: text.micro.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
                if (tip != null)
                  Positioned(
                    left: tip.dx * scale,
                    top: tip.dy * scale,
                    child: FractionalTranslation(
                      translation: const Offset(-0.5, -1),
                      child: IgnorePointer(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.smPlus,
                            vertical: AppSpacing.xsPlus,
                          ),
                          decoration: BoxDecoration(
                            color: colors.espresso,
                            borderRadius: AppRadius.mdAll,
                            boxShadow: AppShadows.lift,
                          ),
                          child: Text(
                            slices[selected!].tooltip,
                            maxLines: 1,
                            style: text.tileLabel.copyWith(
                              color: colors.onEspresso,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Offset _tooltipAnchor(int index) {
    final (a0, a1) = _angles(index);
    final m = (a0 + a1) / 2;
    const r = _radius + _tipGap;
    return Offset(
      (_center.dx + r * math.cos(m)).clamp(_tipMinX, _tipMaxX),
      _center.dy + r * math.sin(m),
    );
  }
}

class _FanPainter extends CustomPainter {
  _FanPainter({
    required this.chart,
    required this.scale,
    required this.pop,
    required this.background,
    required this.valueStyle,
    required this.labelStyle,
  });

  final SleepQualityFanChart chart;
  final double scale;
  final double pop;
  final Color background;
  final TextStyle valueStyle;
  final TextStyle labelStyle;

  @override
  void paint(Canvas canvas, Size size) {
    canvas
      ..save()
      ..scale(scale);
    const c = SleepQualityFanChart._center;
    const r = SleepQualityFanChart._radius;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeJoin = StrokeJoin.round
      ..color = background;

    for (var i = 0; i < chart.slices.length; i++) {
      final slice = chart.slices[i];
      if (slice.value <= 0) continue;
      final (a0, a1) = chart._angles(i);
      final m = (a0 + a1) / 2;
      final off = i == chart.selected ? SleepQualityFanChart._pop * pop : 0.0;
      final o = Offset(off * math.cos(m), off * math.sin(m));
      final path = Path()
        ..moveTo(c.dx + o.dx, c.dy + o.dy)
        ..arcTo(Rect.fromCircle(center: c + o, radius: r), a0, a1 - a0, false)
        ..close();
      canvas
        ..drawPath(path, Paint()..color = slice.color)
        ..drawPath(path, stroke);
    }

    canvas.drawCircle(
      c,
      SleepQualityFanChart._hole,
      Paint()..color = background,
    );
    _text(canvas, chart.centerValue, valueStyle, c.dx, 206);
    _text(canvas, chart.centerLabel, labelStyle, c.dx, 226);
    canvas.restore();
  }

  /// SVG `text-anchor=middle` gibi: `y` metnin taban çizgisidir.
  void _text(Canvas canvas, String s, TextStyle style, double x, double y) {
    final tp = TextPainter(
      text: TextSpan(text: s, style: style),
      textDirection: TextDirection.ltr,
      textScaler: TextScaler.noScaling,
      maxLines: 1,
    )..layout(maxWidth: SleepQualityFanChart._hole * 2);
    final baseline = tp.computeDistanceToActualBaseline(
      TextBaseline.alphabetic,
    );
    tp.paint(canvas, Offset(x - tp.width / 2, y - baseline));
  }

  @override
  bool shouldRepaint(_FanPainter old) =>
      old.chart != chart ||
      old.pop != pop ||
      old.scale != scale ||
      old.background != background;
}
