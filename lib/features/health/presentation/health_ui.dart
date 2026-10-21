import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uyku/core/router/app_router.dart';
import 'package:uyku/core/strings/app_strings.dart';
import 'package:uyku/core/theme/app_colors.dart';
import 'package:uyku/core/theme/app_radius.dart';
import 'package:uyku/core/theme/app_sizes.dart';
import 'package:uyku/core/theme/app_spacing.dart';
import 'package:uyku/core/theme/app_theme.dart';
import 'package:uyku/core/theme/sleep_stage_colors.dart';
import 'package:uyku/core/utils/formatters.dart';
import 'package:uyku/core/widgets/app_icon.dart';
import 'package:uyku/core/widgets/motion.dart';
import 'package:uyku/core/widgets/pressable.dart';
import 'package:uyku/core/widgets/screen_header.dart';
import 'package:uyku/core/widgets/sleep_ring_chart.dart';
import 'package:uyku/features/health/domain/health_check.dart';
import 'package:uyku/features/health/domain/health_snapshot.dart';
import 'package:uyku/features/health/domain/health_tips.dart';
import 'package:uyku/features/health/presentation/health_providers.dart';

extension HealthBandUi on HealthBand {
  String label(AppStrings strings) => switch (this) {
    HealthBand.veryGood => strings.health_bandVeryGood,
    HealthBand.good => strings.health_bandGood,
    HealthBand.fair => strings.health_bandFair,
    HealthBand.needsWork => strings.health_bandNeedsWork,
  };

  /// Halka rengi: 70+ sage, 50–69 honey, <50 ember.
  Color get color => switch (this) {
    HealthBand.veryGood || HealthBand.good => SleepStageColors.sage,
    HealthBand.fair => SleepStageColors.honey,
    HealthBand.needsWork => SleepStageColors.ember,
  };

  /// Uç rozeti (krem ikonun konabildiği deep ton).
  Color get deepColor => switch (this) {
    HealthBand.veryGood || HealthBand.good => SleepStageColors.sageDeep,
    HealthBand.fair => SleepStageColors.honeyDeep,
    HealthBand.needsWork => SleepStageColors.emberDeep,
  };

  /// Tint zemin + metin rengi (ikon daireleri).
  (Color, Color) tint(AppColors colors) => switch (this) {
    HealthBand.veryGood ||
    HealthBand.good => (colors.sageTint, colors.sageText),
    HealthBand.fair => (colors.honeyTint, colors.honeyText),
    HealthBand.needsWork => (colors.emberTint, colors.emberText),
  };
}

extension HealthComponentKindUi on HealthComponentKind {
  String label(AppStrings strings) => switch (this) {
    HealthComponentKind.duration => strings.health_compDuration,
    HealthComponentKind.regularity => strings.health_compRegularity,
    HealthComponentKind.debt => strings.health_compDebt,
    HealthComponentKind.mood => strings.health_compMood,
  };
}

extension HealthTipUi on HealthTip {
  String title(AppStrings strings) => switch (this) {
    HealthTip.payDebt => strings.health_tipPayDebtTitle,
    HealthTip.moreSleep => strings.health_tipMoreSleepTitle,
    HealthTip.steadyBedtime => strings.health_tipSteadyTitle,
    HealthTip.weekendShift => strings.health_tipWeekendTitle,
    HealthTip.windDown => strings.health_tipWindDownTitle,
    HealthTip.keepGoing => strings.health_tipKeepGoingTitle,
  };

  String body(AppStrings strings, HealthSnapshot snapshot) => switch (this) {
    HealthTip.payDebt => strings.health_tipPayDebt,
    HealthTip.moreSleep => strings.health_tipMoreSleep,
    HealthTip.steadyBedtime => strings.health_tipSteady,
    HealthTip.weekendShift => strings.health_tipWeekend(
      formatDurationShort(strings, snapshot.socialJetlagMinutes ?? 0),
    ),
    HealthTip.windDown => strings.health_tipWindDown,
    HealthTip.keepGoing => strings.health_tipKeepGoing,
  };
}

