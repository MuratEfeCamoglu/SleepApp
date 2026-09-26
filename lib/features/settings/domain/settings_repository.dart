import 'package:uyku/features/settings/domain/user_settings.dart';

abstract interface class SettingsRepository {
  UserSettings load();

  Future<void> save(UserSettings settings);
}
