import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uyku/core/providers/core_providers.dart';
import 'package:uyku/core/router/app_router.dart';
import 'package:uyku/core/strings/app_strings.dart';
import 'package:uyku/core/theme/app_theme.dart';
import 'package:uyku/core/widgets/app_icon.dart';
import 'package:uyku/core/widgets/circle_icon_button.dart';
import 'package:uyku/features/dreams/presentation/dream_detail_screen.dart';
import 'package:uyku/features/dreams/presentation/dream_interpret_screen.dart';
import 'package:uyku/features/dreams/presentation/dreams_screen.dart';
import 'package:uyku/features/routine/presentation/routine_screen.dart';
import 'package:uyku/features/settings/data/local_settings_repository.dart';
import 'package:uyku/features/settings/domain/user_settings.dart';
import 'package:uyku/features/sleep_log/data/local_sleep_repository.dart';
import 'package:uyku/features/sleep_log/domain/sleep_entry.dart';
import 'package:uyku/features/sleep_summary/presentation/app_shell.dart';

/// ISKELET §6'daki yeni rotalar (F9: `/dreams` sekme, `/routine` tam ekran).
final List<String> _newRoutes = [
  AppRoutes.premium,
  AppRoutes.health,
  AppRoutes.healthCheck,
  AppRoutes.dreams,
  AppRoutes.dreamNight('2026-10-19'),
  AppRoutes.dreamInterpret,
  AppRoutes.dreamInterpretNight('2026-10-19'),
  AppRoutes.routine,
];

Future<GoRouter> _pump(
  WidgetTester tester,
  UserSettings settings, {
  List<SleepEntry> entries = const [],
}) async {
  tester.view
    ..physicalSize = const Size(1170, 2532)
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({
    LocalSettingsRepository.storageKey: jsonEncode(settings.toJson()),
    if (entries.isNotEmpty)
      LocalSleepRepository.storageKey: jsonEncode([
        for (final e in entries) e.toJson(),
      ]),
  });
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
  addTearDown(container.dispose);
  final router = container.read(appRouterProvider);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        theme: AppTheme.light,
        locale: AppStrings.locale,
        supportedLocales: AppStrings.supportedLocales,
        localizationsDelegates: AppStrings.localizationsDelegates,
        routerConfig: router,
      ),
    ),
  );
  await _settle(tester);
  return router;
}

/// Uyku modu ekranında periyodik zamanlayıcı olduğundan pumpAndSettle yok.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
}

String _path(GoRouter router) =>
    router.routerDelegate.currentConfiguration.uri.path;

Future<String> _goTo(WidgetTester tester, GoRouter router, String loc) async {
  router.go(loc);
  await _settle(tester);
  return _path(router);
}

