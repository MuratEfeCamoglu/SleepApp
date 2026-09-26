import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
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
import 'package:uyku/core/widgets/delta_badge.dart';
import 'package:uyku/core/widgets/legend_dot.dart';
import 'package:uyku/core/widgets/pressable.dart';
import 'package:uyku/core/widgets/screen_header.dart';
import 'package:uyku/core/widgets/segmented_pill.dart';
import 'package:uyku/core/widgets/state_views.dart';
import 'package:uyku/features/insights/presentation/factor_insights_card.dart';
import 'package:uyku/features/settings/presentation/settings_controller.dart';
import 'package:uyku/features/sleep_log/presentation/sleep_log_providers.dart';
import 'package:uyku/features/sleep_summary/presentation/app_shell.dart';
import 'package:uyku/features/track_sleep/presentation/track_controller.dart';
import 'package:uyku/features/trends/domain/trend_aggregator.dart';
import 'package:uyku/features/trends/presentation/trends_providers.dart';

class TrendsScreen extends ConsumerWidget {
  const TrendsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    final selection = ref.watch(trendSelectionProvider);
    final series = ref.watch(trendSeriesProvider(selection.range));

    final header = ScreenHeader(
      eyebrow: strings.trends_eyebrow,
      title: strings.trends_title,
    );
    final ranges = SegmentedPill(
      semanticLabel: strings.trends_rangeLabel,
      labels: [strings.trends_week, strings.trends_month, strings.trends_year],
      selected: selection.range.index,
      onChanged: (i) => ref
          .read(trendSelectionProvider.notifier)
          .setRange(TrendRange.values[i]),
    );

    return series.when(
      loading: () => TabPage(
        children: [
          header,
          ranges,
          const SkeletonBlock(height: 48),
          const SkeletonBlock(height: 280, radius: AppRadius.lgPlusAll),
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
      data: (s) => s.isEmpty
          ? TabPage(
              children: [
                header,
                ranges,
                const SizedBox(height: AppSpacing.lg),
                EmptyState(
                  icon: AppIcons.bars,
                  title: strings.trends_emptyTitle,
                  body: strings.trends_emptyBody,
                  actionLabel: strings.log_startSleepMode,
                  onAction: () =>
                      ref.read(trackControllerProvider.notifier).start(),
                ),
              ],
            )
          : TabPage(
              children: [
                header,
                ranges,
                _AverageRow(series: s),
                _ChartCard(series: s, selected: selection.bar),
                _AverageCards(series: s),
                const FactorInsightsCard(),
              ],
            ),
    );
  }
}

class _AverageRow extends StatelessWidget {
  const _AverageRow({required this.series});

