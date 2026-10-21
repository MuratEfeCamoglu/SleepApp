# RAPOR — Uyku: Premium dalgası (F1–F10)

Tarih: 2026-10-21 · Rol: Raportör (AGENT.md) · Kapsam: ISKELET.md · Kurallar: CLAUDE.md

---

## 1. Özet

Mevcut ücretsiz takipçiye dokunmadan cihazda çalışan bir **premium katman** eklendi. Katmanda şunlar var: yerel entitlement'lı Premium altyapısı ve `/premium` tanıtım ekranı (fiyat placeholder). Skor, uyku borcu, SRI düzenliliği ve sosyal jetlag'i gösteren **Uyku sağlığı** ekranı ile Bugün özet kartı. Ücretsiz, 6 soruluk ve tanı koymayan **sağlık öz-kontrolü**. Tür ve duygu alanlarıyla genişleyen **Rüya günlüğü 2.0**. 77 sembollük TR sözlükle kural tabanlı **rüya yorumu** ve **rüya içgörüleri**. Premium **CSV dışa aktarma**. Projeye ilk kez `flutter_test` altyapısı geldi: 20 dosyada 236 test var. Değişiklik 13 dosyayı etkiliyor (+810 / −21). Bunlara ek olarak 3 yeni feature klasörü (`premium`, `health`, `dreams`), `settings/domain/csv_export.dart`, `sample_data.dart` ve `sleep_log/domain/dream_tags.dart` eklendi. Commit atılmadı.

## 2. Araştırma kaynakları (ISKELET §2)

| Konu | Kaynak türü | Uygulamaya yansıması |
|---|---|---|
| Rakip premium katmanları (Sleep Cycle, Pillow; 3–15 $/ay, ~40 $/yıl) | Uygulama karşılaştırma yazıları | Temel takip ücretsiz kalır. Premium'a derin analiz, rüya yorumu ve dışa aktarma girer. |
| Rüya günlükleri (Dreamiary, Drift, DreamOn, Somnia) | App Store listeleri | Tür ve duygu etiketi eklendi. Sembol sözlüğü cihazda. Zorunlu "bilimsel değildir" uyarısı var. |
| Uyku Düzenlilik İndeksi (SRI) | Brown CS / Sleep as Android | Dakika ızgarasında SRI = 200·p − 100 |
| Sosyal jetlag | JUKUSUI, JMIR mHealth 2019 | Hafta sonu ve hafta içi orta noktalarının farkı |
| STOP-Bang / Epworth / ISI | Klinik formlar, Nature and Science of Sleep 2025 | Lisanslı metinler kopyalanmadı. Soruları kendimiz yazdık ve kontrol yalnızca "uzmana danışmayı düşün" sinyali verir. |

## 3. Özellikler

