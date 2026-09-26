import 'package:flutter/widgets.dart';
import 'package:uyku/core/theme/app_spacing.dart';
import 'package:uyku/core/theme/app_theme.dart';

/// Başlık üstü satır + ekran başlığı; isteğe bağlı sol/sağ eylem.
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({
    required this.eyebrow,
    required this.title,
    this.leading,
    this.trailing,
    super.key,
  });

  final String eyebrow;
  final String title;
  final Widget? leading;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.text;
    return Row(
      children: [
        if (leading != null) ...[
          leading!,
          const SizedBox(width: AppSpacing.mdPlus),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eyebrow,
                style: text.eyebrow.copyWith(color: colors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Semantics(
                header: true,
                child: Text(title, style: text.titleLarge),
              ),
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: AppSpacing.md),
          trailing!,
        ],
      ],
    );
  }
}

/// `surface` zeminli kart.
class SurfaceCard extends StatelessWidget {
  const SurfaceCard({
    required this.child,
    required this.radius,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    super.key,
  });

  final Widget child;
  final BorderRadius radius;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: radius,
      ),
      child: child,
    );
  }
}
