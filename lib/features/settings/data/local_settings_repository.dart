import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uyku/features/settings/domain/settings_repository.dart';
import 'package:uyku/features/settings/domain/user_settings.dart';

class LocalSettingsRepository implements SettingsRepository {
  LocalSettingsRepository(this._prefs);

  static const storageKey = 'user_settings_v1';

  final SharedPreferences _prefs;

  @override
  UserSettings load() {
    final raw = _prefs.getString(storageKey);
    if (raw == null) return const UserSettings();
    try {
      return UserSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on FormatException {
      return const UserSettings();
    }
  }

  @override
  Future<void> save(UserSettings settings) =>
      _prefs.setString(storageKey, jsonEncode(settings.toJson()));
}
