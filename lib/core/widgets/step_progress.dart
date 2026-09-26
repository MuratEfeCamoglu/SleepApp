import 'package:flutter/widgets.dart';
import 'package:uyku/core/theme/app_motion.dart';
import 'package:uyku/core/theme/app_sizes.dart';
import 'package:uyku/core/theme/app_spacing.dart';
import 'package:uyku/core/theme/app_theme.dart';

/// Adım ilerlemesi: [total] pill segment, [step]'e kadar olanlar espresso.
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
              child: AnimatedContainer(
                duration: AppMotion.progress,
                height: AppSizes.progressSegment,
                decoration: ShapeDecoration(
                  color: i <= step ? colors.espresso : colors.surfaceMuted,
                  shape: const StadiumBorder(),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
