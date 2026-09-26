import 'dart:async';

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
import 'package:uyku/core/widgets/app_icon.dart';
import 'package:uyku/core/widgets/full_page.dart';
import 'package:uyku/core/widgets/pressable.dart';
import 'package:uyku/core/widgets/primary_pill_button.dart';
import 'package:uyku/core/widgets/screen_header.dart';
import 'package:uyku/core/widgets/segmented_pill.dart';
import 'package:uyku/core/widgets/state_views.dart';
import 'package:uyku/features/sounds/domain/sleep_sound.dart';
import 'package:uyku/features/sounds/presentation/sound_controller.dart';

extension SleepSoundUi on SleepSound {
  String label(AppStrings strings) => switch (this) {
    SleepSound.music => strings.sound_music,
    SleepSound.piano => strings.sound_piano,
    SleepSound.cycle => strings.sound_cycle,
    SleepSound.lofi => strings.sound_lofi,
  };

  String note(AppStrings strings) => switch (this) {
    SleepSound.music => strings.sound_musicNote,
    SleepSound.piano => strings.sound_pianoNote,
    SleepSound.cycle => strings.sound_cycleNote,
    SleepSound.lofi => strings.sound_lofiNote,
  };

  AppIconData get icon => switch (this) {
    SleepSound.music => AppIcons.moon,
    SleepSound.piano => AppIcons.speaker,
    SleepSound.cycle => AppIcons.wave,
    SleepSound.lofi => AppIcons.layers,
  };

  /// Deep ton: krem ikon üzerine konabilir.
  Color get color => switch (this) {
    SleepSound.music => SleepStageColors.lavenderDeep,
    SleepSound.piano => SleepStageColors.honeyDeep,
    SleepSound.cycle => SleepStageColors.sageDeep,
    SleepSound.lofi => SleepStageColors.emberDeep,
  };
}

class SoundsScreen extends ConsumerStatefulWidget {
  const SoundsScreen({super.key});

  @override
  ConsumerState<SoundsScreen> createState() => _SoundsScreenState();
}

class _SoundsScreenState extends ConsumerState<SoundsScreen> {
  late final Timer _ticker;

  @override
  void initState() {
    super.initState();
    // Kalan süre yazısını güncel tut.
    _ticker = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final colors = context.colors;
    final text = context.text;
    final state = ref.watch(soundControllerProvider);
    final controller = ref.read(soundControllerProvider.notifier);
    final now = ref.watch(clockProvider).now();

    final endsAt = state.endsAt;
    final status = !state.playing
        ? null
        : endsAt == null
        ? strings.sounds_statusEndless(state.sound.label(strings))
        : strings.sounds_status(
            state.sound.label(strings),
            (endsAt.difference(now).inSeconds / 60).ceil().clamp(0, 999),
          );

    final timerLabels = [
      for (final m in SleepSoundTimer.options)
        if (m == null)
          strings.sounds_timerEndless
        else
          strings.sounds_timerMinutes(m),
    ];

    return FullPage(
      eyebrow: strings.sounds_eyebrow,
      title: strings.sounds_title,
      bottom: PrimaryPillButton(
        label: state.playing ? strings.sounds_stop : strings.sounds_play,
        icon: state.playing ? AppIcons.stop : AppIcons.play,
        onPressed: state.playing ? controller.stop : controller.play,
      ),
      children: [
        Semantics(
          container: true,
          label: strings.sounds_group,
          explicitChildNodes: true,
          child: Column(
            children: [
              for (var row = 0; row < 2; row++) ...[
                if (row > 0) const SizedBox(height: AppSpacing.smPlus),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var col = 0; col < 2; col++) ...[
                      if (col > 0) const SizedBox(width: AppSpacing.smPlus),
                      Expanded(
                        child: _SoundTile(
                          sound: SleepSound.values[row * 2 + col],
                          selected:
                              state.sound == SleepSound.values[row * 2 + col],
                          playing: state.playing,
                          onPressed: () => controller.select(
                            SleepSound.values[row * 2 + col],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              header: true,
              child: Text(strings.sounds_timer, style: text.cardTitle),
            ),
            const SizedBox(height: AppSpacing.smPlus),
            SegmentedPill(
              semanticLabel: strings.sounds_timer,
              labels: timerLabels,
              selected: SleepSoundTimer.options.indexOf(state.timerMinutes),
              onChanged: (i) => controller.setTimer(SleepSoundTimer.options[i]),
            ),
          ],
        ),
        if (status != null)
          Semantics(
            liveRegion: true,
            child: Text(
              status,
              textAlign: TextAlign.center,
              style: text.bodyStrong,
            ),
          ),
        Text(
          strings.sounds_note,
          textAlign: TextAlign.center,
          style: text.caption.copyWith(color: colors.textSecondary),
        ),
        const _BreathCard(),
      ],
    );
  }
}

class _SoundTile extends StatelessWidget {
  const _SoundTile({
    required this.sound,
    required this.selected,
    required this.playing,
    required this.onPressed,
  });

  final SleepSound sound;
  final bool selected;
  final bool playing;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final colors = context.colors;
    final text = context.text;
    return Pressable(
      onPressed: onPressed,
      selected: selected,
      semanticLabel: '${sound.label(strings)}, ${sound.note(strings)}',
      excludeChildSemantics: true,
      child: AnimatedContainer(
        duration: AppMotion.toggle,
        padding: const EdgeInsets.all(AppSpacing.mdPlus),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: AppRadius.lgAll,
          border: Border.all(
            color: selected ? colors.espresso : colors.surface,
            width: AppSizes.checkStroke,
          ),
        ),
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
                    color: sound.color,
                    shape: BoxShape.circle,
                  ),
                  child: AppIcon(
                    sound.icon,
                    color: SleepStageColors.creamIcon,
                    size: AppSizes.iconStep,
                  ),
                ),
                const Spacer(),
                if (selected && playing)
                  AppIcon(
                    AppIcons.speaker,
                    color: colors.textPrimary,
                    size: AppSizes.iconSmall,
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(sound.label(strings), style: text.rowLabel),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              sound.note(strings),
              style: text.note.copyWith(color: colors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _BreathCard extends StatelessWidget {
  const _BreathCard();

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final colors = context.colors;
    final text = context.text;
    return SurfaceCard(
      radius: AppRadius.lgAll,
      child: Row(
        children: [
          Container(
            width: AppSizes.tipIcon,
            height: AppSizes.tipIcon,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.sageTint,
              shape: BoxShape.circle,
            ),
            child: AppIcon(AppIcons.breath, color: colors.sageText),
          ),
          const SizedBox(width: AppSpacing.mdPlus),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(strings.breathe_title, style: text.cardTitle),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  strings.breathe_intro,
                  style: text.bodySmall.copyWith(color: colors.textSecondary),
                ),
                LinkButton(
                  label: strings.breathe_start,
                  onPressed: () => context.push(AppRoutes.breathe),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
