import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uyku/core/strings/app_strings.dart';
import 'package:uyku/core/theme/app_sizes.dart';
import 'package:uyku/core/theme/app_spacing.dart';
import 'package:uyku/core/theme/app_theme.dart';
import 'package:uyku/core/theme/sleep_stage_colors.dart';
import 'package:uyku/core/widgets/app_icon.dart';
import 'package:uyku/core/widgets/full_page.dart';
import 'package:uyku/core/widgets/primary_pill_button.dart';
import 'package:uyku/core/widgets/state_views.dart';
import 'package:uyku/features/routine/domain/routine_repository.dart';
import 'package:uyku/features/routine/presentation/routine_providers.dart';

enum _Phase { inhale, hold, exhale }

/// 4-7-8 nefes: 4 sn al, 7 sn tut, 8 sn ver; dört tur.
class BreatheScreen extends ConsumerStatefulWidget {
  const BreatheScreen({super.key});

  static const inhale = 4;
  static const hold = 7;
  static const exhale = 8;
  static const rounds = 4;
  static const int cycle = inhale + hold + exhale;

  /// Dairenin nefes verilmişken küçüldüğü oran.
  static const minScale = 0.55;

  @override
  ConsumerState<BreatheScreen> createState() => _BreatheScreenState();
}

class _BreatheScreenState extends ConsumerState<BreatheScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: BreatheScreen.cycle),
  );
  int _round = 0;
  bool _running = false;
  bool _done = false;
  _Phase? _lastPhase;

  @override
  void initState() {
    super.initState();
    _c
      ..addListener(_onTick)
      ..addStatusListener((status) {
        if (status != AnimationStatus.completed) return;
        if (_round < BreatheScreen.rounds - 1) {
          setState(() => _round++);
          _c.forward(from: 0);
        } else {
          unawaited(_finish());
        }
      });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  double get _seconds => _c.value * BreatheScreen.cycle;

  _Phase get _phase {
    final t = _seconds;
    if (t < BreatheScreen.inhale) return _Phase.inhale;
    if (t < BreatheScreen.inhale + BreatheScreen.hold) return _Phase.hold;
    return _Phase.exhale;
  }

  /// Evrenin bitmesine kalan tam saniye.
  int get _remaining {
    final t = _seconds;
    final end = switch (_phase) {
      _Phase.inhale => BreatheScreen.inhale,
      _Phase.hold => BreatheScreen.inhale + BreatheScreen.hold,
      _Phase.exhale => BreatheScreen.cycle,
    };
    return (end - t).ceil().clamp(1, BreatheScreen.exhale);
  }

  double get _scale {
    const min = BreatheScreen.minScale;
    final t = _seconds;
    return switch (_phase) {
      _Phase.inhale =>
        min + (1 - min) * Curves.easeInOut.transform(t / BreatheScreen.inhale),
      _Phase.hold => 1,
      _Phase.exhale =>
        1 -
            (1 - min) *
                Curves.easeInOut.transform(
                  (t - BreatheScreen.inhale - BreatheScreen.hold) /
                      BreatheScreen.exhale,
                ),
    };
  }

  void _onTick() {
    if (!_running) return;
    final phase = _phase;
    if (phase != _lastPhase) {
      _lastPhase = phase;
      unawaited(HapticFeedback.selectionClick());
    }
    setState(() {});
  }

  void _start() {
    setState(() {
      _round = 0;
      _running = true;
      _done = false;
      _lastPhase = null;
    });
    _c.forward(from: 0);
  }

  void _stop() {
    _c.stop();
    setState(() => _running = false);
  }

  Future<void> _finish() async {
    setState(() {
      _running = false;
      _done = true;
    });
    unawaited(HapticFeedback.lightImpact());
    await ref
        .read(routineProgressProvider.notifier)
        .markDone(routineBreathStep);
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final colors = context.colors;
    final text = context.text;
    final reduced = MediaQuery.disableAnimationsOf(context);

    if (_done) {
      return FullPage(
        eyebrow: strings.breathe_eyebrow,
        title: strings.breathe_title,
        bottom: PrimaryPillButton(
          label: strings.breathe_again,
          onPressed: _start,
        ),
        children: [
          const SizedBox(height: AppSpacing.xxl),
          const IconBadge(
            icon: AppIcons.checkBold,
            background: SleepStageColors.sageDeep,
            foreground: SleepStageColors.creamIcon,
          ),
          Semantics(
            header: true,
            child: Text(
              strings.breathe_doneTitle,
              textAlign: TextAlign.center,
              style: text.titleLarge,
            ),
          ),
          Text(
            strings.breathe_doneBody,
            textAlign: TextAlign.center,
            style: text.bodyLarge.copyWith(color: colors.textSecondary),
          ),
        ],
      );
    }

    final phaseLabel = switch (_phase) {
      _Phase.inhale => strings.breathe_in,
      _Phase.hold => strings.breathe_hold,
      _Phase.exhale => strings.breathe_out,
    };
    final scale = _running ? (reduced ? 1.0 : _scale) : BreatheScreen.minScale;

    return FullPage(
      eyebrow: strings.breathe_eyebrow,
      title: strings.breathe_title,
      bottom: _running
          ? Center(
              child: OutlinePillButton(
                label: strings.breathe_stop,
                onPressed: _stop,
              ),
            )
          : PrimaryPillButton(
              label: strings.breathe_start,
              icon: AppIcons.play,
              onPressed: _start,
            ),
      children: [
        Text(
          strings.breathe_intro,
          style: text.bodyLarge.copyWith(color: colors.textSecondary),
        ),
        Center(
          child: SizedBox(
            width: AppSizes.todayRing,
            height: AppSizes.todayRing,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors.surfaceMuted,
                  ),
                ),
                Transform.scale(
                  scale: scale,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colors.sageTint,
                      border: Border.all(
                        color: SleepStageColors.sageDeep,
                        width: AppSizes.checkStroke,
                      ),
                    ),
                  ),
                ),
                if (_running)
                  Semantics(
                    liveRegion: true,
                    label: phaseLabel,
                    excludeSemantics: true,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          phaseLabel,
                          style: text.titleMedium.copyWith(
                            color: colors.sageText,
                          ),
                        ),
                        Text(
                          '$_remaining',
                          style: text.displayNumber.copyWith(
                            color: colors.sageText,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (_running)
          Text(
            strings.breathe_round(_round + 1, BreatheScreen.rounds),
            textAlign: TextAlign.center,
            style: text.bodyStrong.copyWith(color: colors.textSecondary),
          ),
      ],
    );
  }
}
