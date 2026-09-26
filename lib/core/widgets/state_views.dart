import 'package:flutter/widgets.dart';
import 'package:uyku/core/strings/app_strings.dart';
import 'package:uyku/core/theme/app_motion.dart';
import 'package:uyku/core/theme/app_radius.dart';
import 'package:uyku/core/theme/app_sizes.dart';
import 'package:uyku/core/theme/app_spacing.dart';
import 'package:uyku/core/theme/app_theme.dart';
import 'package:uyku/core/widgets/app_icon.dart';
import 'package:uyku/core/widgets/pressable.dart';
import 'package:uyku/core/widgets/primary_pill_button.dart';

/// Yükleniyor iskeleti: `surfaceMuted` blok, opaklık nabzı (shimmer değil).
class SkeletonBlock extends StatefulWidget {
  const SkeletonBlock({
    this.width,
    this.height = AppSizes.touch,
    this.radius = AppRadius.lgAll,
    this.circle = false,
    super.key,
  });

  final double? width;
  final double height;
  final BorderRadius radius;
  final bool circle;

  @override
  State<SkeletonBlock> createState() => _SkeletonBlockState();
}

class _SkeletonBlockState extends State<SkeletonBlock>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: AppMotion.skeletonPulse,
    lowerBound: 0.5,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AppMotion.reduced(context)) {
      _c.value = 1;
    } else if (!_c.isAnimating) {
      _c.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _c,
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: context.colors.surfaceMuted,
          borderRadius: widget.circle ? null : widget.radius,
          shape: widget.circle ? BoxShape.circle : BoxShape.rectangle,
        ),
      ),
    );
  }
}

/// Boş durum: ikon dairesi + başlık + açıklama + isteğe bağlı CTA.
class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.title,
    required this.body,
    this.icon = AppIcons.moon,
    this.actionLabel,
    this.onAction,
    this.top,
    super.key,
  });

  final String title;
  final String body;
  final AppIconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// İkon yerine gösterilecek görsel (ör. boş halkalar).
  final Widget? top;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.text;
    return Column(
      children: [
        top ??
            Container(
              width: AppSizes.emptyIconCircle,
              height: AppSizes.emptyIconCircle,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colors.honeyTint,
                shape: BoxShape.circle,
              ),
              child: AppIcon(
                icon,
                color: colors.honeyText,
                size: AppSizes.emptyIcon,
              ),
            ),
        const SizedBox(height: AppSpacing.xl),
        Text(title, textAlign: TextAlign.center, style: text.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        Text(
          body,
          textAlign: TextAlign.center,
          style: text.bodyMedium.copyWith(color: colors.textSecondary),
        ),
        if (actionLabel != null) ...[
          const SizedBox(height: AppSpacing.xl),
          PrimaryPillButton(
            label: actionLabel!,
            icon: AppIcons.arrowRight,
            onPressed: onAction,
          ),
        ],
      ],
    );
  }
}

/// Hata durumu: sakin dil + outline "Tekrar dene".
class ErrorState extends StatelessWidget {
  const ErrorState({required this.onRetry, super.key});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final colors = context.colors;
    final text = context.text;
    return Column(
      children: [
        Text(
          strings.common_errorTitle,
          textAlign: TextAlign.center,
          style: text.titleMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          strings.common_errorBody,
          textAlign: TextAlign.center,
          style: text.bodyMedium.copyWith(color: colors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.xl),
        OutlinePillButton(label: strings.common_retry, onPressed: onRetry),
      ],
    );
  }
}

/// İkincil eylem: `textPrimary` kenarlı pill.
class OutlinePillButton extends StatelessWidget {
  const OutlinePillButton({
    required this.label,
    required this.onPressed,
    this.color,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final fg = color ?? context.colors.textPrimary;
    return Pressable(
      onPressed: onPressed,
      semanticLabel: label,
      excludeChildSemantics: true,
      child: Container(
        constraints: const BoxConstraints(minHeight: AppSizes.touch),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.smPlus,
        ),
        decoration: ShapeDecoration(
          shape: StadiumBorder(
            side: BorderSide(color: fg, width: AppSizes.outlineStroke),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: context.text.bodyStrong.copyWith(color: fg),
        ),
      ),
    );
  }
}

/// Altı çizili metin butonu ("Akşam rutinini aç").
class LinkButton extends StatelessWidget {
  const LinkButton({required this.label, required this.onPressed, super.key});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final color = context.colors.textPrimary;
    return Pressable(
      onPressed: onPressed,
      semanticLabel: label,
      excludeChildSemantics: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppSizes.touch),
        child: Align(
          alignment: Alignment.centerLeft,
          widthFactor: 1,
          child: Text(
            label,
            style: context.text.bodyStrong.copyWith(
              color: color,
              decoration: TextDecoration.underline,
              decorationColor: color,
              decorationThickness: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}
