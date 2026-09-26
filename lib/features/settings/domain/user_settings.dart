import 'package:flutter/foundation.dart';
import 'package:uyku/features/chronotype/domain/chronotype.dart';

enum ThemePreference { system, light, dark }

/// Kullanıcı tercihleri. Uyanış hedefi = yatış + hedef süre.
@immutable
class UserSettings {
  const UserSettings({
    this.goalMinutes = UserSettings.defaultGoal,
    this.bedtimeMinute = UserSettings.defaultBedtime,
    this.reminderEnabled = true,
    this.theme = ThemePreference.system,
    this.onboardingDone = false,
    this.trackingStart,
    this.chronotype,
    this.weeklyReport = true,
    this.smartAlarm = true,
    this.weekendShift = 0,
  });

  factory UserSettings.fromJson(Map<String, dynamic> json) => UserSettings(
    goalMinutes: (json['goalMinutes'] as num?)?.toInt() ?? defaultGoal,
    bedtimeMinute: (json['bedtimeMinute'] as num?)?.toInt() ?? defaultBedtime,
    reminderEnabled: json['reminderEnabled'] as bool? ?? true,
    theme:
        ThemePreference.values.asNameMap()[json['theme']] ??
        ThemePreference.system,
    onboardingDone: json['onboardingDone'] as bool? ?? false,
    trackingStart: json['trackingStart'] == null
        ? null
        : DateTime.parse(json['trackingStart'] as String),
    chronotype: Chronotype.values.asNameMap()[json['chronotype']],
    weeklyReport: json['weeklyReport'] as bool? ?? true,
    smartAlarm: json['smartAlarm'] as bool? ?? true,
    weekendShift: (json['weekendShift'] as num?)?.toInt() ?? 0,
  );

  final int goalMinutes;
  final int bedtimeMinute;
  final bool reminderEnabled;
  final ThemePreference theme;
  final bool onboardingDone;

  /// Uyku modu açıkken başlangıç anı.
  final DateTime? trackingStart;

  /// Kronotip testinin sonucu; test yapılmadıysa null.
  final Chronotype? chronotype;

  /// Pazar sabahı haftalık rapor bildirimi.
  final bool weeklyReport;

  /// Alarmı pencere içindeki tahmini hafif uyku anına kurar.
  final bool smartAlarm;

  /// Cuma ve cumartesi geceleri yatış ve uyanış bu kadar dakika kayar.
  final int weekendShift;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'goalMinutes': goalMinutes,
    'bedtimeMinute': bedtimeMinute,
    'reminderEnabled': reminderEnabled,
    'theme': theme.name,
    'onboardingDone': onboardingDone,
    'trackingStart': trackingStart?.toIso8601String(),
    'chronotype': chronotype?.name,
    'weeklyReport': weeklyReport,
    'smartAlarm': smartAlarm,
    'weekendShift': weekendShift,
  };

  static const _unset = Object();

  /// [trackingStart] ve [chronotype] için `null` vermek alanı temizler;
  /// vermemek korur.
  UserSettings copyWith({
    int? goalMinutes,
    int? bedtimeMinute,
    bool? reminderEnabled,
    ThemePreference? theme,
    bool? onboardingDone,
    Object? trackingStart = _unset,
    Object? chronotype = _unset,
    bool? weeklyReport,
    bool? smartAlarm,
    int? weekendShift,
  }) => UserSettings(
    goalMinutes: goalMinutes ?? this.goalMinutes,
    bedtimeMinute: bedtimeMinute ?? this.bedtimeMinute,
    reminderEnabled: reminderEnabled ?? this.reminderEnabled,
    theme: theme ?? this.theme,
    onboardingDone: onboardingDone ?? this.onboardingDone,
    trackingStart: identical(trackingStart, _unset)
        ? this.trackingStart
        : trackingStart as DateTime?,
    chronotype: identical(chronotype, _unset)
        ? this.chronotype
        : chronotype as Chronotype?,
    weeklyReport: weeklyReport ?? this.weeklyReport,
    smartAlarm: smartAlarm ?? this.smartAlarm,
    weekendShift: weekendShift ?? this.weekendShift,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserSettings &&
          other.goalMinutes == goalMinutes &&
          other.bedtimeMinute == bedtimeMinute &&
          other.reminderEnabled == reminderEnabled &&
          other.theme == theme &&
          other.onboardingDone == onboardingDone &&
          other.trackingStart == trackingStart &&
          other.chronotype == chronotype &&
          other.weeklyReport == weeklyReport &&
          other.smartAlarm == smartAlarm &&
          other.weekendShift == weekendShift;

  @override
  int get hashCode => Object.hash(
    goalMinutes,
    bedtimeMinute,
    reminderEnabled,
    theme,
    onboardingDone,
    trackingStart,
    chronotype,
    weeklyReport,
    smartAlarm,
    weekendShift,
  );

  static const int defaultGoal = 8 * 60;
  static const int defaultBedtime = 23 * 60 + 15;
  static const int minGoal = 5 * 60;
  static const int maxGoal = 11 * 60;
  static const goalStep = 15;

  /// Hafta sonu esnekliği seçenekleri (dk).
  static const weekendShiftOptions = [0, 30, 60, 90, 120];

  /// Hatırlatıcı yatıştan bu kadar önce gelir.
  static const reminderLead = 30;

  /// Uyku modu alarm penceresi uyanış hedefinden bu kadar önce açılır.
  static const alarmWindow = 30;

  int get wakeMinute => (bedtimeMinute + goalMinutes) % (24 * 60);

  int get reminderMinute =>
      (bedtimeMinute - reminderLead + 24 * 60) % (24 * 60);

  /// Cuma ve cumartesi akşamları hafta sonu gecesidir.
  static bool isWeekendNight(DateTime night) =>
      night.weekday == DateTime.friday || night.weekday == DateTime.saturday;

  int _shiftFor(DateTime night) => isWeekendNight(night) ? weekendShift : 0;

  /// [night] akşamı için hedef yatış (gün içi dakika).
  int bedtimeFor(DateTime night) =>
      (bedtimeMinute + _shiftFor(night)) % (24 * 60);

  /// [night] gecesinin sabahı için hedef uyanış (gün içi dakika).
  int wakeFor(DateTime night) =>
      (bedtimeMinute + _shiftFor(night) + goalMinutes) % (24 * 60);

  /// [night] akşamı için hatırlatıcı saati (gün içi dakika).
  int reminderFor(DateTime night) =>
      (bedtimeFor(night) - reminderLead + 24 * 60) % (24 * 60);
}
