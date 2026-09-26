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
import 'package:uyku/core/widgets/circle_icon_button.dart';
import 'package:uyku/core/widgets/primary_pill_button.dart';
import 'package:uyku/core/widgets/screen_header.dart';
import 'package:uyku/core/widgets/sleep_ring_chart.dart';
import 'package:uyku/core/widgets/state_views.dart';
import 'package:uyku/core/widgets/step_progress.dart';
import 'package:uyku/features/onboarding/presentation/goal_stepper.dart';
import 'package:uyku/features/settings/domain/user_settings.dart';
import 'package:uyku/features/settings/presentation/settings_controller.dart';
import 'package:uyku/features/settings/presentation/settings_screen.dart';

/// İlk açılış: hedef süre → yatış saati → izinler.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

enum _Permission { unknown, granted, denied }

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  static const _steps = 3;

  int _step = 0;
  late int _goal = ref.read(settingsControllerProvider).goalMinutes;
  late int _bedtime = ref.read(settingsControllerProvider).bedtimeMinute;
  _Permission _permission = _Permission.unknown;

  Future<void> _next() async {
    if (_step < _steps - 1) {
      setState(() => _step++);
      return;
    }
    final c = ref.read(settingsControllerProvider.notifier);
    await c.setGoal(_goal);
    await c.setBedtime(_bedtime);
    await c.completeOnboarding();
  }

  Future<void> _requestPermission() async {
    final ok = await ref.read(notificationServiceProvider).requestPermission();
    if (mounted) {
      setState(
        () => _permission = ok ? _Permission.granted : _Permission.denied,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final colors = context.colors;
    final text = context.text;
    final padding = MediaQuery.paddingOf(context);

    final (title, body, content) = switch (_step) {
      0 => (
        strings.onboarding_goalTitle,
        strings.onboarding_goalBody,
        _goalStep(),
      ),
      1 => (
        strings.onboarding_bedTitle,
        strings.onboarding_bedBody,
        _bedStep(strings),
      ),
      _ => (
        strings.onboarding_permTitle,
        strings.onboarding_permBody,
        _permissionStep(strings),
      ),
    };

    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _step--);
      },
      child: Scaffold(
        body: Padding(
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
                  SizedBox(
                    width: AppSizes.iconButton,
                    height: AppSizes.iconButton,
                    child: _step == 0
                        ? null
                        : CircleIconButton(
                            icon: AppIcons.back,
                            semanticLabel: strings.common_back,
                            onPressed: () => setState(() => _step--),
                          ),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: StepProgress(step: _step, total: _steps),
                  ),
                  const SizedBox(width: AppSpacing.lg + AppSizes.iconButton),
                ],
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: AppMotion.reduced(context)
                      ? Duration.zero
                      : AppMotion.pageTransition,
                  child: ListView(
                    key: ValueKey(_step),
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.xxl,
                    ),
                    children: [
                      Text(
                        strings.onboarding_step(_step + 1, _steps),
                        style: text.eyebrow.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Semantics(
                        header: true,
                        child: Text(title, style: text.titleLarge),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        body,
                        style: text.bodyLarge.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      content,
                    ],
                  ),
                ),
              ),
              PrimaryPillButton(
                label: _step == _steps - 1
                    ? strings.onboarding_start
                    : strings.onboarding_continue,
                icon: AppIcons.arrowRight,
                onPressed: _next,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _goalStep() {
    final colors = context.colors;
    final strings = AppStrings.of(context);
    return Column(
      children: [
        Center(
          child: SleepRingChart(
            size: AppSizes.onboardingRing,
            semanticLabel: strings.duration_hm(_goal ~/ 60, _goal % 60),
            rings: [
              RingSegment(
                value: _goal / UserSettings.maxGoal,
                color: colors.espressoSoft,
                badgeColor: colors.espressoDeep,
                icon: AppIcons.badgeMoon,
              ),
            ],
            strokeWidth: 28,
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        GoalStepper(
          minutes: _goal,
          onChanged: (v) => setState(() => _goal = v),
        ),
      ],
    );
  }

  Widget _bedStep(AppStrings strings) {
    final colors = context.colors;
    final wake = wrapMinute(_bedtime + _goal);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SurfaceCard(
          radius: AppRadius.xlAll,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: BedtimePicker(
            minute: _bedtime,
            onChanged: (v) => setState(() => _bedtime = v),
          ),
        ),
        LinkButton(
          label: strings.chrono_onboardingLink,
          onPressed: () async {
            final minute = await context.push<int>(AppRoutes.chronotype);
            if (minute != null && mounted) setState(() => _bedtime = minute);
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            AppIcon(AppIcons.sun, color: colors.textSecondary),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                strings.onboarding_wakeWindow(
                  formatClock(wake),
                  formatClockRange(
                    strings,
                    wake - UserSettings.alarmWindow,
                    wake,
                  ),
                ),
                style: context.text.bodyMedium.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _permissionStep(AppStrings strings) {
    final colors = context.colors;
    final notifTrailing = switch (_permission) {
      _Permission.granted => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppIcon(
            AppIcons.checkBold,
            color: SleepStageColors.sageDeep,
            size: AppSizes.iconStep,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            strings.onboarding_notifGranted,
            style: context.text.bodyStrong.copyWith(color: colors.sageText),
          ),
        ],
      ),
      _ => OutlinePillButton(
        label: strings.onboarding_notifAllow,
        onPressed: _requestPermission,
      ),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PermissionCard(
          icon: AppIcons.bell,
          iconColor: SleepStageColors.emberDeep,
          title: strings.onboarding_notifTitle,
          body: _permission == _Permission.denied
              ? strings.onboarding_notifDenied
              : strings.onboarding_notifBody,
          trailing: notifTrailing,
        ),
        const SizedBox(height: AppSpacing.md),
        _PermissionCard(
          icon: AppIcons.heart,
          iconColor: SleepStageColors.lavenderDeep,
          title: strings.onboarding_healthTitle,
          body: strings.onboarding_healthBody,
          trailing: Text(
            strings.onboarding_healthSoon,
            style: context.text.bodyStrong.copyWith(
              color: colors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

class _PermissionCard extends StatelessWidget {
  const _PermissionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.body,
    required this.trailing,
  });

  final AppIconData icon;
  final Color iconColor;
  final String title;
  final String body;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.text;
    return SurfaceCard(
      radius: AppRadius.lgAll,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: AppSizes.settingsIcon,
                height: AppSizes.settingsIcon,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: iconColor,
                  shape: BoxShape.circle,
                ),
                child: AppIcon(
                  icon,
                  color: SleepStageColors.creamIcon,
                  size: AppSizes.iconStep,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: Text(title, style: text.cardTitle)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            body,
            style: text.bodySmall.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
          Align(alignment: Alignment.centerLeft, child: trailing),
        ],
      ),
    );
  }
}
