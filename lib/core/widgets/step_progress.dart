import 'package:flutter/widgets.dart';
import 'package:uyku/core/theme/app_motion.dart';
import 'package:uyku/core/theme/app_sizes.dart';
import 'package:uyku/core/theme/app_spacing.dart';
import 'package:uyku/core/theme/app_theme.dart';

/// Adım ilerlemesi: [total] pill segment, [step]'e kadar olanlar espresso.
/// Segment, adım geçişiyle aynı sürede ([AppMotion.pageTransition]) soldan
/// dolar / boşalır; hareket azaltmada anında.
class StepProgress extends StatelessWidget {
  const StepProgress({required this.step, required this.total, super.key});

  final int step;
  final int total;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ExcludeSemantics(
      child: Row(
        children: [
          for (var i = 0; i < total; i++) ...[
            if (i > 0) const SizedBox(width: AppSpacing.xsPlus),
            Expanded(
              child: ClipPath(
                clipper: const ShapeBorderClipper(shape: StadiumBorder()),
                child: Container(
                  height: AppSizes.progressSegment,
                  color: colors.surfaceMuted,
                  alignment: Alignment.centerLeft,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(end: i <= step ? 1 : 0),
                    duration: AppMotion.of(context, AppMotion.pageTransition),
                    curve: AppMotion.entranceCurve,
                    builder: (context, fill, child) => FractionallySizedBox(
                      widthFactor: fill,
                      heightFactor: 1,
                      child: child,
                    ),
                    child: ColoredBox(color: colors.espresso),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
