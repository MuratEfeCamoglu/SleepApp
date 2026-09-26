import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uyku/core/strings/app_strings.dart';
import 'package:uyku/core/theme/app_radius.dart';
import 'package:uyku/core/theme/app_spacing.dart';
import 'package:uyku/core/theme/app_theme.dart';
import 'package:uyku/core/theme/sleep_stage_colors.dart';
import 'package:uyku/core/utils/formatters.dart';
import 'package:uyku/core/widgets/app_icon.dart';
import 'package:uyku/core/widgets/full_page.dart';
import 'package:uyku/core/widgets/primary_pill_button.dart';
import 'package:uyku/core/widgets/screen_header.dart';
import 'package:uyku/core/widgets/state_views.dart';
import 'package:uyku/core/widgets/step_progress.dart';
import 'package:uyku/features/chronotype/domain/chronotype.dart';
import 'package:uyku/features/settings/presentation/settings_controller.dart';

extension ChronotypeUi on Chronotype {
  String label(AppStrings strings) => switch (this) {
    Chronotype.morning => strings.chrono_morning,
    Chronotype.intermediate => strings.chrono_intermediate,
    Chronotype.evening => strings.chrono_evening,
  };

  String body(AppStrings strings) => switch (this) {
    Chronotype.morning => strings.chrono_morningBody,
    Chronotype.intermediate => strings.chrono_intermediateBody,
    Chronotype.evening => strings.chrono_eveningBody,
  };

  AppIconData get icon => switch (this) {
    Chronotype.morning => AppIcons.sun,
    Chronotype.intermediate => AppIcons.clock,
    Chronotype.evening => AppIcons.moon,
  };

  /// Deep ton: krem ikon üzerine konabilir.
  Color get color => switch (this) {
    Chronotype.morning => SleepStageColors.honeyDeep,
    Chronotype.intermediate => SleepStageColors.sageDeep,
    Chronotype.evening => SleepStageColors.lavenderDeep,
  };
}

/// Beş soruluk kronotip testi. Kurulum sırasında açıldıysa önerilen yatış
/// saatini sonuç olarak döndürür; aksi halde ayarlara kendisi yazar.
class ChronotypeScreen extends ConsumerStatefulWidget {
  const ChronotypeScreen({super.key});

  @override
  ConsumerState<ChronotypeScreen> createState() => _ChronotypeScreenState();
}

class _ChronotypeScreenState extends ConsumerState<ChronotypeScreen> {
  final _answers = List<int?>.filled(ChronotypeQuiz.questionCount, null);
  int _index = 0;
  Chronotype? _result;

  bool get _isLast => _index == ChronotypeQuiz.questionCount - 1;

  Future<void> _next() async {
    if (!_isLast) {
      setState(() => _index++);
      return;
    }
    final type = ChronotypeQuiz.classify(_answers.cast<int>());
    await ref.read(settingsControllerProvider.notifier).setChronotype(type);
    if (mounted) setState(() => _result = type);
  }

  void _back() {
    if (_result == null && _index > 0) {
      setState(() => _index--);
    } else {
      FullPage.back(context);
    }
  }

  Future<void> _apply(int minute) async {
    final settings = ref.read(settingsControllerProvider);
    if (!settings.onboardingDone) {
      // Kurulum kendi taslağını tutar; saati ona geri ver.
      context.pop(minute);
      return;
    }
    await ref.read(settingsControllerProvider.notifier).setBedtime(minute);
    if (mounted) FullPage.back(context);
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final result = _result;
    return PopScope(
      canPop: result != null || _index == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _index--);
      },
      child: result == null ? _question(strings) : _resultPage(strings, result),
    );
  }

  Widget _question(AppStrings strings) {
    final text = context.text;
    final options = strings.chrono_options[_index];
    final selected = _answers[_index];
    return FullPage(
      eyebrow: strings.chrono_progress(
        _index + 1,
        ChronotypeQuiz.questionCount,
      ),
      title: strings.chrono_title,
      onBack: _back,
      bottom: PrimaryPillButton(
        label: _isLast ? strings.chrono_seeResult : strings.chrono_next,
        icon: AppIcons.arrowRight,
        onPressed: selected == null ? null : _next,
      ),
      children: [
        StepProgress(step: _index, total: ChronotypeQuiz.questionCount),
        Semantics(
          header: true,
          child: Text(
            strings.chrono_questions[_index],
            style: text.titleMedium,
          ),
        ),
        Column(
          children: [
            for (var i = 0; i < options.length; i++) ...[
              if (i > 0) const SizedBox(height: AppSpacing.sm),
              OptionCard(
                label: options[i],
                selected: selected == i,
                onPressed: () => setState(() => _answers[_index] = i),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _resultPage(AppStrings strings, Chronotype type) {
    final colors = context.colors;
    final text = context.text;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final goal = ref.watch(
      settingsControllerProvider.select((s) => s.goalMinutes),
    );
    final bed = ChronotypeQuiz.suggestedBedtime(type, goal);
    return FullPage(
      eyebrow: strings.chrono_resultEyebrow,
      title: type.label(strings),
      onBack: _back,
      bottom: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PrimaryPillButton(
            label: strings.chrono_apply,
            icon: AppIcons.checkBold,
            onPressed: () => _apply(bed),
          ),
          const SizedBox(height: AppSpacing.md),
          Center(
            child: OutlinePillButton(
              label: strings.chrono_keep,
              onPressed: () => FullPage.back(context),
            ),
          ),
        ],
      ),
      children: [
        IconBadge(
          icon: type.icon,
          background: type.color,
          foreground: SleepStageColors.creamIcon,
        ),
        Text(
          type.body(strings),
          style: text.bodyLarge.copyWith(color: colors.textSecondary),
        ),
        SurfaceCard(
          radius: AppRadius.lgAll,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(strings.chrono_suggestionTitle, style: text.cardTitle),
              const SizedBox(height: AppSpacing.xs),
              Text(formatClock(bed), style: text.clockValue),
              const SizedBox(height: AppSpacing.sm),
              Text(
                strings.chrono_suggestionBody(
                  formatClock(bed),
                  formatClock(bed + goal),
                  formatGoal(strings, locale, goal),
                ),
                style: text.bodySmall.copyWith(color: colors.textSecondary),
              ),
            ],
          ),
        ),
        Text(
          strings.chrono_note,
          textAlign: TextAlign.center,
          style: text.caption.copyWith(color: colors.textSecondary),
        ),
      ],
    );
  }
}
