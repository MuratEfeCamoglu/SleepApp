import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
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
import 'package:uyku/core/widgets/choice_pill.dart';
import 'package:uyku/core/widgets/entrance.dart';
import 'package:uyku/core/widgets/full_page.dart';
import 'package:uyku/core/widgets/primary_pill_button.dart';
import 'package:uyku/core/widgets/screen_header.dart';
import 'package:uyku/core/widgets/state_views.dart';
import 'package:uyku/core/widgets/step_progress.dart';
import 'package:uyku/features/dreams/domain/dream_insights.dart';
import 'package:uyku/features/dreams/domain/dream_interview.dart';
import 'package:uyku/features/dreams/domain/dream_journal.dart';
import 'package:uyku/features/dreams/presentation/dream_interview_controller.dart';
import 'package:uyku/features/dreams/presentation/dream_providers.dart';
import 'package:uyku/features/dreams/presentation/dream_ui.dart';
import 'package:uyku/features/premium/presentation/premium_gate.dart';
import 'package:uyku/features/sleep_log/domain/sleep_entry.dart';
import 'package:uyku/features/sleep_log/presentation/log_screen.dart';
import 'package:uyku/features/sleep_log/presentation/sleep_log_providers.dart';

extension DreamWakeFeelingUi on DreamWakeFeeling {
  String label(AppStrings s) => switch (this) {
    DreamWakeFeeling.relieved => s.dreamsInterview_wakeRelieved,
    DreamWakeFeeling.uneasy => s.dreamsInterview_wakeUneasy,
    DreamWakeFeeling.curious => s.dreamsInterview_wakeCurious,
    DreamWakeFeeling.tired => s.dreamsInterview_wakeTired,
    DreamWakeFeeling.neutral => s.dreamsInterview_wakeNeutral,
  };
}

extension DreamControlUi on DreamControl {
  String label(AppStrings s) => switch (this) {
    DreamControl.yes => s.dreamsInterview_controlYes,
    DreamControl.partly => s.dreamsInterview_controlPartly,
    DreamControl.no => s.dreamsInterview_controlNo,
  };
}

extension DreamPersonUi on DreamPerson {
  String label(AppStrings s) => switch (this) {
    DreamPerson.family => s.dreamsInterview_personFamily,
    DreamPerson.friend => s.dreamsInterview_personFriend,
    DreamPerson.ex => s.dreamsInterview_personEx,
    DreamPerson.workSchool => s.dreamsInterview_personWork,
    DreamPerson.stranger => s.dreamsInterview_personStranger,
  };
}

extension LifeFocusUi on LifeFocus {
  String label(AppStrings s) => switch (this) {
    LifeFocus.workSchool => s.dreamsInterview_lifeWork,
    LifeFocus.relationships => s.dreamsInterview_lifeRelationships,
    LifeFocus.health => s.dreamsInterview_lifeHealth,
    LifeFocus.change => s.dreamsInterview_lifeChange,
    LifeFocus.loneliness => s.dreamsInterview_lifeLoneliness,
    LifeFocus.peace => s.dreamsInterview_lifePeace,
  };
}

extension DreamRecurrenceUi on DreamRecurrence {
  String label(AppStrings s) => switch (this) {
    DreamRecurrence.first => s.dreamsInterview_recurFirst,
    DreamRecurrence.sometimes => s.dreamsInterview_recurSometimes,
    DreamRecurrence.often => s.dreamsInterview_recurOften,
  };
}

/// `/dreams/interpret` — rüyayı yaz (ya da günlükten seç), altı soruyu
/// tek tek yanıtla, sonunda çıkarım. Taslak yalnızca "Kaydet" ile geceye
/// bağlanır; kaydetmeden çıkılırsa hiçbir şey kalıcı olmaz.
class DreamInterpretScreen extends ConsumerStatefulWidget {
  const DreamInterpretScreen({this.night, super.key});

  /// `2026-09-24` — verilirse akış o gecenin rüyasından başlar.
  final String? night;

