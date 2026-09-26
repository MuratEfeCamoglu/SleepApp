import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uyku/core/router/app_router.dart';
import 'package:uyku/core/strings/app_strings.dart';
import 'package:uyku/core/theme/app_radius.dart';
import 'package:uyku/core/theme/app_spacing.dart';
import 'package:uyku/core/theme/app_theme.dart';
import 'package:uyku/core/utils/formatters.dart';
import 'package:uyku/core/widgets/app_icon.dart';
import 'package:uyku/core/widgets/full_page.dart';
import 'package:uyku/core/widgets/primary_pill_button.dart';
import 'package:uyku/core/widgets/screen_header.dart';
import 'package:uyku/core/widgets/segmented_pill.dart';
import 'package:uyku/core/widgets/state_views.dart';
import 'package:uyku/features/onboarding/presentation/goal_stepper.dart';
import 'package:uyku/features/settings/domain/user_settings.dart';
import 'package:uyku/features/settings/presentation/settings_controller.dart';
import 'package:uyku/features/settings/presentation/settings_screen.dart';

/// Hafta sonu esnekliği etiketi: "Yok", "30 dk", "1 sa", "1,5 sa".
String weekendShiftLabel(AppStrings strings, String locale, int minutes) {
  if (minutes == 0) return strings.goals_weekendNone;
  if (minutes < 60) return strings.duration_minutes(minutes);
  return strings.goals_weekendHours(formatHours(locale, minutes));
}

/// Hedef süre, hedef yatış ve hafta sonu esnekliği tek ekranda.
class GoalsScreen extends ConsumerStatefulWidget {
  const GoalsScreen({super.key});

  @override
  ConsumerState<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends ConsumerState<GoalsScreen> {
  late UserSettings _draft = ref.read(settingsControllerProvider);

  Future<void> _save() async {
    await ref
        .read(settingsControllerProvider.notifier)
        .setGoals(
          goalMinutes: _draft.goalMinutes,
          bedtimeMinute: _draft.bedtimeMinute,
          weekendShift: _draft.weekendShift,
        );
    if (mounted) FullPage.back(context);
  }

  Future<void> _openChronotype() async {
    await context.push(AppRoutes.chronotype);
    // Test önerisi kabul edildiyse ayarlara yazıldı; taslağa al.
    final bed = ref.read(settingsControllerProvider).bedtimeMinute;
    if (mounted) setState(() => _draft = _draft.copyWith(bedtimeMinute: bed));
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final colors = context.colors;
    final text = context.text;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final muted = text.bodySmall.copyWith(color: colors.textSecondary);

    // Örnek geceler: bir çarşamba ve bir cuma akşamı.
    final weekday = DateTime(2024, 1, 3);
    final weekend = DateTime(2024, 1, 5);
    const options = UserSettings.weekendShiftOptions;

    Widget section(String title, List<Widget> children) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(header: true, child: Text(title, style: text.cardTitle)),
        const SizedBox(height: AppSpacing.smPlus),
        ...children,
      ],
    );

    return FullPage(
      eyebrow: strings.goals_eyebrow,
      title: strings.goals_title,
      bottom: PrimaryPillButton(
        label: strings.settings_save,
        icon: AppIcons.checkBold,
        onPressed: _save,
      ),
      gap: AppSpacing.xl,
      children: [
        section(strings.goals_duration, [
          GoalStepper(
            minutes: _draft.goalMinutes,
            onChanged: (v) =>
                setState(() => _draft = _draft.copyWith(goalMinutes: v)),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            strings.goals_durationBody,
            textAlign: TextAlign.center,
            style: muted,
          ),
        ]),
        section(strings.goals_bedtime, [
          SurfaceCard(
            radius: AppRadius.xlAll,
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: BedtimePicker(
              minute: _draft.bedtimeMinute,
              onChanged: (v) =>
                  setState(() => _draft = _draft.copyWith(bedtimeMinute: v)),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            strings.goals_weekdayPreview(
              formatClock(_draft.bedtimeFor(weekday)),
              formatClock(_draft.wakeFor(weekday)),
            ),
            style: muted,
          ),
          LinkButton(
            label: strings.goals_chronoLink,
            onPressed: _openChronotype,
          ),
        ]),
        section(strings.goals_weekend, [
          Text(strings.goals_weekendBody, style: muted),
          const SizedBox(height: AppSpacing.md),
          SegmentedPill(
            semanticLabel: strings.goals_weekend,
            labels: [
              for (final m in options) weekendShiftLabel(strings, locale, m),
            ],
            selected: options
                .indexOf(_draft.weekendShift)
                .clamp(0, options.length - 1),
            onChanged: (i) => setState(
              () => _draft = _draft.copyWith(weekendShift: options[i]),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            strings.goals_weekendPreview(
              formatClock(_draft.bedtimeFor(weekend)),
              formatClock(_draft.wakeFor(weekend)),
            ),
            style: muted,
          ),
        ]),
      ],
    );
  }
}
