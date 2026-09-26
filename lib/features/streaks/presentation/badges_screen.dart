import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uyku/core/router/app_router.dart';
import 'package:uyku/core/strings/app_strings.dart';
import 'package:uyku/core/theme/app_motion.dart';
import 'package:uyku/core/theme/app_radius.dart';
import 'package:uyku/core/theme/app_sizes.dart';
import 'package:uyku/core/theme/app_spacing.dart';
import 'package:uyku/core/theme/app_theme.dart';
import 'package:uyku/core/theme/sleep_stage_colors.dart';
import 'package:uyku/core/widgets/app_icon.dart';
import 'package:uyku/core/widgets/full_page.dart';
import 'package:uyku/core/widgets/pressable.dart';
import 'package:uyku/core/widgets/screen_header.dart';
import 'package:uyku/core/widgets/state_views.dart';
import 'package:uyku/features/sleep_log/presentation/sleep_log_providers.dart';
import 'package:uyku/features/streaks/domain/streaks.dart';
import 'package:uyku/features/streaks/presentation/streak_providers.dart';

extension SleepBadgeUi on SleepBadge {
  String title(AppStrings s) => switch (this) {
    SleepBadge.firstNight => s.badge_firstNight,
    SleepBadge.streak3 => s.badge_streak3,
    SleepBadge.streak7 => s.badge_streak7,
    SleepBadge.streak14 => s.badge_streak14,
    SleepBadge.streak30 => s.badge_streak30,
    SleepBadge.nights10 => s.badge_nights10,
    SleepBadge.nights50 => s.badge_nights50,
    SleepBadge.nights100 => s.badge_nights100,
    SleepBadge.restful5 => s.badge_restful5,
    SleepBadge.steady7 => s.badge_steady7,
    SleepBadge.dreamer5 => s.badge_dreamer5,
  };

  String body(AppStrings s) => switch (this) {
    SleepBadge.firstNight => s.badge_firstNightBody,
    SleepBadge.streak3 => s.badge_streak3Body,
    SleepBadge.streak7 => s.badge_streak7Body,
    SleepBadge.streak14 => s.badge_streak14Body,
    SleepBadge.streak30 => s.badge_streak30Body,
    SleepBadge.nights10 => s.badge_nights10Body,
    SleepBadge.nights50 => s.badge_nights50Body,
    SleepBadge.nights100 => s.badge_nights100Body,
    SleepBadge.restful5 => s.badge_restful5Body,
    SleepBadge.steady7 => s.badge_steady7Body,
    SleepBadge.dreamer5 => s.badge_dreamer5Body,
  };

  AppIconData get icon => switch (this) {
    SleepBadge.firstNight => AppIcons.moon,
    SleepBadge.streak3 ||
    SleepBadge.streak7 ||
    SleepBadge.streak14 ||
    SleepBadge.streak30 => AppIcons.flame,
    SleepBadge.nights10 ||
    SleepBadge.nights50 ||
    SleepBadge.nights100 => AppIcons.trophy,
    SleepBadge.restful5 => AppIcons.sun,
    SleepBadge.steady7 => AppIcons.clock,
    SleepBadge.dreamer5 => AppIcons.pen,
  };

  /// Deep ton: krem ikon üzerine konabilir.
  Color get color => switch (this) {
    SleepBadge.firstNight => SleepStageColors.lavenderDeep,
    SleepBadge.streak3 ||
    SleepBadge.streak7 ||
    SleepBadge.streak14 ||
    SleepBadge.streak30 => SleepStageColors.emberDeep,
    SleepBadge.nights10 ||
    SleepBadge.nights50 ||
    SleepBadge.nights100 => SleepStageColors.honeyDeep,
    SleepBadge.restful5 || SleepBadge.steady7 => SleepStageColors.sageDeep,
    SleepBadge.dreamer5 => SleepStageColors.lavenderDeep,
  };
}

class BadgesScreen extends ConsumerStatefulWidget {
  const BadgesScreen({super.key});

  @override
  ConsumerState<BadgesScreen> createState() => _BadgesScreenState();
}

