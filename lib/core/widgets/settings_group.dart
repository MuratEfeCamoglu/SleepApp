import 'package:flutter/widgets.dart';
import 'package:uyku/core/theme/app_radius.dart';
import 'package:uyku/core/theme/app_sizes.dart';
import 'package:uyku/core/theme/app_spacing.dart';
import 'package:uyku/core/theme/app_theme.dart';
import 'package:uyku/core/theme/sleep_stage_colors.dart';
import 'package:uyku/core/widgets/app_icon.dart';
import 'package:uyku/core/widgets/pressable.dart';

/// Büyük harf başlıklı `xl` radius kart; satırlar arası 66 pt içeriden
/// başlayan ayraç.
class SettingsGroup extends StatelessWidget {
  const SettingsGroup({required this.title, required this.children, super.key});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: AppSpacing.xs,
            bottom: AppSpacing.sm,
          ),
          child: Semantics(
            header: true,
            child: Text(
              title.toUpperCase(),
              style: context.text.label.copyWith(color: colors.textSecondary),
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: AppRadius.xlAll,
          ),
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0)
                  Padding(
                    padding: const EdgeInsets.only(
                      left: AppSizes.settingsDividerIndent,
                    ),
                    child: Container(
                      height: AppSizes.divider,
                      color: colors.border,
                    ),
                  ),
                children[i],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// 60 pt satır: 36 pt dolu deep daire + krem ikon, etiket, değer, chevron.
class SettingsRow extends StatelessWidget {
  const SettingsRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    this.value,
    this.onPressed,
    this.trailing,
    super.key,
  });

  final AppIconData icon;

  /// Deep ton (krem ikon yalnızca deep tonların üzerine konur).
  final Color iconColor;
  final String label;
  final String? value;
  final VoidCallback? onPressed;

  /// Chevron yerine (ör. switch).
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.text;
    final row = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: AppSizes.settingsRow),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            Container(
              width: AppSizes.settingsIcon,
              height: AppSizes.settingsIcon,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: iconColor,
                shape: BoxShape.circle,
              ),
              child: AppIcon(
                icon,
                color: SleepStageColors.creamIcon,
                size: AppSizes.iconStep,
              ),
            ),
            const SizedBox(width: AppSpacing.mdPlus + AppSpacing.xs),
            Expanded(child: Text(label, style: text.rowLabel)),
            if (value != null) ...[
              const SizedBox(width: AppSpacing.sm),
              Text(
                value!,
                textAlign: TextAlign.end,
                style: text.bodyMedium.copyWith(color: colors.textSecondary),
              ),
            ],
            if (trailing != null)
              trailing!
            else if (onPressed != null) ...[
              const SizedBox(width: AppSpacing.xs),
              AppIcon(
                AppIcons.chevronRight,
                color: colors.textSecondary,
                size: AppSizes.iconStep,
              ),
            ] else if (value != null)
              const SizedBox(width: AppSpacing.xs + AppSizes.iconStep),
          ],
        ),
      ),
    );
    if (onPressed == null) {
      return MergeSemantics(child: row);
    }
    return Pressable(
      onPressed: onPressed,
      semanticLabel: value == null ? label : '$label, $value',
      excludeChildSemantics: true,
      child: row,
    );
  }
}
