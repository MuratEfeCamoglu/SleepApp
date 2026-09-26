import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uyku/core/providers/core_providers.dart';
import 'package:uyku/core/router/app_router.dart';
import 'package:uyku/core/strings/app_strings.dart';
import 'package:uyku/core/theme/app_radius.dart';
import 'package:uyku/core/theme/app_sizes.dart';
import 'package:uyku/core/theme/app_spacing.dart';
import 'package:uyku/core/theme/app_theme.dart';
import 'package:uyku/core/theme/sleep_stage_colors.dart';
import 'package:uyku/core/utils/formatters.dart';
import 'package:uyku/core/widgets/app_icon.dart';
import 'package:uyku/core/widgets/circle_icon_button.dart';
import 'package:uyku/core/widgets/delta_badge.dart';
import 'package:uyku/core/widgets/screen_header.dart';
import 'package:uyku/core/widgets/sleep_ring_chart.dart';
import 'package:uyku/core/widgets/stage_metric_tile.dart';
import 'package:uyku/core/widgets/state_views.dart';
import 'package:uyku/features/settings/presentation/settings_controller.dart';
import 'package:uyku/features/sleep_log/presentation/sleep_log_providers.dart';
import 'package:uyku/features/sleep_summary/domain/today_summary.dart';
import 'package:uyku/features/sleep_summary/presentation/app_shell.dart';
import 'package:uyku/features/sleep_summary/presentation/today_providers.dart';
import 'package:uyku/features/streaks/presentation/badges_screen.dart';
import 'package:uyku/features/track_sleep/presentation/track_controller.dart';
import 'package:uyku/features/weekly_report/presentation/weekly_report_screen.dart';

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final now = ref.watch(clockProvider).now();
    final summary = ref.watch(todaySummaryProvider);

    final header = ScreenHeader(
      eyebrow: DateFormat('EEEE, d MMMM', locale).format(now),
      title: _greeting(strings, now.hour),
      trailing: CircleIconButton(
        icon: AppIcons.settings,
        semanticLabel: strings.today_settings,
        onPressed: () => context.push(AppRoutes.settings),
      ),
    );

    return summary.when(
      loading: () => TabPage(children: [header, const _TodaySkeleton()]),
      error: (_, _) => TabPage(
        children: [
          header,
          const SizedBox(height: AppSpacing.xxl),
          ErrorState(
            onRetry: () => ref.read(sleepLogProvider.notifier).retry(),
          ),
        ],
      ),
      data: (s) => s.isEmpty
          ? TabPage(
              children: [
                header,
                const SizedBox(height: AppSpacing.sm),
                EmptyState(
                  top: const _Rings(summary: null),
                  title: strings.today_emptyTitle,
                  body: strings.today_emptyBody,
                  actionLabel: strings.log_startSleepMode,
                  onAction: () =>
                      ref.read(trackControllerProvider.notifier).start(),
                ),
              ],
            )
          : TabPage(
              children: [
                header,
                const WeeklyReportCard(),
                _Rings(summary: s),
                _StageTiles(summary: s),
                if (s.weekDelta != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: DeltaBadge(
                      positive: s.weekDelta! >= 0,
                      label: strings.today_deltaWeek(
                        formatDelta(strings, s.weekDelta!),
                      ),
                    ),
                  ),
                const StreakCard(),
                _TipCard(summary: s),
              ],
            ),
    );
  }

  static String _greeting(AppStrings strings, int hour) {
    if (hour >= 5 && hour < 12) return strings.today_greetingMorning;
    if (hour >= 12 && hour < 18) return strings.today_greetingDay;
    if (hour >= 18 && hour < 22) return strings.today_greetingEvening;
    return strings.today_greetingNight;
  }
}

class _Rings extends StatelessWidget {
  const _Rings({required this.summary});

  /// null → boş durum: yalnızca track'ler.
  final TodaySummary? summary;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final colors = context.colors;
    final text = context.text;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final s = summary;
    final entry = s?.entry;

    final label = entry == null
        ? ''
        : s!.isLastNight
        ? strings.today_lastNight
        : strings.today_nightOf(
            DateFormat('d MMM', locale).format(entry.night),
          );
    final duration = entry == null
        ? ''
        : formatDuration(strings, entry.durationMinutes);

