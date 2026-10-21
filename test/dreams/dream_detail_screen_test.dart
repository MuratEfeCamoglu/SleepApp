import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uyku/core/providers/core_providers.dart';
import 'package:uyku/core/strings/app_strings.dart';
import 'package:uyku/core/theme/app_theme.dart';
import 'package:uyku/features/dreams/domain/dream_symbols.dart';
import 'package:uyku/features/dreams/presentation/dream_detail_screen.dart';
import 'package:uyku/features/dreams/presentation/dreams_screen.dart';
import 'package:uyku/features/premium/data/local_premium_repository.dart';
import 'package:uyku/features/sleep_log/data/local_sleep_repository.dart';
import 'package:uyku/features/sleep_log/domain/sleep_entry.dart';

const AppStrings _s = AppStrings.instance;

final SleepEntry _dream = SleepEntry(
  id: '2026-10-19',
  bedtime: DateTime(2026, 10, 19, 23),
  wake: DateTime(2026, 10, 20, 7),
  note: 'Suda yüzüyordum, sonra yılan gördüm',
  dreamKind: DreamKind.nightmare,
);

final _noNote = SleepEntry(
  id: '2026-10-18',
  bedtime: DateTime(2026, 10, 18, 23),
  wake: DateTime(2026, 10, 19, 7),
);

String _meaning(String id) =>
    dreamSymbols.firstWhere((s) => s.id == id).meaning;

Future<void> _pump(
  WidgetTester tester,
  String location, {
  bool premium = false,
  ThemeMode mode = ThemeMode.light,
}) async {
  SharedPreferences.setMockInitialValues({
    LocalSleepRepository.storageKey: jsonEncode([
      _dream.toJson(),
      _noNote.toJson(),
    ]),
    if (premium)
      LocalPremiumRepository.storageKey: jsonEncode({
        'active': true,
        'source': 'debug',
      }),
  });
  final prefs = await SharedPreferences.getInstance();
  final router = GoRouter(
    initialLocation: location,
    routes: [
      // Sekme sayfası: uygulamada Scaffold'u AppShell sağlar.
      GoRoute(
        path: '/dreams',
        builder: (_, _) => const Scaffold(body: DreamsScreen()),
      ),
      GoRoute(
        path: '/dreams/:night',
        builder: (_, state) =>
            DreamDetailScreen(night: state.pathParameters['night']!),
      ),
      GoRoute(path: '/log', builder: (_, _) => const SizedBox()),
      GoRoute(path: '/premium', builder: (_, _) => const SizedBox()),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      // Rüya sekmesi kartındaki sürekli "nefes" animasyonu pumpAndSettle'ı
      // bitirmez; hareket azaltmada durağandır (ayrı testte doğrulanır).
      child: MediaQuery(
        data: const MediaQueryData(
          size: Size(390, 844),
          textScaler: TextScaler.linear(1.3),
          disableAnimations: true,
        ),
        child: MaterialApp.router(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: mode,
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

Future<void> _scrollTo(WidgetTester tester, Finder finder) => tester
    .scrollUntilVisible(finder, 200, scrollable: find.byType(Scrollable).first);

void main() {
  testWidgets('geçersiz gece anahtarı boş durum gösterir', (tester) async {
    await _pump(tester, '/dreams/abc');
    expect(tester.takeException(), isNull);
    expect(find.text(_s.dreams_missingTitle), findsOneWidget);
    expect(find.text(_s.dreams_openJournal), findsOneWidget);
  });

  testWidgets('aralık dışı tarih anahtarı çökmez', (tester) async {
    await _pump(tester, '/dreams/2026-13-45');
    expect(tester.takeException(), isNull);
    expect(find.text(_s.dreams_missingTitle), findsOneWidget);
  });

  testWidgets('kayıt olmayan gece boş durum gösterir', (tester) async {
    await _pump(tester, '/dreams/2020-01-01');
    expect(find.text(_s.dreams_missingTitle), findsOneWidget);
  });

  testWidgets('notsuz kayıt "Notu düzenle" önerir', (tester) async {
    await _pump(tester, '/dreams/${_noNote.id}');
    expect(find.text(_s.dreams_missingTitle), findsOneWidget);
    expect(find.text(_s.dreams_editNote), findsOneWidget);
  });

  testWidgets('ücretsizde yalnız ilk sembol açık, uyarı görünür', (
    tester,
  ) async {
    await _pump(tester, '/dreams/${_dream.id}');
    expect(find.text(_meaning('su')), findsOneWidget);
    expect(find.text(_meaning('yuzmek')), findsNothing);
    expect(find.text(_meaning('yilan')), findsNothing);
    await _scrollTo(tester, find.text(_s.dreams_disclaimer));
    expect(find.text(_s.dreams_disclaimer), findsOneWidget);
    expect(find.text(_s.dreams_readingLockBody(2)), findsOneWidget);
  });

  testWidgets('premium tüm sembolleri açar, uyarı yine görünür (dark)', (
    tester,
  ) async {
    await _pump(
      tester,
      '/dreams/${_dream.id}',
      premium: true,
      mode: ThemeMode.dark,
    );
    for (final id in ['su', 'yuzmek', 'yilan']) {
      await _scrollTo(tester, find.text(_meaning(id)));
      expect(find.text(_meaning(id)), findsOneWidget);
    }
    await _scrollTo(tester, find.text(_s.dreams_disclaimer));
    expect(find.text(_s.dreams_disclaimer), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('/dreams ücretsizde içgörü kartını kilitler', (tester) async {
    await _pump(tester, '/dreams');
    expect(find.text(_s.dreams_insightsLockTitle), findsOneWidget);
    // Kart yer tutucu olarak ağaçta kalır ama görünmez ve okunmaz.
    final hidden = tester.widget<Visibility>(
      find
          .ancestor(
            of: find.text(_s.dreams_insightsTitle),
            matching: find.byType(Visibility),
          )
          .first,
    );
    expect(hidden.visible, isFalse);
    expect(hidden.maintainSemantics, isFalse);
    expect(tester.takeException(), isNull);
  });
}
