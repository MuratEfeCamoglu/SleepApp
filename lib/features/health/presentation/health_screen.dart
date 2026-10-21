import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uyku/core/router/app_router.dart';
import 'package:uyku/core/strings/app_strings.dart';
import 'package:uyku/core/theme/app_colors.dart';
import 'package:uyku/core/theme/app_motion.dart';
import 'package:uyku/core/theme/app_radius.dart';
import 'package:uyku/core/theme/app_sizes.dart';
import 'package:uyku/core/theme/app_spacing.dart';
import 'package:uyku/core/theme/app_theme.dart';
import 'package:uyku/core/theme/sleep_stage_colors.dart';
import 'package:uyku/core/utils/formatters.dart';
import 'package:uyku/core/widgets/app_icon.dart';
import 'package:uyku/core/widgets/full_page.dart';
import 'package:uyku/core/widgets/motion.dart';
import 'package:uyku/core/widgets/pressable.dart';
import 'package:uyku/core/widgets/screen_header.dart';
import 'package:uyku/core/widgets/state_views.dart';
import 'package:uyku/features/health/domain/health_snapshot.dart';
import 'package:uyku/features/health/domain/health_tips.dart';
import 'package:uyku/features/health/presentation/health_providers.dart';
import 'package:uyku/features/health/presentation/health_ui.dart';
import 'package:uyku/features/premium/presentation/premium_gate.dart';
import 'package:uyku/features/sleep_log/presentation/sleep_log_providers.dart';

/// `/health` — uyku sağlığı skoru, borç, düzenlilik ve sosyal jetlag.
/// Bileşen dökümü, skor geçmişi ve öneriler premium.
class HealthScreen extends ConsumerWidget {
  const HealthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    final snapshot = ref.watch(healthSnapshotProvider);

    final footer = <Widget>[const _CheckCard(), const _Disclaimer()];

    return snapshot.when(
      loading: () => FullPage(
        eyebrow: strings.health_eyebrow,
        title: strings.health_title,
        children: const [
          Center(
            child: SkeletonBlock(
              width: AppSizes.healthRing,
              height: AppSizes.healthRing,
              circle: true,
            ),
          ),
          SkeletonBlock(height: AppSizes.healthChart),
          SkeletonBlock(height: AppSizes.healthChart),
        ],
      ),
      error: (_, _) => FullPage(
        eyebrow: strings.health_eyebrow,
        title: strings.health_title,
        children: [
          ErrorState(
            onRetry: () => ref.read(sleepLogProvider.notifier).retry(),
          ),
        ],
      ),
      data: (s) => FullPage(
        eyebrow: strings.health_eyebrow,
        title: strings.health_title,
        children: s == null
            ? [
                EmptyState(
                  icon: AppIcons.heart,
                  title: strings.health_emptyTitle,
                  body: strings.health_emptyBody,
                  actionLabel: strings.health_emptyAction,
                  onAction: () => context.go(AppRoutes.log),
                ),
                ...footer,
              ]
            : [
                _ScoreHeader(snapshot: s),
                _MetricCard(
                  label: strings.health_debt,
                  color: SleepStageColors.ember,
                  value: formatDuration(strings, s.debtMinutes),
                  body: strings.health_debtBody,
                ),
                _MetricCard(
                  label: strings.health_regularity,
                  color: SleepStageColors.sage,
                  value: s.regularity == null
                      ? null
                      : '${s.regularity!.round()}',
                  unit: strings.health_scoreMax,
                  body: strings.health_regularityBody,
                ),
                _MetricCard(
                  label: strings.health_jetlag,
                  color: SleepStageColors.lavender,
                  value: s.socialJetlagMinutes == null
                      ? null
                      : formatDurationShort(strings, s.socialJetlagMinutes!),
                  body: strings.health_jetlagBody,
                ),
                _SectionLabel(strings.health_premiumTitle),
                PremiumGate(
                  title: strings.health_lockTitle,
                  message: strings.health_lockBody,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _BreakdownCard(snapshot: s),
                      const SizedBox(height: AppSpacing.lgPlus),
                      const _HistoryCard(),
                      const SizedBox(height: AppSpacing.lgPlus),
                      _TipsCard(snapshot: s),
                    ],
                  ),
                ),
                ...footer,
              ],
      ),
    );
  }
}