void main() {
  group('kurulum bitmeden', () {
    for (final loc in [..._newRoutes, AppRoutes.settings, AppRoutes.report]) {
      testWidgets('$loc → /onboarding', (tester) async {
        final router = await _pump(tester, const UserSettings());
        expect(_path(router), AppRoutes.onboarding);
        expect(await _goTo(tester, router, loc), AppRoutes.onboarding);
      });
    }

    testWidgets('/chronotype açılabilir', (tester) async {
      final router = await _pump(tester, const UserSettings());
      expect(
        await _goTo(tester, router, AppRoutes.chronotype),
        AppRoutes.chronotype,
      );
    });
  });

  group('Uyku modu açıkken', () {
    final tracking = UserSettings(
      onboardingDone: true,
      trackingStart: DateTime.now().subtract(const Duration(hours: 1)),
    );

    for (final loc in [..._newRoutes, AppRoutes.today, AppRoutes.report]) {
      testWidgets('$loc → /track', (tester) async {
        final router = await _pump(tester, tracking);
        expect(_path(router), AppRoutes.track);
        expect(await _goTo(tester, router, loc), AppRoutes.track);
      });
    }

    for (final loc in [AppRoutes.sounds, AppRoutes.breathe]) {
      testWidgets('$loc açılabilir', (tester) async {
        final router = await _pump(tester, tracking);
        expect(await _goTo(tester, router, loc), loc);
      });
    }
  });

  group('kurulum bitti, Uyku modu kapalı', () {
    const ready = UserSettings(onboardingDone: true);

    for (final loc in _newRoutes) {
      testWidgets('$loc açılır', (tester) async {
        final router = await _pump(tester, ready);
        expect(_path(router), AppRoutes.today);
        expect(await _goTo(tester, router, loc), Uri.parse(loc).path);
      });
    }

    testWidgets('/dreams kabuk sekmesidir; panelde "Rüya" seçili', (
      tester,
    ) async {
      final router = await _pump(tester, ready);
      expect(find.text(AppStrings.instance.nav_dreams), findsOneWidget);
      expect(find.text(AppStrings.instance.nav_routine), findsNothing);
      await tester.tap(find.text(AppStrings.instance.nav_dreams));
      await _settle(tester);
      expect(_path(router), AppRoutes.dreams);
      expect(find.byType(AppShell), findsOneWidget);
      expect(find.byType(DreamsScreen), findsOneWidget);
    });

    testWidgets('Rüya sekmesinde geri butonu yok', (tester) async {
      final router = await _pump(tester, ready);
      await _goTo(tester, router, AppRoutes.dreams);
      expect(find.byType(DreamsScreen), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (w) => w is CircleIconButton && w.icon == AppIcons.back,
        ),
        findsNothing,
      );
    });

    testWidgets('Bugün öneri kartı "Akşam rutinini aç" /routine push eder', (
      tester,
    ) async {
      final today = dateOnly(DateTime.now());
      final night = addDays(today, -1);
      final router = await _pump(
        tester,
        ready,
        entries: [
          SleepEntry(
            id: nightKey(night),
            bedtime: night.add(const Duration(hours: 23)),
            wake: today.add(const Duration(hours: 7)),
          ),
        ],
      );
      final link = find.text(AppStrings.instance.today_openRoutine);
      await tester.scrollUntilVisible(
        link,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      // Alt panelin altında kalmasın: biraz daha kaydır.
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -300));
      await _settle(tester);
      await tester.tap(link);
      await _settle(tester);
      expect(find.byType(RoutineScreen), findsOneWidget);
      expect(router.canPop(), isTrue, reason: 'push, go değil');
      // Push: geri dönünce Bugün kalır.
      router.pop();
      await _settle(tester);
      expect(find.byType(RoutineScreen), findsNothing);
      expect(_path(router), AppRoutes.today);
    });

    testWidgets('/routine kabuk dışı tam ekran, geri butonlu', (tester) async {
      final router = await _pump(tester, ready);
      unawaited(router.push(AppRoutes.routine));
      await _settle(tester);
      expect(find.byType(RoutineScreen), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (w) => w is CircleIconButton && w.icon == AppIcons.back,
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(AppShell),
          matching: find.byType(RoutineScreen),
        ),
        findsNothing,
      );
    });

    testWidgets('/dreams/interpret gece detayıyla çakışmaz', (tester) async {
      final router = await _pump(tester, ready);
      await _goTo(tester, router, AppRoutes.dreamInterpret);
      expect(find.byType(DreamInterpretScreen), findsOneWidget);
      expect(find.byType(DreamDetailScreen), findsNothing);

      await _goTo(tester, router, AppRoutes.dreamNight('2026-10-19'));
      expect(find.byType(DreamDetailScreen), findsOneWidget);
      expect(find.byType(DreamInterpretScreen), findsNothing);
    });

    testWidgets('bildirim payload rotası /report açılır', (tester) async {
      final router = await _pump(tester, ready);
      expect(await _goTo(tester, router, AppRoutes.report), AppRoutes.report);
    });

    testWidgets('/onboarding → /', (tester) async {
      final router = await _pump(tester, ready);
      expect(
        await _goTo(tester, router, AppRoutes.onboarding),
        AppRoutes.today,
      );
    });
  });

  test('kilit kümeleri değişmedi (ISKELET §6)', () {
    expect(AppRoutes.beforeOnboarding, {
      AppRoutes.onboarding,
      AppRoutes.chronotype,
    });
    expect(AppRoutes.whileTracking, {
      AppRoutes.track,
      AppRoutes.sounds,
      AppRoutes.breathe,
    });
  });
}
