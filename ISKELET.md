# ISKELET.md — Uyku: Premium sürüm kapsamı

Bu dosya **yeni özellik dalgasının** sınırlarını çizer: ne yapıyoruz, ne yapmıyoruz, ne zaman "bitti" diyoruz. Tasarım tokenları, bileşenler ve mevcut ekranlar için tek doğruluk kaynağı `CLAUDE.md`'dir; burası onunla çelişirse `CLAUDE.md` kazanır. Agent davranışı: `AGENT.md`.

---

## 1. Amaç

Mevcut ücretsiz takipçiyi (Bugün, Trendler, Kaydet, Kalite, Rutin, Uyku modu, sesler, rapor, rozetler) bozmadan, cihazda çalışan ve sağlık iddiasında bulunmayan **premium** bir katman eklemek:

1. Uyku sağlığını tek bakışta anlatan **Uyku sağlığı** ekranı (skor, uyku borcu, düzenlilik, sosyal jetlag, öz-kontrol).
2. Rüya günlüğünü **rüya yorumu** ve tekrar eden sembol analiziyle zenginleştirmek.
3. Bunları satın alınabilir bir **Premium** üyeliğe bağlamak (mağaza bağlantısı sonra).

## 2. Araştırma özeti (Ekim 2026)

| Bulgu | Kaynak türü | Uygulamaya yansıması |
|---|---|---|
| Sleep Cycle, Pillow vb. premium katmanda akıllı alarm, ayrıntılı trend, horlama kaydı, sağlık entegrasyonu sunuyor; tipik fiyat 3–15 $/ay, ~40 $/yıl. | Uygulama karşılaştırma yazıları | Premium = derin analiz + rüya yorumu + dışa aktarma. Temel takip ücretsiz kalır. |
| Rüya günlüğü uygulamaları duygu etiketi, rüya türü (normal / berrak / kabus / tekrarlayan), kişisel sembol kütüphanesi ve tekrar eden sembolleri öne çıkarıyor; hepsi "psikolojik analiz değildir" uyarısı veriyor. | App Store listeleri (Dreamiary, Drift, DreamOn, Somnia) | Rüya kaydına tür + duygu; sembol sözlüğü cihazda; zorunlu uyarı metni. |
| Uyku Düzenlilik İndeksi (SRI), ardışık günlerde aynı saatte aynı durumda (uyku/uyanık) olma olasılığıdır; süreden bağımsızdır. | Brown CS / Sleep as Android | Düzenlilik skoru dakika ızgarasında SRI ile hesaplanır. |
| Sosyal jetlag = serbest günlerin uyku orta noktası − iş günlerinin orta noktası. | JUKUSUI, JMIR mHealth 2019 | Hafta sonu (cuma/cumartesi gecesi) vs hafta içi orta nokta farkı. |
| STOP-Bang (≥3 risk), Epworth (0–24, >10 artmış uykululuk), ISI (0–28, ≥15 klinik) yaygın tarama ölçekleri; Epworth ve ISI telif ve lisans gerektirir. | Klinik formlar, Nature and Science of Sleep 2025 | Lisanslı ölçekler **birebir kopyalanmaz**; kendi yazdığımız 6 soruluk "Uyku sağlığı kontrolü" yalnızca "bir uzmana danışmayı düşün" sinyali verir, tanı koymaz. |

## 3. Kapsam

### 3.1 Kapsam içi (bu dalga)