| Kod | Ne yapıldı | Ücretsiz / Premium | Ana dosyalar | Rota |
|---|---|---|---|---|
| F1 | `PremiumRepository` (abstract) ile `LocalPremiumRepository` (`premium.v1`), `PremiumStatus`, controller ve provider'lar, `PremiumGate`, paywall ekranı ve Ayarlar'da Premium satırı. Debug'da "Premium'u dene" butonu çıkar. | Altyapı | `lib/features/premium/{domain,data,presentation}/*` | `/premium` |
| F2 | `computeHealthSnapshot`: skor (0–100), 14 gecelik borç, SRI ve jetlag. Uyku sağlığı ekranı ve Bugün'deki `HealthSummaryCard`. | Skor ve borç ücretsiz. Döküm, 30 gecelik grafik ve öneriler premium. | `lib/features/health/domain/health_snapshot.dart`, `health_tips.dart`, `presentation/health_screen.dart`, `health_ui.dart`, `health_providers.dart` | `/health` |
| F3 | 6 soruluk öz-kontrol, 4 bayrak kuralı, son sonucun saklanması (`health.check.v1`) ve "Bu bir tanı değildir" notu | **Ücretsiz** | `health/domain/health_check.dart`, `health_check_repository.dart`, `data/local_health_check_repository.dart`, `presentation/health_check_screen.dart` | `/health/check` |
| F4 | `SleepEntry`'ye `dreamKind` ve `dreamEmotions` eklendi (geriye uyumlu). Kaydet'te tür ve duygu seçimi var. Rüya listesi arama ve tür filtresi içerir. Örnek veriler rüya da üretir. | Liste ücretsiz | `sleep_log/domain/sleep_entry.dart`, `dream_tags.dart`, `log_editor.dart`, `log_screen.dart`, `dreams/domain/dream_journal.dart`, `dreams/presentation/dreams_screen.dart`, `settings/domain/sample_data.dart` | `/dreams` |
| F5 | TR sembol sözlüğü (77 sembol, sözcük başı eşleşme, TR büyük/küçük harf), tema, uyarı metni ve Kaydet'teki "Rüyanı yorumla" bağlantısı | **Premium**. Ücretsizde ilk sembol açık. | `dreams/domain/dream_symbols.dart`, `dream_reading.dart`, `presentation/dream_detail_screen.dart`, `dream_ui.dart` | `/dreams/:night` |
| F6 | 90 gecede en sık 5 sembol, kabus oranı, kabus/diğer süre karşılaştırması ve etkenlerle birlikte görülme (her iki tarafta ≥ 3 gece) | **Premium** | `dreams/domain/dream_insights.dart`, `presentation/dream_insights_card.dart` | `/dreams` kartı |
| F7 | RFC 4180 uyumlu CSV panoya kopyalanır ve "Kopyalandı" geri bildirimi verir (Ayarlar → Veri) | **Premium** | `settings/domain/csv_export.dart`, `settings/presentation/settings_screen.dart` | — |
| F8 | `flutter_test` (sdk) dev bağımlılığı ve `test/` altında 20 dosya (domain, provider, widget, router) | — | `pubspec.yaml`, `test/**` | — |

Ayrıca yapılanlar: `PremiumGate` bileşen galerisine eklendi (`lib/debug/component_gallery_screen.dart`), yeni ölçüler `AppSizes`'a girdi, CLAUDE.md §4/§6/§8 güncellendi, metinler `AppStrings`'e kendi bölüm başlıklarıyla eklendi.

## 4. Kabul kriterleri (ISKELET §7)

| Kod | Durum | Kanıt (test dosyaları) |
|---|---|---|
| F1 | Geçti | `test/premium/premium_status_test.dart`, `local_premium_repository_test.dart` (bozuk kayıt dahil), `premium_controller_test.dart` |
| F2 | Geçti | `test/health/health_snapshot_test.dart` (boş, 3 kayıt, tam hedef, borç tavanı, SRI null, jetlag null ve fazlası), `health_snapshot_provider_test.dart`, `health_independent_test.dart` |
| F3 | Geçti | `test/health/health_check_test.dart` (her bayrak kuralı), `health_check_repository_test.dart` |
| F4 | Geçti | `test/sleep_log/sleep_entry_test.dart` (eski JSON), `local_sleep_repository_test.dart`, `log_editor_test.dart`, `test/settings/sample_data_test.dart` |
| F5 | Geçti | `test/dreams/dream_symbols_test.dart` (≥ 60 sembol, "Suda yüzüyordum, sonra yılan gördüm" → `su`, `yılan`), `dream_reading_test.dart`, `dream_detail_screen_test.dart` (ücretsizde 1 sembol, uyarı metni) |
| F6 | Geçti | `test/dreams/dream_insights_test.dart` |
| F7 | Geçti | `test/settings/csv_export_test.dart` (başlık satırı, virgül/tırnak/baş-son boşluk kaçırma), `csv_export_screen_test.dart` ("Kopyalandı") |
| F8 | Geçti | `flutter test` 236/236, `flutter analyze` temiz, iki grep boş (§6) |
| Tümü | Kısmen | Light/dark ve 1.3 ölçek kodda gözetildi. `/health` ekranları için 1.3 ölçekli widget testi yok ve cihazda görsel test yapılmadı. Rota kilitleri `test/router/app_router_redirect_test.dart` ile doğrulandı. |