  @override
  ConsumerState<DreamInterpretScreen> createState() =>
      _DreamInterpretScreenState();
}

class _DreamInterpretScreenState extends ConsumerState<DreamInterpretScreen> {
  /// Not + 6 soru.
  static final int _progressTotal = DreamInterviewState.resultStep;

  final _note = TextEditingController();
  bool _seeded = false;

  /// Son çizilen adım ve geçiş yönü (ileri: sağdan, geri: soldan).
  int _shownStep = 0;
  bool _forward = true;
  bool _noEntry = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  DreamInterviewController get _controller =>
      ref.read(dreamInterviewProvider.notifier);

  void _seed(List<SleepEntry> entries) {
    if (_seeded) return;
    _seeded = true;
    final key = widget.night;
    if (key == null) return;
    for (final e in entries) {
      if (e.id == key && e.hasDreamNote) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _pick(e);
        });
      }
    }
  }

  void _pick(SleepEntry entry) {
    _controller.startFrom(entry);
    _note.text = entry.note;
  }

  void _clearPick() {
    _controller.clearNight();
    _note.clear();
  }

  Future<void> _save() async {
    final result = await _controller.save();
    if (!mounted) return;
    setState(() => _noEntry = result == DreamSaveResult.noEntry);
  }

  void _restart() {
    ref.invalidate(dreamInterviewProvider);
    _note.clear();
    setState(() => _noEntry = false);
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final state = ref.watch(dreamInterviewProvider);
    final entries = ref.watch(sleepLogProvider);
    if (entries.value case final list?) _seed(list);

    final step = state.step;
    final isResult = state.isResult;
    if (step != _shownStep) {
      _forward = step > _shownStep;
      _shownStep = step;
    }
    final content = switch (step) {
      0 => _NoteStep(
        controller: _note,
        state: state,
        journal: dreamJournal(entries.value ?? const []),
        onPick: _pick,
        onClearPick: _clearPick,
      ),
      _ when isResult => _Result(
        state: state,
        noEntry: _noEntry,
        onRestart: _restart,
      ),
      _ => _QuestionStep(question: state.question!, answers: state.answers),
    };

    final saved = state.saved;
    final bottom = isResult
        ? PrimaryPillButton(
            label: saved
                ? strings.dreamsInterview_saved
                : state.night != null
                ? strings.dreamsInterview_saveNight
                : strings.dreamsInterview_saveYesterday,
            icon: saved ? AppIcons.checkBold : AppIcons.arrowRight,
            background: saved ? SleepStageColors.sageDeep : null,
            foreground: saved ? SleepStageColors.cream : null,
            onPressed: saved ? () {} : _save,
          )
        : PrimaryPillButton(
            label: step == _progressTotal - 1
                ? strings.dreamsInterview_finish
                : strings.dreamsInterview_next,
            icon: AppIcons.arrowRight,
            onPressed: state.canAdvance ? _controller.next : null,
          );

    return FullPage(
      eyebrow: isResult
          ? strings.dreamsInterview_eyebrow
          : strings.dreamsInterview_step(step + 1, _progressTotal),
      title: isResult
          ? strings.dreamsInterview_resultTitle
          : strings.dreamsInterview_title,
      // Geri: önceki adım (cevap korunur); ilk adımda sayfadan çıkar.
      onBack: step > 0 ? _controller.back : null,
      bottom: bottom,
      children: [
        StepProgress(
          step: math.min(step, _progressTotal - 1),
          total: _progressTotal,
        ),
        _StepSwitcher(
          forward: _forward,
          child: KeyedSubtree(key: ValueKey(step), child: content),
        ),
      ],
    );
  }
}

/// Adımlar arası: solma + 16px yatay kayma (`AppMotion.pageTransition`).
/// İleride yeni adım sağdan gelir, eskisi sola gider; geride tersi.
/// Hareket azaltmada anında.
class _StepSwitcher extends StatelessWidget {
  const _StepSwitcher({required this.forward, required this.child});

