import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:uyku/core/theme/app_motion.dart';
import 'package:uyku/core/theme/app_sizes.dart';
import 'package:uyku/core/theme/app_spacing.dart';
import 'package:uyku/core/theme/app_theme.dart';
import 'package:uyku/core/theme/sleep_stage_colors.dart';
import 'package:uyku/core/widgets/app_icon.dart';
import 'package:uyku/core/widgets/pressable.dart';

/// 56 yükseklik espresso pill (CLAUDE.md §7.4). `onPressed == null` → %40.
class PrimaryPillButton extends StatelessWidget {
  const PrimaryPillButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.background,
    this.foreground,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppIconData? icon;

  /// Varsayılan espresso; "Kaydedildi" gibi durumlar için değiştirilebilir.
  final Color? background;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final fg = foreground ?? colors.onEspresso;
    return Opacity(
      opacity: onPressed == null ? 0.4 : 1,
      child: Pressable(
        onPressed: onPressed,
        semanticLabel: label,
        excludeChildSemantics: true,
        child: AnimatedContainer(
          duration: AppMotion.toggle,
          constraints: const BoxConstraints(minHeight: AppSizes.buttonHeight),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
          decoration: ShapeDecoration(
            color: background ?? colors.espresso,
            shape: const StadiumBorder(),
          ),
          // Etiket değişince (ör. "Kaydedildi") eskisi solar, yenisi büyür.
          child: AnimatedSwitcher(
            duration: AppMotion.reduced(context)
                ? Duration.zero
                : AppMotion.swap,
            switchInCurve: AppMotion.entranceCurve,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween<double>(
                  begin: AppMotion.pressScale,
                  end: 1,
                ).animate(animation),
                child: child,
              ),
            ),
            child: Row(
              key: ValueKey(label),
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: context.text.button.copyWith(color: fg),
                  ),
                ),
                if (icon != null) ...[
                  const SizedBox(width: AppSpacing.smPlus),
                  AppIcon(icon!, color: fg, size: AppSizes.iconStep),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Uyku modundaki "Uyandım": basılı tutunca soldan honey dolar, 1.2 sn'de
/// onaylanır; bırakınca 150 ms'de sıfırlanır. Ekran okuyucu için
/// `onLongPress` ve `onTap` doğrudan onaylar.
class HoldToConfirmButton extends StatefulWidget {
  const HoldToConfirmButton({
    required this.label,
    required this.semanticLabel,
    required this.onConfirmed,
    super.key,
  });

  final String label;
  final String semanticLabel;
  final VoidCallback onConfirmed;

  @override
  State<HoldToConfirmButton> createState() => _HoldToConfirmButtonState();
}

class _HoldToConfirmButtonState extends State<HoldToConfirmButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: AppMotion.holdToConfirm,
    reverseDuration: AppMotion.holdRelease,
  )..addStatusListener(_onStatus);

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) _confirm();
  }

  void _confirm() {
    unawaited(HapticFeedback.mediumImpact());
    widget.onConfirmed();
  }

  void _down() {
    if (AppMotion.reduced(context)) {
      _c.value = 1;
      return;
    }
    _c.forward();
  }

  void _up() {
    if (_c.isCompleted) return;
    _c.reverse();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.text;
    return Semantics(
      button: true,
      label: widget.semanticLabel,
      onLongPress: _confirm,
      onTap: _confirm,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _down(),
        onTapUp: (_) => _up(),
        onTapCancel: _up,
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final active = _c.value > 0.5;
            final fg = active ? SleepStageColors.onHoney : colors.onEspresso;
            return ClipPath(
              clipper: const ShapeBorderClipper(shape: StadiumBorder()),
              child: SizedBox(
                height: AppSizes.holdButtonHeight,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ColoredBox(color: colors.espresso),
                    FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: _c.value,
                      child: const ColoredBox(color: SleepStageColors.honey),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox.square(
                          dimension: AppSizes.holdRing,
                          child: CustomPaint(
                            painter: _MiniRingPainter(
                              value: _c.value,
                              color: fg,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Text(
                          widget.label,
                          style: text.button.copyWith(color: fg),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _MiniRingPainter extends CustomPainter {
  _MiniRingPainter({required this.value, required this.color});

  final double value;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 3.0;
    final rect = (Offset.zero & size).deflate(stroke / 2);
    canvas
      ..drawArc(
        rect,
        0,
        2 * math.pi,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..color = color.withValues(alpha: 0.3),
      )
      ..drawArc(
        rect,
        -math.pi / 2,
        2 * math.pi * value,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.round
          ..color = color,
      );
  }

  @override
  bool shouldRepaint(_MiniRingPainter old) =>
      old.value != value || old.color != color;
}
