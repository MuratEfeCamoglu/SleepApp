import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';

/// Döngüde tek ses çalar.
abstract interface class SoundPlayer {
  Future<void> play(String asset);
  Future<void> stop();
  Future<void> setVolume(double volume);
  Future<void> dispose();
}

class JustAudioSoundPlayer implements SoundPlayer {
  final _player = AudioPlayer();
  bool _sessionReady = false;
  String? _loaded;

  Future<void> _ensureSession() async {
    if (_sessionReady) return;
    // Ekran kilitliyken de çalsın, diğer seslerle karışmasın.
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
    _sessionReady = true;
  }

  @override
  Future<void> play(String asset) async {
    await _ensureSession();
    if (_loaded != asset) {
      await _player.setAsset(asset);
      await _player.setLoopMode(LoopMode.one);
      _loaded = asset;
    }
    await _player.setVolume(1);
    // `play` çalma bitene kadar tamamlanmaz; beklemeden bırak.
    _player.play().ignore();
  }

  @override
  Future<void> stop() => _player.pause();

  @override
  Future<void> setVolume(double volume) => _player.setVolume(volume);

  @override
  Future<void> dispose() => _player.dispose();
}
