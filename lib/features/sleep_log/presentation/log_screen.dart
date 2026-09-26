import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uyku/core/router/app_router.dart';
import 'package:uyku/core/strings/app_strings.dart';
import 'package:uyku/core/theme/app_radius.dart';
import 'package:uyku/core/theme/app_sizes.dart';
import 'package:uyku/core/theme/app_spacing.dart';
import 'package:uyku/core/theme/app_theme.dart';
import 'package:uyku/core/theme/sleep_stage_colors.dart';
import 'package:uyku/core/utils/formatters.dart';
import 'package:uyku/core/widgets/app_icon.dart';
import 'package:uyku/core/widgets/choice_pill.dart';
import 'package:uyku/core/widgets/circle_icon_button.dart';
import 'package:uyku/core/widgets/primary_pill_button.dart';
import 'package:uyku/core/widgets/screen_header.dart';
import 'package:uyku/core/widgets/state_views.dart';
import 'package:uyku/features/sleep_log/domain/sleep_entry.dart';
import 'package:uyku/features/sleep_log/presentation/log_editor.dart';
import 'package:uyku/features/sleep_log/presentation/sleep_log_providers.dart';
import 'package:uyku/features/sleep_summary/presentation/app_shell.dart';
import 'package:uyku/features/track_sleep/presentation/track_controller.dart';

extension WakeMoodUi on WakeMood {
  String label(AppStrings strings) => switch (this) {
    WakeMood.exhausted => strings.log_moodExhausted,
    WakeMood.tired => strings.log_moodTired,
    WakeMood.normal => strings.log_moodNormal,
    WakeMood.refreshed => strings.log_moodRefreshed,
    WakeMood.great => strings.log_moodGreat,
  };
}

extension SleepFactorUi on SleepFactor {
  String label(AppStrings strings) => switch (this) {
    SleepFactor.caffeine => strings.log_factorCaffeine,
    SleepFactor.alcohol => strings.log_factorAlcohol,
    SleepFactor.lateMeal => strings.log_factorLateMeal,
    SleepFactor.exercise => strings.log_factorExercise,
    SleepFactor.screen => strings.log_factorScreen,
    SleepFactor.stress => strings.log_factorStress,
    SleepFactor.noise => strings.log_factorNoise,
  };
}

class LogScreen extends ConsumerStatefulWidget {
  const LogScreen({this.night, super.key});

  /// `2026-09-24` — verilirse o gece açılır.
  final String? night;

  @override
  ConsumerState<LogScreen> createState() => _LogScreenState();
}

class _LogScreenState extends ConsumerState<LogScreen> {
  @override
  void initState() {
    super.initState();
    _applyNight();
  }

