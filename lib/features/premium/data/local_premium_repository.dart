import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uyku/features/premium/domain/premium_repository.dart';
import 'package:uyku/features/premium/domain/premium_status.dart';

class LocalPremiumRepository implements PremiumRepository {
  LocalPremiumRepository(this._prefs);

  static const storageKey = 'premium.v1';

  final SharedPreferences _prefs;

  @override
  PremiumStatus load() {
    final raw = _prefs.getString(storageKey);
    if (raw == null) return const PremiumStatus();
    // Bozuk veya beklenmeyen biçimli kayıt açılışı çökertmemeli; kapalıya düş.
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return const PremiumStatus();
      return PremiumStatus.fromJson(decoded);
    } on FormatException {
      return const PremiumStatus();
    }
  }

  @override
  Future<void> save(PremiumStatus status) =>
      _prefs.setString(storageKey, jsonEncode(status.toJson()));
}
