import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uyku/core/providers/core_providers.dart';
import 'package:uyku/core/router/app_router.dart';
import 'package:uyku/core/strings/app_strings.dart';
import 'package:uyku/core/theme/app_sizes.dart';
import 'package:uyku/core/theme/app_spacing.dart';
import 'package:uyku/core/theme/app_theme.dart';
import 'package:uyku/core/theme/sleep_stage_colors.dart';
import 'package:uyku/core/utils/formatters.dart';
import 'package:uyku/core/widgets/app_icon.dart';
import 'package:uyku/core/widgets/app_sheet.dart';
import 'package:uyku/core/widgets/app_switch.dart';
import 'package:uyku/core/widgets/circle_icon_button.dart';
import 'package:uyku/core/widgets/primary_pill_button.dart';
import 'package:uyku/core/widgets/sleep_ring_chart.dart';
import 'package:uyku/core/widgets/state_views.dart';
import 'package:uyku/features/settings/domain/user_settings.dart';
import 'package:uyku/features/settings/presentation/settings_controller.dart';
import 'package:uyku/features/sleep_log/domain/sleep_entry.dart';
import 'package:uyku/features/track_sleep/domain/alarm_plan.dart';
import 'package:uyku/features/track_sleep/presentation/track_controller.dart';

/// Uyku modu — her zaman koyu tema.
// TODO(uyku): screen_brightness ile parlaklığı düşür, çıkışta geri al;
// WakelockPlus değerlendirilecek.
class TrackScreen extends StatelessWidget {
  const TrackScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.dark,
      child: const Scaffold(body: _TrackBody()),
    );
  }
}

class _TrackBody extends ConsumerStatefulWidget {
  const _TrackBody();

  @override
  ConsumerState<_TrackBody> createState() => _TrackBodyState();
}

class _TrackBodyState extends ConsumerState<_TrackBody> {
  late final Timer _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker.cancel();
    super.dispose();
  }

  Future<void> _cancel() async {
    final strings = AppStrings.of(context);
    final ok = await confirmSheet(
      context,
      title: strings.track_cancelTitle,
      body: strings.track_cancelBody,
      confirmLabel: strings.track_cancelConfirm,
    );
    if (!ok) return;
    await ref.read(trackControllerProvider.notifier).cancel();
    if (mounted) context.go(AppRoutes.today);
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final settings = ref.watch(settingsControllerProvider);
    final result = ref.watch(trackControllerProvider);
    final now = ref.watch(clockProvider).now();
    final padding = MediaQuery.paddingOf(context);
    final start = settings.trackingStart;

    final body = switch ((start, result)) {
      (final DateTime s, _) => _Tracking(
        start: s,
        now: now,
        settings: settings,
      ),
      (null, TrackSaved(:final entry)) => _Morning(entry: entry),
      (null, TrackTooShort()) => _Message(
        text: strings.track_tooShort,
        action: strings.track_home,
        onAction: () => context.go(AppRoutes.today),
      ),
      (null, null) => _Idle(now: now, settings: settings),
    };

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xl,
        padding.top + AppSpacing.sm,
        AppSpacing.xl,
        padding.bottom + AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const _ModePill(),
              const Spacer(),
              CircleIconButton(
                icon: AppIcons.speaker,
                semanticLabel: strings.sounds_title,
                onPressed: () => context.push(AppRoutes.sounds),
              ),
              const SizedBox(width: AppSpacing.sm),
              CircleIconButton(
                icon: AppIcons.close,
                semanticLabel: start == null
                    ? strings.common_close
                    : strings.track_cancel,
                onPressed: start == null
                    ? () => context.go(AppRoutes.today)
                    : _cancel,
              ),
            ],
          ),
          Expanded(child: body),
        ],
      ),
    );
  }
}

class _ModePill extends StatelessWidget {
  const _ModePill();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      constraints: const BoxConstraints(minHeight: AppSizes.badgeHeight),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: ShapeDecoration(
        color: colors.surface,
        shape: const StadiumBorder(),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppIcon(
            AppIcons.moon,
            color: SleepStageColors.honey,
            size: AppSizes.iconSmall,
          ),
          const SizedBox(width: AppSpacing.xsPlus),
          Text(AppStrings.of(context).track_mode, style: context.text.chip),
        ],
      ),
    );
  }
}

class _Tracking extends ConsumerWidget {
  const _Tracking({
    required this.start,
    required this.now,
    required this.settings,
  });

