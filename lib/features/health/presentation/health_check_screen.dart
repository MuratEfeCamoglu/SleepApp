import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uyku/core/strings/app_strings.dart';
import 'package:uyku/core/theme/app_radius.dart';
import 'package:uyku/core/theme/app_sizes.dart';
import 'package:uyku/core/theme/app_spacing.dart';
import 'package:uyku/core/theme/app_theme.dart';
import 'package:uyku/core/widgets/app_icon.dart';
import 'package:uyku/core/widgets/choice_pill.dart';
import 'package:uyku/core/widgets/full_page.dart';
import 'package:uyku/core/widgets/primary_pill_button.dart';
import 'package:uyku/core/widgets/screen_header.dart';
import 'package:uyku/core/widgets/state_views.dart';
import 'package:uyku/features/health/domain/health_check.dart';
import 'package:uyku/features/health/presentation/health_providers.dart';
import 'package:uyku/features/health/presentation/health_ui.dart';

/// `/health/check` — 6 soruluk öz-kontrol (ücretsiz). Tanı koymaz; yalnız
/// "bir uzmana danışmayı düşün" sinyali verir.
class HealthCheckScreen extends ConsumerStatefulWidget {
  const HealthCheckScreen({super.key});

  @override
  ConsumerState<HealthCheckScreen> createState() => _HealthCheckScreenState();
}

class _HealthCheckScreenState extends ConsumerState<HealthCheckScreen> {
  final Map<HealthQuestion, int> _answers = {};
  HealthCheckResult? _result;
  bool _submitting = false;

  bool get _complete => _answers.length == HealthQuestion.values.length;

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      final result = await ref
          .read(healthCheckProvider.notifier)
          .submit(Map.of(_answers));
      if (!mounted) return;
      setState(() => _result = result);
    } finally {
      // Kaydetme hata verse de buton kilitli kalmasın.
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _retake() => setState(() {
    _answers.clear();
    _result = null;
  });

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final result = _result;
    if (result != null) {
      // Ayrı anahtar: sonuç sayfası da kademeli girişle gelir.
      return FullPage(
        key: const ValueKey('result'),
        eyebrow: strings.health_checkTitle,
        title: strings.health_checkResultTitle,
        bottom: PrimaryPillButton(
          label: strings.health_checkDone,
          onPressed: () => FullPage.back(context),
        ),
        children: [
          _TakenAt(result: result),
          if (result.hasFlags)
            for (final flag in result.flags) _FlagCard(flag: flag)
          else
            const _ClearCard(),
          const _Note(),
          Center(
            child: OutlinePillButton(
              label: strings.health_checkRetake,
              onPressed: _retake,
            ),
          ),
        ],
      );
    }

    const questions = HealthQuestion.values;
    return FullPage(
      key: const ValueKey('questions'),
      eyebrow: strings.health_checkEyebrow,
      title: strings.health_checkTitle,
      bottom: PrimaryPillButton(
        label: strings.health_checkSubmit,
        icon: AppIcons.arrowRight,
        onPressed: _complete && !_submitting ? _submit : null,
      ),
      children: [
        Text(
          strings.health_checkLead,
          style: context.text.bodyMedium.copyWith(
            color: context.colors.textSecondary,
          ),
        ),
        for (var i = 0; i < questions.length; i++)
          _QuestionCard(
            index: i,
            total: questions.length,
            question: questions[i],
            answer: _answers[questions[i]],
            onAnswer: (v) => setState(() => _answers[questions[i]] = v),
          ),
        const _Note(),
      ],
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    required this.index,
    required this.total,
    required this.question,
    required this.answer,
    required this.onAnswer,
  });

  final int index;
  final int total;
  final HealthQuestion question;
  final int? answer;
  final ValueChanged<int> onAnswer;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final colors = context.colors;
    final text = context.text;
    final labels = healthAnswerLabels(strings);
    return SurfaceCard(
      radius: AppRadius.lgAll,
      padding: const EdgeInsets.all(AppSpacing.lgPlus),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            strings.health_checkProgress(index + 1, total),
            style: text.tileLabel.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(question.text(strings), style: text.cardTitle),
          const SizedBox(height: AppSpacing.md),
          Semantics(
            container: true,
            label: question.text(strings),
            explicitChildNodes: true,
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (var v = 0; v < labels.length; v++)
                  ChoicePill(
                    label: labels[v],
                    selected: answer == v,
                    height: AppSizes.touch,
                    onPressed: () => onAnswer(v),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TakenAt extends StatelessWidget {
  const _TakenAt({required this.result});

  final HealthCheckResult result;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    return Text(
      strings.health_checkTakenAt(
        DateFormat('d MMMM y', locale).format(result.takenAt),
      ),
      style: context.text.bodyMedium.copyWith(
        color: context.colors.textSecondary,
      ),
    );
  }
}

class _FlagCard extends StatelessWidget {
  const _FlagCard({required this.flag});

  final HealthFlag flag;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final colors = context.colors;
    return _ResultCard(
      icon: AppIcons.bell,
      tint: colors.honeyTint,
      iconColor: colors.honeyText,
      title: flag.title(strings),
      body: flag.body(strings),
      footer: strings.health_checkConsult,
    );
  }
}

class _ClearCard extends StatelessWidget {
  const _ClearCard();

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final colors = context.colors;
    return _ResultCard(
      icon: AppIcons.checkBold,
      tint: colors.sageTint,
      iconColor: colors.sageText,
      title: strings.health_checkClearTitle,
      body: strings.health_checkClear,
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.icon,
    required this.tint,
    required this.iconColor,
    required this.title,
    required this.body,
    this.footer,
  });

  final AppIconData icon;
  final Color tint;
  final Color iconColor;
  final String title;
  final String body;
  final String? footer;

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
              decoration: BoxDecoration(color: tint, shape: BoxShape.circle),
              child: AppIcon(icon, color: iconColor),
            ),
            const SizedBox(width: AppSpacing.mdPlus),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: text.cardTitle),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    body,
                    style: text.bodySmall.copyWith(color: colors.textSecondary),
                  ),
                  if (footer != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(footer!, style: text.bodyStrong),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Bu bir tanı değildir" notu; soru ve sonuç ekranında her zaman görünür.
class _Note extends StatelessWidget {
  const _Note();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surfaceMuted,
        borderRadius: AppRadius.mdPlusAll,
      ),
      child: Text(
        AppStrings.of(context).health_checkNote,
        style: context.text.caption.copyWith(color: colors.textPrimary),
      ),
    );
  }
}
