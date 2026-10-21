import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uyku/core/providers/core_providers.dart';
import 'package:uyku/core/strings/app_strings.dart';
import 'package:uyku/core/theme/app_theme.dart';
import 'package:uyku/features/premium/data/local_premium_repository.dart';
import 'package:uyku/features/settings/domain/csv_export.dart';
import 'package:uyku/features/settings/presentation/settings_screen.dart';
import 'package:uyku/features/sleep_log/data/local_sleep_repository.dart';
import 'package:uyku/features/sleep_log/domain/sleep_entry.dart';

const AppStrings _s = AppStrings.instance;

final _entries = [
  SleepEntry(
    id: '2026-10-19',
    bedtime: DateTime(2026, 10, 19, 23),
    wake: DateTime(2026, 10, 20, 7),
    note: 'deniz, "mavi"',
  ),
  SleepEntry(
    id: '2026-10-18',
    bedtime: DateTime(2026, 10, 18, 23, 30),
    wake: DateTime(2026, 10, 19, 6, 45),
  ),
];

/// Ayarlar ekranını kurar; panoya yazılan metni döndüren fonksiyon verir.
Future<String? Function()> _pump(
  WidgetTester tester, {
  required bool premium,
  List<SleepEntry> entries = const [],
  ThemeMode mode = ThemeMode.light,
}) async {
  SharedPreferences.setMockInitialValues({
    LocalSleepRepository.storageKey: jsonEncode([
      for (final e in entries) e.toJson(),
    ]),
    if (premium)
      LocalPremiumRepository.storageKey: jsonEncode({
        'active': true,
        'source': 'debug',
      }),
  });
  String? clipboard;
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (call) async {
      if (call.method == 'Clipboard.setData') {
        clipboard = (call.arguments as Map)['text'] as String?;
      }
      return null;
    },
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    ),
  );
  final prefs = await SharedPreferences.getInstance();
  final router = GoRouter(
    initialLocation: '/settings',
    routes: [
      GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
      GoRoute(path: '/premium', builder: (_, _) => const Text('premium-route')),
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
  final row = find.text(_s.export_csvRow);
  await tester.scrollUntilVisible(
    row,
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
  return () => clipboard;
}

void main() {
  testWidgets('premium kapalı: satır kilitli, dokununca /premium açılır', (
    tester,
  ) async {
    final clipboard = await _pump(tester, premium: false, entries: _entries);
    expect(find.text(_s.export_locked), findsWidgets);
    await tester.tap(find.text(_s.export_csvRow));
    await tester.pumpAndSettle();
    expect(find.text('premium-route'), findsOneWidget);
    expect(clipboard(), isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('premium açık, kayıt yok: "Kayıt yok" ve kopyalama olmaz', (
    tester,
  ) async {
    final clipboard = await _pump(tester, premium: true);
    expect(find.text(_s.export_empty), findsOneWidget);
    await tester.tap(find.text(_s.export_csvRow));
    await tester.pumpAndSettle();
    expect(clipboard(), isNull);
    expect(find.text(_s.export_copied), findsNothing);
    expect(find.text('premium-route'), findsNothing);
  });

  testWidgets('premium açık: CSV panoya kopyalanır, "Kopyalandı" görünür', (
    tester,
  ) async {
    final clipboard = await _pump(
      tester,
      premium: true,
      entries: _entries,
      mode: ThemeMode.dark,
    );
    await tester.tap(find.text(_s.export_csvRow));
    await tester.pumpAndSettle();
    final csv = clipboard();
    expect(csv, entriesToCsv(_entries));
    expect(csv, startsWith('$csvHeader\r\n2026-10-18,'));
    expect(csv, endsWith(',"deniz, ""mavi"""\r\n'));
    expect(find.text(_s.export_copied), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
