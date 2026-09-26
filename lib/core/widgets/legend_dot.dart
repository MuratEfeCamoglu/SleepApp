import 'package:flutter/widgets.dart';
import 'package:uyku/core/theme/app_sizes.dart';
import 'package:uyku/core/theme/app_spacing.dart';
import 'package:uyku/core/theme/app_theme.dart';

/// Nokta + etiket (CLAUDE.md §7.7).
class LegendDot extends StatelessWidget {
  const LegendDot({
    required this.label,
    required this.color,
    this.size = AppSizes.dotSmall,
    super.key,
  });

  final String label;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppSpacing.xsPlus),
        Text(
          label,
          style: context.text.caption.copyWith(color: colors.textSecondary),
        ),
      ],
    );
  }
}
