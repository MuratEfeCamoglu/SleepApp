import 'package:flutter_test/flutter_test.dart';
import 'package:uyku/features/premium/domain/premium_status.dart';

void main() {
  group('PremiumStatus JSON', () {
    test('varsayılan kapalı gidiş-dönüş', () {
      const status = PremiumStatus();
      expect(status.active, isFalse);
      expect(status.source, PremiumSource.none);
      expect(PremiumStatus.fromJson(status.toJson()), status);
    });

    test('aktif debug durumu gidiş-dönüş', () {
      final status = PremiumStatus(
        active: true,
        since: DateTime(2026, 10, 21, 9, 30),
        source: PremiumSource.debug,
      );
      expect(PremiumStatus.fromJson(status.toJson()), status);
    });

    test('store kaynağı gidiş-dönüş', () {
      final status = PremiumStatus(
        active: true,
        since: DateTime.utc(2026, 1, 2),
        source: PremiumSource.store,
      );
      expect(PremiumStatus.fromJson(status.toJson()), status);
    });

    test('boş JSON kapalıya düşer', () {
      expect(
        PremiumStatus.fromJson(const <String, dynamic>{}),
        const PremiumStatus(),
      );
    });

    test('bilinmeyen kaynak none olur', () {
      final status = PremiumStatus.fromJson(const {
        'active': true,
        'source': 'gift',
      });
      expect(status.source, PremiumSource.none);
      expect(status.active, isTrue);
    });
  });

  test('copyWith null vererek since temizlenir', () {
    final status = PremiumStatus(active: true, since: DateTime(2026));
    expect(status.copyWith(since: null).since, isNull);
    expect(status.copyWith(active: false).since, status.since);
  });
}