## 5. Test turu günlüğü

| Tur | Kapsam | Akış | Testçinin bulguları ve düzeltmeler | Test sayısı |
|---|---|---|---|---|
| 1 | F8 + F1 | Geliştirici → Testçi | Bozuk `premium.v1` kaydı açılışta çökme yapıyordu, düzeltildi. | 28 → 37 |
| 2 | F2 + F3 | Geliştirici → Testçi | Bant etiketi 1.3 ölçekte kesiliyordu, `FittedBox` ile çözüldü. Kayıt hatasında "Sonucu gör" kilitli kalıyordu, `try/finally` ile çözüldü. | 94 → 109 |
| 3 | F4 – F6 | Geliştirici → Testçi | 9 sembol eşleşme hatası düzeltildi: yollarda, düşmüştüm, takip, kapıldım, evrim, paramparça, trendler, tipi, kazara. 7 yorum metninin dili yumuşatıldı. Örnek veride UI'ın repository'ye doğrudan dokunması (UI→repository ihlali) giderildi. | 164 → 193 |
| 4 | F7 ve pürüzler | Geliştirici → Testçi | Etkenler (factors) için tolerans eklendi. Yükleme durumlarına iskelet gösterimi eklendi. Kullanılmayan string silindi. CSV'de baş/son boşluk içeren alanların tırnaklanması düzeltildi. Router redirect testleri (24) eklendi. | 200 → 236 |

## 6. Doğrulama çıktıları (Raportör kendi çalıştırdı, 2026-10-21)

```
$ flutter analyze
Analyzing SleepApp...
No issues found! (ran in 7.0s)

$ flutter test
00:06 +235: .../test/router/app_router_redirect_test.dart: kilit kümeleri değişmedi (ISKELET §6)
00:06 +236: All tests passed!

$ grep -rn "Color(0x" lib/ | grep -v core/theme
(boş)

$ grep -rnE "Text\('[^']" lib/features
(boş)
```

## 7. Açık noktalar ve sonraki adımlar

- **Ödeme yok.** RevenueCat/StoreKit/Play Billing bağlanmadı. Fiyat placeholder: "Fiyat mağaza bağlanınca gösterilecek". Mağaza gelince `StorePremiumRepository` aynı arayüzle eklenecek.
- **Cihazda görsel test yapılmadı** (light/dark, 1.3 ölçek, küçük ekran).
- `/health` ve `/health/check` için `textScaler` 1.3 widget testi yok.
- Bugün'de kayıt sayısı 3'ten azken fazladan 18pt boşluk kalıyor. Bu, mevcut bölüm aralığı deseninden geliyor.
- Yeni ekranlardaki `SkeletonBlock` yükseklikleri sabit sayı. `AppSizes`'a taşınmalı.
- CSV formül enjeksiyonu: `=`, `+`, `-` veya `@` ile başlayan not, tablo programında formül olarak açılabilir. Kaçırılıp kaçırılmayacağı ürün kararı.
- `dreamEmotions` CSV'ye yazılmıyor (başlık ISKELET §7'deki sabit sütunlara uyuyor).
- "Örnek verilerle doldur" yalnızca debug derlemede var.
- Sembol eşleşmesinde belirsiz kelimeler kalıyor: "Deniz" ve "Su" özel isim olabilir. "doktora" doktor sembolünü, "dişi" diş sembolünü, "ateşim var" ateş sembolünü yanlış tetikleyebilir.
- Tüm JSON bozuksa kalıcı hata ekranı açılıyor. Kurtarma ya da sıfırlama yolu düşünülmeli.
- Commit atılmadı. Değişiklikler çalışma ağacında duruyor.