  final TrendSeries series;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final colors = context.colors;
    final text = context.text;
    final avg = series.average!;
    final unit = text.displayUnit.copyWith(color: colors.textSecondary);
    final delta = series.delta;
    final deltaLabel = delta == null
        ? null
        : switch (series.range) {
            TrendRange.week => strings.trends_deltaWeek(
              formatDelta(strings, delta),
            ),
            TrendRange.month => strings.trends_deltaMonth(
              formatDelta(strings, delta),
            ),
            TrendRange.year => strings.trends_deltaYear(
              formatDelta(strings, delta),
            ),
          };
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.end,
      runSpacing: AppSpacing.sm,
      spacing: AppSpacing.sm,
      children: [
        Semantics(
          label: '${strings.trends_average}, ${formatDuration(strings, avg)}',
          excludeSemantics: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                strings.trends_average,
                style: text.tileLabel.copyWith(color: colors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text.rich(
                TextSpan(
                  style: text.displayNumber,
                  children: [
                    TextSpan(text: '${avg ~/ 60}'),
                    TextSpan(text: '${strings.unit_hour} ', style: unit),
                    TextSpan(text: '${avg % 60}'),
                    TextSpan(text: strings.unit_minute, style: unit),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (deltaLabel != null)
          DeltaBadge(label: deltaLabel, positive: delta! >= 0, compact: true),
      ],
    );
  }
}

class _ChartCard extends ConsumerWidget {
  const _ChartCard({required this.series, required this.selected});

  final TrendSeries series;
  final int? selected;

  static const double _barArea = AppSizes.trendChart - AppSizes.trendLabelArea;

  /// Tasarımda 0,3 pt/dk: 8 saatlik hedef çizgisi 144 pt yükseklikte.
  static const double _minMaxY = _barArea / 0.3;

  double get _barWidth => switch (series.range) {
    TrendRange.week => 28,
    TrendRange.month => 44,
    TrendRange.year => 22,
  };

  String _label(BuildContext context, TrendBar bar, {required bool full}) {
    final strings = AppStrings.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    return switch (series.range) {
      TrendRange.week => DateFormat(
        full ? 'EEEE' : 'E',
        locale,
      ).format(bar.start),
      TrendRange.month =>
        full
            ? strings.trends_weekFull(bar.index)
            : strings.trends_weekShort(bar.index),
      TrendRange.year => DateFormat(
        full ? 'MMMM' : 'MMM',
        locale,
      ).format(bar.start),
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    final colors = context.colors;
    final text = context.text;
    final goal = ref.watch(
      settingsControllerProvider.select((s) => s.goalMinutes),
    );
    final bars = series.bars;
    final lastWithData = bars.lastIndexWhere((b) => b.minutes != null);
    final sel = (selected ?? lastWithData).clamp(0, bars.length - 1);
    final selBar = bars[sel];
    final maxValue = bars.fold<int>(0, (m, b) => math.max(m, b.minutes ?? 0));
    final maxY = math.max(_minMaxY, maxValue + 20.0);

    BarChartRodData rod(TrendBar b, {required bool on}) {
      final st = b.stages;
      final a = on ? 1.0 : 0.5;
      final deep = st.deep.toDouble();
      final rem = deep + st.rem;
      final total = (b.minutes ?? 0).toDouble();
      return BarChartRodData(
        toY: total,
        width: _barWidth,
        borderRadius: AppRadius.smAll,
        color: AppColors.transparent,
        rodStackItems: [
          BarChartRodStackItem(
            0,
            deep,
            SleepStageColors.ember.withValues(alpha: a),
          ),
          BarChartRodStackItem(
            deep,
            rem,
            SleepStageColors.sage.withValues(alpha: a),
          ),
          BarChartRodStackItem(
            rem,
            total,
            colors.espressoSoft.withValues(alpha: a),
          ),
        ],
      );
    }

    return SurfaceCard(
      radius: AppRadius.lgPlusAll,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.mdPlus,
        AppSpacing.lg,
        AppSpacing.mdPlus,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _label(context, selBar, full: true),
                  style: text.chip.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                selBar.minutes == null
                    ? strings.trends_noData
                    : formatDuration(strings, selBar.minutes!),
                style: text.chip.copyWith(color: colors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: AppSizes.trendChart,
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  height: _barArea,
                  child: ExcludeSemantics(
                    child: BarChart(
                      duration: AppMotion.reduced(context)
                          ? Duration.zero
                          : AppMotion.chartMorph,
                      curve: AppMotion.entranceCurve,
                      BarChartData(
                        minY: 0,
                        maxY: maxY,
                        alignment: BarChartAlignment.spaceAround,
                        gridData: const FlGridData(show: false),
                        borderData: FlBorderData(show: false),
                        titlesData: const FlTitlesData(show: false),
                        barTouchData: const BarTouchData(enabled: false),
                        extraLinesData: ExtraLinesData(
                          horizontalLines: [
                            HorizontalLine(
                              y: goal.toDouble(),
                              color: colors.goalLine,
                              strokeWidth: AppSizes.goalLineWidth,
                              dashArray: const [
                                AppSizes.goalDash,
                                AppSizes.goalDash,
                              ],
                              label: HorizontalLineLabel(
                                show: true,
                                alignment: Alignment.topRight,
                                padding: const EdgeInsets.only(
                                  bottom: AppSpacing.xs,
                                ),
                                style: text.micro.copyWith(
                                  color: colors.textSecondary,
                                ),
                                labelResolver: (_) => strings.trends_goal(
                                  formatDurationShort(strings, goal),
                                ),
                              ),
                            ),
                          ],
                        ),
                        barGroups: [
                          for (var i = 0; i < bars.length; i++)
                            BarChartGroupData(
                              x: i,
                              barRods: [rod(bars[i], on: i == sel)],
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Etiketler ve dokunma alanları: her bar bir buton.
                Positioned.fill(
                  child: Row(
                    children: [
                      for (var i = 0; i < bars.length; i++)
                        Expanded(
                          child: Pressable(
                            onPressed: () => ref
                                .read(trendSelectionProvider.notifier)
                                .selectBar(i),
                            selected: i == sel,
                            semanticLabel: strings.trends_barSemantic(
                              _label(context, bars[i], full: true),
                              bars[i].minutes == null
                                  ? strings.trends_noData
                                  : formatDuration(strings, bars[i].minutes!),
                            ),
                            excludeChildSemantics: true,
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: Text(
                                _label(context, bars[i], full: false),
                                maxLines: 1,
                                overflow: TextOverflow.clip,
                                textScaler: MediaQuery.textScalerOf(
                                  context,
                                ).clamp(maxScaleFactor: 1.15),
                                style: text.navLabel.copyWith(
                                  color: i == sel
                                      ? colors.textPrimary
                                      : colors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.xs,
            children: [
              LegendDot(
                label: strings.stage_deep,
                color: SleepStageColors.ember,
              ),
              LegendDot(label: strings.stage_rem, color: SleepStageColors.sage),
              LegendDot(label: strings.stage_light, color: colors.espressoSoft),
            ],
          ),
        ],
      ),
    );
  }
}

class _AverageCards extends StatelessWidget {
  const _AverageCards({required this.series});

  final TrendSeries series;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    Widget card(String label, int? minute) => Expanded(
      child: _StatCard(
        label: label,
        value: minute == null ? '–' : formatClock(minute),
      ),
    );
    return Row(
      children: [
        card(strings.trends_avgBed, series.averageBedMinute),
        const SizedBox(width: AppSpacing.smPlus),
        card(strings.trends_avgWake, series.averageWakeMinute),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.text;
    return Semantics(
      label: '$label, $value',
      excludeSemantics: true,
      child: SurfaceCard(
        radius: AppRadius.lgAll,
        padding: const EdgeInsets.all(AppSpacing.mdPlus),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: text.tileLabel.copyWith(color: colors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(value, style: text.metric),
          ],
        ),
      ),
    );
  }
}