class _BadgesScreenState extends ConsumerState<BadgesScreen> {
  @override
  void initState() {
    super.initState();
    // Açılınca kazanılanları "görüldü" say. Build sırasında durum
    // değiştirilemeyeceği için bir sonraki mikro göreve bırakılır.
    ref.listenManual(streakSummaryProvider, (_, next) {
      final earned = next.value?.earned.map((b) => b.badge).toList();
      if (earned == null || earned.isEmpty) return;
      scheduleMicrotask(() {
        if (mounted) {
          unawaited(ref.read(seenBadgesProvider.notifier).markSeen(earned));
        }
      });
    }, fireImmediately: true);
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final summary = ref.watch(streakSummaryProvider);

    return summary.when(
      loading: () => FullPage(
        eyebrow: strings.streak_eyebrow,
        title: strings.streak_title,
        children: const [SkeletonBlock(height: 96), SkeletonBlock(height: 240)],
      ),
      error: (_, _) => FullPage(
        eyebrow: strings.streak_eyebrow,
        title: strings.streak_title,
        children: [
          ErrorState(
            onRetry: () => ref.read(sleepLogProvider.notifier).retry(),
          ),
        ],
      ),
      data: (s) => FullPage(
        eyebrow: strings.streak_eyebrow,
        title: strings.streak_title,
        children: [
          Row(
            children: [
              Expanded(
                child: _StreakStat(
                  label: strings.streak_current,
                  value: strings.streak_nights(s.current),
                  highlight: s.current > 0,
                ),
              ),
              const SizedBox(width: AppSpacing.smPlus),
              Expanded(
                child: _StreakStat(
                  label: strings.streak_best,
                  value: strings.streak_nights(s.best),
                ),
              ),
            ],
          ),
          Semantics(
            header: true,
            child: Text(strings.streak_badges, style: context.text.cardTitle),
          ),
          Column(
            children: [
              for (var i = 0; i < s.badges.length; i += 2) ...[
                if (i > 0) const SizedBox(height: AppSpacing.smPlus),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: _BadgeTile(progress: s.badges[i])),
                      const SizedBox(width: AppSpacing.smPlus),
                      Expanded(
                        child: i + 1 < s.badges.length
                            ? _BadgeTile(progress: s.badges[i + 1])
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _StreakStat extends StatelessWidget {
  const _StreakStat({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

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
            Row(
              children: [
                AppIcon(
                  AppIcons.flame,
                  color: highlight
                      ? SleepStageColors.emberDeep
                      : colors.textSecondary,
                  size: AppSizes.iconSmall,
                ),
                const SizedBox(width: AppSpacing.xs),
                Flexible(
                  child: Text(
                    label,
                    style: text.tileLabel.copyWith(color: colors.textSecondary),
                  ),
                ),
              ],
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

class _BadgeTile extends StatelessWidget {
  const _BadgeTile({required this.progress});

  final BadgeProgress progress;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final colors = context.colors;
    final text = context.text;
    final badge = progress.badge;
    final earned = progress.earned;
    final value = progress.progress.clamp(0, badge.target);
    final status = earned
        ? strings.streak_earned
        : strings.streak_progress(value, badge.target);
    final state = earned ? status : '${strings.streak_locked}, $status';
    return Semantics(
      label: '${badge.title(strings)}, ${badge.body(strings)}, $state',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.mdPlus),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: AppRadius.lgAll,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: AppSizes.settingsIcon,
              height: AppSizes.settingsIcon,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: earned ? badge.color : colors.surfaceMuted,
                shape: BoxShape.circle,
              ),
              child: AppIcon(
                earned ? badge.icon : AppIcons.lock,
                color: earned
                    ? SleepStageColors.creamIcon
                    : colors.textSecondary,
                size: AppSizes.iconStep,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(badge.title(strings), style: text.rowLabel),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              badge.body(strings),
              style: text.note.copyWith(color: colors.textSecondary),
            ),
            const Spacer(),
            const SizedBox(height: AppSpacing.sm),
            if (!earned) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(AppSizes.progressBar),
                child: SizedBox(
                  height: AppSizes.progressSegment,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: ColoredBox(color: colors.surfaceMuted),
                      ),
                      FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: value / badge.target,
                        child: ColoredBox(color: badge.color),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
            ],
            Text(
              status,
              style: text.caption.copyWith(
                color: earned ? colors.sageText : colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bugün ekranındaki seri kartı; yeni rozet varsa işaretler.
class StreakCard extends ConsumerWidget {
  const StreakCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(streakSummaryProvider).value;
    if (summary == null) return const SizedBox.shrink();
    final seen = ref.watch(seenBadgesProvider);
    final fresh = summary.earned.any((b) => !seen.contains(b.badge));
    final strings = AppStrings.of(context);
    final colors = context.colors;
    final text = context.text;
    final active = summary.current > 0;
    final title = active
        ? strings.streak_cardTitle(summary.current)
        : strings.streak_cardStart;
    final body = active
        ? strings.streak_cardBody(summary.best)
        : strings.streak_cardStartBody;

    return Pressable(
      onPressed: () => context.push(AppRoutes.badges),
      semanticLabel: [
        title,
        body,
        if (fresh) strings.streak_newBadge,
      ].join(', '),
      excludeChildSemantics: true,
      child: SurfaceCard(
        radius: AppRadius.lgAll,
        child: Row(
          children: [
            AnimatedContainer(
              duration: AppMotion.toggle,
              width: AppSizes.tipIcon,
              height: AppSizes.tipIcon,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active ? colors.emberTint : colors.surfaceMuted,
                shape: BoxShape.circle,
              ),
              child: AppIcon(
                AppIcons.flame,
                color: active ? colors.emberText : colors.textSecondary,
              ),
            ),
            const SizedBox(width: AppSpacing.mdPlus),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: text.cardTitle),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    body,
                    style: text.bodySmall.copyWith(color: colors.textSecondary),
                  ),
                ],
              ),
            ),
            if (fresh) ...[
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xxs,
                ),
                decoration: ShapeDecoration(
                  color: colors.honeyTint,
                  shape: const StadiumBorder(),
                ),
                child: Text(
                  strings.streak_newBadge,
                  style: text.caption.copyWith(color: colors.honeyText),
                ),
              ),
            ],
            const SizedBox(width: AppSpacing.sm),
            AppIcon(AppIcons.chevronRight, color: colors.textSecondary),
          ],
        ),
      ),
    );
  }
}
