import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uyku/core/router/app_router.dart';
import 'package:uyku/core/strings/app_strings.dart';
import 'package:uyku/core/theme/app_radius.dart';
import 'package:uyku/core/theme/app_sizes.dart';
import 'package:uyku/core/theme/app_spacing.dart';
import 'package:uyku/core/theme/app_theme.dart';
import 'package:uyku/core/utils/formatters.dart';
import 'package:uyku/core/widgets/app_icon.dart';
import 'package:uyku/core/widgets/delta_badge.dart';
import 'package:uyku/core/widgets/full_page.dart';
import 'package:uyku/core/widgets/pressable.dart';
import 'package:uyku/core/widgets/screen_header.dart';
import 'package:uyku/core/widgets/state_views.dart';
import 'package:uyku/features/settings/presentation/settings_controller.dart';
import 'package:uyku/features/sleep_log/presentation/log_screen.dart';
import 'package:uyku/features/sleep_log/presentation/sleep_log_providers.dart';
import 'package:uyku/features/weekly_report/domain/weekly_report.dart';

final FutureProvider<WeeklyReport> weeklyReportProvider =
    FutureProvider.autoDispose<WeeklyReport>((ref) async {
      final entries = await ref.watch(sleepLogProvider.future);
      final goal = ref.watch(
        settingsControllerProvider.select((s) => s.goalMinutes),
      );
      return WeeklyReport.build(entries, goal, ref.watch(todayProvider));
    });

class WeeklyReportScreen extends ConsumerWidget {
  const WeeklyReportScreen({super.key});

  /// Bu dakikadan az sapma "çok düzenli", bundan fazlası "oynak".
  static const _steady = 20;
  static const _loose = 45;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final report = ref.watch(weeklyReportProvider);

    String range(WeeklyReport r) => strings.report_range(
      DateFormat('d MMM', locale).format(r.firstMorning),
      DateFormat('d MMM', locale).format(r.lastMorning),
    );

    return report.when(
      loading: () => FullPage(
        eyebrow: '',
        title: strings.report_title,
        children: const [SkeletonBlock(height: 120), SkeletonBlock()],
      ),
      error: (_, _) => FullPage(
        eyebrow: '',
        title: strings.report_title,
        children: [
          ErrorState(
            onRetry: () => ref.read(sleepLogProvider.notifier).retry(),
          ),
        ],
      ),
      data: (r) => FullPage(
        eyebrow: range(r),
        title: strings.report_title,
        children: r.isEmpty
            ? [
                EmptyState(
                  title: strings.report_emptyTitle,
                  body: strings.report_emptyBody,
                ),
              ]
            : [
                _AverageCard(report: r),
                _Grid(report: r),
                if (r.bedtimeSpread != null) _consistency(context, r),
                if (r.bestNight != null) _bestNight(context, r),
                if (r.topFactor != null)
                  _InfoCard(
                    title: strings.report_topFactor,
                    body: strings.report_topFactorValue(
                      r.topFactor!.factor.label(strings),
                      r.topFactor!.nights,
                    ),
                  ),
              ],
      ),
    );
  }

  Widget _consistency(BuildContext context, WeeklyReport r) {
    final strings = AppStrings.of(context);
    final spread = r.bedtimeSpread!;
    final verdict = spread <= _steady
        ? strings.report_spreadGood
        : spread <= _loose
        ? strings.report_spreadFair
        : strings.report_spreadPoor;
    return _InfoCard(
      title: strings.report_consistency,
      body:
          '${strings.report_spread(strings.duration_minutes(spread))} '
          '$verdict',
    );
  }

  Widget _bestNight(BuildContext context, WeeklyReport r) {
    final strings = AppStrings.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final best = r.bestNight!;
    return _InfoCard(
      title: strings.report_bestNight,
      body: strings.report_bestNightValue(
        DateFormat('EEEE', locale).format(best.night),
        formatDuration(strings, best.durationMinutes),
        best.mood.label(strings),
      ),
    );
  }
}

class _AverageCard extends StatelessWidget {
  const _AverageCard({required this.report});

  final WeeklyReport report;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final colors = context.colors;
    final text = context.text;
    final avg = report.average!;
    final unit = text.displayUnit.copyWith(color: colors.textSecondary);
    final delta = report.delta;
    return SurfaceCard(
      radius: AppRadius.lgPlusAll,
      padding: const EdgeInsets.all(AppSpacing.lgPlus),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            strings.report_average,
            style: text.tileLabel.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xs),
          Semantics(
            label: formatDuration(strings, avg),
            excludeSemantics: true,
            child: Text.rich(
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
          ),
          if (delta != null) ...[
            const SizedBox(height: AppSpacing.md),
            DeltaBadge(
              positive: delta >= 0,
              label: strings.report_delta(formatDelta(strings, delta)),
            ),
          ],
        ],
      ),
    );
  }
}

class _Grid extends StatelessWidget {
  const _Grid({required this.report});

  final WeeklyReport report;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    String clock(int? m) => m == null ? '–' : formatClock(m);
    final cells = [
      (
        strings.report_logged,
        strings.report_loggedValue(report.nights, WeeklyReport.nightsInWeek),
      ),
      (
        strings.report_goalNights,
        strings.report_nightsValue(report.goalNights),
      ),
      (strings.trends_avgBed, clock(report.averageBedMinute)),
      (strings.trends_avgWake, clock(report.averageWakeMinute)),
    ];
    Widget row(int a) => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _Stat(label: cells[a].$1, value: cells[a].$2),
        ),
        const SizedBox(width: AppSpacing.smPlus),
        Expanded(
          child: _Stat(label: cells[a + 1].$1, value: cells[a + 1].$2),
        ),
      ],
    );
    return Column(
      children: [
        row(0),
        const SizedBox(height: AppSpacing.smPlus),
        row(2),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.text;
    return MergeSemantics(
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
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value, style: text.metric),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.text;
    return MergeSemantics(
      child: SurfaceCard(
        radius: AppRadius.lgAll,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: text.cardTitle),
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

/// Pazar günü Bugün ekranında görünen rapor kartı.
class WeeklyReportCard extends ConsumerWidget {
  const WeeklyReportCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(todayProvider);
    if (today.weekday != DateTime.sunday) return const SizedBox.shrink();
    final report = ref.watch(weeklyReportProvider).value;
    if (report == null || report.isEmpty) return const SizedBox.shrink();
    final strings = AppStrings.of(context);
    final colors = context.colors;
    final text = context.text;
    final body = strings.report_cardBody(
      formatDuration(strings, report.average!),
      report.nights,
    );
    return Pressable(
      onPressed: () => context.push(AppRoutes.report),
      semanticLabel: '${strings.report_cardTitle}, $body',
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
              child: AppIcon(AppIcons.bars, color: colors.sageText),
            ),
            const SizedBox(width: AppSpacing.mdPlus),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(strings.report_cardTitle, style: text.cardTitle),
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
