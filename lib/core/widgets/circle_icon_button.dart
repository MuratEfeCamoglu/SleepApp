import 'package:flutter/widgets.dart';
import 'package:uyku/core/theme/app_sizes.dart';
import 'package:uyku/core/theme/app_theme.dart';
import 'package:uyku/core/widgets/app_icon.dart';
import 'package:uyku/core/widgets/pressable.dart';

enum CircleIconButtonVariant { outline, filled }

/// Yuvarlak ikon butonu (CLAUDE.md §7.5). [semanticLabel] zorunludur.
class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    required this.icon,
    required this.semanticLabel,
    required this.onPressed,
    this.variant = CircleIconButtonVariant.outline,
    this.size = AppSizes.iconButton,
    this.iconSize = AppSizes.icon,
    this.lineColor,
    this.color,
    super.key,
  });

  final AppIconData icon;
  final String semanticLabel;
  final VoidCallback? onPressed;
  final CircleIconButtonVariant variant;
  final double size;
  final double iconSize;

  /// Outline kenar rengi; varsayılan `textPrimary`.
  final Color? lineColor;

  /// İkon rengi; varsayılan `textPrimary` (filled'da `onEspresso`).
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final filled = variant == CircleIconButtonVariant.filled;
    return Opacity(
      opacity: onPressed == null ? 0.4 : 1,
      child: Pressable(
        onPressed: onPressed,
        semanticLabel: semanticLabel,
        excludeChildSemantics: true,
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled ? colors.espresso : null,
            border: filled
                ? null
                : Border.all(
                    color: lineColor ?? colors.textPrimary,
                    width: AppSizes.outlineStroke,
                  ),
          ),
          child: AppIcon(
            icon,
            size: iconSize,
            color: color ?? (filled ? colors.onEspresso : colors.textPrimary),
          ),
        ),
      ),
    );
  }
}
