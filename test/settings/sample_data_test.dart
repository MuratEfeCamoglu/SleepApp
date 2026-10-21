import 'package:flutter_test/flutter_test.dart';
import 'package:uyku/features/dreams/domain/dream_insights.dart';
import 'package:uyku/features/dreams/domain/dream_journal.dart';
import 'package:uyku/features/dreams/domain/dream_symbols.dart';
import 'package:uyku/features/settings/domain/sample_data.dart';
import 'package:uyku/features/settings/domain/user_settings.dart';
import 'package:uyku/features/sleep_log/domain/sleep_entry.dart';

void main() {
  final today = DateTime(2026, 10, 21);
  const settings = UserSettings();
  final entries = buildSampleEntries(today, settings);

  test('son 60 gece, gece başına tek kayıt, dün gece dahil', () {
    expect(entries, hasLength(60));
    expect(entries.map((e) => e.id).toSet(), hasLength(60));
    expect(entries.last.id, '2026-10-20');
    for (final e in entries) {
      expect(nightKey(nightOf(e.wake)), e.id);
    }
  });

  test('aynı tohum aynı listeyi verir', () {
    expect(buildSampleEntries(today, settings), entries);
  });

  test('bazı gecelerde rüya; kabuslar yaklaşık %15', () {
    final dreams = entries.where((e) => e.hasDreamNote).toList();
    final nightmares = dreams
        .where((e) => e.dreamKind == DreamKind.nightmare)
        .length;
    expect(dreams.length, inInclusiveRange(12, 40));
    expect(nightmares, greaterThanOrEqualTo(DreamInsightsCalculator.minNights));
    expect(nightmares / dreams.length, inInclusiveRange(0.08, 0.25));
  });

  test('her rüya notu sözlükte en az bir sembol içerir', () {
    for (final e in entries.where((e) => e.hasDreamNote)) {
      expect(findSymbols(e.note), isNotEmpty, reason: e.note);
    }
  });

  test('örnek veride içgörü kartı dolu görünür', () {
    final i = computeDreamInsights(entries, today);
    expect(i.topSymbols, hasLength(DreamInsightsCalculator.topCount));
    expect(i.nightmareRate, isNotNull);
    expect(i.durationDelta, isNotNull);
  });
}
