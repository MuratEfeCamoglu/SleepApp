import 'package:flutter/widgets.dart';
import 'package:uyku/core/theme/app_radius.dart';
import 'package:uyku/core/theme/app_sizes.dart';
import 'package:uyku/core/theme/app_spacing.dart';
import 'package:uyku/core/theme/app_theme.dart';

/// Renkli nokta + etiket, altında değer ve birim (CLAUDE.md §7.3).
class StageMetricTile extends StatelessWidget {
  const StageMetricTile({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
    super.key,
  });

  final String label;
  final String value;
  final String unit;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.text;
    return Semantics(
      container: true,
      label: '$label, $value$unit',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.mdPlus),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: AppRadius.lgAll,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: AppSizes.dot,
                  height: AppSizes.dot,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppSpacing.xsPlus),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.tileLabel.copyWith(color: colors.textSecondary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.smPlus),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text.rich(
                TextSpan(
                  text: value,
                  style: text.metric,
                  children: [
                    TextSpan(
                      text: unit,
                      style: text.metricUnit.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
