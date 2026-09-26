import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Bildirim metinleri seçili dilde çağıran taraftan gelir.
typedef NotificationText = ({String title, String body, String channel});

/// `weekday` günü (`DateTime.monday`…`sunday`) `minute` dakikasında.
typedef ReminderTime = ({int weekday, int minute});

abstract class NotificationService {
  Future<void> init();
  Future<bool> requestPermission();
  Future<bool> permissionGranted();

  /// Sistem bildirim ayarlarını açar (izin kalıcı reddedildiğinde).
  Future<void> openSystemSettings();

  /// Haftanın her günü için ayrı tekrarlanan hatırlatıcı; hafta sonu
  /// esnekliğinde cuma ve cumartesi saatleri farklıdır.
  Future<void> scheduleBedtimeReminders(
    List<ReminderTime> times,
    NotificationText text,
  );
  Future<void> cancelBedtimeReminder();
  Future<void> scheduleWakeAlarm(DateTime at, NotificationText text);
  Future<void> cancelWakeAlarm();

  /// Her pazar [minuteOfDay]'de; dokununca [route] açılır.
  Future<void> scheduleWeeklyReport(
    int minuteOfDay,
    String route,
    NotificationText text,
  );
  Future<void> cancelWeeklyReport();

  /// Uygulama açıkken dokunulan bildirimin rotası.
  Stream<String> get routeTaps;

  /// Uygulamayı bir bildirim açtıysa onun rotası.
  Future<String?> launchRoute();
}

/// Web ve testler için: hiçbir şey yapmaz, izin verilmiş sayılır.
class NoopNotificationService implements NotificationService {
  @override
  Future<void> init() async {}
  @override
  Future<bool> requestPermission() async => true;
  @override
  Future<bool> permissionGranted() async => true;
  @override
  Future<void> openSystemSettings() async {}
  @override
  Future<void> scheduleBedtimeReminders(
    List<ReminderTime> times,
    NotificationText text,
  ) async {}
  @override
  Future<void> cancelBedtimeReminder() async {}
  @override
  Future<void> scheduleWakeAlarm(DateTime at, NotificationText text) async {}
  @override
  Future<void> cancelWakeAlarm() async {}
  @override
  Future<void> scheduleWeeklyReport(
    int minuteOfDay,
    String route,
    NotificationText text,
  ) async {}
  @override
  Future<void> cancelWeeklyReport() async {}
  @override
  Stream<String> get routeTaps => const Stream.empty();
  @override
  Future<String?> launchRoute() async => null;
}

class LocalNotificationService implements NotificationService {
  final _plugin = FlutterLocalNotificationsPlugin();
  final _taps = StreamController<String>.broadcast();
  bool _ready = false;

  /// Eski sürümdeki tek günlük hatırlatıcı; yalnızca iptal için.
  static const _legacyBedtimeId = 1;

  /// Haftalık hatırlatıcılar: 10 + gece sırası. Gün değil gece sırası
  /// kullanılır; gece yarısını geçen yatışlarda iki hatırlatıcı aynı takvim
  /// gününe düşebilir.
  static const _bedtimeBaseId = 10;
  static const _alarmId = 2;
  static const _weeklyId = 3;

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  @override
  Future<void> init() async {
    if (_ready) return;
    tzdata.initializeTimeZones();
    try {
      final zone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zone.identifier));
    } on Exception catch (e) {
      debugPrint('Saat dilimi alınamadı, UTC kullanılıyor: $e');
    }
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (response) {
        final route = response.payload;
        if (route != null && route.isNotEmpty) _taps.add(route);
      },
    );
    _ready = true;
  }

  @override
  Stream<String> get routeTaps => _taps.stream;

  @override
  Future<String?> launchRoute() async {
    await init();
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details == null || !details.didNotificationLaunchApp) return null;
    final route = details.notificationResponse?.payload;
    return route == null || route.isEmpty ? null : route;
  }

  @override
  Future<bool> requestPermission() async {
    await init();
    final android = _android;
    if (android != null) {
      final ok = await android.requestNotificationsPermission() ?? false;
      if (ok && !(await android.canScheduleExactNotifications() ?? true)) {
        await android.requestExactAlarmsPermission();
      }
      return ok;
    }
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    return await ios?.requestPermissions(
          alert: true,
          sound: true,
          badge: true,
        ) ??
        false;
  }

  @override
  Future<bool> permissionGranted() async {
    await init();
    return await _android?.areNotificationsEnabled() ?? true;
  }

  @override
  Future<void> openSystemSettings() async {
    await init();
    await _plugin.openAppNotificationSettings();
  }

  Future<AndroidScheduleMode> _mode() async =>
      await _android?.canScheduleExactNotifications() ?? false
      ? AndroidScheduleMode.exactAllowWhileIdle
      : AndroidScheduleMode.inexactAllowWhileIdle;

  @override
  Future<void> scheduleBedtimeReminders(
    List<ReminderTime> times,
    NotificationText text,
  ) async {
    await cancelBedtimeReminder();
    final now = tz.TZDateTime.now(tz.local);
    for (var i = 0; i < times.length; i++) {
      final t = times[i];
      var at = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        t.minute ~/ 60,
        t.minute % 60,
      );
      while (at.weekday != t.weekday || !at.isAfter(now)) {
        at = tz.TZDateTime(
          tz.local,
          at.year,
          at.month,
          at.day + 1,
          at.hour,
          at.minute,
        );
      }
      await _plugin.zonedSchedule(
        id: _bedtimeBaseId + i,
        title: text.title,
        body: text.body,
        scheduledDate: at,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails('bedtime', text.channel),
          iOS: const DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    }
  }

  @override
  Future<void> cancelBedtimeReminder() async {
    await init();
    await _plugin.cancel(id: _legacyBedtimeId);
    for (var d = 0; d < 7; d++) {
      await _plugin.cancel(id: _bedtimeBaseId + d);
    }
  }

  @override
  Future<void> scheduleWakeAlarm(DateTime at, NotificationText text) async {
    await init();
    await _plugin.zonedSchedule(
      id: _alarmId,
      title: text.title,
      body: text.body,
      scheduledDate: tz.TZDateTime.from(at, tz.local),
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          'wake_alarm',
          text.channel,
          importance: Importance.max,
          priority: Priority.max,
          category: AndroidNotificationCategory.alarm,
          audioAttributesUsage: AudioAttributesUsage.alarm,
        ),
        iOS: const DarwinNotificationDetails(presentSound: true),
      ),
      androidScheduleMode: await _mode(),
    );
  }

  @override
  Future<void> cancelWakeAlarm() async {
    await init();
    await _plugin.cancel(id: _alarmId);
  }

  @override
  Future<void> scheduleWeeklyReport(
    int minuteOfDay,
    String route,
    NotificationText text,
  ) async {
    await init();
    final now = tz.TZDateTime.now(tz.local);
    var at = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      minuteOfDay ~/ 60,
      minuteOfDay % 60,
    );
    while (at.weekday != DateTime.sunday || !at.isAfter(now)) {
      at = tz.TZDateTime(
        tz.local,
        at.year,
        at.month,
        at.day + 1,
        at.hour,
        at.minute,
      );
    }
    await _plugin.zonedSchedule(
      id: _weeklyId,
      title: text.title,
      body: text.body,
      scheduledDate: at,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails('weekly_report', text.channel),
        iOS: const DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      payload: route,
    );
  }

  @override
  Future<void> cancelWeeklyReport() async {
    await init();
    await _plugin.cancel(id: _weeklyId);
  }
}
