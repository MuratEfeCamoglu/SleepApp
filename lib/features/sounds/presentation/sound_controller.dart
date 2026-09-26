import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uyku/core/providers/core_providers.dart';
import 'package:uyku/features/sounds/data/sound_player.dart';
import 'package:uyku/features/sounds/domain/sleep_sound.dart';

final soundPlayerProvider = Provider<SoundPlayer>((ref) {
  final player = JustAudioSoundPlayer();
  ref.onDispose(player.dispose);
  return player;
});

@immutable
class SoundState {
  const SoundState({
    this.sound = SleepSound.music,
    this.playing = false,
    this.timerMinutes = SleepSoundTimer.defaultMinutes,
    this.endsAt,
  });

  final SleepSound sound;
  final bool playing;

  /// Seçili zamanlayıcı; null → kapanmaz.
  final int? timerMinutes;

  /// Çalarken zamanlayıcının biteceği an.
  final DateTime? endsAt;

  SoundState copyWith({
    SleepSound? sound,
    bool? playing,
    int? Function()? timerMinutes,
    DateTime? Function()? endsAt,
  }) => SoundState(
    sound: sound ?? this.sound,
    playing: playing ?? this.playing,
    timerMinutes: timerMinutes == null ? this.timerMinutes : timerMinutes(),
    endsAt: endsAt == null ? this.endsAt : endsAt(),
  );
}

/// Uygulama boyunca yaşar: ekranlar arasında gezinirken ses sürer.
final soundControllerProvider = NotifierProvider<SoundController, SoundState>(
  SoundController.new,
);

class SoundController extends Notifier<SoundState> {
  Timer? _stopTimer;
  Timer? _fadeTimer;

  SoundPlayer get _player => ref.read(soundPlayerProvider);

  @override
  SoundState build() {
    ref.onDispose(_cancelTimers);
    return const SoundState();
  }

  void _cancelTimers() {
    _stopTimer?.cancel();
    _fadeTimer?.cancel();
  }

  Future<void> play([SleepSound? sound]) async {
    final next = sound ?? state.sound;
    _cancelTimers();
    await _player.play(next.asset);
    state = state.copyWith(sound: next, playing: true);
    _armTimer();
  }

  Future<void> stop() async {
    _cancelTimers();
    await _player.stop();
    state = state.copyWith(playing: false, endsAt: () => null);
  }

  /// Çalıyorsa yeni sese geçer; durmuşsa yalnızca seçer.
  Future<void> select(SleepSound sound) async {
    if (state.playing) {
      await play(sound);
    } else {
      state = state.copyWith(sound: sound);
    }
  }

  void setTimer(int? minutes) {
    state = state.copyWith(timerMinutes: () => minutes);
    if (state.playing) {
      _cancelTimers();
      _armTimer();
    }
  }

  void _armTimer() {
    final minutes = state.timerMinutes;
    if (minutes == null) {
      state = state.copyWith(endsAt: () => null);
      return;
    }
    final duration = Duration(minutes: minutes);
    state = state.copyWith(
      endsAt: () => ref.read(clockProvider).now().add(duration),
    );
    _stopTimer = Timer(duration, _fadeAndStop);
  }

  /// Sesi [SleepSoundTimer.fadeOut] boyunca kısıp durdurur.
  void _fadeAndStop() {
    const steps = 16;
    var step = 0;
    _fadeTimer = Timer.periodic(SleepSoundTimer.fadeOut ~/ steps, (t) {
      step++;
      if (step >= steps) {
        t.cancel();
        unawaited(stop());
        return;
      }
      unawaited(_player.setVolume(1 - step / steps));
    });
  }
}