## 8. Varsayımlar

ISKELET §10:

- V1: Mevcut tüm özellikler ücretsiz kalır. Premium yalnızca yeni derin analizleri kapsar.
- V2: Bu dalgada ödeme sağlayıcısı yok. Entitlement `LocalPremiumRepository`'de tutulur.
- V3: Rüya yorumu kural tabanlıdır ve cihazda çalışır, LLM yoktur.
- V4: Sağlık kontrolü güvenlik bilgisi olduğu için ücretsizdir.
- V5: "Projede test yok" kuralı değişti. Domain testleri eklendi. Ayrıca sınırlı widget testleri ve router testleri de yazıldı, yani V5'teki "widget testi yok" ifadesinin ötesine geçildi.
- V6: Yeni pub paketi eklenmedi. Panoya kopyalama `Clipboard` ile yapılıyor.

Turlarda alınan kararlar:

- **Borç peşin ödenmez:** geceler eskiden yeniye işlenir. Borç hiçbir adımda 0'ın altına inmez ve gece başına en fazla 60 dk geri ödenir.
- **SRI ızgarası 12:00 – 12:00:** gece yarısını aşan uykular tek günde kalsın diye 1440 dakikalık ızgara öğleden öğlene kurulur.
- **Sembol sözlüğü domain katmanında** (`dreams/domain/dream_symbols.dart`). Kod içi sabit veridir, yerelleştirme gerekmediği için `AppStrings` dışında tutulur.
- **Kabus öneri kartı ücretsiz:** güvenlik ve iyi oluş bilgisi paywall arkasına konmaz (V4 ile aynı gerekçe).
- **Sağlık kontrolü ücretsiz** (F3, V4).

## 9. Ek tur: F9 ve F10

| Kod | Ne yapıldı | Testçinin bulduğu / düzelttiği |
|---|---|---|
| F9 | Alt paneldeki 5. sekme Rutin → **Rüya** (`/dreams` kabuk sekmesi); Akşam rutini tam ekran `/routine`. Sorulu rüya yorumu `/dreams/interpret` (`?night=` ile günlükten): not → 6 soru → çıkarım (genel tema, duygu-yaşam bağlantısı, yansıtıcı sorular, öneri; premium: sembol × cevap ve uyku verisi bağlantısı). Saf motor `inferDream` (`dreams/domain/dream_interview.dart`). | 4 çelişkili şablon (kabus + sakin ton, sakin + huzur tekrarı, olumlu rüyada "işlenen duygu", sakin rüyada kontrol sorusu) düzeltildi; 8100 cevap kombinasyonunu tarayan regresyon testi eklendi. Kayıt yokken notun kaybolması `pendingDreamDraftProvider` ile giderildi. |
| F10 | `core/widgets/motion.dart` (CountUp, GrowIn, CelebrateBounce, AmbientBreath), FullPage'e kademeli giriş, yöne göre adım geçişi, StepProgress dolumu, PrimaryPillButton opaklık geçişi, PremiumGate solma, EmptyState girişi. Yeni tokenlar: `AppMotion.popScale`, `ambient`, `ambientScale`, `AppMotion.of`; `AppSizes.skeletonCard/Medium/Row`. | Hareket azaltma, gradient/blur/gölge yokluğu, dispose ve Semantics doğrulandı; Uyku modu etkilenmedi. |

Doğrulama (2026-10-21): `flutter analyze` → `No issues found!`; `flutter test` → `+302: All tests passed!`; iki §11 grep boş. Uygulama Android 12 cihazda (debug) açıldı, açılışta hata yok.

Açık noktalar: iç içe `Entrance` bazı yerlerde (EmptyState ikonu, PremiumLockCard, sembol kartları) giriş animasyonunu üst üste bindiriyor; taşınan rüya taslağı yalnız bellekte; README görselleri yeni ekranları içermiyor.
