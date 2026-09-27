# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Sleep & Recovery Tracker (Flutter)

Bu dosya projede çalışan her ajanın ve geliştiricinin **tek doğruluk kaynağıdır**. Renk, tipografi, ölçü, bileşen ve ekran kararları buradadır. Bir ekran promptu bu dosyayla çelişirse bu dosya kazanır; değişiklik gerekiyorsa önce burayı güncelle.

Görsel referans: `Uyku sağlığı uygulaması.html` (5 ekran × açık/koyu: Bugün, Trendler, Kalite, Kaydet, Akşam rutini) — **ana ekranlarda bu dosya kazanır**. Diğer ekranlar (Kurulum, Uyku modu, Ayarlar, Galeri) Design kanvası "Sleep & Recovery — Mobil Uygulama"ya göredir. Ölçüler 390×844 pt çerçeveye göredir.

---

## 1. Ürün özeti

- Uyku süresini, evrelerini (REM / Core / Post) ve kaliteyi gösteren sakin, premium bir takipçi.
- Uygulama yalnızca **Türkçe**dir.
- Veri kaynağı: cihazda (`shared_preferences`, JSON) elle kayıt + Uyku modu; evreler süreden tahmin edilir. İleride **HealthKit (iOS)** ve **Health Connect (Android)** aynı arayüzle.
- His: minimal, sakin, sıcak. Düz ve mat yüzeyler, kalın stroke'lu dairesel grafikler, yuvarlak hatlı kalın başlıklar.

## 2. Kesin yasaklar

- Gradient, cam (blur/glassmorphism), neon, gölge yığınları **yok**.
- Material varsayılan görünümü **yok**: ripple/ink splash, elevation gölgeleri, varsayılan `AppBar`, `FloatingActionButton`, `BottomNavigationBar`, `Card` elevation'ı kullanılmaz.
- `core/theme` dışında `Color(0x…)`, `Colors.*`, sabit `fontSize`, sabit `EdgeInsets` sayısı, sabit `BorderRadius` **yok**. Hepsi token'dan gelir.
- Widget içinde kullanıcıya görünen sabit string **yok**. Hepsi `AppStrings`'ten (`lib/core/strings/app_strings.dart`) gelir.
- Emoji UI öğesi olarak kullanılmaz.
- Sahte veri gerçekmiş gibi gösterilmez; fiyat vb. bilinmeyen değerler için mağaza verisi (RevenueCat/StoreKit) bağlanana kadar açıkça işaretli placeholder kullanılır.

## 3. Teknoloji yığını

`flutter pub add` ile güncel stable sürümleri ekle; sürümleri elle uydurma.

