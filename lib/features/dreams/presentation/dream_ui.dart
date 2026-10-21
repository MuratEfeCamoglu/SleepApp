import 'package:flutter/widgets.dart';
import 'package:uyku/core/strings/app_strings.dart';
import 'package:uyku/core/theme/app_sizes.dart';
import 'package:uyku/core/theme/app_spacing.dart';
import 'package:uyku/core/theme/app_theme.dart';
import 'package:uyku/features/sleep_log/domain/sleep_entry.dart';

extension DreamKindUi on DreamKind {
  String label(AppStrings strings) => switch (this) {
    DreamKind.normal => strings.dreams_kindNormal,
    DreamKind.lucid => strings.dreams_kindLucid,
    DreamKind.nightmare => strings.dreams_kindNightmare,
    DreamKind.recurring => strings.dreams_kindRecurring,
  };
}

extension DreamEmotionUi on DreamEmotion {
  String label(AppStrings strings) => switch (this) {
    DreamEmotion.calm => strings.dreams_emotionCalm,
    DreamEmotion.joy => strings.dreams_emotionJoy,
    DreamEmotion.fear => strings.dreams_emotionFear,
    DreamEmotion.sadness => strings.dreams_emotionSadness,
    DreamEmotion.anger => strings.dreams_emotionAnger,
    DreamEmotion.confusion => strings.dreams_emotionConfusion,
  };
}

/// Salt okunur etiket: tür dolu (kabus ember tonunda), duygu outline.
class DreamTag extends StatelessWidget {
  const DreamTag.kind(DreamKind this.kind, {super.key}) : emotion = null;

  const DreamTag.emotion(DreamEmotion this.emotion, {super.key}) : kind = null;

  final DreamKind? kind;
  final DreamEmotion? emotion;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final colors = context.colors;
    final k = kind;
    final nightmare = k == DreamKind.nightmare;
    final background = k == null
        ? null
        : nightmare
        ? colors.emberTint
        : colors.surfaceMuted;
    final foreground = nightmare ? colors.emberText : colors.textPrimary;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.smPlus,
        vertical: AppSpacing.xs,
      ),
      decoration: ShapeDecoration(
        color: background,
        shape: StadiumBorder(
          side: k == null
              ? BorderSide(
                  color: colors.chipLine,
                  width: AppSizes.outlineStroke,
                )
              : BorderSide.none,
        ),
      ),
      child: Text(
        k?.label(strings) ?? emotion!.label(strings),
        style: context.text.caption.copyWith(
          color: foreground,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Tür + duygu etiketleri; ikisi de yoksa boş.
class DreamTags extends StatelessWidget {
  const DreamTags({required this.entry, super.key});

  final SleepEntry entry;

  @override
  Widget build(BuildContext context) {
    final kind = entry.dreamKind;
    return Wrap(
      spacing: AppSpacing.xsPlus,
      runSpacing: AppSpacing.xsPlus,
      children: [
        if (kind != null) DreamTag.kind(kind),
        for (final e in entry.dreamEmotions) DreamTag.emotion(e),
      ],
    );
  }
}
