import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uyku/core/providers/core_providers.dart';
import 'package:uyku/core/strings/app_strings.dart';
import 'package:uyku/core/theme/app_theme.dart';
import 'package:uyku/core/widgets/primary_pill_button.dart';
import 'package:uyku/features/dreams/presentation/dream_interpret_screen.dart';
import 'package:uyku/features/sleep_log/data/local_sleep_repository.dart';
import 'package:uyku/features/sleep_log/domain/sleep_entry.dart';
import 'package:uyku/features/sleep_log/presentation/log_editor.dart';
import 'package:uyku/features/sleep_log/presentation/log_screen.dart';
import 'package:uyku/features/sleep_log/presentation/sleep_log_providers.dart';

const AppStrings _s = AppStrings.instance;

class _FixedClock extends Clock {
  const _FixedClock(this.value);

  final DateTime value;

  @override
  DateTime now() => value;
}

/// Bugün 2026-10-21; dün gecenin (2026-10-20) kaydı yok.
final _older = SleepEntry(
  id: '2026-10-18',
  bedtime: DateTime(2026, 10, 18, 23),
  wake: DateTime(2026, 10, 19, 7),
);

/// Uyku modunun sonradan yazdığı gece (notsuz).
final _tracked = SleepEntry(
  id: '2026-10-20',
  bedtime: DateTime(2026, 10, 20, 23),
  wake: DateTime(2026, 10, 21, 7),
);

Future<void> _pump(WidgetTester tester) async {
  tester.view
    ..physicalSize = const Size(1170, 2532)
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({
    LocalSleepRepository.storageKey: jsonEncode([_older.toJson()]),
  });
  final prefs = await SharedPreferences.getInstance();
  final router = GoRouter(
    initialLocation: '/dreams/interpret',
    routes: [
      GoRoute(
        path: '/dreams/interpret',
        builder: (_, _) => const DreamInterpretScreen(),
      ),
      // Uygulamada Kaydet kabuk sekmesidir; Scaffold kabuktan gelir.
      GoRoute(
        path: '/log',
        builder: (_, _) => const Scaffold(body: LogScreen()),
      ),
      GoRoute(path: '/', builder: (_, _) => const SizedBox()),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        clockProvider.overrideWithValue(_FixedClock(DateTime(2026, 10, 21, 9))),
      ],
      child: MaterialApp.router(
        theme: AppTheme.light,
        locale: AppStrings.locale,
        supportedLocales: AppStrings.supportedLocales,
        localizationsDelegates: AppStrings.localizationsDelegates,
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _tapText(WidgetTester tester, String label) async {
  await tester.scrollUntilVisible(
    find.text(label),
    100,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

Future<void> _next(WidgetTester tester) async {
  await tester.tap(find.byType(PrimaryPillButton));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('kayıt yoksa yorum notu Kaydet ekranına taşınır ve not alanını '
      'doldurur; kaydedince geceye yazılır', (tester) async {
    await _pump(tester);

    await tester.enterText(find.byType(TextField), 'Köprüden düşüyordum');
    await tester.pumpAndSettle();
    await _tapText(tester, _s.dreams_kindNightmare);
    await _next(tester);
    for (final a in [
      _s.dreams_emotionFear,
      _s.dreamsInterview_wakeUneasy,
      _s.dreamsInterview_controlNo,
      _s.dreamsInterview_none,
      _s.dreamsInterview_lifeChange,
      _s.dreamsInterview_recurFirst,
    ]) {
      await _tapText(tester, a);
      await _next(tester);
    }

    // Sonuç: dün gece kaydı yok → uyarı + "Uykunu kaydet".
    await tester.tap(find.text(_s.dreamsInterview_saveYesterday));
    await tester.pumpAndSettle();
    expect(find.text(_s.dreamsInterview_noEntry), findsOneWidget);
    await _tapText(tester, _s.dreamsInterview_noEntryAction);

    // Kaydet ekranı: henüz kayıt yok, taslağın saklandığı söylenir.
    expect(find.byType(LogScreen), findsOneWidget);
    expect(find.text(_s.log_startTitle), findsOneWidget);
    expect(find.text(_s.log_pendingDream), findsOneWidget);

    // Uyku modu geceyi yazar → not alanı taslakla dolu açılır.
    final container = ProviderScope.containerOf(
      tester.element(find.byType(LogScreen)),
    );
    await container.read(sleepLogProvider.notifier).save(_tracked);
    await tester.pumpAndSettle();

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, 'Köprüden düşüyordum');
    final draft = container.read(logEditorProvider)!;
    expect(draft.dreamKind, DreamKind.nightmare);
    expect(draft.dreamEmotions, {DreamEmotion.fear});
    // Henüz kalıcı değil: yalnız "Uykuyu kaydet" ile yazılır.
    expect(
      container.read(sleepLogProvider).value!.forNight(_tracked.night)!.note,
      isEmpty,
    );

    await _tapText(tester, _s.log_save);
    final saved = container
        .read(sleepLogProvider)
        .value!
        .forNight(_tracked.night)!;
    expect(saved.note, 'Köprüden düşüyordum');
    expect(saved.dreamKind, DreamKind.nightmare);
    expect(saved.dreamEmotions, [DreamEmotion.fear]);
    expect(container.read(pendingDreamDraftProvider), isNull);
    expect(find.text(_s.log_saved), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
