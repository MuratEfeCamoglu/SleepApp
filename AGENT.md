# AGENT.md — Uyku: Agent tanımı

Kurallar: `CLAUDE.md` (tasarım, kod, doğrulama). Kapsam ve kabul kriterleri: `ISKELET.md`. Bu dosya üç ajan rolünün nasıl birlikte çalıştığını anlatır.

## Roller

| Rol | Görevi | Dokunabildiği yer |
|---|---|---|
| **Geliştirici** | ISKELET.md'deki bir özelliği (F1…F8) kabul kriterine göre uygular. | `lib/`, `test/`, `pubspec.yaml` (yalnız `flutter_test` sdk), `CLAUDE.md` §4/§6/§8 satır eklemeleri |
| **Testçi** | Geliştiricinin işini bağımsız doğrular: domain testleri yazar/genişletir, `flutter analyze`, `flutter test` ve §11 grep'lerini çalıştırır, kabul kriterlerini tek tek işaretler; bulduğu hatayı düzeltir veya geliştiriciye geri yazar. | `test/`, hatanın bulunduğu `lib/` dosyası |
| **Raportör** | Tüm turlardan sonra `docs/RAPOR.md` yazar: yapılanlar, kabul kriteri tablosu (geçti/kaldı), doğrulama çıktıları, açık noktalar. Kod değiştirmez. | `docs/RAPOR.md` |

Ajanlar **sırayla** çalışır (Geliştirici → Testçi, özellik başına); `lib/core/strings/app_strings.dart` ve `lib/core/router/app_router.dart` ortak dosya olduğu için paralel düzenleme yapılmaz.

## Yetkiler (sormadan yapılır)

- `lib/features/<yeni>/` altında `domain/data/presentation` oluşturmak.
- `AppStrings`'e kendi `// <Özellik>` başlığı altında metin eklemek.
- `AppRoutes`'a ISKELET.md §6'daki rotaları eklemek.
- `core/theme` ve `AppSizes`'a token eklemek (CLAUDE.md'ye de yazarak).
- `flutter pub get`, `flutter analyze`, `flutter test` çalıştırmak.

## Onay gerektirenler (koordinatöre/kullanıcıya sor)

- Yeni pub paketi eklemek — çünkü CLAUDE.md §3 yığını sabitler ve offline/izin etkisi olabilir.
- `path_provider_android` sabitini kaldırmak — çünkü NDK 28.2 indirtir.
- Mevcut bir özelliği premium'a taşımak — çünkü kullanıcıdan özellik geri almak kapsam dışı (ISKELET §3.2).
- `SleepEntry`'de alan silmek veya yeniden adlandırmak — çünkü kayıtlı veriyi bozar.

## Yasaklar

- Kod üretimi (`build_runner`, `freezed`, `*.g.dart`) — çünkü proje `flutter run` öncesi adım istemez.
- `core/theme` dışında `Color(0x…)`, `Colors.*`, sabit `fontSize`/`EdgeInsets`/`BorderRadius` sayısı — çünkü tema tutarlılığı tokenlarla korunur.
- Widget'ta sabit kullanıcı metni — çünkü tüm metinler `AppStrings`'te.
- Tanı koyan, hastalık adı söyleyen veya tedavi öneren metin — çünkü uygulama tıbbi cihaz değildir ve mağaza politikaları bunu reddeder.
- Gerçekmiş gibi görünen fiyat veya kullanıcı yorumu — çünkü CLAUDE.md §2 sahte veriyi yasaklar.
- Lisanslı ölçek metinleri (Epworth, ISI, STOP-Bang, PSQI) — çünkü telif ve ticari lisans gerekir.
- Testleri geçirmek için testi zayıflatmak veya `// ignore` ile uyarı susturmak — çünkü doğrulama anlamını yitirir.

## Çalışma döngüsü

1. **Anla** — CLAUDE.md, ISKELET.md'de ilgili `F` satırı ve kabul kriteri, ilgili feature klasörü.
2. **Planla** — Değişecek dosyaları listele.
3. **Uygula** — Önce saf domain (test edilebilir), sonra provider, sonra ekran.
4. **Doğrula** — `flutter analyze` (0 uyarı), `flutter test`, §11 grep'leri.
5. **Düzelt** — Kök nedeni bul, en fazla 3 deneme; çözülmezse rapora yaz.
6. **Raporla** — Değişen dosyalar, geçen/kalan kriterler, varsayımlar.

## "Bitti" tanımı

- [ ] ISKELET.md §7'deki ilgili kabul kriterleri karşılandı.
- [ ] `flutter analyze` → `No issues found!`
- [ ] `flutter test` → tüm testler geçti.
- [ ] `grep -rn "Color(0x" lib/ | grep -v core/theme` ve `grep -rnE "Text\('[^']" lib/features` boş.
- [ ] Light + dark, `textScaler` 1.3 düşünülerek yazıldı (sabit yükseklikli metin kutusu yok).
- [ ] CLAUDE.md'de yeni rota/klasör/ekran satırı eklendi.

## Belirsizlikte karar kuralları

- İki yol varsa daha basit ve geri alınabilir olanı seç, kararı raporda belirt.
- Tasarım kararı gerekiyorsa mevcut en yakın ekranı (Haftalık rapor, Etken analizi, Rozetler) örnek al.
- Sağlık/rüya metninde şüphe varsa daha temkinli ifadeyi seç.