    int pct(double v) => (v * 100).round();

    return Center(
      child: SleepRingChart(
        size: AppSizes.todayRing,
        semanticLabel: s == null
            ? strings.today_emptyTitle
            : strings.today_ringSemantic(
                label,
                duration,
                pct(s.totalRatio),
                pct(s.remRatio),
                pct(s.deepRatio),
              ),
        celebrate: s != null && s.totalRatio >= 1,
        rings: [
          RingSegment(
            value: s?.totalRatio ?? 0,
            color: colors.espressoSoft,
            badgeColor: colors.espressoDeep,
            icon: AppIcons.badgeMoon,
          ),
          RingSegment(
            value: s?.remRatio ?? 0,
            color: SleepStageColors.sage,
            badgeColor: SleepStageColors.sageDeep,
            icon: AppIcons.badgeEye,
          ),
          RingSegment(
            value: s?.deepRatio ?? 0,
            color: SleepStageColors.ember,
            badgeColor: SleepStageColors.emberDeep,
            icon: AppIcons.badgeWave,
          ),
        ],
        center: entry == null
            ? AppIcon(
                AppIcons.moon,
                color: colors.textSecondary,
                size: AppSizes.emptyIcon,
              )
            : SizedBox(
                width: AppSizes.todayRing * 0.45,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.micro.copyWith(color: colors.textSecondary),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(duration, style: text.ringValue),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _StageTiles extends StatelessWidget {
  const _StageTiles({required this.summary});

  final TodaySummary summary;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final colors = context.colors;
    final st = summary.stages;
    final tiles = [
      (strings.stage_rem, st.rem, SleepStageColors.sage),
      (strings.stage_deep, st.deep, SleepStageColors.ember),
      (strings.stage_light, st.light, colors.espressoSoft),
    ];
    return Row(
      children: [
        for (var i = 0; i < tiles.length; i++) ...[
          if (i > 0) const SizedBox(width: AppSpacing.smPlus),
          Expanded(
            child: StageMetricTile(
              label: tiles[i].$1,
              value: formatStage(tiles[i].$2),
              unit: strings.unit_stage,
              color: tiles[i].$3,
            ),
          ),
        ],
      ],
    );
  }
}

class _TipCard extends ConsumerWidget {
  const _TipCard({required this.summary});

  final TodaySummary summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    final colors = context.colors;
    final text = context.text;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final settings = ref.watch(settingsControllerProvider);
    final tonight = ref.watch(todayProvider);
    final time = formatClock(settings.bedtimeFor(tonight));
    final goal = formatGoal(strings, locale, settings.goalMinutes);
    final body = switch (summary.tip) {
      BedtimeTip.earlier => strings.today_tipEarlier(
        time,
        goal,
        summary.tipMinutes,
      ),
      BedtimeTip.later => strings.today_tipLater(time, summary.tipMinutes),
      BedtimeTip.onTrack => strings.today_tipOnTrack(time, goal),
      BedtimeTip.noData => strings.today_tipNoData(
        time,
        goal,
        formatClock(settings.wakeFor(tonight)),
      ),
    };

    return SurfaceCard(
      radius: AppRadius.lgAll,
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
                Text(strings.today_tipTitle, style: text.cardTitle),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  body,
                  style: text.bodySmall.copyWith(color: colors.textSecondary),
                ),
                LinkButton(
                  label: strings.today_openRoutine,
                  onPressed: () => context.go(AppRoutes.routine),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TodaySkeleton extends StatelessWidget {
  const _TodaySkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SkeletonBlock(
          width: AppSizes.todayRing,
          height: AppSizes.todayRing,
          circle: true,
        ),
        const SizedBox(height: AppSpacing.lgPlus),
        Row(
          children: [
            for (var i = 0; i < 3; i++) ...[
              if (i > 0) const SizedBox(width: AppSpacing.smPlus),
              const Expanded(child: SkeletonBlock(height: 72)),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.lgPlus),
        const SkeletonBlock(height: 120),
      ],
    );
  }
}
