import 'package:uyku/features/premium/domain/premium_status.dart';

/// Premium hakkının kaynağı. Mağaza bağlanınca `StorePremiumRepository`
/// aynı arayüzle eklenir.
abstract interface class PremiumRepository {
  PremiumStatus load();

  Future<void> save(PremiumStatus status);
}
