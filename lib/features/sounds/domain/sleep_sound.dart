/// Uyku müzikleri; `assets/sounds/` altındaki MP3 dosyaları.
enum SleepSound {
  music('sleep_music'),
  piano('piano'),
  cycle('sleep_cycle'),
  lofi('lofi');

  const SleepSound(this.file);

  final String file;

  String get asset => 'assets/sounds/$file.mp3';
}

abstract final class SleepSoundTimer {
  /// Zamanlayıcı seçenekleri (dk); null → kapanmaz.
  static const options = <int?>[15, 30, 60, null];

  static const defaultMinutes = 30;

  /// Zamanlayıcı bitince ses bu sürede kısılarak durur.
  static const fadeOut = Duration(seconds: 8);
}