class _ScoreHeader extends StatelessWidget {
  const _ScoreHeader({required this.snapshot});

  final HealthSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final colors = context.colors;
    final text = context.text;
    return Column(
      children: [
        Center(child: HealthScoreRing(score: snapshot.score)),
        const SizedBox(height: AppSpacing.md),
        Text(
          strings.health_scoreLabel,
          textAlign: TextAlign.center,
          style: text.cardTitle,
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          strings.health_basedOn(snapshot.nights),
          textAlign: TextAlign.center,
          style: text.bodySmall.copyWith(color: colors.textSecondary),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Text(
        label.toUpperCase(),
        style: context.text.label.copyWith(color: context.colors.textSecondary),
      ),
    );
  }
}

/// Renkli nokta + etiket, değer ve kısa açıklama. [value] null ise
/// "Daha fazla kayıt gerekli".
class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.color,
    required this.value,
    required this.body,
    this.unit = '',
  });

  final String label;
  final Color color;
  final String? value;
  final String unit;
  final String body;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final colors = context.colors;
    final text = context.text;
    return MergeSemantics(
      child: SurfaceCard(
        radius: AppRadius.lgAll,
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
                Expanded(
                  child: Text(
                    label,
                    style: text.tileLabel.copyWith(color: colors.textSecondary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            if (value == null)
              Text(strings.health_needMore, style: text.bodyStrong)
            else
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
            const SizedBox(height: AppSpacing.xs),
            Text(
              body,
              style: text.bodySmall.copyWith(color: colors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _BreakdownCard extends StatelessWidget {
  const _BreakdownCard({required this.snapshot});

  final HealthSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final colors = context.colors;
    final text = context.text;
    final excluded = snapshot.component(HealthComponentKind.regularity) == null;
    return SurfaceCard(
      radius: AppRadius.lgPlusAll,
      padding: const EdgeInsets.all(AppSpacing.lgPlus),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(strings.health_breakdownTitle, style: text.cardTitle),
          ),
          for (final c in snapshot.components) ...[
            const SizedBox(height: AppSpacing.md),
            Semantics(
              label: strings.health_componentSemantic(
                c.kind.label(strings),
                c.points,
                c.max,
              ),
              excludeSemantics: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          c.kind.label(strings),
                          style: text.bodyMedium,
                        ),
                      ),
                      Text(
                        strings.health_points(c.points, c.max),
                        style: text.bodyStrong,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  _Bar(
                    value: c.max == 0 ? 0 : c.points / c.max,
                    colors: colors,
                  ),
                ],
              ),
            ),
          ],
          if (excluded) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              strings.health_regularityExcluded,
              style: text.caption.copyWith(color: colors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}

/// İnce ilerleme çubuğu: `surfaceMuted` zemin, espresso dolgu.
class _Bar extends StatelessWidget {
  const _Bar({required this.value, required this.colors});

  final double value;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppRadius.smAll,
      child: SizedBox(
        height: AppSizes.progressBar,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: colors.surfaceMuted),
            // Halka dolumuyla aynı sürede soldan dolar.
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: value.clamp(0.0, 1.0)),
              duration: AppMotion.of(context, AppMotion.ringFill),
              curve: AppMotion.ringCurve,
              builder: (context, fill, child) => FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: fill,
                child: child,
              ),
              child: ColoredBox(color: colors.espressoSoft),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryCard extends ConsumerWidget {
  const _HistoryCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    final colors = context.colors;
    final text = context.text;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final history = ref.watch(healthHistoryProvider);
    final points = history.value ?? const [];
    final scored = [
      for (final p in points)
        if (p.score != null) p.score!,
    ];

    Widget body;
    if (history.isLoading && !history.hasValue) {
      body = const SkeletonBlock(height: AppSizes.healthChart);
    } else if (scored.isEmpty) {
      body = Text(
        strings.health_historyEmpty,
        style: text.bodySmall.copyWith(color: colors.textSecondary),
      );
    } else {
      final summary = strings.health_historySemantic(
        scored.length,
        scored.reduce(math.min),
        scored.reduce(math.max),
        scored.last,
      );
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            label: summary,
            excludeSemantics: true,
            // İlk açılışta çubuklar alttan büyür (chartMorph), Trendler gibi.
            child: SizedBox(
              height: AppSizes.healthChart,
              child: GrowIn(
                builder: (context, factor) => BarChart(
                  duration: AppMotion.reduced(context)
                      ? Duration.zero
                      : AppMotion.chartMorph,
                  curve: AppMotion.entranceCurve,
                  BarChartData(
                    minY: 0,
                    maxY: 100,
                    alignment: BarChartAlignment.spaceBetween,
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    titlesData: const FlTitlesData(show: false),
                    barTouchData: const BarTouchData(enabled: false),
                    barGroups: [
                      for (var i = 0; i < points.length; i++)
                        BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: (points[i].score ?? 0) * factor,
                              width: AppSizes.healthBar,
                              borderRadius: AppRadius.smAll,
                              color: points[i].score == null
                                  ? AppColors.transparent
                                  : HealthBand.of(points[i].score!).color,
                              backDrawRodData: BackgroundBarChartRodData(
                                show: true,
                                toY: 100,
                                color: colors.surfaceMuted,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ExcludeSemantics(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    DateFormat('d MMM', locale).format(points.first.night),
                    style: text.navLabel.copyWith(color: colors.textSecondary),
                  ),
                ),
                Text(
                  DateFormat('d MMM', locale).format(points.last.night),
                  style: text.navLabel.copyWith(color: colors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return SurfaceCard(
      radius: AppRadius.lgPlusAll,
      padding: const EdgeInsets.all(AppSpacing.lgPlus),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(strings.health_historyTitle, style: text.cardTitle),
          ),
          const SizedBox(height: AppSpacing.md),
          body,
        ],
      ),
    );
  }
}

class _TipsCard extends StatelessWidget {
  const _TipsCard({required this.snapshot});

  final HealthSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final colors = context.colors;
    final text = context.text;
    final tips = healthTips(snapshot);
    return SurfaceCard(
      radius: AppRadius.lgPlusAll,
      padding: const EdgeInsets.all(AppSpacing.lgPlus),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(strings.health_tipsTitle, style: text.cardTitle),
          ),
          for (final tip in tips) ...[
            const SizedBox(height: AppSpacing.md),
            MergeSemantics(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: AppSizes.tipIcon,
                    height: AppSizes.tipIcon,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: colors.honeyTint,
                      shape: BoxShape.circle,
                    ),
                    child: AppIcon(AppIcons.moon, color: colors.honeyText),
                  ),
                  const SizedBox(width: AppSpacing.mdPlus),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(tip.title(strings), style: text.bodyStrong),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          tip.body(strings, snapshot),
                          style: text.bodySmall.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// `/health/check` kartı; son sonucun tarihini gösterir.
class _CheckCard extends ConsumerWidget {
  const _CheckCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    final colors = context.colors;
    final text = context.text;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final last = ref.watch(healthCheckProvider);
    final body = last == null
        ? strings.health_checkCardBody
        : [
            strings.health_checkLast(
              DateFormat('d MMMM y', locale).format(last.takenAt),
            ),
            if (last.hasFlags)
              strings.health_checkLastFlags(last.flags.length)
            else
              strings.health_checkLastClear,
          ].join(' · ');
    return Pressable(
      onPressed: () => context.push(AppRoutes.healthCheck),
      semanticLabel: '${strings.health_checkCardTitle}, $body',
      excludeChildSemantics: true,
      child: SurfaceCard(
        radius: AppRadius.lgAll,
        child: Row(
          children: [
            Container(
              width: AppSizes.tipIcon,
              height: AppSizes.tipIcon,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colors.sageTint,
                shape: BoxShape.circle,
              ),
              child: AppIcon(AppIcons.checkBold, color: colors.sageText),
            ),
            const SizedBox(width: AppSpacing.mdPlus),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(strings.health_checkCardTitle, style: text.cardTitle),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    body,
                    style: text.bodySmall.copyWith(color: colors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            AppIcon(AppIcons.chevronRight, color: colors.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _Disclaimer extends StatelessWidget {
  const _Disclaimer();

  @override
  Widget build(BuildContext context) {
    return Text(
      AppStrings.of(context).health_disclaimer,
      textAlign: TextAlign.center,
      style: context.text.caption.copyWith(color: context.colors.textSecondary),
    );
  }
}
