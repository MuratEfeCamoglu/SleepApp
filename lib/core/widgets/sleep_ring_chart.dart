import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:uyku/core/theme/app_motion.dart';
import 'package:uyku/core/theme/app_theme.dart';
import 'package:uyku/core/theme/sleep_stage_colors.dart';
import 'package:uyku/core/widgets/app_icon.dart';

/// Bir halka: değer (0–1+), renk ve uç rozeti.
@immutable
class RingSegment {
  const RingSegment({
    required this.value,
    required this.color,
    required this.badgeColor,
    required this.icon,
  });

  final double value;
  final Color color;
  final Color badgeColor;
  final AppIconData icon;

  @override
  bool operator ==(Object other) =>
      other is RingSegment &&
      other.value == value &&
      other.color == color &&
      other.badgeColor == badgeColor &&
      other.icon == icon;

  @override
  int get hashCode => Object.hash(value, color, badgeColor, icon);
}

/// İç içe dolan halkalar (CLAUDE.md §7.1). Geometri 284 birimlik tasarım
/// kutusunda hesaplanır ve [size]'a ölçeklenir; böylece HTML ile birebir
/// aynı oranları korur.
class SleepRingChart extends StatefulWidget {
  const SleepRingChart({
    required this.rings,
    required this.size,
    required this.semanticLabel,
    this.strokeWidth = 20,
    this.gap = 8,
    this.center,
    this.celebrate = false,
    super.key,
  });

  final List<RingSegment> rings;
  final double size;
  final double strokeWidth;
  final double gap;
  final Widget? center;
  final bool celebrate;
  final String semanticLabel;

  /// Tasarım kutusu.
  static const designBox = 284.0;

  @override
  State<SleepRingChart> createState() => _SleepRingChartState();
}

class _SleepRingChartState extends State<SleepRingChart>
    with TickerProviderStateMixin {
  late final AnimationController _fill;
  late final AnimationController _bounce;
  bool _started = false;

  Duration get _total =>
      AppMotion.ringFill +
      AppMotion.ringStagger * math.max(0, widget.rings.length - 1);

  @override
  void initState() {
    super.initState();
    _fill = AnimationController(vsync: this, duration: _total)
      ..addStatusListener(_onFillStatus);
    _bounce = AnimationController(vsync: this, duration: AppMotion.celebrate);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      _start();
    }
  }

  @override
  void didUpdateWidget(SleepRingChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_sameRings(oldWidget.rings, widget.rings)) {
      _fill.duration = _total;
      _start();
    }
  }

  bool _sameRings(List<RingSegment> a, List<RingSegment> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  void _start() {
    _bounce.value = 0;
    if (AppMotion.reduced(context)) {
      _fill.value = 1;
    } else {
      _fill.forward(from: 0);
    }
  }

  void _onFillStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed &&
        widget.celebrate &&
        mounted &&
        !AppMotion.reduced(context)) {
      unawaited(HapticFeedback.lightImpact());
      _bounce.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _fill.dispose();
    _bounce.dispose();
    super.dispose();
  }

  double _progress(int index) {
    final totalMs = _total.inMilliseconds;
    if (totalMs == 0) return 1;
    final elapsed = _fill.value * totalMs;
    final local =
        (elapsed - index * AppMotion.ringStagger.inMilliseconds) /
        AppMotion.ringFill.inMilliseconds;
    return AppMotion.ringCurve.transform(local.clamp(0.0, 1.0));
  }

  /// 1 → 1.35 → 1
  double get _badgeScale {
    final t = _bounce.value;
    if (t == 0) return 1;
    return 1 + 0.35 * math.sin(t * math.pi);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      label: widget.semanticLabel,
      image: true,
      child: SizedBox.square(
        dimension: widget.size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            ExcludeSemantics(
              child: AnimatedBuilder(
                animation: Listenable.merge([_fill, _bounce]),
                builder: (context, _) => CustomPaint(
                  size: Size.square(widget.size),
                  painter: _RingPainter(
                    rings: widget.rings,
                    progress: [
                      for (var i = 0; i < widget.rings.length; i++)
                        _progress(i),
                    ],
                    track: colors.surfaceMuted,
                    strokeWidth: widget.strokeWidth,
                    gap: widget.gap,
                    badgeScale: _badgeScale,
                  ),
                ),
              ),
            ),
            if (widget.center != null) widget.center!,
          ],
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.rings,
    required this.progress,
    required this.track,
    required this.strokeWidth,
    required this.gap,
    required this.badgeScale,
  });

  final List<RingSegment> rings;
  final List<double> progress;
  final Color track;
  final double strokeWidth;
  final double gap;
  final double badgeScale;

  static const _badgeRadius = 12.0;
  static const _iconSize = 12.0;
  static const _inset = 2.0;
  static const double _start = -math.pi / 2;

  @override
  void paint(Canvas canvas, Size size) {
    const box = SleepRingChart.designBox;
    canvas
      ..save()
      ..scale(size.width / box);
    const c = Offset(box / 2, box / 2);

    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = track;

    for (var i = 0; i < rings.length; i++) {
      final r = box / 2 - _inset - strokeWidth / 2 - i * (strokeWidth + gap);
      canvas.drawCircle(c, r, trackPaint);
    }

    for (var i = 0; i < rings.length; i++) {
      final ring = rings[i];
      final r = box / 2 - _inset - strokeWidth / 2 - i * (strokeWidth + gap);
      final p = math.min(ring.value.clamp(0.0, 1.0) * progress[i], 0.9999);
      if (p > 0.002) {
        canvas.drawArc(
          Rect.fromCircle(center: c, radius: r),
          _start,
          2 * math.pi * p,
          false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = strokeWidth
            ..strokeCap = StrokeCap.round
            ..color = ring.color,
        );
      }
      if (p > 0.02) {
        final a = _start + 2 * math.pi * p;
        final badge = Offset(c.dx + r * math.cos(a), c.dy + r * math.sin(a));
        canvas.drawCircle(
          badge,
          _badgeRadius * badgeScale,
          Paint()..color = ring.badgeColor,
        );
        final icon = _iconSize * badgeScale;
        AppIconPainter.paintIcon(
          canvas,
          ring.icon,
          SleepStageColors.creamIcon,
          Rect.fromCenter(center: badge, width: icon, height: icon),
        );
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress ||
      old.rings != rings ||
      old.track != track ||
      old.badgeScale != badgeScale;
}
