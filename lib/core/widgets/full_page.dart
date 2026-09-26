import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:uyku/core/router/app_router.dart';
import 'package:uyku/core/strings/app_strings.dart';
import 'package:uyku/core/theme/app_motion.dart';
import 'package:uyku/core/theme/app_radius.dart';
import 'package:uyku/core/theme/app_sizes.dart';
import 'package:uyku/core/theme/app_spacing.dart';
import 'package:uyku/core/theme/app_theme.dart';
import 'package:uyku/core/widgets/app_icon.dart';
import 'package:uyku/core/widgets/circle_icon_button.dart';
import 'package:uyku/core/widgets/pressable.dart';
import 'package:uyku/core/widgets/screen_header.dart';

/// Sekme dışı tam ekran sayfa: geri butonlu başlık + kaydırılabilir içerik,
/// isteğe bağlı altta sabit eylem (thumb-zone CTA).
class FullPage extends StatelessWidget {
  const FullPage({
    required this.eyebrow,
    required this.title,
    required this.children,
    this.bottom,
    this.onBack,
    this.trailing,
    this.gap = AppSpacing.lgPlus,
    super.key,
  });

  final String eyebrow;
  final String title;
  final List<Widget> children;

  /// Ekranın altına sabitlenen eylem.
  final Widget? bottom;

  /// Varsayılan: geri git, yoksa Bugün.
  final VoidCallback? onBack;
  final Widget? trailing;
  final double gap;

  static void back(BuildContext context) =>
      context.canPop() ? context.pop() : context.go(AppRoutes.today);

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final padding = MediaQuery.paddingOf(context);
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final side = math.max(
            AppSpacing.xl,
            (constraints.maxWidth - AppSizes.maxContentWidth) / 2,
          );
          final header = ScreenHeader(
            leading: CircleIconButton(
              icon: AppIcons.back,
              semanticLabel: strings.common_back,
              onPressed: onBack ?? () => back(context),
            ),
            eyebrow: eyebrow,
            title: title,
            trailing: trailing,
          );
          final items = [header, ...children];
          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: EdgeInsets.fromLTRB(
                    side,
                    padding.top + AppSpacing.sm,
                    side,
                    bottom == null
                        ? padding.bottom + AppSpacing.xxl
                        : AppSpacing.xl,
                  ),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => SizedBox(height: gap),
                  itemBuilder: (_, i) => items[i],
                ),
              ),
              if (bottom != null)
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    side,
                    0,
                    side,
                    padding.bottom + AppSpacing.lg,
                  ),
                  child: bottom,
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Seçilebilir kart satırı: seçiliyken espresso kenar ve dolu işaret.
class OptionCard extends StatelessWidget {
  const OptionCard({
    required this.label,
    required this.selected,
    required this.onPressed,
    this.detail,
    super.key,
  });

  final String label;
  final String? detail;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.text;
    return Pressable(
      onPressed: onPressed,
      selected: selected,
      semanticLabel: detail == null ? label : '$label, $detail',
      excludeChildSemantics: true,
      child: AnimatedContainer(
        duration: AppMotion.toggle,
        constraints: const BoxConstraints(minHeight: AppSizes.settingsRow),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: AppRadius.lgMinusAll,
          border: Border.all(
            color: selected ? colors.espresso : colors.surface,
            width: AppSizes.checkStroke,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: text.rowLabel),
                  if (detail != null) ...[
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      detail!,
                      style: text.note.copyWith(color: colors.textSecondary),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            AnimatedContainer(
              duration: AppMotion.toggle,
              width: AppSizes.checkCircle,
              height: AppSizes.checkCircle,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? colors.espresso : null,
                border: Border.all(
                  color: selected ? colors.espresso : colors.chipLine,
                  width: AppSizes.checkStroke,
                ),
              ),
              child: selected
                  ? AppIcon(
                      AppIcons.check,
                      color: colors.onEspresso,
                      size: AppSizes.checkIcon,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

/// Ortada dolu ikon dairesi (sonuç ekranları için).
class IconBadge extends StatelessWidget {
  const IconBadge({
    required this.icon,
    required this.background,
    required this.foreground,
    super.key,
  });

  final AppIconData icon;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: AppSizes.emptyIconCircle,
        height: AppSizes.emptyIconCircle,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: background, shape: BoxShape.circle),
        child: AppIcon(icon, color: foreground, size: AppSizes.emptyIcon),
      ),
    );
  }
}
