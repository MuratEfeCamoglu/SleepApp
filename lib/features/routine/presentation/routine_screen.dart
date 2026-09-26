import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uyku/core/providers/core_providers.dart';
import 'package:uyku/core/router/app_router.dart';
import 'package:uyku/core/strings/app_strings.dart';
import 'package:uyku/core/theme/app_motion.dart';
import 'package:uyku/core/theme/app_radius.dart';
import 'package:uyku/core/theme/app_sizes.dart';
import 'package:uyku/core/theme/app_spacing.dart';
import 'package:uyku/core/theme/app_theme.dart';
import 'package:uyku/core/theme/sleep_stage_colors.dart';
import 'package:uyku/core/utils/formatters.dart';
import 'package:uyku/core/widgets/app_icon.dart';
import 'package:uyku/core/widgets/app_switch.dart';
import 'package:uyku/core/widgets/pressable.dart';
import 'package:uyku/core/widgets/screen_header.dart';
import 'package:uyku/core/widgets/state_views.dart';
import 'package:uyku/features/routine/domain/routine_repository.dart';
import 'package:uyku/features/routine/presentation/routine_providers.dart';
import 'package:uyku/features/settings/presentation/settings_controller.dart';
import 'package:uyku/features/sleep_summary/presentation/app_shell.dart';

class RoutineScreen extends ConsumerWidget {
  const RoutineScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final settings = ref.watch(settingsControllerProvider);
    final done = ref.watch(routineProgressProvider);
    final evening = eveningOf(ref.watch(clockProvider).now());
    final reminder = settings.reminderFor(evening);

    final steps = [
      (
        strings.routine_step1Title,
        strings.routine_step1Note(formatClock(reminder)),
      ),
      (
        strings.routine_step2Title,
        strings.routine_step2Note(formatClock(reminder + 5)),
      ),
      (strings.routine_step3Title, strings.routine_step3Note),
      (strings.routine_step4Title, strings.routine_step4Note),
      (strings.routine_step5Title, strings.routine_step5Note),
    ];

    return TabPage(
      children: [
        ScreenHeader(
          eyebrow: strings.routine_eyebrow(
            formatClock(settings.bedtimeFor(evening)),
            formatGoal(strings, locale, settings.goalMinutes),
          ),
          title: strings.routine_title,
        ),
        _ReminderCard(enabled: settings.reminderEnabled, minute: reminder),
        _Progress(done: done.length),
        Column(
          children: [
            for (var i = 0; i < steps.length; i++) ...[
              if (i > 0) const SizedBox(height: AppSpacing.sm),
              _StepTile(
                title: steps[i].$1,
                note: steps[i].$2,
                done: done.contains(i),
                onPressed: () =>
                    ref.read(routineProgressProvider.notifier).toggle(i),
              ),
            ],
          ],
        ),
        const _RelaxCard(),
      ],
    );
  }
}

/// Uyku sesleri ve nefes egzersizine giriş.
class _RelaxCard extends StatelessWidget {
  const _RelaxCard();

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final colors = context.colors;
    final text = context.text;
    return SurfaceCard(
      radius: AppRadius.lgAll,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(strings.relax_title, style: text.cardTitle),
          const SizedBox(height: AppSpacing.xs),
          Text(
            strings.relax_body,
            style: text.bodySmall.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              OutlinePillButton(
                label: strings.sounds_title,
                onPressed: () => context.push(AppRoutes.sounds),
              ),
              OutlinePillButton(
                label: strings.breathe_title,
                onPressed: () => context.push(AppRoutes.breathe),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReminderCard extends ConsumerWidget {
  const _ReminderCard({required this.enabled, required this.minute});

  final bool enabled;
  final int minute;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    final colors = context.colors;
    final text = context.text;
    final granted = ref.watch(notificationPermissionProvider).value ?? true;
    return SurfaceCard(
      radius: AppRadius.lgAll,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lgPlus,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(strings.routine_reminderTitle, style: text.cardTitle),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      strings.routine_reminderBody(formatClock(minute)),
                      style: text.bodySmall.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              AppSwitch(
                value: enabled,
                semanticLabel: strings.routine_reminderTitle,
                onChanged: (v) async {
                  await ref
                      .read(settingsControllerProvider.notifier)
                      .setReminder(enabled: v);
                  ref.invalidate(notificationPermissionProvider);
                },
              ),
            ],
          ),
          if (enabled && !granted) ...[
            const SizedBox(height: AppSpacing.md),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.xs,
              children: [
                Text(
                  strings.routine_permissionDenied,
                  style: text.caption.copyWith(color: colors.emberText),
                ),
                OutlinePillButton(
                  label: strings.routine_grant,
                  onPressed: () async {
                    final service = ref.read(notificationServiceProvider);
                    final ok = await service.requestPermission();
                    if (!ok) await service.openSystemSettings();
                    ref.invalidate(notificationPermissionProvider);
                  },
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress({required this.done});

  final int done;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final colors = context.colors;
    final text = context.text;
    return Semantics(
      label:
          '${strings.routine_tonight}, '
          '${strings.routine_progress(done, routineStepCount)}',
      excludeSemantics: true,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(strings.routine_tonight, style: text.bodyStrong),
              ),
              Text(
                strings.routine_progress(done, routineStepCount),
                style: text.bodyMedium.copyWith(
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSizes.progressBar),
            child: SizedBox(
              width: double.infinity,
              height: AppSizes.progressBar,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ColoredBox(color: colors.surfaceMuted),
                  ),
                  TweenAnimationBuilder<double>(
                    tween: Tween(end: done / routineStepCount),
                    duration: AppMotion.progress,
                    builder: (context, v, _) => FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: v,
                      child: const DecoratedBox(
                        decoration: ShapeDecoration(
                          color: SleepStageColors.sageDeep,
                          shape: StadiumBorder(),
                        ),
                        child: SizedBox.expand(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepTile extends StatelessWidget {
  const _StepTile({
    required this.title,
    required this.note,
    required this.done,
    required this.onPressed,
  });

  final String title;
  final String note;
  final bool done;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.text;
    return Pressable(
      onPressed: onPressed,
      toggled: done,
      semanticLabel: '$title, $note',
      excludeChildSemantics: true,
      child: Container(
        constraints: const BoxConstraints(
          minHeight: AppSizes.routineStepMinHeight,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.smPlus,
        ),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: AppRadius.lgMinusAll,
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: AppMotion.toggle,
              width: AppSizes.checkCircle,
              height: AppSizes.checkCircle,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done ? SleepStageColors.sageDeep : null,
                border: Border.all(
                  color: done ? SleepStageColors.sageDeep : colors.chipLine,
                  width: AppSizes.checkStroke,
                ),
              ),
              child: done
                  ? const AppIcon(
                      AppIcons.check,
                      color: SleepStageColors.cream,
                      size: AppSizes.checkIcon,
                    )
                  : null,
            ),
            const SizedBox(width: AppSpacing.mdPlus),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedOpacity(
                    duration: AppMotion.toggle,
                    opacity: done ? 0.6 : 1,
                    child: Text(title, style: text.rowLabel),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    note,
                    style: text.note.copyWith(color: colors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
