import 'package:flutter/widgets.dart';
import 'package:uyku/core/theme/app_motion.dart';
import 'package:uyku/core/theme/app_sizes.dart';
import 'package:uyku/core/theme/app_spacing.dart';
import 'package:uyku/core/theme/app_theme.dart';
import 'package:uyku/core/widgets/pressable.dart';

/// `surfaceMuted` zeminde seçili espresso pill'ler.
class SegmentedPill extends StatelessWidget {
  const SegmentedPill({
    required this.labels,
    required this.selected,
    required this.onChanged,
    required this.semanticLabel,
    super.key,
  });

  final List<String> labels;
  final int selected;
  final ValueChanged<int> onChanged;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      container: true,
      label: semanticLabel,
      explicitChildNodes: true,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xs),
        decoration: ShapeDecoration(
          color: colors.surfaceMuted,
          shape: const StadiumBorder(),
        ),
        child: Row(
          children: [
            for (var i = 0; i < labels.length; i++) ...[
              if (i > 0) const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Pressable(
                  onPressed: () => onChanged(i),
                  semanticLabel: labels[i],
                  selected: i == selected,
                  excludeChildSemantics: true,
                  child: AnimatedContainer(
                    duration: AppMotion.toggle,
                    constraints: const BoxConstraints(
                      minHeight: AppSizes.segmentHeight,
                    ),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                    ),
                    decoration: ShapeDecoration(
                      color: i == selected
                          ? colors.espresso
                          : colors.surfaceMuted,
                      shape: const StadiumBorder(),
                    ),
                    child: Text(
                      labels[i],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.segment.copyWith(
                        color: i == selected
                            ? colors.onEspresso
                            : colors.textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
