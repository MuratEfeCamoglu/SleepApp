import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uyku/core/strings/app_strings.dart';
import 'package:uyku/core/theme/app_radius.dart';
import 'package:uyku/core/theme/app_sizes.dart';
import 'package:uyku/core/theme/app_spacing.dart';
import 'package:uyku/core/theme/app_theme.dart';
import 'package:uyku/core/utils/formatters.dart';
import 'package:uyku/core/widgets/delta_badge.dart';
import 'package:uyku/core/widgets/screen_header.dart';
import 'package:uyku/features/insights/domain/factor_insights.dart';
import 'package:uyku/features/settings/presentation/settings_controller.dart';
import 'package:uyku/features/sleep_log/domain/sleep_entry.dart';
import 'package:uyku/features/sleep_log/presentation/log_screen.dart';
import 'package:uyku/features/sleep_log/presentation/sleep_log_providers.dart';

final FutureProvider<FactorAnalysis> factorAnalysisProvider =
    FutureProvider.autoDispose<FactorAnalysis>((ref) async {
      final entries = await ref.watch(sleepLogProvider.future);
      final goal = ref.watch(
        settingsControllerProvider.select((s) => s.goalMinutes),
      );
      return FactorAnalyzer.analyze(entries, goal, ref.watch(todayProvider));
    });

extension SleepFactorInsightUi on SleepFactor {
  /// "Kafein aldığın gecelerde"
  String when(AppStrings strings) => switch (this) {
    SleepFactor.caffeine => strings.insights_whenCaffeine,
    SleepFactor.alcohol => strings.insights_whenAlcohol,
    SleepFactor.lateMeal => strings.insights_whenLateMeal,
    SleepFactor.exercise => strings.insights_whenExercise,
    SleepFactor.screen => strings.insights_whenScreen,
    SleepFactor.stress => strings.insights_whenStress,
    SleepFactor.noise => strings.insights_whenNoise,
  };
}

/// Trendler ekranındaki etken analizi kartı.
class FactorInsightsCard extends ConsumerWidget {
  const FactorInsightsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analysis = ref.watch(factorAnalysisProvider).value;
    if (analysis == null) return const SizedBox.shrink();
    final strings = AppStrings.of(context);
    final colors = context.colors;
    final text = context.text;
    final muted = text.bodySmall.copyWith(color: colors.textSecondary);

    return SurfaceCard(
      radius: AppRadius.lgPlusAll,
      padding: const EdgeInsets.all(AppSpacing.lgPlus),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(strings.insights_title, style: text.cardTitle),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            strings.insights_subtitle(FactorAnalyzer.windowNights),
            style: text.caption.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
          if (analysis.isEmpty) Text(strings.insights_emptyBody, style: muted),
          for (var i = 0; i < analysis.insights.length; i++) ...[
            if (i > 0) ...[
              const SizedBox(height: AppSpacing.md),
              Container(height: AppSizes.divider, color: colors.outline),
              const SizedBox(height: AppSpacing.md),
            ],
            _InsightRow(insight: analysis.insights[i]),
          ],
          if (analysis.pending.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              [
                for (final p in analysis.pending)
                  strings.insights_pending(
                    p.factor.label(strings),
                    p.nights,
                    FactorAnalyzer.minNights,
                  ),
              ].join(' · '),
              style: text.caption.copyWith(color: colors.textSecondary),
            ),
          ],
          if (!analysis.isEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              strings.insights_note,
              style: text.caption.copyWith(color: colors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}

class _InsightRow extends StatelessWidget {
  const _InsightRow({required this.insight});

  final FactorInsight insight;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final colors = context.colors;
    final text = context.text;
    final delta = insight.durationDelta;
    final noticeable = delta.abs() >= FactorAnalyzer.noticeableMinutes;
    final when = insight.factor.when(strings);
    final sentence = !noticeable
        ? strings.insights_same(when)
        : delta < 0
        ? strings.insights_less(when, formatDurationShort(strings, -delta))
        : strings.insights_more(when, formatDurationShort(strings, delta));
    final rate = strings.insights_goodRate(
      (insight.goodRateWith * 100).round(),
      (insight.goodRateWithout * 100).round(),
    );
    final nights = strings.insights_nights(
      insight.nightsWith,
      insight.nightsWithout,
    );

    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  insight.factor.label(strings),
                  style: text.rowLabel,
                ),
              ),
              if (noticeable)
                DeltaBadge(
                  label: formatDelta(strings, delta),
                  positive: delta > 0,
                  compact: true,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(sentence, style: text.bodySmall),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            '$rate\n$nights',
            style: text.caption.copyWith(color: colors.textSecondary),
          ),
        ],
      ),
    );
  }
}