  final bool forward;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final currentKey = child.key;
    final dir = forward ? 1.0 : -1.0;
    return AnimatedSwitcher(
      duration: AppMotion.of(context, AppMotion.pageTransition),
      switchInCurve: AppMotion.entranceCurve,
      switchOutCurve: AppMotion.entranceCurve,
      layoutBuilder: (current, previous) => Stack(
        fit: StackFit.passthrough,
        alignment: Alignment.topCenter,
        children: [...previous, ?current],
      ),
      transitionBuilder: (child, animation) {
        // Gelen adım +dir yönünden, giden adım −dir yönüne kayar.
        final side = child.key == currentKey ? dir : -dir;
        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) => Opacity(
            opacity: animation.value,
            child: Transform.translate(
              offset: Offset(
                side * AppMotion.pageOffset * (1 - animation.value),
                0,
              ),
              child: child,
            ),
          ),
          child: child,
        );
      },
      child: child,
    );
  }
}

class _StepHeading extends StatelessWidget {
  const _StepHeading({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final text = context.text;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(header: true, child: Text(title, style: text.titleMedium)),
        const SizedBox(height: AppSpacing.xs),
        Text(
          body,
          style: text.bodyMedium.copyWith(color: context.colors.textSecondary),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Text(
        label.toUpperCase(),
        style: context.text.label.copyWith(color: context.colors.textSecondary),
      ),
    );
  }
}

// — Adım 0: rüya notu —

class _NoteStep extends ConsumerWidget {
  const _NoteStep({
    required this.controller,
    required this.state,
    required this.journal,
    required this.onPick,
    required this.onClearPick,
  });

  /// Günlükte en çok bu kadar gece önerilir.
  static const _pickCount = 5;

  /// Seçim kartındaki not önizlemesi.
  static const _previewLength = 60;

  final TextEditingController controller;
  final DreamInterviewState state;
  final List<SleepEntry> journal;
  final ValueChanged<SleepEntry> onPick;
  final VoidCallback onClearPick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    final colors = context.colors;
    final text = context.text;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final dateFormat = DateFormat('d MMMM, EEEE', locale);
    final notifier = ref.read(dreamInterviewProvider.notifier);
    final picked = state.night;

    String preview(String note) {
      final n = note.trim().replaceAll('\n', ' ');
      return n.length <= _previewLength
          ? n
          : '${n.substring(0, _previewLength).trimRight()}…';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StepHeading(
          title: strings.dreamsInterview_noteTitle,
          body: strings.dreamsInterview_noteBody,
        ),
        const SizedBox(height: AppSpacing.md),
        Semantics(
          textField: true,
          label: strings.dreamsInterview_noteLabel,
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: AppRadius.lgAll,
            ),
            child: TextField(
              controller: controller,
              minLines: 4,
              maxLines: 10,
              textCapitalization: TextCapitalization.sentences,
              inputFormatters: [
                LengthLimitingTextInputFormatter(
                  DreamInterviewState.maxNoteLength,
                ),
              ],
              style: text.bodyMedium,
              cursorColor: colors.espresso,
              decoration: InputDecoration.collapsed(
                hintText: strings.dreamsInterview_noteHint,
                hintStyle: text.bodyMedium.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              onChanged: notifier.setNote,
            ),
          ),
        ),
        if (picked != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.md,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                strings.dreamsInterview_pickedFrom(
                  dateFormat.format(DateTime.parse(picked)),
                ),
                style: text.caption.copyWith(color: colors.textSecondary),
              ),
              LinkButton(
                label: strings.dreamsInterview_pickClear,
                onPressed: onClearPick,
              ),
            ],
          ),
        ],
        const SizedBox(height: AppSpacing.lgPlus),
        Text(strings.dreamsInterview_kindTitle, style: text.cardTitle),
        const SizedBox(height: AppSpacing.smPlus),
        Semantics(
          container: true,
          label: strings.dreams_kindGroup,
          explicitChildNodes: true,
          child: Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final k in DreamKind.values)
                ChoicePill(
                  label: k.label(strings),
                  selected: state.kind == k,
                  onPressed: () => notifier.toggleKind(k),
                ),
            ],
          ),
        ),
        if (journal.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lgPlus),
          Text(strings.dreamsInterview_pickTitle, style: text.cardTitle),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            strings.dreamsInterview_pickBody,
            style: text.bodySmall.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.smPlus),
          for (final e in journal.take(_pickCount)) ...[
            OptionCard(
              label: dateFormat.format(e.night),
              detail: preview(e.note),
              selected: picked == e.id,
              onPressed: () => onPick(e),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ],
    );
  }
}

