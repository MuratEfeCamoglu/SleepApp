import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uyku/core/strings/app_strings.dart';
import 'package:uyku/core/theme/app_colors.dart';
import 'package:uyku/core/theme/app_motion.dart';
import 'package:uyku/core/theme/app_radius.dart';
import 'package:uyku/core/theme/app_sizes.dart';
import 'package:uyku/core/theme/app_spacing.dart';
import 'package:uyku/core/theme/app_theme.dart';
import 'package:uyku/core/theme/sleep_stage_colors.dart';
import 'package:uyku/core/widgets/app_icon.dart';
import 'package:uyku/core/widgets/pressable.dart';
import 'package:uyku/core/widgets/screen_header.dart';
import 'package:uyku/core/widgets/sleep_quality_fan_chart.dart';
import 'package:uyku/core/widgets/state_views.dart';
import 'package:uyku/features/sleep_log/domain/sleep_quality.dart';
import 'package:uyku/features/sleep_log/presentation/sleep_log_providers.dart';
import 'package:uyku/features/sleep_quality/domain/quality_distribution.dart';
import 'package:uyku/features/sleep_quality/presentation/quality_providers.dart';
import 'package:uyku/features/sleep_summary/presentation/app_shell.dart';
import 'package:uyku/features/track_sleep/presentation/track_controller.dart';

/// Kalite grubunun etiketi ve rengi — tek yerde.
extension QualityCategoryUi on QualityCategory {
  String label(AppStrings strings) => switch (this) {
    QualityCategory.restorative => strings.quality_restorative,
    QualityCategory.good => strings.quality_good,
    QualityCategory.fair => strings.quality_fair,
    QualityCategory.fragmented => strings.quality_fragmented,
    QualityCategory.sleepless => strings.quality_sleepless,
  };

  Color color(AppColors colors) => switch (this) {
    QualityCategory.restorative => SleepStageColors.sage,
    QualityCategory.good => colors.espressoSlice,
    QualityCategory.fair => SleepStageColors.honey,
    QualityCategory.fragmented => SleepStageColors.ember,
    QualityCategory.sleepless => SleepStageColors.lavender,
  };
}

class QualityScreen extends ConsumerWidget {
  const QualityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    final dist = ref.watch(qualityDistributionProvider);
    final header = ScreenHeader(
      eyebrow: strings.quality_eyebrow,
      title: strings.quality_title,
    );
    return dist.when(
      loading: () => TabPage(
        gap: AppSpacing.mdPlus,
        children: [
          header,
          const SkeletonBlock(height: AppSizes.fanHeight),
          for (var i = 0; i < 5; i++)
            const SkeletonBlock(
              height: AppSizes.qualityRowHeight,
              radius: AppRadius.mdPlusAll,
            ),
        ],
      ),
      error: (_, _) => TabPage(
        children: [
          header,
          ErrorState(
            onRetry: () => ref.read(sleepLogProvider.notifier).retry(),
          ),
        ],
      ),
      data: (d) => d.isEmpty
          ? TabPage(
              children: [
                header,
                const SizedBox(height: AppSpacing.lg),
                EmptyState(
                  icon: AppIcons.gauge,
                  title: strings.quality_emptyTitle,
                  body: strings.quality_emptyBody,
                  actionLabel: strings.log_startSleepMode,
                  onAction: () =>
                      ref.read(trackControllerProvider.notifier).start(),
                ),
              ],
            )
          : TabPage(
              gap: AppSpacing.mdPlus,
              children: [
                header,
                _Fan(dist: d),
                _Rows(dist: d),
              ],
            ),
    );
  }
}

class _Fan extends ConsumerWidget {
  const _Fan({required this.dist});

  final QualityDistribution dist;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    final colors = context.colors;
    final selected = ref.watch(qualitySelectionProvider);
    const cats = QualityCategory.values;
    final summary = [
      for (final c in cats)
        '${c.label(strings)} ${strings.quality_percent(dist.percentOf(c))}',
    ].join(', ');
    return Center(
      child: SleepQualityFanChart(
        semanticLabel: strings.quality_fanSemantic(summary),
        centerValue: strings.quality_percent(dist.goodPercent),
        centerLabel: strings.quality_goodNights,
        selected: selected != null && dist.countOf(cats[selected]) > 0
            ? selected
            : null,
        onSelect: (i) =>
            ref.read(qualitySelectionProvider.notifier).toggle(i ?? selected),
        slices: [
          for (final c in cats)
            FanSlice(
              label: c.label(strings),
              value: dist.countOf(c).toDouble(),
              color: c.color(colors),
              tooltip: strings.quality_tooltip(
                c.label(strings),
                strings.quality_nights(dist.countOf(c)),
              ),
            ),
        ],
      ),
    );
  }
}

class _Rows extends ConsumerWidget {
  const _Rows({required this.dist});

  final QualityDistribution dist;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    final colors = context.colors;
    final text = context.text;
    final selected = ref.watch(qualitySelectionProvider);
    return Column(
      children: [
        for (final c in QualityCategory.values) ...[
          if (c.index > 0) const SizedBox(height: AppSpacing.xs),
          Pressable(
            onPressed: () =>
                ref.read(qualitySelectionProvider.notifier).toggle(c.index),
            selected: selected == c.index,
            semanticLabel:
                '${c.label(strings)}, '
                '${strings.quality_nights(dist.countOf(c))}, '
                '${strings.quality_percent(dist.percentOf(c))}',
            excludeChildSemantics: true,
            child: AnimatedContainer(
              duration: AppMotion.toggle,
              constraints: const BoxConstraints(
                minHeight: AppSizes.qualityRowHeight,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.mdPlus,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: selected == c.index ? colors.surface : null,
                borderRadius: AppRadius.mdPlusAll,
              ),
              child: Row(
                children: [
                  Container(
                    width: AppSizes.rowDot,
                    height: AppSizes.rowDot,
                    decoration: BoxDecoration(
                      color: c.color(colors),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: Text(c.label(strings), style: text.rowLabel)),
                  Text(
                    strings.quality_nights(dist.countOf(c)),
                    style: text.chip.copyWith(
                      color: colors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  ConstrainedBox(
                    constraints: const BoxConstraints(
                      minWidth: AppSizes.qualityValueWidth,
                    ),
                    child: Text(
                      strings.quality_percent(dist.percentOf(c)),
                      textAlign: TextAlign.end,
                      style: text.valueSmall,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
