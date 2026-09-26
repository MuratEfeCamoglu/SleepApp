import 'package:flutter/widgets.dart';
import 'package:uyku/core/theme/app_motion.dart';
import 'package:uyku/core/theme/app_sizes.dart';
import 'package:uyku/core/theme/app_spacing.dart';
import 'package:uyku/core/theme/app_theme.dart';
import 'package:uyku/core/widgets/pressable.dart';

/// Seçilebilir outline chip: seçiliyken espresso dolgu.
class ChoicePill extends StatelessWidget {
  const ChoicePill({
    required this.label,
    required this.selected,
    required this.onPressed,
    this.height = AppSizes.chipHeight,
    this.strong = false,
    this.expand = false,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;
  final double height;

  /// Uyanış hissi chip'i gibi kalın ve dar etiket.
  final bool strong;

  /// Izgarada hücreyi doldurur.
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.text;
    return Pressable(
      onPressed: onPressed,
      semanticLabel: label,
      toggled: selected,
      excludeChildSemantics: true,
      child: AnimatedContainer(
        duration: AppMotion.toggle,
        constraints: BoxConstraints(minHeight: height),
        alignment: expand ? Alignment.center : null,
        padding: EdgeInsets.symmetric(
          horizontal: expand ? AppSpacing.xxs : AppSpacing.mdPlus,
          vertical: AppSpacing.xs,
        ),
        decoration: ShapeDecoration(
          color: selected ? colors.espresso : null,
          shape: StadiumBorder(
            side: BorderSide(
              color: selected ? colors.espresso : colors.chipLine,
              width: AppSizes.outlineStroke,
            ),
          ),
        ),
        child: Row(
          mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: (strong ? text.chipStrong : text.chip).copyWith(
                    color: selected ? colors.onEspresso : colors.textPrimary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