  @override
  void didUpdateWidget(LogScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.night != widget.night) _applyNight();
  }

  void _applyNight() {
    final raw = widget.night;
    final parsed = raw == null ? null : DateTime.tryParse(raw);
    if (parsed == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(logNightProvider.notifier).select(parsed);
    });
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final entries = ref.watch(sleepLogProvider);
    final night = ref.watch(logNightProvider);
    final draft = ref.watch(logEditorProvider);

    final header = ScreenHeader(
      leading: CircleIconButton(
        icon: AppIcons.back,
        semanticLabel: strings.common_back,
        onPressed: () => context.go(AppRoutes.today),
      ),
      eyebrow: strings.log_nightOf(DateFormat('EEEE', locale).format(night)),
      title: strings.log_title,
    );

    return entries.when(
      loading: () =>
          TabPage(children: [header, const SkeletonBlock(height: 200)]),
      error: (_, _) => TabPage(
        children: [
          header,
          ErrorState(
            onRetry: () => ref.read(sleepLogProvider.notifier).retry(),
          ),
        ],
      ),
      data: (list) {
        if (draft == null) {
          return TabPage(children: [header, const _StartCard()]);
        }
        final saved = draft.matches(list.forNight(draft.night));
        return TabPage(
          children: [
            header,
            _TimesCard(draft: draft),
            _Moods(draft: draft),
            _Factors(draft: draft),
            _DreamNote(key: ValueKey(draft.entry.id), initial: draft.note),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PrimaryPillButton(
                  label: saved ? strings.log_saved : strings.log_save,
                  icon: saved ? AppIcons.checkBold : AppIcons.arrowRight,
                  background: saved ? SleepStageColors.sageDeep : null,
                  foreground: saved ? SleepStageColors.cream : null,
                  onPressed: saved
                      ? () {}
                      : () => ref.read(logEditorProvider.notifier).save(),
                ),
                const SizedBox(height: AppSpacing.md),
                Center(
                  child: OutlinePillButton(
                    label: strings.log_startSleepMode,
                    onPressed: () =>
                        ref.read(trackControllerProvider.notifier).start(),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

/// O gece kayıt yoksa: tek veri kaynağı Uyku modudur.
class _StartCard extends ConsumerWidget {
  const _StartCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    final colors = context.colors;
    final text = context.text;
    return SurfaceCard(
      radius: AppRadius.lgPlusAll,
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
                AppIcons.moon,
                color: colors.honeyText,
                size: AppSizes.emptyIcon,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            strings.log_startTitle,
            textAlign: TextAlign.center,
            style: text.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            strings.log_startBody,
            textAlign: TextAlign.center,
            style: text.bodyMedium.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xl),
          PrimaryPillButton(
            label: strings.log_startSleepMode,
            icon: AppIcons.moon,
            onPressed: () => ref.read(trackControllerProvider.notifier).start(),
          ),
        ],
      ),
    );
  }
}

/// Uyku modunun ölçtüğü saatler — salt okunur.
class _TimesCard extends StatelessWidget {
  const _TimesCard({required this.draft});

  final LogDraft draft;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final colors = context.colors;
    final text = context.text;

    Widget column(String label, DateTime time) => Expanded(
      child: MergeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: text.eyebrow.copyWith(color: colors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.smPlus),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(formatClockOf(time), style: text.clockValue),
            ),
          ],
        ),
      ),
    );

    return SurfaceCard(
      radius: AppRadius.lgPlusAll,
      padding: const EdgeInsets.all(AppSpacing.lgPlus),
      child: Column(
        children: [
          Row(
            children: [
              column(strings.log_bedtime, draft.entry.bedtime),
              const SizedBox(width: AppSpacing.md),
              column(strings.log_wake, draft.entry.wake),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(height: AppSizes.divider, color: colors.outline),
          const SizedBox(height: AppSpacing.mdPlus),
          MergeSemantics(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    strings.log_total,
                    style: text.bodyMedium.copyWith(
                      color: colors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  formatDuration(strings, draft.entry.durationMinutes),
                  style: text.valueMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Moods extends ConsumerWidget {
  const _Moods({required this.draft});

  final LogDraft draft;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(strings.log_moodTitle, style: context.text.cardTitle),
        ),
        const SizedBox(height: AppSpacing.smPlus),
        Semantics(
          container: true,
          label: strings.log_moodGroup,
          explicitChildNodes: true,
          child: Row(
            children: [
              for (final m in WakeMood.values) ...[
                if (m.index > 0) const SizedBox(width: AppSpacing.xsPlus),
                Expanded(
                  child: ChoicePill(
                    label: m.label(strings),
                    selected: draft.mood == m,
                    height: AppSizes.moodChipHeight,
                    strong: true,
                    expand: true,
                    onPressed: () =>
                        ref.read(logEditorProvider.notifier).setMood(m),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _Factors extends ConsumerWidget {
  const _Factors({required this.draft});

  final LogDraft draft;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(strings.log_factorsTitle, style: context.text.cardTitle),
        ),
        const SizedBox(height: AppSpacing.smPlus),
        Semantics(
          container: true,
          label: strings.log_factorsGroup,
          explicitChildNodes: true,
          child: Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final f in SleepFactor.values)
                ChoicePill(
                  label: f.label(strings),
                  selected: draft.factors.contains(f),
                  onPressed: () =>
                      ref.read(logEditorProvider.notifier).toggleFactor(f),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Rüya günlüğü: serbest not, kayıtla birlikte saklanır.
class _DreamNote extends ConsumerStatefulWidget {
  const _DreamNote({required this.initial, super.key});

  final String initial;

  @override
  ConsumerState<_DreamNote> createState() => _DreamNoteState();
}

class _DreamNoteState extends ConsumerState<_DreamNote> {
  static const _maxLength = 1000;

  late final TextEditingController _controller = TextEditingController(
    text: widget.initial,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final colors = context.colors;
    final text = context.text;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            AppIcon(
              AppIcons.pen,
              color: colors.textSecondary,
              size: AppSizes.iconSmall,
            ),
            const SizedBox(width: AppSpacing.xsPlus),
            Semantics(
              header: true,
              child: Text(strings.dream_title, style: text.cardTitle),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          strings.dream_body,
          style: text.bodySmall.copyWith(color: colors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.smPlus),
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: AppRadius.lgAll,
          ),
          child: TextField(
            controller: _controller,
            minLines: 3,
            maxLines: 8,
            textCapitalization: TextCapitalization.sentences,
            inputFormatters: [LengthLimitingTextInputFormatter(_maxLength)],
            style: text.bodyMedium,
            cursorColor: colors.espresso,
            decoration: InputDecoration.collapsed(
              hintText: strings.dream_hint,
              hintStyle: text.bodyMedium.copyWith(color: colors.textSecondary),
            ),
            onChanged: (v) => ref.read(logEditorProvider.notifier).setNote(v),
          ),
        ),
      ],
    );
  }
}