  final DateTime start;
  final DateTime now;
  final UserSettings settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    final colors = context.colors;
    final text = context.text;
    final elapsed = now.difference(start).inMinutes.clamp(0, 24 * 60);
    final ratio = elapsed / settings.goalMinutes;
    return Column(
      children: [
        const Spacer(),
        SleepRingChart(
          size: AppSizes.trackRing,
          semanticLabel: strings.track_ringSemantic(
            formatDuration(strings, elapsed),
            (ratio * 100).round(),
          ),
          rings: [
            RingSegment(
              value: ratio,
              color: SleepStageColors.ember,
              badgeColor: SleepStageColors.emberDeep,
              icon: AppIcons.badgeMoon,
            ),
          ],
          strokeWidth: 16,
          center: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(formatClockOf(now), style: text.displayClock),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                strings.track_elapsed(formatDuration(strings, elapsed)),
                style: text.bodyMedium.copyWith(color: colors.textSecondary),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        _AlarmInfo(
          plan: AlarmPlan.forStart(settings, start),
          smartEnabled: settings.smartAlarm,
        ),
        const Spacer(),
        Text(
          strings.track_holdHint,
          textAlign: TextAlign.center,
          style: text.caption.copyWith(color: colors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.md),
        HoldToConfirmButton(
          label: strings.track_wake,
          semanticLabel: strings.track_holdSemantic,
          onConfirmed: () =>
              ref.read(trackControllerProvider.notifier).finish(),
        ),
      ],
    );
  }
}

class _Idle extends ConsumerWidget {
  const _Idle({required this.now, required this.settings});

  final DateTime now;
  final UserSettings settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    final text = context.text;
    return Column(
      children: [
        const Spacer(),
        Text(formatClockOf(now), style: text.displayClock),
        const SizedBox(height: AppSpacing.md),
        _AlarmInfo(
          plan: AlarmPlan.forStart(settings, now),
          smartEnabled: settings.smartAlarm,
        ),
        const SizedBox(height: AppSpacing.lg),
        _SmartToggle(enabled: settings.smartAlarm),
        const Spacer(),
        PrimaryPillButton(
          label: strings.log_startSleepMode,
          icon: AppIcons.moon,
          onPressed: () => ref.read(trackControllerProvider.notifier).start(),
        ),
      ],
    );
  }
}

class _Morning extends StatelessWidget {
  const _Morning({required this.entry});

  final SleepEntry entry;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final colors = context.colors;
    final text = context.text;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Spacer(),
        Center(
          child: Container(
            width: AppSizes.emptyIconCircle,
            height: AppSizes.emptyIconCircle,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.honeyTint,
              shape: BoxShape.circle,
            ),
            child: AppIcon(
              AppIcons.sun,
              color: colors.honeyText,
              size: AppSizes.emptyIcon,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Semantics(
          header: true,
          child: Text(
            strings.track_morningTitle,
            textAlign: TextAlign.center,
            style: text.titleLarge,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          strings.track_morningBody(
            formatDuration(strings, entry.durationMinutes),
          ),
          textAlign: TextAlign.center,
          style: text.bodyLarge.copyWith(color: colors.textSecondary),
        ),
        const Spacer(),
        PrimaryPillButton(
          label: strings.track_morningCta,
          icon: AppIcons.arrowRight,
          onPressed: () => context.go(AppRoutes.logNight(entry.id)),
        ),
        const SizedBox(height: AppSpacing.md),
        Center(
          child: OutlinePillButton(
            label: strings.track_home,
            onPressed: () => context.go(AppRoutes.today),
          ),
        ),
      ],
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.text,
    required this.action,
    required this.onAction,
  });

  final String text;
  final String action;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Spacer(),
        Text(text, textAlign: TextAlign.center, style: context.text.bodyLarge),
        const Spacer(),
        PrimaryPillButton(label: action, onPressed: onAction),
      ],
    );
  }
}

/// Alarm penceresi ve alarmın çalacağı an.
class _AlarmInfo extends StatelessWidget {
  const _AlarmInfo({required this.plan, required this.smartEnabled});

  final AlarmPlan plan;
  final bool smartEnabled;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final colors = context.colors;
    final text = context.text;
    final at = formatClockOf(plan.at);
    final line = !smartEnabled
        ? strings.smart_off(at)
        : plan.smart
        ? strings.smart_at(at)
        : strings.smart_fallback(at);
    return MergeSemantics(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppIcon(AppIcons.clock, color: colors.textSecondary),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Text(
                  strings.track_alarmWindow(
                    strings.time_range(
                      formatClockOf(plan.windowStart),
                      formatClockOf(plan.windowEnd),
                    ),
                  ),
                  style: text.bodyMedium.copyWith(color: colors.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            line,
            textAlign: TextAlign.center,
            style: text.bodyStrong.copyWith(
              color: plan.smart ? SleepStageColors.honey : colors.textSecondary,
            ),
          ),
          if (plan.smart) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              strings.smart_note,
              textAlign: TextAlign.center,
              style: text.caption.copyWith(color: colors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}

class _SmartToggle extends ConsumerWidget {
  const _SmartToggle({required this.enabled});

  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(strings.smart_title, style: context.text.bodyStrong),
        const SizedBox(width: AppSpacing.md),
        AppSwitch(
          value: enabled,
          semanticLabel: strings.smart_title,
          onChanged: (v) => ref
              .read(settingsControllerProvider.notifier)
              .setSmartAlarm(enabled: v),
        ),
      ],
    );
  }
}
