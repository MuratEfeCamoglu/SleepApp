import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uyku/core/notifications/notification_service.dart';
import 'package:uyku/core/providers/core_providers.dart';
import 'package:uyku/core/router/app_router.dart';
import 'package:uyku/core/strings/app_strings.dart';
import 'package:uyku/features/chronotype/domain/chronotype.dart';
import 'package:uyku/features/settings/data/local_settings_repository.dart';
import 'package:uyku/features/settings/domain/settings_repository.dart';
import 'package:uyku/features/settings/domain/user_settings.dart';
import 'package:uyku/features/sleep_log/domain/sleep_entry.dart';
import 'package:uyku/features/track_sleep/domain/alarm_plan.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => LocalSettingsRepository(ref.watch(sharedPreferencesProvider)),
);

/// Ayarları tutar; değişiklikte kaydeder ve bildirimleri yeniden kurar.
final settingsControllerProvider =
    NotifierProvider<SettingsController, UserSettings>(SettingsController.new);

class SettingsController extends Notifier<UserSettings> {
  @override
  UserSettings build() => ref.watch(settingsRepositoryProvider).load();

  Future<void> _update(UserSettings next, {bool syncReminder = false}) async {
    state = next;
    await ref.read(settingsRepositoryProvider).save(next);
    if (syncReminder) await this.syncReminder();
  }

  Future<void> setGoal(int minutes) => _update(
    state.copyWith(
      goalMinutes: minutes.clamp(UserSettings.minGoal, UserSettings.maxGoal),
    ),
  );

  Future<void> setBedtime(int minute) =>
      _update(state.copyWith(bedtimeMinute: minute), syncReminder: true);

  Future<void> setTheme(ThemePreference theme) =>
      _update(state.copyWith(theme: theme));

  /// Açarken izin ister; izin yoksa ayar yine kaydedilir, ekran uyarı
  /// gösterir.
  Future<void> setReminder({required bool enabled}) async {
    if (enabled) {
      await ref.read(notificationServiceProvider).requestPermission();
    }
    await _update(state.copyWith(reminderEnabled: enabled), syncReminder: true);
  }

  /// Hedef ayarları ekranı: hepsini tek seferde kaydeder.
  Future<void> setGoals({
    required int goalMinutes,
    required int bedtimeMinute,
    required int weekendShift,
  }) => _update(
    state.copyWith(
      goalMinutes: goalMinutes.clamp(
        UserSettings.minGoal,
        UserSettings.maxGoal,
      ),
      bedtimeMinute: bedtimeMinute,
      weekendShift: weekendShift,
    ),
    syncReminder: true,
  );

  Future<void> setChronotype(Chronotype? type) =>
      _update(state.copyWith(chronotype: type));

  Future<void> setWeeklyReport({required bool enabled}) async {
    if (enabled) {
      await ref.read(notificationServiceProvider).requestPermission();
    }
    await _update(state.copyWith(weeklyReport: enabled), syncReminder: true);
  }

  Future<void> setSmartAlarm({required bool enabled}) =>
      _update(state.copyWith(smartAlarm: enabled));

  Future<void> setWeekendShift(int minutes) =>
      _update(state.copyWith(weekendShift: minutes), syncReminder: true);

  Future<void> completeOnboarding() =>
      _update(state.copyWith(onboardingDone: true), syncReminder: true);

  Future<void> startTracking(DateTime start) async {
    await _update(state.copyWith(trackingStart: start));
    const strings = AppStrings.instance;
    await ref
        .read(notificationServiceProvider)
        .scheduleWakeAlarm(AlarmPlan.forStart(state, start).at, (
          title: strings.notif_alarmTitle,
          body: strings.notif_alarmBody,
          channel: strings.notif_alarmChannel,
        ));
  }

  Future<void> stopTracking() async {
    await _update(state.copyWith(trackingStart: null));
    await ref.read(notificationServiceProvider).cancelWakeAlarm();
  }

  Future<void> syncReminder() async {
    final service = ref.read(notificationServiceProvider);
    await _syncWeeklyReport(service);
    if (!state.reminderEnabled || !state.onboardingDone) {
      await service.cancelBedtimeReminder();
      return;
    }
    const strings = AppStrings.instance;
    await service.scheduleBedtimeReminders(reminderTimes(state), (
      title: strings.notif_bedtimeTitle,
      body: strings.notif_bedtimeBody,
      channel: strings.notif_bedtimeChannel,
    ));
  }

  /// Haftanın her akşamı için hatırlatıcı anı. Yatış gece yarısından
  /// sonraysa hatırlatıcı ertesi takvim gününe düşebilir.
  static List<ReminderTime> reminderTimes(UserSettings settings) {
    final monday = DateTime(2024); // 1 Ocak 2024 pazartesi.
    return [
      for (var i = 0; i < 7; i++)
        () {
          final night = addDays(monday, i);
          final bed = settings.bedtimeFor(night);
          final at = night.add(
            Duration(
              days: bed < 12 * 60 ? 1 : 0,
              minutes: bed - UserSettings.reminderLead,
            ),
          );
          return (weekday: at.weekday, minute: at.hour * 60 + at.minute);
        }(),
    ];
  }

  /// Pazar 09:00; dokununca rapor ekranı açılır.
  static const int weeklyReportMinute = 9 * 60;

  Future<void> _syncWeeklyReport(NotificationService service) async {
    if (!state.weeklyReport || !state.onboardingDone) {
      await service.cancelWeeklyReport();
      return;
    }
    const s = AppStrings.instance;
    await service.scheduleWeeklyReport(weeklyReportMinute, AppRoutes.report, (
      title: s.notif_weeklyTitle,
      body: s.notif_weeklyBody,
      channel: s.notif_weeklyChannel,
    ));
  }
}
