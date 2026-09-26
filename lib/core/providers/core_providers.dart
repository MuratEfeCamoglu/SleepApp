import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uyku/core/notifications/notification_service.dart';

/// `main` içinde yüklenen örnekle override edilir.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) =>
      throw UnimplementedError('sharedPreferencesProvider override edilmeli'),
);

/// Şimdiki zaman; tek noktadan okunur.
class Clock {
  const Clock();

  DateTime now() => DateTime.now();
}

final clockProvider = Provider<Clock>((ref) => const Clock());

/// Web'de no-op; `main` gerçek servisle override eder.
final notificationServiceProvider = Provider<NotificationService>(
  (ref) => NoopNotificationService(),
);
