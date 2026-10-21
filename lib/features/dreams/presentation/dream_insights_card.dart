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
import 'package:uyku/core/widgets/state_views.dart';
import 'package:uyku/features/dreams/domain/dream_insights.dart';
import 'package:uyku/features/dreams/presentation/dream_providers.dart';
import 'package:uyku/features/insights/domain/factor_insights.dart';
import 'package:uyku/features/premium/presentation/premium_gate.dart';
import 'package:uyku/features/sleep_log/presentation/log_screen.dart';

/// `/dreams` üstündeki içgörü kartı; tamamı Premium.
class DreamInsightsCard extends ConsumerWidget {
  const DreamInsightsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dreamInsightsProvider);
    final insights = state.value;
    if (insights == null) {
      // Yüklenirken iskelet; hata olursa kart sessizce gizlenir.
      return state.isLoading && !state.hasError
          ? const SkeletonBlock(
              height: AppSizes.healthChart,
              radius: AppRadius.lgPlusAll,
            )
          : const SizedBox.shrink();
    }
    final strings = AppStrings.of(context);
    return PremiumGate(
      title: strings.dreams_insightsLockTitle,
      message: strings.dreams_insightsLockBody,
      child: _InsightsBody(insights: insights),
    );
  }
}

class _InsightsBody extends StatelessWidget {
  const _InsightsBody({required this.insights});

  final DreamInsights insights;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final colors = context.colors;
    final text = context.text;
    final caption = text.caption.copyWith(color: colors.textSecondary);
    final muted = text.bodySmall.copyWith(color: colors.textSecondary);

    Widget divider() => Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Container(height: AppSizes.divider, color: colors.outline),
    );

    final rate = insights.nightmareRate;
    final delta = insights.durationDelta;
    final factor = insights.nightmareFactor;

    return SurfaceCard(
      radius: AppRadius.lgPlusAll,
      padding: const EdgeInsets.all(AppSpacing.lgPlus),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(strings.dreams_insightsTitle, style: text.cardTitle),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            strings.dreams_insightsSubtitle(
              DreamInsightsCalculator.windowNights,
            ),
            style: caption,
          ),
          const SizedBox(height: AppSpacing.md),
          if (insights.isEmpty)
            Text(strings.dreams_insightsEmpty, style: muted)
          else ...[
            Text(strings.dreams_topSymbols, style: text.rowLabel),
            const SizedBox(height: AppSpacing.sm),
            if (insights.topSymbols.isEmpty)
              Text(strings.dreams_topSymbolsEmpty, style: muted),
            for (final c in insights.topSymbols)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: MergeSemantics(
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(c.symbol.title, style: text.bodyMedium),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        strings.dreams_symbolNights(c.nights),
                        style: text.bodyMedium.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            divider(),
            MergeSemantics(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          strings.dreams_nightmareRate,
                          style: text.rowLabel,
                        ),
                      ),
                      if (rate != null)
                        Text(
                          strings.dreams_percent((rate * 100).round()),
                          style: text.valueMedium,
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    rate == null
                        ? strings.dreams_needMore(
                            DreamInsightsCalculator.minNights,
                          )
                        : strings.dreams_nightmareRateValue(
                            insights.nightmareNights,
                            insights.kindedNights,
                          ),
                    style: caption,
                  ),
                ],
              ),
            ),
            if (delta != null) ...[
              divider(),
              _NightmareSleep(insights: insights, delta: delta),
            ],
            if (factor != null) ...[
              divider(),
              Text(
                strings.dreams_nightmareFactor(
                  factor.factor.label(strings),
                  factor.nights,
                ),
                style: text.bodySmall,
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            Text(strings.dreams_insightsNote, style: caption),
          ],
        ],
      ),
    );
  }
}

class _NightmareSleep extends StatelessWidget {
  const _NightmareSleep({required this.insights, required this.delta});

  final DreamInsights insights;
  final int delta;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final colors = context.colors;
    final text = context.text;
    final noticeable = delta.abs() >= FactorAnalyzer.noticeableMinutes;
    final sentence = !noticeable
        ? strings.dreams_nightmareSame
        : delta < 0
        ? strings.dreams_nightmareLess(formatDurationShort(strings, -delta))
        : strings.dreams_nightmareMore(formatDurationShort(strings, delta));
    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  strings.dreams_nightmareSleep,
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
            strings.dreams_averages(
              formatDuration(strings, insights.nightmareAverage!),
              formatDuration(strings, insights.otherAverage!),
            ),
            style: text.caption.copyWith(color: colors.textSecondary),
          ),
        ],
      ),
    );
  }
}
