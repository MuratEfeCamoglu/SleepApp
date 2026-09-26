import 'package:flutter/widgets.dart';
import 'package:uyku/core/theme/app_sizes.dart';
import 'package:uyku/core/theme/app_spacing.dart';
import 'package:uyku/core/theme/app_theme.dart';
import 'package:uyku/core/widgets/app_icon.dart';

/// Değişim rozeti (CLAUDE.md §7.6): artışta sage + yukarı ok, azalışta
/// ember + aşağı ok.
class DeltaBadge extends StatelessWidget {
  const DeltaBadge({
    required this.label,
    required this.positive,
    this.compact = false,
    super.key,
  });

  final String label;
  final bool positive;

  /// Trendler başlığındaki küçük (28) varyant.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.text;
    final fg = positive ? colors.sageText : colors.emberText;
    return Container(
      constraints: BoxConstraints(
        minHeight: compact ? AppSizes.badgeHeightSmall : AppSizes.badgeHeight,
      ),
      padding: EdgeInsets.only(
        left: compact ? AppSpacing.xsPlus : AppSpacing.sm,
        right: compact ? AppSpacing.smPlus : AppSpacing.md,
        top: AppSpacing.xs,
        bottom: AppSpacing.xs,
      ),
      decoration: ShapeDecoration(
        color: positive ? colors.sageTint : colors.emberTint,
        shape: const StadiumBorder(),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon(
            positive ? AppIcons.arrowUp : AppIcons.arrowDown,
            color: fg,
            size: compact ? AppSizes.iconSmall - 2 : AppSizes.iconSmall,
          ),
          SizedBox(width: compact ? AppSpacing.xs : AppSpacing.xsPlus),
          Flexible(
            child: Text(
              label,
              style: (compact ? text.tileLabel : text.chip).copyWith(color: fg),
            ),
          ),
        ],
      ),
    );
  }
}
