import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uyku/features/premium/data/local_premium_repository.dart';
import 'package:uyku/features/premium/domain/premium_status.dart';

void main() {
  test('kayıt yoksa kapalı döner', () async {
    SharedPreferences.setMockInitialValues({});
    final repo = LocalPremiumRepository(await SharedPreferences.getInstance());
    expect(repo.load(), const PremiumStatus());
  });

  test('kaydedilen durum premium.v1 anahtarından geri okunur', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final status = PremiumStatus(
      active: true,
      since: DateTime(2026, 10, 21),
      source: PremiumSource.debug,
    );
    await LocalPremiumRepository(prefs).save(status);
    expect(prefs.getString('premium.v1'), isNotNull);
    expect(LocalPremiumRepository(prefs).load(), status);
  });

  test('bozuk JSON kapalıya düşer', () async {
    SharedPreferences.setMockInitialValues({'premium.v1': '{bozuk'});
    final repo = LocalPremiumRepository(await SharedPreferences.getInstance());
    expect(repo.load(), const PremiumStatus());
  });

  test('nesne olmayan JSON kapalıya düşer', () async {
    SharedPreferences.setMockInitialValues({'premium.v1': '[true]'});
    final repo = LocalPremiumRepository(await SharedPreferences.getInstance());
    expect(repo.load(), const PremiumStatus());
  });

  test('yanlış tipli alan kapalıya düşer', () async {
    SharedPreferences.setMockInitialValues({
      'premium.v1': '{"active":"evet","source":"debug"}',
    });
    final repo = LocalPremiumRepository(await SharedPreferences.getInstance());
    expect(repo.load(), const PremiumStatus());
  });

  test('bozuk tarih kapalıya düşer', () async {
    SharedPreferences.setMockInitialValues({
      'premium.v1': '{"active":true,"since":"dün","source":"debug"}',
    });
    final repo = LocalPremiumRepository(await SharedPreferences.getInstance());
    expect(repo.load(), const PremiumStatus());
  });
}