| Kod | Özellik | Premium mu? | Klasör |
|---|---|---|---|
| F1 | **Premium altyapısı**: `PremiumRepository` (abstract) + `LocalPremiumRepository`, `premiumProvider`, `PremiumGate` widget'ı, `/premium` tanıtım ekranı (paywall), Ayarlar'da "Premium" satırı | — | `features/premium/` |
| F2 | **Uyku sağlığı ekranı** `/health`: Uyku sağlığı skoru (0–100) + uyku borcu (14 gece) + düzenlilik (SRI) + sosyal jetlag + açıklamalar. Bugün'de özet kartı | Skor ve borç ücretsiz; bileşen dökümü, 30 gecelik skor grafiği ve öneriler premium | `features/health/` |
| F3 | **Uyku sağlığı kontrolü** `/health/check`: 6 soruluk kendi yazdığımız öz-kontrol (horlama/nefes durması, gün içi uyuklama, dalma güçlüğü, gece uyanma, sabah yorgunluğu, bacak huzursuzluğu) → sonuç kartları ve "uzmana danış" yönlendirmesi | **Ücretsiz** (güvenlik bilgisi paywall arkasında olmaz) | `features/health/` |
| F4 | **Rüya günlüğü 2.0**: kayda rüya türü (`DreamKind`: normal, lucid, nightmare, recurring) ve duygu (`DreamEmotion`: 6 adet) eklenir; `/dreams` liste ekranı (arama + tür filtresi); Ayarlar → "Örnek verilerle doldur" rüya notu/tür/duygu da üretir | Liste ücretsiz | `features/dreams/` + `sleep_log` modeli |
| F5 | **Rüya yorumu** `/dreams/:night`: cihazdaki TR sembol sözlüğü (≥ 60 sembol, her biri 1–2 cümle yansıtıcı yorum), notta geçen sembollerin bulunması, duygu + tür üzerinden genel tema, "bu yorum bilimsel değildir" uyarısı | **Premium** (ücretsizde ilk 1 sembol görünür, kalanı kilitli) | `features/dreams/` |
| F6 | **Rüya içgörüleri**: son 90 gecede en sık 5 sembol, kabus oranı, kabus gecelerinin ortalama uyku süresi vs diğerleri, etkenlerle birlikte görülme (en az 3 gece kuralı) | **Premium** | `features/dreams/` |
| F7 | **Dışa aktarma**: tüm kayıtları CSV olarak panoya kopyala (Ayarlar → Veri) | **Premium** | `features/settings/` |
| F9 | **Rüya sekmesi + sorulu rüya yorumu**: alt paneldeki 5. sekme "Rutin" yerine **"Rüya"** olur (`/dreams` shell sekmesi); Akşam rutini tam ekran `/routine` olarak Bugün'deki öneri kartından ve Ayarlar'dan açılır. Rüya sekmesinin üstünde "Rüyanı yorumla" girişi: rüyayı yaz (veya günlükten seç) → adım adım 6 soru (baskın duygu, uyanınca his, kontrol sende miydi, tanıdık kişiler, şu anki yaşam teması, tekrar ediyor mu) → çıkarım sayfası | Sorular + özet çıkarım ücretsiz; derin çıkarım (sembol × cevap bağlantıları, uyku verisiyle ilişki) premium | `features/dreams/` |
| F10 | **Görsel ve animasyon cilası**: yeni ekranlar (Premium, Uyku sağlığı, Sağlık kontrolü, Rüya listesi/detay/yorum) ana ekranlarla aynı hareket dilini kullanır (`AppMotion.entrance`, `ringFill`, `pressScale`, `swap`, `chartMorph`); skor sayısı sayarak gelir; adım geçişleri kayarak/solarak; seçimlerde ölçek geri bildirimi; tutarlı kart hiyerarşisi | — | ilgili `presentation/` |
| F8 | **Doğrulama altyapısı**: `flutter_test` (sdk) dev bağımlılığı, `test/` altında saf domain testleri | — | `test/` |

### 3.2 Kapsam dışı (bu dalgada yapılmaz)

- Gerçek ödeme (RevenueCat / StoreKit / Play Billing) — fiyat placeholder'dır, satın alma butonu yalnızca debug'da yerel kilidi açar.
- Bulut senkronu, hesap/giriş, sunucu.
- Yapay zekâ / LLM ile rüya yorumu (ağ gerekir, gizlilik riski). Sembol sözlüğü cihazdadır.
- Mikrofonla horlama kaydı, hareket sensörüyle evre ölçümü.
- Tıbbi tanı, ilaç önerisi, lisanslı ölçeklerin (Epworth, ISI, STOP-Bang, PSQI) metni.
- Mevcut ücretsiz özelliklerin premium'a taşınması (kullanıcıdan özellik geri almak yok).
- Yeni dil desteği.

