import 'package:intl/intl.dart';
import 'package:uyku/core/strings/app_strings.dart';

/// Gün içindeki dakika sayısı.
const int minutesPerDay = 24 * 60;

/// Değeri gün içine sarar (−10 → 1430).
int wrapMinute(int minute) =>
    ((minute % minutesPerDay) + minutesPerDay) % minutesPerDay;

/// Gün içi dakikayı `HH:mm` biçiminde yazar.
String formatClock(int minuteOfDay) {
  final m = wrapMinute(minuteOfDay);
  final h = (m ~/ 60).toString().padLeft(2, '0');
  final mm = (m % 60).toString().padLeft(2, '0');
  return '$h:$mm';
}

String formatClockOf(DateTime time) => formatClock(minuteOfDayOf(time));

int minuteOfDayOf(DateTime time) => time.hour * 60 + time.minute;

/// `06:30 – 07:00`
String formatClockRange(AppStrings strings, int start, int end) =>
    strings.time_range(formatClock(start), formatClock(end));

/// `7s 42dk` — negatif değerler sıfıra çekilir.
String formatDuration(AppStrings strings, int minutes) {
  final m = minutes < 0 ? 0 : minutes;
  return strings.duration_hm(m ~/ 60, m % 60);
}

/// `8s` ya da `7s 30dk` — tam saatlerde dakika yazılmaz.
String formatDurationShort(AppStrings strings, int minutes) {
  final m = minutes < 0 ? 0 : minutes;
  if (m % 60 == 0) return strings.duration_h(m ~/ 60);
  if (m < 60) return strings.duration_m(m);
  return strings.duration_hm(m ~/ 60, m % 60);
}

/// Evre değeri: `1:54`.
String formatStage(int minutes) {
  final m = minutes < 0 ? 0 : minutes;
  return '${m ~/ 60}:${(m % 60).toString().padLeft(2, '0')}';
}

/// Hedef saat: `8`, `7,5`, `8,25` (TR'de virgül).
String formatHours(String locale, int minutes) =>
    NumberFormat('0.##', locale).format(minutes / 60);

/// `8 saat`
String formatGoal(AppStrings strings, String locale, int minutes) =>
    strings.duration_goal(formatHours(locale, minutes));

/// `+24 dk` / `−18 dk`
String formatDelta(AppStrings strings, int minutes) {
  final sign = minutes > 0
      ? '+'
      : minutes < 0
      ? '−'
      : '±';
  return strings.delta_value(sign, minutes.abs());
}
