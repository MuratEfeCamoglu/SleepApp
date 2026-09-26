import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uyku/features/routine/domain/routine_repository.dart';

class LocalRoutineRepository implements RoutineRepository {
  LocalRoutineRepository(this._prefs);

  static const storageKey = 'routine_days_v1';

  /// Bu kadar akşamdan eskisi tutulmaz.
  static const keepDays = 60;

  final SharedPreferences _prefs;

  Map<String, List<int>> _read() {
    final raw = _prefs.getString(storageKey);
    if (raw == null) return {};
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return map.map(
      (key, value) => MapEntry(key, (value as List<dynamic>).cast<int>()),
    );
  }

  @override
  Set<int> doneSteps(String eveningKey) => {...?_read()[eveningKey]};

  @override
  Future<void> saveDoneSteps(String eveningKey, Set<int> steps) {
    final all = _read()..[eveningKey] = (steps.toList()..sort());
    final keys = all.keys.toList()..sort();
    if (keys.length > keepDays) {
      keys.take(keys.length - keepDays).forEach(all.remove);
    }
    return _prefs.setString(storageKey, jsonEncode(all));
  }

  @override
  Future<void> clear() => _prefs.remove(storageKey);
}