| Amaç | Paket |
|---|---|
| State | `flutter_riverpod` (elle yazılmış provider'lar) |
| Routing | `go_router` |
| Modeller | Düz Dart sınıfları; `copyWith`, `==`, `toJson`/`fromJson` elle yazılır |
| Grafik (bar) | `fl_chart` |
| Metin / biçim | `AppStrings` (düz Dart), `flutter_localizations` (sdk, yalnızca Material/Cupertino TR metinleri), `intl` (`NumberFormat`) |
| Depolama | `shared_preferences` |
| Bildirim | `flutter_local_notifications`, `timezone`, `flutter_timezone` |
| Ses | `just_audio`, `audio_session` (uyku sesleri; iOS'ta `UIBackgroundModes: audio`) |
| Font | `google_fonts` **yerine** fontları `assets/fonts/` altına göm (offline için) |
| Sağlık (sonra) | `health` |
| Lint | `very_good_analysis` |

Diğer kurallar:

- Dart 3, null-safety, `sealed class` ve pattern matching serbest.
- **Kod üretimi yok**: `build_runner`, `freezed`, `riverpod_generator`, `json_serializable`, `gen-l10n` kullanılmaz; `*.g.dart` / `*.freezed.dart` dosyası olmaz. `flutter run` öncesi ek adım gerekmez.
- Riverpod: `Provider`, `NotifierProvider`, `AsyncNotifierProvider`, `FutureProvider` elle tanımlanır (`@riverpod` varsayılanına denk olarak ekran durumları `.autoDispose`). UI yalnızca provider okur, repository'ye doğrudan dokunmaz.

## 4. Klasör yapısı (feature-first)

```
lib/
  main.dart                     # giriş noktası + UykuApp (tema, router, TR locale)
  core/
    theme/                      # app_colors.dart, sleep_stage_colors.dart, app_typography.dart,
                                # app_spacing.dart, app_radius.dart, app_shadows.dart,
                                # app_motion.dart, app_theme.dart
    widgets/                    # imza bileşenler (bölüm 7)
    router/                     # app_router.dart, transitions.dart
    providers/                  # sharedPreferences, clock, notificationService
    notifications/              # NotificationService (flutter_local_notifications)
    strings/                    # app_strings.dart (tüm kullanıcı metinleri)
    utils/                      # formatters.dart (süre, saat, ondalık)
  features/
    sleep_summary/  { domain, data, presentation }
    sleep_quality/  { domain, data, presentation }
    track_sleep/    { domain, data, presentation }
    trends/         { domain, data, presentation }
    sleep_log/      { domain, data, presentation }   # Kaydet; ortak SleepEntry + SleepRepository (+ rüya notu)
    insights/       { domain, presentation }         # Etken analizi (Trendler kartı)
    chronotype/     { domain, presentation }         # Kronotip testi
    weekly_report/  { domain, presentation }         # Haftalık rapor + Bugün kartı
    sounds/         { domain, data, presentation }   # Uyku sesleri, 4-7-8 nefes
    streaks/        { domain, presentation }         # Seriler ve rozetler
    routine/        { domain, data, presentation }   # Akşam rutini
    onboarding/     { domain, data, presentation }
    settings/       { domain, data, presentation }
  debug/
    component_gallery_screen.dart
```

- `domain/`: elle yazılmış değişmez modeller + **abstract** repository (`abstract interface class SleepRepository`).
- `data/`: `LocalSleepRepository` (shared_preferences); `HealthSleepRepository` sonradan aynı arayüzle eklenir. Provider override ile değiştirilir.
- `presentation/`: ekran, ekran-özel widget'lar, Riverpod controller'lar (`Notifier`).
- `core/theme/app_sizes.dart` (`AppSizes`): bileşen ölçüleri (dokunma hedefi, ikon, buton/chip yükseklikleri). Sabit boyut gerekiyorsa buraya ekle.

### 4.1 Veri akışı

- `main.dart`: `SharedPreferences` yüklenir ve `sharedPreferencesProvider`a override edilir (override edilmezse provider hata fırlatır). `notificationServiceProvider` web'de `NoopNotificationService`, diğer platformlarda `LocalNotificationService` ile gelir.
- Tek veri kaynağı `sleepLogProvider`dır (`features/sleep_log/presentation/sleep_log_providers.dart`, `AsyncNotifier<List<SleepEntry>>`, geceye göre artan sıralı). Bugün, Trendler, Kalite, Seriler, Rapor ve Etken analizi bu listeden türeyen provider'larla hesaplanır. Ayrı kalıcı özet tutulmaz.
- Kayıt kimliği gece anahtarıdır: `SleepEntry.id = nightKey(nightOf(wake))` (`2026-09-24`; uyanıştan 12 saat geriye gidilerek bulunan akşam). Tarih aritmetiğinde `addDays`/`dateOnly` kullan (DST güvenli). Gece başına tek kayıt vardır.
- Evreler (Derin/REM/Hafif) ölçülmez, `SleepStages` ile süreden **tahmin** edilir. UI bunu "tahmini" diye sunar.
- Şimdiki zaman yalnızca `clockProvider`dan okunur. `todayProvider` uygulama öne gelince (`AppLifecycleListener.onResume`) invalidate edilir.
- `settingsControllerProvider` (`UserSettings`): `onboardingDone` ve `trackingStart` (Uyku modu) alanlarını içerir. `appRouterProvider` bu iki alanı dinleyip `redirect` ile kurulum ve uyku modu kilitlerini uygular (`AppRoutes.beforeOnboarding`, `AppRoutes.whileTracking`). Yeni tam ekran rota eklerken bu kümeleri gözden geçir.
- Bildirim payload'ı rota string'idir; `UykuApp` bunu `router.push` ile açar. Açılışta `syncReminder()` planlı bildirimleri yeniden kurar.
- Dolu ekranları görmek için uygulamada **Ayarlar → Örnek verilerle doldur** kullanılır.

## 5. Tasarım tokenları

### 5.1 AppColors

| Token | Light | Dark | Kullanım |
|---|---|---|---|
| `background` | `#F4EDE2` | `#1A1411` | Scaffold (krem) |
| `surface` | `#FBF7F1` | `#251D19` | Kart, tile, tab bar |
| `surfaceMuted` | `#E8DFD1` | `#352B25` | Halka track'i, skeleton, segment zemini |
| `border` | `#DCD0BF` | `#40352D` | İnce ayraçlar, pasif plan kartı kenarı |
| `textPrimary` | `#2B211C` | `#F2EADF` | Ana metin |
| `textSecondary` | `#6F5F54` | `#B3A395` | İkincil metin, birimler, caption (≥4.5:1) |
| `espresso` (primary) | `#2B211C` | `#F2EADF` | Primary buton, seçili pill, seçili tab |
| `onEspresso` | `#F4EDE2` | `#2B211C` | Primary üstündeki metin/ikon |
| `espressoSoft` | `#6B5549` | `#A38878` | Toplam uyku halkası, Post |
| `espressoDeep` | `#2B211C` | `#5C463B` | Toplam halkası uç rozeti |
| `panel` | `#2B211C` | `#30251F` | Sleep Quality alt paneli |
| `onPanel` / `onPanelMuted` / `panelOutline` | `#F2EADF` / `#CDBFB1` / `#8A776A` | aynı | Panel içi metin ve outline butonlar |
| `sageTint` / `sageText` | `#DCE6D5` / `#43603C` | `#2E3A2B` / `#AECBA5` | DeltaBadge |
| `emberTint` / `emberText` | `#F6DCCD` / `#8A3A17` | `#3D2419` / `#F0A07A` | Negatif DeltaBadge |
| `honeyTint` / `honeyText` | `#F5E3BC` / `#7A5712` | `#3D3020` / `#E7B04A` | Öneri kartı ikon dairesi |
| `espressoSlice` | `#2B211C` | `#7A6254` | Fan grafiğinde "İyi" dilimi |
| `chipLine` | `#B8A999` | `#6B5B50` | Outline chip/stepper kenarı, kapalı switch |
| `goalLine` | `#8A776A` | `#8A776A` | Trend grafiği kesikli hedef çizgisi |
| `outline` | `#2B211C` %14 | `#F2EADF` %16 | Kart içi ayraç |

Dark tema koyu espresso tabanlıdır; saf siyah (`#000`) kullanılmaz.

### 5.2 SleepStageColors (tema bağımsız)

| Evre / anlam | Ana | Deep (rozet, dolu ikon dairesi) |
|---|---|---|
| `sage`: Normal, REM halkası, hedef üstü | `#8FAE86` | `#56704F` |
| `ember`: Core, Düzensiz, hedef altı, Track Sleep halkası | `#E27A4A` | `#A94F26` |
| `honey`: REM (fan), "En avantajlı", FloatingCenterAction | `#E7B04A` | `#A87A1F` |
| `lavender`: İnsomniak, yatış saati | `#B3A5D9` | `#6E5CA3` |
| `espressoSoft`: Toplam, Post | tema değeri | tema `espressoDeep` |

Evre renkleri ve kullanımları:

- Fan grafiğinde Core dilimi `espresso`dur: light'ta `#2B211C`, dark'ta `#7A6254`.
- Krem ikon yalnızca **deep** tonların üzerine konur. Ana tonlar (sage/honey) üzerine krem metin/ikon konmaz, kontrast yetmez.
- Renkle ayrılan her şey ikinci bir ipucu taşır: konum, etiket veya lejant.

### 5.3 AppTypography

Fontlar: **Nunito** (başlık ve sayılar, 700/800/900) ve **Figtree** (gövde, 400/500/600/700). Fallback: `system-ui`.

| Stil | Font | Ağırlık | Boyut / satır | Not |
|---|---|---|---|---|
| `displayNumber` | Nunito | 900 | 40 / 40, tracking −1 | Trend ortalaması. Birim 18pt/800 `textSecondary` |
| `ringValue` | Nunito | 900 | 24 / 26 | Halka merkezindeki süre |
| `clockValue` | Nunito | 800 | 32 / 32 | Kaydet ekranı saatleri |
| `eyebrow` | Figtree | 600 | 13 / 18 | Başlık üstü satır (`textSecondary`) |
| `cardTitle` | Figtree | 700 | 15 / 20 | Kart ve grup başlığı |
| `bodySmall` | Figtree | 400 | 13 / 19 | Kart açıklaması |
| `navLabel` | Figtree | 700 | 11 / 14 | Alt panel etiketi, grafik ekseni |
| `displayClock` | Nunito | 900 | 72 / 72, tracking −2 | Yalnızca Track Sleep |
| `titleLarge` | Nunito | 800 | 28 / 32 | Ekran başlığı |
| `titleMedium` | Nunito | 700 | 20 / 26 | Alt başlık ("Uyku süren") |
| `metric` | Nunito | 800 | 22 / 22 | StageMetricTile değeri, birim 13/700 |
| `button` | Nunito | 800 | 17 / 20 | Pill butonlar |
| `bodyLarge` | Figtree | 400 | 16 / 24 | Açıklama |
| `bodyMedium` | Figtree | 500 | 14 / 20 | Satır değeri, lejant |
| `label` | Figtree | 700 | 12 / 16, tracking +0.06em, BÜYÜK HARF | Grup başlığı |
| `caption` | Figtree | 500 | 12 / 16 | Yasal metin, ipucu |

Sayı biçimi TR locale'e göredir, `NumberFormat` kullan:

- Ondalık ayırıcı virgüldür: **8,25 sa**.
- Süre: `7s 42dk` (EN `7h 42m`); evre değerleri `1:54 sa`; hedef `8 saat`.
- Saat formatı `HH:mm`.
- Aralıklarda en-dash kullanılır: `06:30 – 07:00`.

### 5.4 AppSpacing

`xxs 2 · xs 4 · xsPlus 6 · sm 8 · smPlus 10 · md 12 · mdPlus 14 · lg 16 · lgPlus 18 · xl 24 · xxl 32 · xxxl 48`

- Bölüm arası boşluk `lgPlus` (18), tile ızgarası `smPlus` (10).

- Ekran yatay padding'i `xl` (24).
- Üst içerik SafeArea + 8 ile başlar. Kanvastaki 56pt üst boşluk durum çubuğunu temsil eder; sahte status bar çizme.
- Thumb-zone CTA:
  - Tab bar varsa tab bar'ın `lg` (16) üstünde durur.
  - Tab bar yoksa SafeArea'nın `lg` üstünde durur.

### 5.5 AppRadius

`sm 8 · md 12 · mdPlus 16 · lgMinus 18 · lg 20 · lgPlus 24 · xl 28 · pill = StadiumBorder`

| Radius | Kullanım |
|---|---|
| `lg` | Tile ve stat kartı |
| `mdPlus` / `lgMinus` | Kalite satırı / rutin adımı |
| `lgPlus` | Grafik kartı, Kaydet kartı |
| `xl` | Grup kartı, alt panel üst köşeleri |
| `pill` | Butonlar, segment kontrol, gün şeridi |

### 5.6 AppShadows

- `none` varsayılandır.
- `lift` = `0 8 24` ile `espresso` %10, yalnızca tooltip için.
- Başka hiçbir yerde gölge yok.

### 5.7 AppMotion

| Token | Değer |
|---|---|
| `ringFill` | 900ms, `Curves.easeOutCubic`; halkalar arası 120ms gecikme |
| `pageTransition` | 280ms: fade + 16px dikey kayma, `CustomTransitionPage` |
| `sliceSelect` | 180ms, `easeOut`; seçili dilim 8px dışa |
| `celebrate` | 400ms bounce (rozet ölçeği 1 → 1.35 → 1) + `HapticFeedback.lightImpact()` |
| `holdToConfirm` | 1200ms lineer; bırakınca 150ms'de sıfıra döner |
| `skeletonPulse` | 900ms, opaklık 1 ↔ 0.5 (shimmer **değil**) |
| `entrance` | Sekme içeriği ilk açılışta: 420ms `easeOutCubic`, solma + 12px yükselme, öğe başı 45ms gecikme (en çok 5 öğe). Sonradan kaydırılarak gelenler animasyonsuz |
| `tabSwitch` | 220ms; sekme değişince içerik %40 opaklıktan ve 8px aşağıdan gelir |
| `pressScale` | Basılıyken 0.97 ölçek (`toggle` süresiyle), opaklık düşüşüyle birlikte |
| `swap` | 240ms; buton etiketi değişince (ör. "Kaydedildi") solma + 0.97 → 1 ölçek |
| `chartMorph` | 380ms `easeOutCubic`; trend çubukları aralık değişince akar |

`MediaQuery.disableAnimations` true ise animasyonlar son değere atlar.

### 5.8 ThemeData

- `useMaterial3: true` açık kalır, ama varsayılanlar ezilir:
  - `splashFactory: NoSplash.splashFactory`
  - `highlightColor: transparent`
  - `scaffoldBackgroundColor: background`
- `ColorScheme` tokenlardan kurulur: `primary=espresso`, `onPrimary=onEspresso`, `surface=surface`.
- Tüm renk ve metin tokenları `ThemeExtension<AppColors>` üzerinden `context.colors`, `context.text` ile okunur.

## 6. Navigasyon

- `go_router` + `StatefulShellRoute.indexedStack` ile 5 sekme (HTML'deki alt panel):
  - **Bugün** `/` · **Trendler** `/trends` · ortada **Kaydet** `/log` · **Kalite** `/quality` · **Rutin** `/routine`
- Tam ekran rotalar (shell dışı): `/onboarding`, `/track`, `/settings`, `/goals`, `/chronotype`, `/report`, `/sounds`, `/breathe`, `/badges`, `/debug/gallery` (yalnızca `kDebugMode`). Ortak iskelet `FullPage` (`core/widgets/full_page.dart`).
- Kurulum bitmeden yalnızca `/onboarding` ve `/chronotype` açılır; Uyku modu açıkken yalnızca `/track`, `/sounds`, `/breathe`.
- Bildirime dokunulunca payload'daki rota açılır (haftalık rapor → `/report`).
- `AppNavPanel` özel widget'tır:
  - Ekran altına yapışık `panel` renkli blok, üst köşeler `xl` (28), içerik yüksekliği 72 + alt güvenli alan (en az 24).
  - 5 kolon; etiket + 22pt ikon. Seçili `honey`, diğerleri `onPanelMuted`.
  - Ortada `FloatingCenterAction` (64pt honey daire, 4px panel halkası, 30pt yukarı taşar) + "Kaydet" etiketi.
- Ayarlar, Bugün başlığındaki sağ üst `CircleIconButton`'dan açılır.
- İlk açılış: Kurulum → Bugün. Paywall şimdilik yok (abonelik kapsam dışı).
- Uyku modu açıkken uygulama her açılışta `/track`'e yönlenir.

## 7. İmza bileşenler (`core/widgets/`)

Hepsi yalnız token kullanır, light ve dark'ta çalışır.

1. **`SleepRingChart`**
   - Parametreler: `List<RingSegment> rings` (`value 0–1`, `color`, `badgeColor`, `IconData icon`), `double size`, `double strokeWidth = 20`, `double gap = 8`, `Widget? center`, `bool celebrate = false`.
   - `CustomPainter`. Halkalar dıştan içe çizilir ve her halkanın arkasında `surfaceMuted` track vardır. Stroke ucu yuvarlaktır, başlangıç −90°'dir.
   - Uç rozeti: yarıçap 12, `badgeColor` dolgu, içinde 12pt krem ikon. Konumu `c + r·cos(a)`, `c + r·sin(a)` ile hesaplanır.
   - `AnimationController` + `Interval` ile halka başına 120ms kaydırma.
   - `value ≥ 1` iken 0.9999'a kırp.
   - `Semantics(label:)` ile değerleri okunur hale getir.
2. **`SleepQualityFanChart`**
   - Parametreler: `List<FanSlice> slices` (`label`, `value`, `color`), `double sweepAngle = 120°`, `ValueChanged<int?> onSelect`.
   - Merkez widget'ın alt ortasındadır. Dilimler −150°'den −30°'ye değerle orantılı açılarla dizilir.
   - Dilim araları 2px `background` stroke'tur.
   - Dokunulan dilim 8px dışa kayar ve `lift` gölgeli espresso tooltip gösterir ("Normal · %38").
   - Hit test açı ve yarıçapla yapılır.
   - Ekranda espresso panelin **arkasında** durur (`Stack`): panelin üst kenarı merkezin 32pt üstündedir.
3. **`StageMetricTile`**
   - `label`, `value`, `unit`, `color`.
   - `surface` zemin, `lg` radius, 14/12 padding.
   - Üstte 10pt renkli nokta + `caption`, altta `metric` + birim.
4. **`PrimaryPillButton`**
   - 56 yükseklik, pill, espresso.
   - `label` + opsiyonel sağ ikon.
   - `onPressed == null` → %40 opaklık.
   - `holdToConfirm` varyantı Track Sleep'te kullanılır: 64 yükseklik, soldan dolan honey, içinde küçük ilerleme halkası.
5. **`CircleIconButton`**
   - 48pt (onboarding'de 56).
   - `outline` (1.5px `textPrimary`) ve `filled` (espresso) varyantları var.
   - Zorunlu `semanticLabel`.
6. **`DeltaBadge`**
   - 32 yükseklik pill.
   - `sageTint` zemin, `sageText` metin, yukarı ok.
   - Negatif değişimde ember tint + aşağı ok.
7. **`LegendDot`**
   - 10pt nokta + `bodyMedium` etiket.
   - `Wrap(spacing: 18, runSpacing: 10)`.
8. **`FloatingCenterAction`**
   - 68pt honey daire, espresso ikon, panel renginde 4px halka.
   - Panel barının 28pt üstüne taşar.

Ek paylaşılanlar:

- `AppTabBar`
- `SegmentedPill`: `surfaceMuted` zemin, seçili espresso, 40 yükseklik.
- `DayStrip`: 7 × 44×64 pill. Seçili olan espresso; hedef tutan günün altında 4pt sage nokta.
- `SettingsGroup` / `SettingsRow`.
- `SkeletonBlock`.
- `EmptyState`, `ErrorState`.

## 8. Ekranlar

| Ekran | Kanvas | Özet |
|---|---|---|
| Bugün | HTML 1 | Tarih + selam + ayarlar butonu → SleepRingChart 240pt (dış toplam/hedef, orta sage REM, iç ember Derin) merkezde "Dün gece · 7s 42dk" → 3 StageMetricTile (REM, Derin, Hafif) → DeltaBadge (geçen haftaya göre) → öneri kartı + "Akşam rutinini aç". |
| Kaydet | HTML 4 | Geri + "X gecesi" → yatış/uyanış ±5 dk → toplam → "Nasıl uyandın?" 5 chip → "Uykunu etkileyenler" 7 chip → "Uykuyu kaydet" (kaydedilince sage "Kaydedildi"). Altta "Uyku modunu başlat". |
| Akşam rutini | HTML 5 | Hatırlatıcı switch → ilerleme çubuğu → 5 işaretlenebilir adım. |
| Uyku Kalitesi | HTML 3 | "Son 30 gece" → 5 dilimli fan (Dinlendirici, İyi, Orta, Bölünmüş, Uykusuz), merkezde "%60 iyi geçen gece" → seçilebilir satır listesi. |
| Trendler | HTML 2 | Hafta/Ay/Yıl SegmentedPill → ortalama + DeltaBadge → `fl_chart` yığılı bar (Derin/REM/Hafif), kesikli hedef çizgisi, seçili bar tam opak → Ort. yatış / Ort. uyanış kartları. |
| Uyku modu | Uyku modu | Her zaman dark. Pill "Uyku modu" → 300pt ember halka içinde `displayClock` ve geçen süre → alarm penceresi → "Bitirmek için basılı tut" + hold-to-confirm "Uyandım" (1.2s). Bitince "Günaydın" özeti. `// TODO(brightness): screen_brightness ile parlaklığı düşür, çıkışta geri al.` `WakelockPlus` değerlendirilecek. |
| Kurulum (3 adım) | Kurulum 1–3 | Üstte 3 pill segment ilerleme. 1: hedef süre (±0.25 sa, 5–11 sa aralığı). 2: yatış saati, özel `BedtimePicker` (iki `CupertinoPicker`, 15 dk aralık; seçim bandı `espresso` pill, seçili satır `onEspresso` kalın, diğerleri `textSecondary`) + hesaplanan alarm penceresi. 3: Sağlık ve Bildirim izin kartları. Alt CTA'lar: Devam / Başlayalım. |
| Ayarlar | Ayarlar | Gruplar: Uyku, Uygulama, Veri. Kart `xl` radius. Satır 60pt: 36pt dolu **deep** renk daire + krem ikon, etiket, değer, chevron. Ayraç 1px `border`, 66pt içeriden başlar. |
| Etken analizi | Trendler altı kartı | Son 60 gecede her etken için etkenli/etkensiz gecelerin ortalama süresi ve iyi gece oranı; her iki tarafta en az 3 gece. Evreler tahmini olduğundan evre karşılaştırması yapılmaz; "neden-sonuç değildir" notu gösterilir. |
| Kronotip testi | `/chronotype` | 5 soru (kısaltılmış Horne–Östberg puanlaması: ≤11 akşamcı, ≥18 sabahçı) → tür + önerilen yatış (doğal uyanış − hedef süre, 15 dk'ya yuvarlı). Kurulum 2. adımdan ve Ayarlar'dan açılır; kurulumda saati geri döndürür, sonrasında ayara yazar. |
| Haftalık rapor | `/report` | Pazar akşamından cumartesi akşamına 7 gece. Ortalama + önceki haftaya fark, kayıtlı/hedefe ulaşılan gece, ort. yatış/uyanış, düzenlilik (yatış sapması), en iyi gece, en sık etken. Pazar 09:00 bildirimi (ayarla kapatılır); pazar günü Bugün'de kart. |
| Akıllı alarm | Uyku modu | Hafif uykuyu **ölçmez**: 15 dk dalma + 90 dk döngü varsayımıyla pencere (uyanış − 30 dk … uyanış) içindeki son döngü sonuna kurulur; yoksa pencere sonuna. Ekranda "tahmini" yazar. Ayarlar'dan ve Uyku modu boş ekranından kapatılır. |
| Uyku sesleri | `/sounds` | Uyku müziği, Piyano, Uyku döngüsü, Lo-fi (`assets/sounds/*.mp3`, döngüde çalar). Zamanlayıcı 15/30/60 dk/sürekli, sonunda 8 sn kısılarak durur. Rutin kartından ve Uyku modundan açılır. |
| 4-7-8 nefes | `/breathe` | 4 sn al, 7 sn tut, 8 sn ver; 4 tur. Bitince rutindeki nefes adımı işaretlenir. Hareket azaltmada daire büyümez. |
| Rüya günlüğü | Kaydet ekranı | Etkenlerin altında serbest not (en çok 1000 karakter); kayıtla birlikte saklanır. |
| Seriler ve rozetler | `/badges` + Bugün kartı | Seri: hedef süreye ulaşılan ardışık geceler (dün gecenin kaydı henüz yoksa önceki geceden sayılır). 11 rozet kayıtlardan hesaplanır; yalnızca "görüldü" listesi saklanır, yeni rozet Bugün'de işaretlenir. |
| Hedef ayarları | `/goals` | Hedef süre, hedef yatış, hafta sonu esnekliği (0/30/60/90/120 dk; cuma ve cumartesi geceleri yatış ve uyanış kayar). Hatırlatıcı her gece için ayrı haftalık bildirim; alarm, Bugün önerisi ve rutin de geceye göre hedefi kullanır. |
| Durumlar | Özet · boş/yükleniyor/hata | Boş: track'ler + ay ikonu + "İlk uykunu kaydet" + CTA. Yükleniyor: `surfaceMuted` bloklar, opaklık nabzı. Hata: sakin dil + outline "Tekrar dene". |
| Bileşen Galerisi | Bileşen Galerisi sayfası | `/debug/gallery`: Halka / Kontrol / Fan / Renk / Ölçü sekmeleri, light + dark. |

## 9. Erişilebilirlik

- Dokunma hedefleri ≥ 44×44 pt (Android'de 48dp tercih edilir).
- Metin kontrastı ≥ 4.5:1 (24pt üstü ≥ 3:1).
- Her ikon-only butonda `Semantics(label)` bulunur.
- Grafiklerde özet `Semantics` bulunur ("Toplam 8,25 saat, REM 2,14 saat…").
- `textScaler` 1.3'te taşma olmaz. Gerekirse satırlar sarılır, sayılar `FittedBox` ile küçülür.
- Hold-to-confirm için `Semantics(onLongPress:)` ve ekran okuyucu için alternatif onay eylemi tanımlanır.
- Hareket azaltma ayarına uyulur (bkz. 5.7).

## 10. Metinler

- Tüm kullanıcı metinleri `lib/core/strings/app_strings.dart` içindeki `AppStrings` sınıfındadır; widget'ta `AppStrings.of(context)`, context yoksa `AppStrings.instance`.
- Üye adlandırması `ekran_öğe` biçimindedir: `summary_title`, `summary_trackCta`, parametreli olanlar metot (`quality_delta(...)`).
- Süre metinleri: `{hours}s {minutes}dk` biçimi `duration_hm` gibi metotlardadır.
- Uzun metinler `textScaler` 1.3'te taşmamalı.

## 11. Doğrulama

Projede test yok.

```sh
flutter pub get
flutter run              # ilk açılışta Kurulum gelir
flutter analyze
```

- `pubspec.yaml`: `path_provider_android` 2.2.x'e sabitlenmiştir (2.3+ NDK 28.2 indirtir). Kaldırmadan önce sor.
- Uyku sesi eklemek için dosyayı `assets/sounds/` altına koy ve `lib/features/sounds/domain/sleep_sound.dart` içindeki `SleepSound`'a ekle. (`tool/generate_sounds.py` eski WAV gürültü üreticisidir; mevcut MP3'leri üretmez.)
- Uygulama ikonu `python tool/generate_icon.py` ile üretilir (Pillow): Android legacy + adaptive + monochrome, iOS, web. İkonu değiştirmek için PNG'leri elle düzenleme, scripti değiştirip yeniden çalıştır.

1. `flutter analyze` **0 uyarı** vermeli (`very_good_analysis`).
2. Sabit değer taraması:
   - `grep -rn "Color(0x" lib/ | grep -v core/theme` → **boş** olmalı.
   - `grep -rnE "Text\('[^']" lib/features` → **boş** olmalı (`AppStrings` dışı string).

## 12. Çalışma biçimi (ajanlar için)

- Önce bu dosyayı oku, sonra ilgili feature klasörünü.
- Yeni token gerekiyorsa önce `core/theme`e ve bu dosyaya ekle, sonra kullan.
- Ekranları bitirmeden önce Bileşen Galerisi'nde bileşeni göster; onay sonrası ekrana geç.
- Küçük, odaklı değişiklikler yap. Sorulmadan yeniden tasarım yapma.
- Commit mesajları: `feat(summary): …`, `fix(theme): …`.
