import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uyku/features/sleep_log/domain/sleep_entry.dart';
import 'package:uyku/features/sleep_log/domain/sleep_repository.dart';

/// Kayıtları cihazda JSON olarak saklar.
class LocalSleepRepository implements SleepRepository {
  LocalSleepRepository(this._prefs);

  static const storageKey = 'sleep_entries_v1';

  final SharedPreferences _prefs;

  Map<String, SleepEntry> _read() {
    final raw = _prefs.getString(storageKey);
    if (raw == null) return {};
    final list = (jsonDecode(raw) as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(SleepEntry.fromJson);
    return {for (final e in list) e.id: e};
  }

  Future<void> _write(Map<String, SleepEntry> entries) => _prefs.setString(
    storageKey,
    jsonEncode(entries.values.map((e) => e.toJson()).toList()),
  );

  @override
  Future<List<SleepEntry>> fetchAll() async =>
      _read().values.toList()..sort((a, b) => a.wake.compareTo(b.wake));

  @override
  Future<void> save(SleepEntry entry) => saveAll([entry]);

  @override
  Future<void> saveAll(List<SleepEntry> entries) {
    final all = _read();
    for (final e in entries) {
      all[e.id] = e;
    }
    return _write(all);
  }

  @override
  Future<void> delete(String id) => _write(_read()..remove(id));

  @override
  Future<void> clear() => _prefs.remove(storageKey);
}
