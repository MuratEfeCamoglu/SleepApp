import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uyku/features/health/domain/health_check.dart';
import 'package:uyku/features/health/domain/health_check_repository.dart';

class LocalHealthCheckRepository implements HealthCheckRepository {
  LocalHealthCheckRepository(this._prefs);

  static const storageKey = 'health.check.v1';

  final SharedPreferences _prefs;

  @override
  HealthCheckResult? load() {
    final raw = _prefs.getString(storageKey);
    if (raw == null) return null;
    // Bozuk veya beklenmeyen biçimli kayıt açılışı çökertmemeli; yok say.
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      return HealthCheckResult.fromJson(decoded);
    } on FormatException {
      return null;
    }
  }

  @override
  Future<void> save(HealthCheckResult result) =>
      _prefs.setString(storageKey, jsonEncode(result.toJson()));
}