// — Adım 1–6: sorular —

class _QuestionStep extends ConsumerWidget {
  const _QuestionStep({required this.question, required this.answers});

  final DreamQuestion question;
  final DreamInterviewAnswers answers;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = AppStrings.of(context);
    final n = ref.read(dreamInterviewProvider.notifier);
    final a = answers;
    final (
      String title,
      String body,
      List<(String, bool, VoidCallback)> opts,
    ) = switch (question) {
      DreamQuestion.emotion => (
        s.dreamsInterview_q1Title,
        s.dreamsInterview_q1Body,
        [
          for (final v in DreamEmotion.values)
            (v.label(s), a.emotion == v, () => n.setEmotion(v)),
        ],
      ),
      DreamQuestion.wake => (
        s.dreamsInterview_q2Title,
        s.dreamsInterview_q2Body,
        [
          for (final v in DreamWakeFeeling.values)
            (v.label(s), a.wake == v, () => n.setWake(v)),
        ],
      ),
      DreamQuestion.control => (
        s.dreamsInterview_q3Title,
        s.dreamsInterview_q3Body,
        [
          for (final v in DreamControl.values)
            (v.label(s), a.control == v, () => n.setControl(v)),
        ],
      ),
      DreamQuestion.people => (
        s.dreamsInterview_q4Title,
        s.dreamsInterview_q4Body,
        [
          for (final v in DreamPerson.values)
            (
              v.label(s),
              a.people?.contains(v) ?? false,
              () => n.togglePerson(v),
            ),
          (
            s.dreamsInterview_none,
            a.people != null && a.people!.isEmpty,
            () => n.togglePerson(null),
          ),
        ],
      ),
      DreamQuestion.life => (
        s.dreamsInterview_q5Title,
        s.dreamsInterview_q5Body,
        [
          for (final v in LifeFocus.values)
            (v.label(s), a.life == v, () => n.setLife(v)),
        ],
      ),
      DreamQuestion.recurrence => (
        s.dreamsInterview_q6Title,
        s.dreamsInterview_q6Body,
        [
          for (final v in DreamRecurrence.values)
            (v.label(s), a.recurrence == v, () => n.setRecurrence(v)),
        ],
      ),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StepHeading(title: title, body: body),
        const SizedBox(height: AppSpacing.lg),
        Semantics(
          container: true,
          label: title,
          explicitChildNodes: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < opts.length; i++) ...[
                if (i > 0) const SizedBox(height: AppSpacing.sm),
                OptionCard(
                  label: opts[i].$1,
                  selected: opts[i].$2,
                  onPressed: opts[i].$3,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// — Sonuç —

class _Result extends ConsumerWidget {
  const _Result({
    required this.state,
    required this.noEntry,
    required this.onRestart,
  });

  final DreamInterviewState state;
  final bool noEntry;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    final colors = context.colors;
    final text = context.text;
    final insightsState = ref.watch(dreamInsightsProvider);
    final inference = inferDream(
      note: state.note,
      kind: state.kind,
      answers: state.answers,
      insights: insightsState.value,
    );
    const gap = SizedBox(height: AppSpacing.lgPlus);
    const small = SizedBox(height: AppSpacing.smPlus);
    final kind = inference.kind;
    final emotion = inference.emotion;

    // Bölümler sırayla gelir: önce "Genel tema" hafif ölçek + solma ile,
    // ardından diğerleri kademeli (en çok 5 gecikme adımı).
    Widget section(int index, String label, Widget body) => Entrance(
      index: index,
      offset: index == 0 ? 0 : AppMotion.entranceOffset,
      scaleFrom: index == 0 ? AppMotion.popScale : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [_SectionLabel(label), small, body],
      ),
    );

    final tags = [
      if (kind != null) DreamTag.kind(kind),
      if (emotion != null) DreamTag.emotion(emotion),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        section(
          0,
          strings.dreamsInterview_sectionTheme,
          _TextCard(
            leading: Wrap(
              spacing: AppSpacing.xsPlus,
              runSpacing: AppSpacing.xsPlus,
              children: [
                // Etiket çipleri kartın ardından sırayla belirir.
                for (var i = 0; i < tags.length; i++)
                  Entrance(
                    index: i + 1,
                    offset: 0,
                    scaleFrom: AppMotion.popScale,
                    child: tags[i],
                  ),
              ],
            ),
            body: inference.theme,
          ),
        ),
        gap,
        section(
          1,
          strings.dreamsInterview_sectionLife,
          _TextCard(body: inference.lifeLink),
        ),
        gap,
        section(
          2,
          strings.dreamsInterview_sectionReflect,
          SurfaceCard(
            radius: AppRadius.lgAll,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < inference.reflections.length; i++) ...[
                  if (i > 0) const SizedBox(height: AppSpacing.md),
                  _Bullet(text: inference.reflections[i]),
                ],
              ],
            ),
          ),
        ),
        gap,
        section(
          3,
          strings.dreamsInterview_sectionSuggestion,
          _SuggestionCard(inference: inference),
        ),
        gap,
        section(
          4,
          strings.dreamsInterview_sectionSymbols,
          inference.symbolNotes.isEmpty
              ? _TextCard(body: strings.dreams_noSymbols, muted: true)
              : PremiumGate(
                  title: strings.dreamsInterview_symbolsLockTitle,
                  message: strings.dreamsInterview_symbolsLockBody,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Sembol kartları bölümün ardından sırayla belirir.
                      for (
                        var i = 0;
                        i < inference.symbolNotes.length;
                        i++
                      ) ...[
                        if (i > 0) const SizedBox(height: AppSpacing.smPlus),
                        Entrance(
                          index: 4 + i,
                          child: _SymbolNoteCard(
                            title: inference.symbolNotes[i].$1.title,
                            meaning: inference.symbolNotes[i].$1.meaning,
                            note: inference.symbolNotes[i].$2,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
        ),
        gap,
        section(
          5,
          strings.dreamsInterview_sectionSleep,
          insightsState.isLoading && !insightsState.hasValue
              ? const SkeletonBlock(height: AppSizes.settingsRow)
              : PremiumGate(
                  title: strings.dreamsInterview_sleepLockTitle,
                  message: strings.dreamsInterview_sleepLockBody,
                  child: _SleepLinkCard(link: inference.sleepLink),
                ),
        ),
        if (noEntry) ...[
          gap,
          SurfaceCard(
            radius: AppRadius.lgAll,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(strings.dreamsInterview_noEntry, style: text.bodySmall),
                const SizedBox(height: AppSpacing.md),
                OutlinePillButton(
                  label: strings.dreamsInterview_noEntryAction,
                  onPressed: () => context.go(AppRoutes.log),
                ),
              ],
            ),
          ),
        ],
        gap,
        Entrance(
          index: 5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                strings.dreams_disclaimer,
                textAlign: TextAlign.center,
                style: text.caption.copyWith(color: colors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.md),
              Center(
                child: LinkButton(
                  label: strings.dreamsInterview_restart,
                  onPressed: onRestart,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TextCard extends StatelessWidget {
  const _TextCard({required this.body, this.leading, this.muted = false});

  final String body;
  final Widget? leading;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final text = context.text;
    return MergeSemantics(
      child: SurfaceCard(
        radius: AppRadius.lgAll,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (leading != null) ...[
              leading!,
              const SizedBox(height: AppSpacing.smPlus),
            ],
            Text(
              body,
              style: muted
                  ? text.bodySmall.copyWith(color: context.colors.textSecondary)
                  : text.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final style = context.text.bodyMedium;
    final lineHeight = (style.fontSize ?? 0) * (style.height ?? 1);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: lineHeight,
          child: Center(
            child: Container(
              width: AppSizes.dotSmall,
              height: AppSizes.dotSmall,
              decoration: BoxDecoration(
                color: colors.espressoSoft,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.smPlus),
        Expanded(
          child: Text(text, style: style.copyWith(color: colors.textPrimary)),
        ),
      ],
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({required this.inference});

  final DreamInference inference;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final colors = context.colors;
    final text = context.text;
    final (String? link, String? route) = switch (inference.suggestion) {
      DreamSuggestion.breathe => (
        strings.dreamsInterview_openBreathe,
        AppRoutes.breathe,
      ),
      DreamSuggestion.windDown => (
        strings.dreamsInterview_openRoutine,
        AppRoutes.routine,
      ),
      _ => (null, null),
    };
    return SurfaceCard(
      radius: AppRadius.lgAll,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: AppSizes.tipIcon,
            height: AppSizes.tipIcon,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.sageTint,
              shape: BoxShape.circle,
            ),
            child: AppIcon(
              inference.suggestion == DreamSuggestion.rewriteEnding
                  ? AppIcons.pen
                  : AppIcons.breath,
              color: colors.sageText,
            ),
          ),
          const SizedBox(width: AppSpacing.mdPlus),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(inference.suggestionText, style: text.bodySmall),
                if (link != null && route != null)
                  LinkButton(label: link, onPressed: () => context.push(route)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SymbolNoteCard extends StatelessWidget {
  const _SymbolNoteCard({
    required this.title,
    required this.meaning,
    required this.note,
  });

  final String title;
  final String meaning;

  /// Cevaplara göre bağlam cümlesi.
  final String note;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.text;
    return MergeSemantics(
      child: SurfaceCard(
        radius: AppRadius.lgAll,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: AppSizes.tipIcon,
              height: AppSizes.tipIcon,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colors.honeyTint,
                shape: BoxShape.circle,
              ),
              child: AppIcon(AppIcons.sparkle, color: colors.honeyText),
            ),
            const SizedBox(width: AppSpacing.mdPlus),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: text.cardTitle),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    meaning,
                    style: text.bodySmall.copyWith(color: colors.textSecondary),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(note, style: text.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SleepLinkCard extends StatelessWidget {
  const _SleepLinkCard({required this.link});

  final DreamSleepLink? link;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final colors = context.colors;
    final text = context.text;
    final muted = text.bodySmall.copyWith(color: colors.textSecondary);
    final l = link;
    if (l == null) {
      return SurfaceCard(
        radius: AppRadius.lgAll,
        child: Text(
          strings.dreamsInterview_sleepNeedMore(
            DreamInsightsCalculator.minNights,
          ),
          style: muted,
        ),
      );
    }
    final delta = l.durationDelta;
    final factor = l.nightmareFactor;
    return MergeSemantics(
      child: SurfaceCard(
        radius: AppRadius.lgAll,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              strings.dreamsInterview_sleepAverage(
                l.dreamNights,
                formatDuration(strings, l.dreamAverage),
              ),
              style: text.bodyMedium,
            ),
            if (delta != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                delta < 0
                    ? strings.dreams_nightmareLess(
                        formatDurationShort(strings, -delta),
                      )
                    : delta > 0
                    ? strings.dreams_nightmareMore(
                        formatDurationShort(strings, delta),
                      )
                    : strings.dreams_nightmareSame,
                style: text.bodySmall,
              ),
            ] else ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                strings.dreams_needMore(DreamInsightsCalculator.minNights),
                style: muted,
              ),
            ],
            if (factor != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                strings.dreams_nightmareFactor(
                  factor.factor.label(strings),
                  factor.nights,
                ),
                style: l.isNightmare ? text.bodyStrong : text.bodySmall,
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            Text(strings.dreams_insightsNote, style: muted),
          ],
        ),
      ),
    );
  }
}
