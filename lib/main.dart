import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uyku/core/notifications/notification_service.dart';
import 'package:uyku/core/providers/core_providers.dart';
import 'package:uyku/core/router/app_router.dart';
import 'package:uyku/core/strings/app_strings.dart';
import 'package:uyku/core/theme/app_theme.dart';
import 'package:uyku/features/settings/domain/user_settings.dart';
import 'package:uyku/features/settings/presentation/settings_controller.dart';
import 'package:uyku/features/sleep_log/presentation/sleep_log_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final notifications = kIsWeb
      ? NoopNotificationService()
      : LocalNotificationService();
  unawaited(notifications.init());
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        notificationServiceProvider.overrideWithValue(notifications),
      ],
      child: const UykuApp(),
    ),
  );
}

class UykuApp extends ConsumerStatefulWidget {
  const UykuApp({super.key});

  @override
  ConsumerState<UykuApp> createState() => _UykuAppState();
}

class _UykuAppState extends ConsumerState<UykuApp> {
  late final AppLifecycleListener _lifecycle;
  StreamSubscription<String>? _taps;

  @override
  void initState() {
    super.initState();
    // Planlı bildirimleri güncel ayarlarla yeniden kur (yeni sürümle gelen
    // haftalık rapor dahil).
    unawaited(ref.read(settingsControllerProvider.notifier).syncReminder());
    // Bildirime dokunulunca ilgili ekranı aç (ör. haftalık rapor).
    final notifications = ref.read(notificationServiceProvider);
    _taps = notifications.routeTaps.listen(_openRoute);
    unawaited(
      notifications.launchRoute().then((route) {
        if (route != null) _openRoute(route);
      }),
    );
    // Gün değişmiş olabilir: öne gelince "bugün"ü yenile.
    _lifecycle = AppLifecycleListener(
      onResume: () => ref.invalidate(todayProvider),
    );
  }

  void _openRoute(String route) {
    if (mounted) unawaited(ref.read(appRouterProvider).push(route));
  }

  @override
  void dispose() {
    unawaited(_taps?.cancel());
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsControllerProvider);
    return MaterialApp.router(
      onGenerateTitle: (context) => AppStrings.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: switch (settings.theme) {
        ThemePreference.system => ThemeMode.system,
        ThemePreference.light => ThemeMode.light,
        ThemePreference.dark => ThemeMode.dark,
      },
      locale: AppStrings.locale,
      localizationsDelegates: AppStrings.localizationsDelegates,
      supportedLocales: AppStrings.supportedLocales,
      routerConfig: ref.watch(appRouterProvider),
    );
  }
}