## 4. Veri modeli

Tümü elle yazılmış, değişmez, `copyWith` / `==` / `toJson` / `fromJson` içerir (CLAUDE.md §3).

| Varlık | Alanlar | Saklama |
|---|---|---|
| `SleepEntry` (genişler) | + `DreamKind? dreamKind`, + `List<DreamEmotion> dreamEmotions` (boşsa JSON'a yazılmaz; eski kayıtlar okunabilir kalır) | `sleepLogProvider` (mevcut anahtar) |
| `PremiumStatus` | `bool active`, `DateTime? since`, `PremiumSource source` (`none`, `debug`, `store`) | `shared_preferences` anahtarı `premium.v1` |
| `HealthSnapshot` (türetilir, saklanmaz) | `int score`, `int debtMinutes`, `double? regularity` (0–100), `int? socialJetlagMinutes`, `List<HealthComponent> components` | — |
| `HealthComponent` | `HealthComponentKind kind` (duration, regularity, debt, mood), `int points`, `int max` | — |
| `HealthCheckResult` | `Map<HealthQuestion, int> answers`, `List<HealthFlag> flags`, `DateTime takenAt` | `health.check.v1` (son sonuç) |
| `DreamSymbol` (sabit veri) | `String id`, `List<String> keywords` (küçük harf, TR kökler), `String title`, `String meaning` | Kod içi sabit liste |
| `DreamReading` (türetilir) | `List<DreamSymbol> symbols`, `String? theme`, `DreamKind? kind` | — |

## 5. Hesaplama kuralları (ölçülebilir)

- **Uyku borcu**: son 14 gecenin her biri için `max(0, hedef − süre)`; kaydı olmayan gece hesaba katılmaz. Fazla uyku borcu en fazla gece başına 60 dk düşürür ("geri ödeme"); geceler eskiden yeniye işlenir ve borç hiçbir adımda 0'ın altına inmez (önceden fazla uyumak sonraki borcu peşin ödemez).
- **Düzenlilik (SRI)**: son 14 gecede ardışık kayıtlı gün çiftleri için 1440 dakikalık ızgarada aynı durumda olma oranı; `SRI = 200·p − 100`, ekranda 0–100'e kırpılır. En az 5 ardışık çift yoksa `null` ("Daha fazla kayıt gerekli").
- **Sosyal jetlag**: son 28 gecede hafta sonu gecesi (cuma/cumartesi) orta noktası ortalaması − hafta içi orta noktası ortalaması (dakika, mutlak değer). Her iki grupta en az 2 gece yoksa `null`.
- **Uyku sağlığı skoru** (0–100, son 14 gece, en az 3 kayıt; yoksa `null`):
  - Süre 40 puan: ortalama süre hedefin %90'ı ve üstündeyse 40; %70 ve altında 0; arası doğrusal.
  - Düzenlilik 25 puan: `SRI/100·25` (SRI yoksa bu bileşen dışarıda bırakılır ve skor 75 üzerinden 100'e ölçeklenir).
  - Borç 20 puan: borç 0 → 20, 7 saat ve üstü → 0, arası doğrusal.
  - Uyanış hissi 15 puan: `WakeMood` ortalaması (0–4) /4 · 15.
  - Bantlar: 85+ "Çok iyi", 70–84 "İyi", 50–69 "Orta", <50 "Geliştirilebilir".
- **Sağlık kontrolü bayrakları** (her soru 0–3, "Hiç / Bazen / Sık / Neredeyse her gece"):
  - Horlama/nefes durması ≥ 2 → `breathing` (metin: "Uykuda nefes düzeni" + "Bir uzmana danışmayı düşün"; kullanıcı metninde hastalık adı geçmez).
  - Gün içi uyuklama ≥ 2 → `daytimeSleepiness`.
  - Dalma güçlüğü + gece uyanma toplamı ≥ 4 → `insomniaSymptoms`.
  - Bacak huzursuzluğu ≥ 2 → `restlessLegs`.
  - Bayrak yoksa "Belirgin bir işaret yok" kartı. Her sonuçta "Bu bir tanı değildir" notu.
- **Rüya sembolü eşleşmesi**: not küçük harfe çevrilir (TR `İ→i`, `I→ı`), noktalama atılır; sembol anahtar kelimesi bir kelimenin **başında** geçerse eşleşir (TR ekleri: "suda", "suyun" → `su`). Aynı sembol bir notta bir kez sayılır.

## 6. Navigasyon eklemeleri

Shell dışı tam ekran rotalar: `/premium`, `/health`, `/health/check`, `/dreams`, `/dreams/:night`. Hepsi `FullPage` iskeletini kullanır. Kurulum ve Uyku modu kilit kümeleri (`AppRoutes.beforeOnboarding`, `whileTracking`) **değişmez**. Giriş noktaları:

- Bugün: Uyku sağlığı özet kartı → `/health`.
- Kaydet: rüya notu varsa "Rüyanı yorumla" bağlantısı → `/dreams/:night`.
- Ayarlar: Premium satırı → `/premium`; "Rüya günlüğü" → `/dreams`; Veri grubunda "CSV olarak kopyala" (F7).
- Kilitli her premium yüzey `PremiumGate` ile sarılır: içerik `surfaceMuted` blokla örtülür, kilit ikonu + "Premium ile aç" butonu `/premium`'a gider.

## 7. Kabul kriterleri

| Kod | Kriter |
|---|---|
| F1 | Premium kapalıyken kilitli yüzeylerin hepsi `PremiumGate` gösterir; `/premium` ekranında fiyat **"Fiyat mağaza bağlanınca gösterilecek"** placeholder'ıyla görünür; debug derlemede "Premium'u dene (geliştirici)" butonu kilidi açar, uygulama yeniden başlatılınca kalıcıdır; release derlemede bu buton yoktur. |
| F2 | Örnek verilerle doldurulmuş uygulamada `/health` skor, borç, SRI ve jetlag'i gösterir; 3'ten az kayıtta skor yerine `EmptyState`; `computeHealthSnapshot` için en az 6 birim testi geçer (boş, 3 kayıt, tam hedef, borç tavanı, SRI null, jetlag null). |
| F3 | 6 sorunun hepsi cevaplanmadan "Sonucu gör" pasif (%40 opak); her bayrak kuralı birim testle doğrulanır; sonuç ekranında "Bu bir tanı değildir" metni her durumda görünür. |
| F4 | Eski JSON (rüya alanı yok) hatasız okunur (test); Kaydet'te tür ve duygu seçimi kayıtla saklanır; `/dreams` yalnız notu olan geceleri yeniden eskiye listeler, arama notta geçen metni süzer. |
| F5 | Sözlükte ≥ 60 sembol; "Suda yüzüyordum, sonra yılan gördüm" notu `su` ve `yılan` sembollerini bulur (test); ücretsizde yalnız ilk sembol açık; her yorum ekranında uyarı metni görünür. |
| F6 | 90 gecede en sık 5 sembol sıralı döner; kabus oranı ve süre karşılaştırması her iki tarafta ≥ 3 gece yoksa gösterilmez (test). |
| F7 | Premium açıkken CSV başlık satırı `gece,yatis,uyanis,sure_dk,uyanis_hissi,etkenler,ruya_turu,not` ile panoya kopyalanır ve "Kopyalandı" geri bildirimi görünür; virgül/tırnak içeren not RFC 4180'e göre kaçırılır (test). |
| F9 | Alt panelde Rüya sekmesi görünür ve seçilince `/dreams` açılır; `/routine` tam ekran açılır ve Bugün'deki "Akşam rutinini aç" onu push eder; yorum akışında her soru tek ekranda, "İleri" cevapsız pasif, "Geri" önceki cevabı korur; 6 soru sonunda çıkarım sayfası en az 3 bölüm üretir (genel tema, duygu-yaşam bağlantısı, öneri soru/egzersiz); çıkarım motoru saf fonksiyon ve ≥10 birim testi; aynı girdi aynı çıktıyı verir; çıkarım taslağı yalnız "Kaydet" ile geceye bağlanır; uyarı metni görünür. |
| F10 | `MediaQuery.disableAnimations` true iken tüm yeni animasyonlar son değere atlar; gradient/blur/gölge eklenmez; animasyon süreleri yalnız `AppMotion` tokenlarından gelir; 60 fps hedefi için animasyonlar `AnimatedBuilder`/implicit widget ile sınırlı alt ağaçları yeniden çizer. |
| F8 | `flutter test` 0 hata; `flutter analyze` 0 uyarı; CLAUDE.md §11'deki iki grep boş. |
| Tümü | Light + dark'ta çalışır; `textScaler` 1.3'te taşma yok; yeni ikon-only butonlarda `Semantics`; tüm metinler `AppStrings`'te. |

## 8. Geliştirme sırası

1. F8 (test altyapısı) + F1 (premium) — diğerleri `PremiumGate`'e bağlı.
2. F2 + F3 (sağlık) — `sleepLogProvider` ve ayarlardan türer.
3. F4 (model genişlemesi) → F5 → F6 (rüya).
4. F7 (dışa aktarma).
5. Bileşen galerisine `PremiumGate` ve skor halkası eklenir; CLAUDE.md §6–§8 güncellenir.

## 9. Riskler ve önlemler

| Risk | Önlem |
|---|---|
| Sağlık metinleri tanı gibi algılanır, mağaza reddi (Apple 1.4.1, Google Health policy). | Her sağlık ve rüya ekranında sabit uyarı; "tanı", "hastalık var" ifadeleri yok; yalnız "bir uzmana danışmayı düşün". |
| Lisanslı ölçeklerin (Epworth, ISI) izinsiz kullanımı. | Kendi yazdığımız sorular; ölçek adları ve puan aralıkları kullanılmaz. |
| Sahte fiyat gerçek gibi görünür (CLAUDE.md §2). | Fiyat yerine açık placeholder metni; satın alma butonu release'te pasif ve "Yakında" etiketli. |
| `SleepEntry` şema değişikliği eski kayıtları bozar. | Yeni alanlar opsiyonel, `fromJson` varsayılanlı; geriye uyumluluk birim testi. |
| Paralel ajanlar `app_strings.dart` ve router'da çakışır. | Ajanlar sırayla çalışır; her feature kendi `// <Bölüm>` başlığı altına string ekler. |
| SRI az veride yanıltıcı. | Eşik altında `null` ve "Daha fazla kayıt gerekli". |

## 10. Varsayımlar

- V1: Mevcut tüm özellikler ücretsiz kalır; premium yalnız yeni derin analizleri kapsar.
- V2: Ödeme sağlayıcısı bu dalgada yok; entitlement `LocalPremiumRepository`'de, mağaza gelince `StorePremiumRepository` aynı arayüzle eklenir.
- V3: Rüya yorumu kural tabanlıdır ve cihazdadır; LLM yok.
- V4: Sağlık kontrolü güvenlik bilgisi olduğu için ücretsizdir.
- V5: `CLAUDE.md`'deki "Projede test yok" kuralı bu dalgayla değişir: domain, provider, router ve widget testleri eklenir; golden test yoktur.
- V6: Yeni paket eklenmez; panoya kopyalama `flutter/services.dart` `Clipboard` ile yapılır.