extension HealthQuestionUi on HealthQuestion {
  String text(AppStrings strings) => switch (this) {
    HealthQuestion.breathing => strings.health_qBreathing,
    HealthQuestion.daytimeSleepiness => strings.health_qDaytimeSleepiness,
    HealthQuestion.fallingAsleep => strings.health_qFallingAsleep,
    HealthQuestion.nightWaking => strings.health_qNightWaking,
    HealthQuestion.morningTired => strings.health_qMorningTired,
    HealthQuestion.restlessLegs => strings.health_qRestlessLegs,
  };
}

extension HealthFlagUi on HealthFlag {
  String title(AppStrings strings) => switch (this) {
    HealthFlag.breathing => strings.health_flagBreathingTitle,
    HealthFlag.daytimeSleepiness => strings.health_flagDaytimeTitle,
    HealthFlag.insomniaSymptoms => strings.health_flagSleepContinuityTitle,
    HealthFlag.restlessLegs => strings.health_flagLegsTitle,
  };

  String body(AppStrings strings) => switch (this) {
    HealthFlag.breathing => strings.health_flagBreathing,
    HealthFlag.daytimeSleepiness => strings.health_flagDaytime,
    HealthFlag.insomniaSymptoms => strings.health_flagSleepContinuity,
    HealthFlag.restlessLegs => strings.health_flagLegs,
  };
}

/// Cevap etiketleri, 0–3 sırasıyla.
List<String> healthAnswerLabels(AppStrings strings) => [
  strings.health_answerNever,
  strings.health_answerSometimes,
  strings.health_answerOften,
  strings.health_answerNightly,
];

/// Tek halkalı skor göstergesi: bant renginde dolan halka, merkezde skor ve
/// bant etiketi (renk tek ipucu değildir).
class HealthScoreRing extends StatelessWidget {
  const HealthScoreRing({
    required this.score,
    this.size = AppSizes.healthRing,
    super.key,
  });

  final int score;
  final double size;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final colors = context.colors;
    final text = context.text;
    final band = HealthBand.of(score);
    return SleepRingChart(
      size: size,
      semanticLabel: strings.health_ringSemantic(score, band.label(strings)),
      celebrate: band == HealthBand.veryGood,
      rings: [
        RingSegment(
          value: score / 100,
          color: band.color,
          badgeColor: band.deepColor,
          icon: AppIcons.badgeMoon,
        ),
      ],
      // Halka etiketi son değeri okur; sayan merkez semantikten çıkarılır.
      center: SizedBox(
        width: size * 0.6,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CountUp(
              value: score,
              builder: (context, shown) => FittedBox(
                fit: BoxFit.scaleDown,
                child: Text.rich(
                  TextSpan(
                    text: '$shown',
                    style: text.displayNumber,
                    children: [
                      TextSpan(
                        text: strings.health_scoreMax,
                        style: text.displayUnit.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  maxLines: 1,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            // Bant etiketi rengin ikinci ipucu; 1.3 ölçekte kesilmesin.
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                band.label(strings),
                textAlign: TextAlign.center,
                maxLines: 1,
                style: text.bodyStrong.copyWith(color: colors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bugün ekranındaki özet kartı: skor + bant + borç; dokununca `/health`.
class HealthSummaryCard extends ConsumerWidget {
  const HealthSummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(healthSnapshotProvider).value;
    if (snapshot == null) return const SizedBox.shrink();
    final strings = AppStrings.of(context);
    final colors = context.colors;
    final text = context.text;
    final band = snapshot.band;
    final (tintBg, tintFg) = band.tint(colors);
    final title = strings.health_cardTitle(snapshot.score, band.label(strings));
    final body = strings.health_cardBody(
      formatDuration(strings, snapshot.debtMinutes),
    );
    return Pressable(
      onPressed: () => context.push(AppRoutes.health),
      semanticLabel: '$title, $body',
      excludeChildSemantics: true,
      child: SurfaceCard(
        radius: AppRadius.lgAll,
        child: Row(
          children: [
            Container(
              width: AppSizes.tipIcon,
              height: AppSizes.tipIcon,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: tintBg, shape: BoxShape.circle),
              child: AppIcon(AppIcons.heart, color: tintFg),
            ),
            const SizedBox(width: AppSpacing.mdPlus),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Skor halkayla aynı sürede sayar; okunan etiket sondur.
                  CountUp(
                    value: snapshot.score,
                    builder: (context, shown) => Text(
                      strings.health_cardTitle(shown, band.label(strings)),
                      style: text.cardTitle,
                    ),
                  ),
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
