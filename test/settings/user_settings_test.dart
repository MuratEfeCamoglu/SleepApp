import 'package:flutter_test/flutter_test.dart';
import 'package:uyku/features/chronotype/domain/chronotype.dart';
import 'package:uyku/features/settings/domain/user_settings.dart';

void main() {
  group('UserSettings JSON', () {
    test('varsayılanlar gidiş-dönüş', () {
      const settings = UserSettings();
      expect(UserSettings.fromJson(settings.toJson()), settings);
    });

    test('tüm alanlar dolu gidiş-dönüş', () {
      final settings = UserSettings(
        goalMinutes: 7 * 60 + 45,
        bedtimeMinute: 23 * 60 + 30,
        reminderEnabled: false,
        theme: ThemePreference.dark,
        onboardingDone: true,
        trackingStart: DateTime(2026, 9, 24, 23, 12),
        chronotype: Chronotype.evening,
        weeklyReport: false,
        smartAlarm: false,
        weekendShift: 60,
      );
      expect(UserSettings.fromJson(settings.toJson()), settings);
    });

    test('boş JSON varsayılanlara düşer', () {
      expect(
        UserSettings.fromJson(const <String, dynamic>{}),
        const UserSettings(),
      );
    });

    test('bilinmeyen tema sisteme düşer', () {
      final settings = UserSettings.fromJson(const {'theme': 'neon'});
      expect(settings.theme, ThemePreference.system);
    });
  });

  test('copyWith null vererek trackingStart temizlenir', () {
    final settings = UserSettings(trackingStart: DateTime(2026, 9, 24, 23));
    expect(settings.copyWith(trackingStart: null).trackingStart, isNull);
    expect(settings.copyWith().trackingStart, settings.trackingStart);
  });

  test('uyanış hedefi gece yarısını sarar', () {
    const settings = UserSettings(bedtimeMinute: 23 * 60, goalMinutes: 9 * 60);
    expect(settings.wakeMinute, 8 * 60);
  });
}
