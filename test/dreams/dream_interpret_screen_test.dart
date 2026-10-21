import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uyku/core/providers/core_providers.dart';
import 'package:uyku/core/strings/app_strings.dart';
import 'package:uyku/core/theme/app_theme.dart';
import 'package:uyku/core/widgets/app_icon.dart';
import 'package:uyku/core/widgets/circle_icon_button.dart';
import 'package:uyku/core/widgets/primary_pill_button.dart';
import 'package:uyku/features/dreams/presentation/dream_interpret_screen.dart';
import 'package:uyku/features/sleep_log/data/local_sleep_repository.dart';
import 'package:uyku/features/sleep_log/domain/sleep_entry.dart';

const AppStrings _s = AppStrings.instance;

final SleepEntry _dream = SleepEntry(
  id: '2026-10-19',
  bedtime: DateTime(2026, 10, 19, 23),
  wake: DateTime(2026, 10, 20, 7),
  note: 'Annemle bir köprüden geçiyorduk',
  dreamKind: DreamKind.nightmare,
  dreamEmotions: const [DreamEmotion.fear],
);

Future<void> _pump(WidgetTester tester, String location) async {
  tester.view
    ..physicalSize = const Size(1170, 2532)
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({
    LocalSleepRepository.storageKey: jsonEncode([_dream.toJson()]),
  });
  final prefs = await SharedPreferences.getInstance();
  final router = GoRouter(
    initialLocation: location,
    routes: [
      GoRoute(
        path: '/dreams/interpret',
        builder: (_, state) =>
            DreamInterpretScreen(night: state.uri.queryParameters['night']),
      ),
      GoRoute(path: '/', builder: (_, _) => const SizedBox()),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: MediaQuery(
        data: const MediaQueryData(
          size: Size(390, 844),
          textScaler: TextScaler.linear(1.3),
        ),
        child: MaterialApp.router(
          theme: AppTheme.light,
          locale: AppStrings.locale,
          supportedLocales: AppStrings.supportedLocales,
          localizationsDelegates: AppStrings.localizationsDelegates,
          routerConfig: router,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

PrimaryPillButton _cta(WidgetTester tester) =>
    tester.widget<PrimaryPillButton>(find.byType(PrimaryPillButton));

Future<void> _choose(WidgetTester tester, String label) async {
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
  testWidgets('boş notta İleri pasif; altı soru sonunda üç bölüm ve uyarı', (
    tester,
  ) async {
    await _pump(tester, '/dreams/interpret');
    expect(_cta(tester).onPressed, isNull);

    await tester.enterText(find.byType(TextField), 'Uçuyordum');
    await tester.pumpAndSettle();
    expect(_cta(tester).onPressed, isNotNull);
    await _next(tester);

    final answers = [
      _s.dreams_emotionFear,
      _s.dreamsInterview_wakeUneasy,
      _s.dreamsInterview_controlNo,
      _s.dreamsInterview_none,
      _s.dreamsInterview_lifeChange,
      _s.dreamsInterview_recurFirst,
    ];
    for (final a in answers) {
      expect(_cta(tester).onPressed, isNull, reason: 'cevapsız: $a');
      await _choose(tester, a);
      expect(_cta(tester).onPressed, isNotNull);
      await _next(tester);
    }

    expect(find.text(_s.dreamsInterview_resultTitle), findsOneWidget);
    for (final section in [
      _s.dreamsInterview_sectionTheme,
      _s.dreamsInterview_sectionLife,
      _s.dreamsInterview_sectionReflect,
      _s.dreamsInterview_sectionSuggestion,
    ]) {
      expect(find.text(section.toUpperCase()), findsOneWidget);
    }
    await tester.scrollUntilVisible(
      find.text(_s.dreams_disclaimer),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text(_s.dreams_disclaimer), findsOneWidget);
    expect(find.text(_s.dreamsInterview_saveYesterday), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('?night= günlükteki rüyadan başlar; Geri cevabı korur', (
    tester,
  ) async {
    await _pump(tester, '/dreams/interpret?night=2026-10-19');
    expect(find.text(_dream.note), findsWidgets);
    expect(_cta(tester).onPressed, isNotNull);
    await _next(tester);
    // Baskın duygu kayıttan gelir.
    expect(_cta(tester).onPressed, isNotNull);
    await _next(tester);
    await _choose(tester, _s.dreamsInterview_wakeTired);
    await tester.tap(
      find.byWidgetPredicate(
        (w) => w is CircleIconButton && w.icon == AppIcons.back,
      ),
    );
    await tester.pumpAndSettle();
    await _next(tester);
    expect(_cta(tester).onPressed, isNotNull);
    expect(tester.takeException(), isNull);
  });
}
