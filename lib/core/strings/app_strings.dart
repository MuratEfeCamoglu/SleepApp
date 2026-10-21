// Uygulama metinleri. Uygulama yalnızca Türkçedir; kullanıcıya görünen her
// metin buradan okunur.
// ignore_for_file: non_constant_identifier_names, lines_longer_than_80_chars

import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class AppStrings {
  const AppStrings._();

  static const instance = AppStrings._();

  static const locale = Locale('tr');

  /// Material/Cupertino bileşenlerinin kendi metinleri (tarih seçici vb.).
  static const localizationsDelegates = <LocalizationsDelegate<Object>>[
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  static const List<Locale> supportedLocales = [locale];

  /// Widget'lar metinleri buradan okur.
  static AppStrings of(BuildContext context) => instance;

  String get appTitle => 'Uyku';

  String get nav_label => 'Ana menü';

  String get nav_today => 'Bugün';

  String get nav_trends => 'Trendler';

  String get nav_log => 'Kaydet';

  String get nav_logSemantic => 'Uykunu kaydet';

  String get nav_quality => 'Kalite';

  String get nav_routine => 'Rutin';

  String get nav_dreams => 'Rüya';

  String get common_back => 'Geri';

  String get common_close => 'Kapat';

  String get common_cancel => 'Vazgeç';

  String get common_retry => 'Tekrar dene';

  String get common_errorTitle => 'Bir şeyler ters gitti';

  String get common_errorBody =>
      'Verilerine şu an ulaşamadık. Birazdan tekrar dene.';

  String get common_loading => 'Yükleniyor';

  String duration_hm(int hours, int minutes) {
    return '${hours}s ${minutes}dk';
  }

  String duration_h(int hours) {
    return '${hours}s';
  }

  String duration_m(int minutes) {
    return '${minutes}dk';
  }

  String duration_minutes(int minutes) {
    return '$minutes dk';
  }

  String duration_stage(String value) {
    return value;
  }

  String duration_goal(String hours) {
    return '$hours saat';
  }

  String get unit_hour => 's';

  String get unit_minute => 'dk';

  String get unit_stage => ' sa';

  String time_range(String start, String end) {
    return '$start – $end';
  }

  String delta_value(String sign, int minutes) {
    return '$sign$minutes dk';
  }

  String get stage_rem => 'REM';

  String get stage_deep => 'Derin';

  String get stage_light => 'Hafif';

  String get today_greetingMorning => 'Günaydın';

  String get today_greetingDay => 'İyi günler';

  String get today_greetingEvening => 'İyi akşamlar';

  String get today_greetingNight => 'İyi geceler';

  String get today_settings => 'Ayarlar';

  String get today_lastNight => 'Dün gece';

  String today_nightOf(String date) {
    return '$date gecesi';
  }

  String today_ringSemantic(
    String label,
    String duration,
    int total,
    int rem,
    int deep,
  ) {
    return '$label: $duration. Hedefin yüzde $total kadarı. REM hedefin yüzde $rem kadarı, derin uyku yüzde $deep kadarı.';
  }

  String today_deltaWeek(String delta) {
    return 'Geçen haftaya göre $delta';
  }

  String get today_tipTitle => 'Bu geceki önerin';

  String today_tipEarlier(String time, String goal, int minutes) {
    return 'Saat $time gibi yatmayı dene. $goal hedefine ulaşmak için dün geceden $minutes dk erken.';
  }

  String today_tipLater(String time, int minutes) {
    return 'Saat $time gibi yatmayı dene. Dün gece $minutes dk erken yattın; bu ritmi korumak da iyi gelir.';
  }

  String today_tipOnTrack(String time, String goal) {
    return 'Saat $time gibi yatmayı dene. Dün geceki düzenini koru; $goal hedefin için doğru yoldasın.';
  }

  String today_tipNoData(String time, String goal, String wake) {
    return 'Saat $time gibi yatmayı dene. $goal hedefiyle uyanış saatin $wake olur.';
  }

  String get today_openRoutine => 'Akşam rutinini aç';

  String get today_emptyTitle => 'İlk uykunu kaydet';

  String get today_emptyBody =>
      'Bu gece yatarken Uyku modunu başlat, uyanınca bitir; halkalar burada dolacak.';

  String get trends_eyebrow => 'Uyku süresi';

  String get trends_title => 'Trendler';

  String get trends_rangeLabel => 'Zaman aralığı';

  String get trends_week => 'Hafta';

  String get trends_month => 'Ay';

  String get trends_year => 'Yıl';

  String get trends_average => 'Ortalama';

  String trends_deltaWeek(String delta) {
    return 'Geçen haftaya göre $delta';
  }

  String trends_deltaMonth(String delta) {
    return 'Geçen aya göre $delta';
  }

  String trends_deltaYear(String delta) {
    return 'Geçen yıla göre $delta';
  }

  String trends_goal(String duration) {
    return 'Hedef $duration';
  }

  String get trends_noData => 'Kayıt yok';

  String get trends_avgBed => 'Ort. yatış';

  String get trends_avgWake => 'Ort. uyanış';

  String trends_weekShort(int n) {
    return '$n. hf';
  }

  String trends_weekFull(int n) {
    return '$n. hafta';
  }

  String trends_barSemantic(String label, String value) {
    return '$label, $value';
  }

  String trends_chartSemantic(String average) {
    return 'Uyku süresi grafiği. Ortalama $average.';
  }

  String get trends_emptyTitle => 'Henüz trend yok';

  String get trends_emptyBody =>
      'Birkaç gece kaydettiğinde uyku sürenin nasıl değiştiğini burada göreceksin.';

  String get quality_eyebrow => 'Son 30 gece';

  String get quality_title => 'Uyku kalitesi';

  String get quality_goodNights => 'iyi geçen gece';

  String quality_nights(int count) {
    return '$count gece';
  }

  String quality_percent(int value) {
    return '%$value';
  }

  String quality_tooltip(String label, String nights) {
    return '$label · $nights';
  }

  String quality_fanSemantic(String summary) {
    return 'Son 30 gecenin kaliteye göre dağılımı. $summary';
  }

  String get quality_restorative => 'Dinlendirici';

  String get quality_good => 'İyi';

  String get quality_fair => 'Orta';

  String get quality_fragmented => 'Bölünmüş';

  String get quality_sleepless => 'Uykusuz';

  String get quality_emptyTitle => 'Kalite için veri bekleniyor';

  String get quality_emptyBody =>
      'Son 30 gecede kayıt yok. Uykunu kaydettikçe gecelerin burada gruplanacak.';

  String get log_title => 'Uykunu kaydet';

  String log_nightOf(String weekday) {
    return '$weekday gecesi';
  }

  String get log_bedtime => 'Yatış';

  String get log_wake => 'Uyanış';

  String get log_total => 'Toplam uyku';

  String get log_moodTitle => 'Nasıl uyandın?';

  String get log_moodGroup => 'Uyanış hissi';

  String get log_moodExhausted => 'Bitkin';

  String get log_moodTired => 'Yorgun';

  String get log_moodNormal => 'Normal';

  String get log_moodRefreshed => 'Dinç';

  String get log_moodGreat => 'Harika';

  String get log_factorsTitle => 'Uykunu etkileyenler';

  String get log_factorsGroup => 'Etkenler';

  String get log_factorCaffeine => 'Kafein';

  String get log_factorAlcohol => 'Alkol';

  String get log_factorLateMeal => 'Geç yemek';

  String get log_factorExercise => 'Egzersiz';

  String get log_factorScreen => 'Ekran';

  String get log_factorStress => 'Stres';

  String get log_factorNoise => 'Gürültü';

  String get log_save => 'Uykuyu kaydet';

  String get log_saved => 'Kaydedildi';

  String get log_startSleepMode => 'Uyku modunu başlat';

  String routine_eyebrow(String time, String goal) {
    return 'Hedef yatış $time · $goal';
  }

  String get routine_title => 'Akşam rutini';

  String get routine_reminderTitle => 'Yatma vakti hatırlatıcısı';

  String routine_reminderBody(String time) {
    return 'Saat $time olunca rutine başlaman için bildirim';
  }

  String get routine_permissionDenied =>
      'Bildirim izni kapalı; hatırlatıcı gelmeyecek.';

  String get routine_grant => 'İzin ver';

  String get routine_tonight => 'Bu akşam';

  String routine_progress(int done, int total) {
    return '$done / $total tamamlandı';
  }

  String get routine_step1Title => 'Ekranları bırak';

  String routine_step1Note(String time) {
    return '$time · telefonu yatak odası dışında şarj et';
  }

  String get routine_step2Title => 'Işıkları kıs';

  String routine_step2Note(String time) {
    return '$time · sıcak, loş ışık';
  }

  String get routine_step3Title => '4-7-8 nefes egzersizi';

  String get routine_step3Note => '5 dk';

  String get routine_step4Title => 'Yarının listesini yaz';

  String get routine_step4Note => '3 dk · aklını boşalt';

  String get routine_step5Title => 'Odayı serinlet';

  String get routine_step5Note => '18–20 °C ideal';

  String get settings_title => 'Ayarlar';

  String get settings_groupSleep => 'Uyku';

  String get settings_groupApp => 'Uygulama';

  String get settings_groupData => 'Veri';

  String get settings_goal => 'Hedef süre';

  String get settings_bedtime => 'Hedef yatış';

  String get settings_wake => 'Uyanış';

  String get settings_theme => 'Tema';

  String get settings_themeSystem => 'Sistem';

  String get settings_themeLight => 'Açık';

  String get settings_themeDark => 'Koyu';

  String get settings_reminder => 'Yatma hatırlatıcısı';

  String get settings_on => 'Açık';

  String get settings_off => 'Kapalı';

  String get settings_clear => 'Tüm kayıtları sil';

  String get settings_clearTitle => 'Tüm kayıtlar silinsin mi?';

  String get settings_clearBody =>
      'Uyku kayıtların ve rutin geçmişin silinir, ayarların kalır. Bu işlem geri alınamaz.';

  String get settings_clearConfirm => 'Sil';

  String get settings_gallery => 'Bileşen galerisi';

  String get settings_sample => 'Örnek verilerle doldur';

  String get settings_sampleTitle => 'Örnek verilerle doldurulsun mu?';

  String get settings_sampleBody =>
      'Son 60 gece örnek kayıtlarla (rüya notları dahil) doldurulur. Aynı gecelerdeki kayıtların üzerine yazılır.';

  String get settings_sampleConfirm => 'Doldur';

  String get settings_sampleDone => 'Örnek veriler eklendi';

  String settings_version(String version) {
    return 'Sürüm $version';
  }

  String get settings_estimateNote =>
      'Evreler (REM, derin, hafif) süreden tahmin edilir; tıbbi ölçüm değildir.';

  String get settings_save => 'Kaydet';

  String onboarding_step(int current, int total) {
    return 'Adım $current / $total';
  }

  String get onboarding_goalTitle => 'Kaç saat uyumak istiyorsun?';

  String get onboarding_goalBody =>
      "Yetişkinler için önerilen aralık 7–9 saat. Sonra Ayarlar'dan değiştirebilirsin.";

  String get onboarding_goalMinus => 'Hedefi 15 dakika azalt';

  String get onboarding_goalPlus => 'Hedefi 15 dakika artır';

  String get onboarding_bedTitle => 'Genelde ne zaman yatarsın?';

  String get onboarding_bedBody =>
      'Önerilerini ve hatırlatıcını hedef yatış saatine göre ayarlarız.';

  String onboarding_wakeWindow(String time, String range) {
    return 'Uyanış $time · alarm penceresi $range';
  }

  String get onboarding_permTitle => 'Hatırlatıcılar';

  String get onboarding_permBody =>
      'Yatma vaktine yaklaşınca nazikçe haber verelim.';

  String get onboarding_notifTitle => 'Bildirimler';

  String get onboarding_notifBody =>
      'Yatma hatırlatıcısı ve Uyku modu alarmı için.';

  String get onboarding_notifAllow => 'İzin ver';

  String get onboarding_notifGranted => 'İzin verildi';

  String get onboarding_notifDenied =>
      "İzin verilmedi. Ayarlar'dan açabilirsin.";

  String get onboarding_healthTitle => 'Sağlık verisi';

  String get onboarding_healthBody =>
      'Apple Sağlık ve Health Connect desteği yakında.';

  String get onboarding_healthSoon => 'Yakında';

  String get onboarding_continue => 'Devam';

  String get onboarding_start => 'Başlayalım';

  String get track_mode => 'Uyku modu';

  String track_elapsed(String duration) {
    return 'Geçen süre $duration';
  }

  String track_alarmWindow(String range) {
    return 'Alarm penceresi $range';
  }

  String get track_holdHint => 'Bitirmek için basılı tut';

  String get track_wake => 'Uyandım';

  String get track_holdSemantic => 'Uyandım. Onaylamak için basılı tut.';

  String get track_cancel => 'Uyku modunu kapat';

  String get track_cancelTitle => 'Uyku modu kapatılsın mı?';

  String get track_cancelBody => 'Bu oturum kaydedilmeyecek.';

  String get track_cancelConfirm => 'Kapat';

  String get track_morningTitle => 'Günaydın';

  String track_morningBody(String duration) {
    return '$duration uyudun. Nasıl uyandığını ekleyerek kaydı tamamla.';
  }

  String get track_morningCta => 'Kaydı tamamla';

  String get track_tooShort =>
      'Oturum 20 dakikadan kısa olduğu için kaydedilmedi.';

  String get track_home => "Bugün'e dön";

  String track_ringSemantic(String duration, int percent) {
    return 'Uyku süresi $duration, hedefin yüzde $percent kadarı.';
  }

  String get notif_bedtimeTitle => 'Rutin vakti';

  String get notif_bedtimeBody =>
      'Ekranları bırakıp akşam rutinine başlama zamanı.';

  String get notif_bedtimeChannel => 'Yatma hatırlatıcısı';

  String get notif_alarmTitle => 'Günaydın';

  String get notif_alarmBody =>
      'Uyanma pencereni geldi. Uyandığında Uyku modunu bitir.';

  String get notif_alarmChannel => 'Uyandırma alarmı';

  String get gallery_title => 'Bileşen galerisi';

  String get gallery_rings => 'Halka';

  String get gallery_controls => 'Kontrol';

  String get gallery_fan => 'Fan';

  String get gallery_colors => 'Renk';

  String get gallery_sizes => 'Ölçü';

  String get gallery_darkTheme => 'Koyu tema';

  String get gallery_replay => 'Animasyonu yeniden oynat';

  String get log_startTitle => 'Bu gece için kayıt yok';

  String get log_startBody =>
      'Yatarken Uyku modunu başlat, uyanınca bitir. Süreyi yalnızca saat ölçer; sonra nasıl uyandığını eklersin.';

  String get log_pendingDream =>
      'Rüya notun saklandı; uykunu kaydettiğinde not alanına eklenecek.';

  // Etken analizi

  String get insights_title => 'Etkenler ve uykun';

  String insights_subtitle(int nights) => 'Son $nights gece karşılaştırması';

  String get insights_whenCaffeine => 'Kafein aldığın gecelerde';

  String get insights_whenAlcohol => 'Alkol aldığın gecelerde';

  String get insights_whenLateMeal => 'Geç yemek yediğin gecelerde';

  String get insights_whenExercise => 'Egzersiz yaptığın gecelerde';

  String get insights_whenScreen => 'Yatmadan ekrana baktığın gecelerde';

  String get insights_whenStress => 'Stresli gecelerde';

  String get insights_whenNoise => 'Gürültülü gecelerde';

  String insights_less(String when, String duration) =>
      '$when ortalama $duration daha az uyudun.';

  String insights_more(String when, String duration) =>
      '$when ortalama $duration daha fazla uyudun.';

  String insights_same(String when) => '$when uyku süren pek değişmedi.';

  String insights_goodRate(int withValue, int withoutValue) =>
      'İyi geçen gece: %$withValue · diğer gecelerde %$withoutValue';

  String insights_nights(int withNights, int withoutNights) =>
      '$withNights gece etkenli, $withoutNights gece etkensiz';

  String get insights_emptyBody =>
      'Kaydet ekranında etkenleri işaretledikçe neyin uykunu nasıl etkilediğini burada göreceksin. Her etken için en az 3 gece gerekir.';

  String insights_pending(String factor, int nights, int needed) =>
      '$factor: $nights/$needed gece';

  String get insights_note =>
      'Karşılaştırmadır, neden-sonuç göstermez. Evreler tahmini olduğu için süre ve iyi gece oranı kullanılır.';

  // Kronotip testi

  String get chrono_title => 'Kronotip testi';

  String chrono_progress(int n, int total) => 'Soru $n / $total';

  List<String> get chrono_questions => const [
    'Hiçbir yükümlülüğün olmayan bir günde kaçta uyanırdın?',
    'Uyandıktan sonraki ilk yarım saatte kendini nasıl hissedersin?',
    'Akşam kaçta yorgunluk hissedip uyumak istersin?',
    'Günün hangi saatlerinde en iyi hissedersin?',
    'Kendini nasıl tanımlarsın?',
  ];

  List<List<String>> get chrono_options => const [
    [
      '05:00 – 06:30',
      '06:30 – 07:45',
      '07:45 – 09:45',
      '09:45 – 11:00',
      "11:00'den sonra",
    ],
    ['Çok yorgun', 'Biraz yorgun', 'Oldukça dinç', 'Çok dinç'],
    [
      '20:00 – 21:00',
      '21:00 – 22:15',
      '22:15 – 00:45',
      '00:45 – 02:00',
      "02:00'den sonra",
    ],
    ['Sabah erken', 'Öğleden önce', 'Öğleden sonra', 'Akşam ve gece'],
    [
      'Kesinlikle sabahçı',
      'Akşamcıdan çok sabahçı',
      'Sabahçıdan çok akşamcı',
      'Kesinlikle akşamcı',
    ],
  ];

  String get chrono_next => 'Devam';

  String get chrono_seeResult => 'Sonucu gör';

  String get chrono_resultEyebrow => 'Kronotipin';

  String get chrono_morning => 'Sabahçı';

  String get chrono_intermediate => 'Ara tip';

  String get chrono_evening => 'Akşamcı';

  String get chrono_morningBody =>
      'Enerjin sabahın erken saatlerinde yüksek. Erken yatıp erken kalkmak sana doğal gelir.';

  String get chrono_intermediateBody =>
      'Ne çok erkenci ne de gece kuşusun. Her gün aynı saatte yatman en çok işine yarar.';

  String get chrono_eveningBody =>
      'Enerjin akşama doğru artar. Yatışını kademeli öne çekmek ve sabah gün ışığına çıkmak ritmini dengeler.';

  String get chrono_suggestionTitle => 'Önerilen yatış';

  String chrono_suggestionBody(String bed, String wake, String goal) =>
      '$goal hedefinle $bed yatış, $wake uyanış.';

  String get chrono_apply => 'Bu saati kullan';

  String get chrono_keep => 'Şimdilik değil';

  String get chrono_note =>
      'Kısa bir öz değerlendirmedir, tıbbi tanı değildir.';

  String get chrono_settingsRow => 'Kronotip';

  String get chrono_notTaken => 'Testi yap';

  String get chrono_onboardingLink => 'Emin değil misin? Kronotip testini yap';

  // Haftalık rapor

  String get report_title => 'Haftalık rapor';

  String report_range(String first, String last) => '$first – $last';

  String get report_average => 'Ortalama uyku';

  String report_delta(String delta) => 'önceki haftaya göre $delta';

  String get report_logged => 'Kayıtlı gece';

  String report_loggedValue(int nights, int total) => '$nights / $total';

  String get report_goalNights => 'Hedefe ulaşılan';

  String report_nightsValue(int nights) => '$nights gece';

  String get report_goodNights => 'İyi geçen';

  String get report_consistency => 'Düzenlilik';

  String report_spread(String minutes) =>
      'Yatış saatin ortalamadan $minutes sapmış.';

  String get report_spreadGood =>
      'Çok düzenli bir hafta; vücut saatin bunu sever.';

  String get report_spreadFair =>
      'Fena değil. Yatışı her gün aynı 30 dakikaya toplamak işine yarar.';

  String get report_spreadPoor =>
      'Yatış saatin epey oynamış. Önce yatış saatini sabitlemeyi dene.';

  String get report_bestNight => 'En iyi gecen';

  String report_bestNightValue(String day, String duration, String mood) =>
      '$day · $duration · $mood';

  String get report_topFactor => 'En sık etken';

  String report_topFactorValue(String factor, int nights) =>
      '$factor · $nights gece';

  String get report_emptyTitle => 'Geçen hafta kayıt yok';

  String get report_emptyBody =>
      'Bu hafta Uyku modunu kullan; pazar sabahı raporun burada olur.';

  String get report_cardTitle => 'Haftalık raporun hazır';

  String report_cardBody(String average, int nights) =>
      'Ortalama $average · $nights gece kayıt';

  String get report_open => 'Raporu aç';

  String get report_setting => 'Haftalık rapor';

  String get notif_weeklyTitle => 'Haftalık raporun hazır';

  String get notif_weeklyBody => 'Geçen haftanın uykusuna bir göz at.';

  String get notif_weeklyChannel => 'Haftalık rapor';

  // Akıllı alarm

  String get smart_title => 'Akıllı alarm';

  String smart_at(String time) => 'Alarm $time · tahmini hafif uyku';

  String smart_fallback(String time) =>
      'Döngü sonu pencereye denk gelmiyor; alarm $time';

  String smart_off(String time) => 'Alarm $time';

  String get smart_note =>
      'Uyku döngüsü tahminine göredir; hafif uykuyu ölçmez.';

  // Uyku sesleri ve nefes

  String get sounds_eyebrow => 'Rahatla';

  String get sounds_title => 'Uyku sesleri';

  String get sound_music => 'Uyku müziği';

  String get sound_piano => 'Piyano';

  String get sound_cycle => 'Uyku döngüsü';

  String get sound_lofi => 'Lo-fi';

  String get sound_musicNote => 'Yumuşak ve sakin';

  String get sound_pianoNote => 'Yavaş piyano';

  String get sound_cycleNote => 'Derin ve dingin';

  String get sound_lofiNote => 'Hafif ritim';

  String get sounds_group => 'Ses seçimi';

  String get sounds_timer => 'Zamanlayıcı';

  String sounds_timerMinutes(int minutes) => '$minutes dk';

  String get sounds_timerEndless => 'Sürekli';

  String get sounds_play => 'Çal';

  String get sounds_stop => 'Durdur';

  String sounds_status(String sound, int minutes) =>
      '$sound çalıyor · $minutes dk sonra kısılarak durur';

  String sounds_statusEndless(String sound) => '$sound çalıyor';

  String get sounds_note =>
      'Ses döngüde çalar, ekran kilitliyken de sürer. Zamanlayıcı bitince yavaşça kısılır.';

  String get breathe_eyebrow => 'Rehberli nefes';

  String get breathe_title => '4-7-8 nefes';

  String get breathe_intro =>
      'Burnundan 4 saniye nefes al, 7 saniye tut, ağzından 8 saniyede ver. Dört tur yeterli.';

  String get breathe_in => 'Nefes al';

  String get breathe_hold => 'Tut';

  String get breathe_out => 'Nefes ver';

  String breathe_round(int n, int total) => 'Tur $n / $total';

  String get breathe_start => 'Başla';

  String get breathe_stop => 'Bitir';

  String get breathe_doneTitle => 'Tamamlandı';

  String get breathe_doneBody =>
      'Rutindeki nefes adımı işaretlendi. Şimdi yatağa geçebilirsin.';

  String get breathe_again => 'Bir daha';

  String get relax_title => 'Rahatlamana yardım';

  String get relax_body =>
      'Uykuya dalmadan önce bir ses aç ya da nefes egzersizi yap.';

  String get relax_start => 'Başla';

  // Rüya günlüğü

  String get dream_title => 'Rüya günlüğü';

  String get dream_body =>
      'Hatırladığın rüyayı ya da sabah aklından geçenleri kısaca yaz.';

  String get dream_hint => 'Bu gece rüyamda…';

  // Seriler ve rozetler

  String get streak_eyebrow => 'Motivasyon';

  String get streak_title => 'Seriler ve rozetler';

  String get streak_current => 'Güncel seri';

  String get streak_best => 'En iyi seri';

  String streak_nights(int nights) => '$nights gece';

  String streak_cardTitle(int nights) => '$nights gece üst üste hedefte';

  String get streak_cardStart => 'Seriye başla';

  String streak_cardBody(int best) => 'En iyi serin $best gece';

  String get streak_cardStartBody =>
      'Hedef süreni tuttuğun her gece seriye eklenir.';

  String get streak_newBadge => 'Yeni rozet';

  String get streak_badges => 'Rozetler';

  String streak_progress(int value, int target) => '$value / $target';

  String get streak_earned => 'Kazanıldı';

  String get streak_locked => 'Kilitli';

  String get badge_firstNight => 'İlk gece';

  String get badge_firstNightBody => 'İlk uykunu kaydet.';

  String get badge_streak3 => 'Isınma';

  String get badge_streak3Body => '3 gece üst üste hedefe ulaş.';

  String get badge_streak7 => 'Bir hafta';

  String get badge_streak7Body => '7 gece üst üste hedefe ulaş.';

  String get badge_streak14 => 'İki hafta';

  String get badge_streak14Body => '14 gece üst üste hedefe ulaş.';

  String get badge_streak30 => 'Bir ay';

  String get badge_streak30Body => '30 gece üst üste hedefe ulaş.';

  String get badge_nights10 => '10 gece';

  String get badge_nights10Body => '10 gece kaydet.';

  String get badge_nights50 => '50 gece';

  String get badge_nights50Body => '50 gece kaydet.';

  String get badge_nights100 => '100 gece';

  String get badge_nights100Body => '100 gece kaydet.';

  String get badge_restful5 => 'Dinlenmiş';

  String get badge_restful5Body => '5 dinlendirici gece geçir.';

  String get badge_steady7 => 'Saat gibi';

  String get badge_steady7Body =>
      '7 gece üst üste hedef yatışının 30 dakika yakınında yat.';

  String get badge_dreamer5 => 'Rüya avcısı';

  String get badge_dreamer5Body => 'Rüya günlüğüne 5 not yaz.';

  // Hedef ayarları

  String get goals_eyebrow => 'Uyku';

  String get goals_title => 'Hedeflerin';

  String get goals_duration => 'Hedef süre';

  String get goals_durationBody =>
      'Yetişkinler için önerilen aralık 7–9 saattir.';

  String get goals_bedtime => 'Hedef yatış';

  String goals_weekdayPreview(String bed, String wake) =>
      'Hafta içi: $bed yatış, $wake uyanış';

  String goals_weekendPreview(String bed, String wake) =>
      'Hafta sonu: $bed yatış, $wake uyanış';

  String get goals_weekend => 'Hafta sonu esnekliği';

  String get goals_weekendBody =>
      'Cuma ve cumartesi geceleri yatış ve uyanış bu kadar ileri kayar. Hatırlatıcı ve alarm da buna göre kurulur.';

  String get goals_weekendNone => 'Yok';

  String goals_weekendHours(String hours) => '$hours sa';

  String get goals_chronoLink => 'Kronotip testiyle öneri al';

  String get goals_open => 'Hedefleri düzenle';

  String get time_separator => ':';

  // Premium

  String get premium_title => 'Premium';

  String get premium_lead =>
      'Uykunu daha derinden anla. Temel takip her zaman ücretsiz kalır.';

  String get premium_compareTitle => 'Neler var?';

  String get premium_colFree => 'Ücretsiz';

  String get premium_colPremium => 'Premium';

  String get premium_rowTracking => 'Uyku kaydı, trendler ve kalite';

  String get premium_rowRoutine =>
      'Akşam rutini, uyku sesleri ve haftalık rapor';

  String get premium_rowHealthFree => 'Uyku sağlığı skoru ve kontrolü';

  String get premium_rowHealth => 'Uyku sağlığı ayrıntıları ve skor geçmişi';

  String get premium_rowDreamsFree => 'Rüya günlüğü ve ilk sembolün yorumu';

  String get premium_rowDreamReading => 'Rüya yorumunun tamamı ve genel tema';

  String get premium_rowDreamInsights => 'Rüya içgörüleri';

  String get premium_rowDreamInterviewFree => 'Sorulu rüya yorumu (özet)';

  String get premium_rowDreamInterviewDeep =>
      'Sembol ve uyku bağlantılı derin yorum';

  String get premium_rowExport => 'CSV dışa aktarma';

  String premium_rowSemantic(String feature, {required bool free}) => free
      ? "$feature: ücretsiz ve Premium'da var"
      : "$feature: yalnızca Premium'da var";

  String get premium_priceTitle => 'Fiyat';

  String get premium_pricePlaceholder => 'Fiyat mağaza bağlanınca gösterilecek';

  String get premium_comingSoon => 'Yakında';

  String get premium_tryDebug => "Premium'u dene (geliştirici)";

  String get premium_disableDebug => "Premium'u kapat (geliştirici)";

  String get premium_active => 'Premium aktif';

  String get premium_activeBody => 'Tüm Premium özellikler açık.';

  String premium_activeSince(String date) => '$date tarihinden beri açık.';

  String get premium_gateTitle => 'Premium özellik';

  String get premium_gateBody => 'Bu bölüm Premium ile açılır.';

  String get premium_unlock => 'Premium ile aç';

  String get premium_settingsGroup => 'Üyelik';

  String get premium_settingsRow => 'Premium';

  String get premium_settingsActive => 'Aktif';

  String get premium_settingsInactive => 'Kapalı';

  // Dışa aktarma

  String get export_csvRow => 'CSV olarak kopyala';

  String get export_locked => 'Premium';

  String get export_empty => 'Kayıt yok';

  String get export_copied => 'Kopyalandı';

  // Uyku sağlığı

  String get health_title => 'Uyku sağlığı';

  String get health_eyebrow => 'Son 14 gece';

  String get health_scoreLabel => 'Uyku sağlığı skoru';

  String get health_scoreMax => '/100';

  String get health_bandVeryGood => 'Çok iyi';

  String get health_bandGood => 'İyi';

  String get health_bandFair => 'Orta';

  String get health_bandNeedsWork => 'Geliştirilebilir';

  String health_ringSemantic(int score, String band) =>
      'Uyku sağlığı skoru 100 üzerinden $score, $band.';

  String health_basedOn(int nights) => 'Son 14 gecedeki $nights kayda göre.';

  String get health_debt => 'Uyku borcu';

  String get health_debtBody =>
      'Hedefin altında kalan sürelerin toplamı. Hedefi aşan geceler borcu biraz azaltır.';

  String get health_regularity => 'Düzenlilik';

  String get health_regularityBody =>
      'Ardışık gecelerde aynı saatlerde uyuyup uyanma ölçüsü. 100 en düzenlisi.';

  String get health_jetlag => 'Sosyal jetlag';

  String get health_jetlagBody =>
      'Hafta sonu uyku saatinin hafta içine göre kayması (son 28 gece).';

  String get health_needMore => 'Daha fazla kayıt gerekli';

  String get health_premiumTitle => 'Ayrıntılı analiz';

  String get health_lockTitle => 'Skorunu daha yakından incele';

  String get health_lockBody =>
      'Skor dökümü, 30 gecelik geçmiş ve sana özel öneriler Premium ile açılır.';

  String get health_breakdownTitle => 'Skorun dökümü';

  String get health_compDuration => 'Süre';

  String get health_compRegularity => 'Düzenlilik';

  String get health_compDebt => 'Uyku borcu';

  String get health_compMood => 'Uyanış hissi';

  String health_points(int points, int max) => '$points / $max';

  String health_componentSemantic(String label, int points, int max) =>
      '$label: $max puan üzerinden $points';

  String get health_regularityExcluded =>
      'Düzenlilik için yeterli ardışık kayıt yok; skor diğer bileşenlerden hesaplandı.';

  String get health_historyTitle => 'Son 30 gece';

  String get health_historyEmpty => 'Grafik için daha fazla kayıt gerekli.';

  String health_historySemantic(int nights, int low, int high, int last) =>
      'Son 30 gecede $nights gece için skor var. En düşük $low, en yüksek $high, son değer $last.';

  String get health_tipsTitle => 'Önerilerin';

  String get health_tipPayDebtTitle => 'Borcu azalt';

  String get health_tipPayDebt => 'Bu hafta 2 gece 30 dk erken yat.';

  String get health_tipMoreSleepTitle => 'Süreyi artır';

  String get health_tipMoreSleep =>
      'Ortalaman hedefin altında. Yatışı 15 dk öne çekerek başla.';

  String get health_tipSteadyTitle => 'Saatini sabitle';

  String get health_tipSteady => 'Yatış saatini her gün ±30 dk içinde tut.';

  String get health_tipWeekendTitle => 'Hafta sonu kayması';

  String health_tipWeekend(String shift) =>
      'Hafta sonu uyku saatin $shift kayıyor. Farkı 1 saatin altında tutmayı dene.';

  String get health_tipWindDownTitle => 'Sakin bir geçiş';

  String get health_tipWindDown =>
      'Yatmadan 30 dk önce ekranı bırak ve akşam rutinine geç.';

  String get health_tipKeepGoingTitle => 'Ritmini koru';

  String get health_tipKeepGoing =>
      'Değerlerin iyi görünüyor; aynı düzende devam et.';

  String get health_emptyTitle => 'Biraz daha kayıt gerekli';

  String get health_emptyBody =>
      'Uyku sağlığı skoru için son 14 gecede en az 3 kayıt gerekir.';

  String get health_emptyAction => 'Uykunu kaydet';

  String get health_checkCardTitle => 'Uyku sağlığı kontrolünü yap';

  String get health_checkCardBody =>
      '6 kısa soruyla dikkat etmeye değer işaretlere bak. Ücretsiz.';

  String health_checkLast(String date) => 'Son kontrol: $date';

  String health_checkLastFlags(int count) => '$count işarete dikkat';

  String get health_checkLastClear => 'Belirgin bir işaret yok';

  String get health_disclaimer =>
      'Bu skor tahminidir, tıbbi değerlendirme değildir.';

  String health_cardTitle(int score, String band) =>
      'Uyku sağlığı $score · $band';

  String health_cardBody(String debt) => 'Uyku borcu $debt';

  String get health_checkTitle => 'Uyku sağlığı kontrolü';

  String get health_checkEyebrow => 'Son bir ay';

  String get health_checkLead =>
      'Son bir ayını düşünerek cevapla. Bu kontrol yalnızca dikkat etmeye değer işaretleri gösterir.';

  String health_checkProgress(int index, int total) => 'Soru $index / $total';

  String get health_qBreathing =>
      'Uyurken horladığını ya da nefesinin kısa süre durduğunu biri fark etti mi?';

  String get health_qDaytimeSleepiness =>
      'Gün içinde otururken, okurken ya da bir şey izlerken istemeden uyukladığın oluyor mu?';

  String get health_qFallingAsleep =>
      'Yattıktan sonra uykuya dalman yarım saatten uzun sürüyor mu?';

  String get health_qNightWaking =>
      'Gece uyanıp yeniden uykuya dalmakta zorlandığın oluyor mu?';

  String get health_qMorningTired =>
      'Yeterince uyuduğun gecelerden sonra bile yorgun uyandığın oluyor mu?';

  String get health_qRestlessLegs =>
      'Akşam dinlenirken bacaklarında huzursuzluk ya da onları oynatma isteği hissediyor musun?';

  String get health_answerNever => 'Hiç';

  String get health_answerSometimes => 'Bazen';

  String get health_answerOften => 'Sık';

  String get health_answerNightly => 'Neredeyse her gece';

  String get health_checkSubmit => 'Sonucu gör';

  String get health_checkRetake => 'Kontrolü yeniden yap';

  String get health_checkDone => 'Tamam';

  String get health_checkResultTitle => 'Sonucun';

  String health_checkTakenAt(String date) => '$date tarihinde yapıldı';

  String get health_flagBreathingTitle => 'Uykuda nefes düzeni';

  String get health_flagBreathing =>
      'Uykuda horlama ya da nefes duraklaması fark edilmiş. Bu, uykunun dinlendiriciliğini etkileyebilir.';

  String get health_flagDaytimeTitle => 'Gün içi uyuklama';

  String get health_flagDaytime =>
      'Gün içinde sık uyuklamak, gece uykusunun yeterince dinlendirmediğine işaret edebilir. Uykulu hissederken araç kullanma.';

  String get health_flagSleepContinuityTitle =>
      'Uykuya dalma ve uykuyu sürdürme';

  String get health_flagSleepContinuity =>
      'Uykuya dalmakta ya da gece yeniden uyumakta sık zorlanıyorsun. Bu uzun süredir devam ediyorsa üzerinde durmaya değer.';

  String get health_flagLegsTitle => 'Bacaklarda huzursuzluk';

  String get health_flagLegs =>
      'Akşamları bacaklarda huzursuzluk hissi uykuya geçişi zorlaştırabilir.';

  String get health_checkConsult => 'Bir uzmana danışmayı düşün.';

  String get health_checkClearTitle => 'Belirgin bir işaret yok';

  String get health_checkClear =>
      'Cevaplarında dikkat çeken bir işaret görünmüyor. Uykunda bir değişiklik fark edersen kontrolü yeniden yapabilirsin.';

  String get health_checkNote =>
      'Bu bir tanı değildir. Sonuç yalnızca cevaplarına dayanır; uykunla ilgili bir endişen varsa bir sağlık uzmanıyla konuş.';

  // Rüya

  String get dreams_title => 'Rüya günlüğü';

  String get dreams_eyebrow => 'Rüyaların';

  String get dreams_settingsRow => 'Rüya günlüğü';

  String get dreams_kindTitle => 'Rüya türü';

  String get dreams_kindGroup => 'Rüya türü, tek seçim';

  String get dreams_kindNormal => 'Normal';

  String get dreams_kindLucid => 'Berrak';

  String get dreams_kindNightmare => 'Kabus';

  String get dreams_kindRecurring => 'Tekrarlayan';

  String get dreams_emotionTitle => 'Rüyada ne hissettin?';

  String get dreams_emotionGroup => 'Rüyadaki duygular, çoklu seçim';

  String get dreams_emotionCalm => 'Sakin';

  String get dreams_emotionJoy => 'Neşe';

  String get dreams_emotionFear => 'Korku';

  String get dreams_emotionSadness => 'Hüzün';

  String get dreams_emotionAnger => 'Öfke';

  String get dreams_emotionConfusion => 'Karmaşa';

  String get dreams_readLink => 'Rüyanı yorumla';

  String get dreams_searchHint => 'Notlarda ara';

  String get dreams_searchLabel => 'Rüya notlarında ara';

  String get dreams_clearSearch => 'Aramayı temizle';

  String get dreams_filterLabel => 'Rüya türüne göre süz';

  String get dreams_filterAll => 'Tümü';

  String dreams_count(int count) => '$count rüya notu';

  String get dreams_emptyTitle => 'Henüz rüya notu yok';

  String get dreams_emptyBody =>
      'Kaydet ekranında rüya notu yazdığın geceler burada, yeniden eskiye listelenir.';

  String get dreams_emptyAction => 'Uykunu kaydet';

  String get dreams_noResultsTitle => 'Sonuç yok';

  String get dreams_noResultsBody =>
      'Aramana ya da seçtiğin türe uyan bir rüya notu bulunamadı.';

  String dreams_nightOf(String date) => '$date gecesi';

  String get dreams_detailTitle => 'Rüyan';

  String get dreams_noteTitle => 'Notun';

  String get dreams_readingTitle => 'Yorum';

  String get dreams_themeTitle => 'Genel tema';

  String get dreams_noTheme =>
      'Genel tema için Kaydet ekranında rüya türünü ya da duygunu ekleyebilirsin.';

  String get dreams_noSymbols => 'Bu notta sözlükteki bir sembol bulamadık.';

  String get dreams_readingLockTitle => 'Yorumun tamamı';

  String dreams_readingLockBody(int more) => more > 0
      ? '$more sembol daha ve genel tema Premium ile açılır.'
      : 'Genel tema Premium ile açılır.';

  String get dreams_suggestionTitle => 'Kabustan sonra';

  String get dreams_disclaimer =>
      'Rüya yorumları eğlence ve öz-yansıtma içindir; bilimsel veya tıbbi değildir.';

  String get dreams_editNote => 'Notu düzenle';

  String get dreams_missingTitle => 'Bu gece için rüya notu yok';

  String get dreams_missingBody =>
      'Not silinmiş ya da hiç yazılmamış olabilir. Kaydet ekranından ekleyebilirsin.';

  String get dreams_openJournal => 'Rüya günlüğüne dön';

  String get dreams_insightsTitle => 'Rüya içgörüleri';

  String dreams_insightsSubtitle(int nights) => 'Son $nights gece';

  String get dreams_insightsLockTitle => 'Rüyalarındaki örüntüleri gör';

  String get dreams_insightsLockBody =>
      'En sık sembollerin, kabus oranın ve kabus gecelerinde uykun Premium ile görünür.';

  String get dreams_insightsEmpty =>
      'Rüya notu, türü ya da duygusu girdiğin geceler arttıkça örüntüler burada görünür.';

  String get dreams_topSymbols => 'En sık semboller';

  String get dreams_topSymbolsEmpty =>
      'Notlarında henüz sözlükteki bir sembol geçmedi.';

  String dreams_symbolNights(int nights) => '$nights gece';

  String get dreams_nightmareRate => 'Kabus oranı';

  String dreams_percent(int percent) => '%$percent';

  String dreams_nightmareRateValue(int nightmares, int kinded) =>
      'Türünü girdiğin $kinded rüyanın $nightmares tanesi kabus';

  String get dreams_nightmareSleep => 'Kabus gecelerinde uyku';

  String dreams_nightmareLess(String duration) =>
      'Kabus gecelerinde ortalama $duration daha az uyudun.';

  String dreams_nightmareMore(String duration) =>
      'Kabus gecelerinde ortalama $duration daha fazla uyudun.';

  String get dreams_nightmareSame =>
      'Kabus gecelerinde uyku süren pek değişmedi.';

  String dreams_averages(String nightmare, String other) =>
      'Kabus: $nightmare · diğer rüyalı geceler: $other';

  String dreams_nightmareFactor(String factor, int nights) =>
      'Kabus gecelerinde en sık etken: $factor ($nights gece)';

  String dreams_needMore(int needed) =>
      'Karşılaştırma için kabus ve diğer rüyalarda en az $needed gece gerekli';

  String get dreams_insightsNote =>
      'Karşılaştırmadır, neden-sonuç göstermez. Sembol sayımı nottaki kelimelere dayanır.';

  // Rüya yorumu (sorulu)

  String get dreamsInterview_cardTitle => 'Rüyanı yorumla';

  String get dreamsInterview_cardBody =>
      'Rüyanı yaz, birkaç kısa soruyu yanıtla; birlikte sakin bir yorum çıkaralım.';

  String get dreamsInterview_cardCta => 'Başla';

  String get dreamsInterview_detailCta => 'Sorularla yorumla';

  String get dreamsInterview_eyebrow => 'Rüya yorumu';

  String get dreamsInterview_title => 'Rüyanı yorumla';

  String get dreamsInterview_resultTitle => 'Rüyanın yorumu';

  String dreamsInterview_step(int step, int total) => 'Adım $step / $total';

  String get dreamsInterview_noteTitle => 'Rüyanı anlat';

  String get dreamsInterview_noteBody =>
      'Aklında kalanları yaz; küçük ayrıntılar da işe yarar.';

  String get dreamsInterview_noteHint => 'Rüyamda…';

  String get dreamsInterview_noteLabel => 'Rüya notu';

  String dreamsInterview_pickedFrom(String date) => '$date gecesinden';

  String get dreamsInterview_pickClear => 'Kendi notumu yazacağım';

  String get dreamsInterview_kindTitle => 'Rüya türü (isteğe bağlı)';

  String get dreamsInterview_pickTitle => 'Günlükten seç';

  String get dreamsInterview_pickBody =>
      'Notu olan son gecelerden biriyle başla.';

  String get dreamsInterview_next => 'İleri';

  String get dreamsInterview_finish => 'Yorumu gör';

  String get dreamsInterview_none => 'Hiçbiri';

  String get dreamsInterview_q1Title => 'Rüyada en baskın duygu neydi?';

  String get dreamsInterview_q1Body => 'Aklında en çok kalan hissi seç.';

  String get dreamsInterview_q2Title => 'Uyandığında nasıl hissettin?';

  String get dreamsInterview_q2Body =>
      'Uyandıktan sonraki ilk birkaç dakikayı düşün.';

  String get dreamsInterview_q3Title => 'Rüyada kontrol sende miydi?';

  String get dreamsInterview_q3Body =>
      'Olayların gidişatını yönlendirebiliyor muydun?';

  String get dreamsInterview_q4Title => 'Rüyada tanıdık kişiler var mıydı?';

  String get dreamsInterview_q4Body => 'Birden çok seçebilirsin.';

  String get dreamsInterview_q5Title =>
      'Bu aralar hayatında en çok ne yer kaplıyor?';

  String get dreamsInterview_q5Body => 'Aklına ilk geleni seç.';

  String get dreamsInterview_q6Title =>
      'Bu rüya ya da benzeri tekrar ediyor mu?';

  String get dreamsInterview_q6Body => 'Benzer bir rüyayı daha önce gördün mü?';

  String get dreamsInterview_wakeRelieved => 'Rahatlamış';

  String get dreamsInterview_wakeUneasy => 'Huzursuz';

  String get dreamsInterview_wakeCurious => 'Meraklı';

  String get dreamsInterview_wakeTired => 'Yorgun';

  String get dreamsInterview_wakeNeutral => 'Nötr';

  String get dreamsInterview_controlYes => 'Evet';

  String get dreamsInterview_controlPartly => 'Kısmen';

  String get dreamsInterview_controlNo => 'Hayır';

  String get dreamsInterview_personFamily => 'Aile';

  String get dreamsInterview_personFriend => 'Arkadaş';

  String get dreamsInterview_personEx => 'Eski bir ilişki';

  String get dreamsInterview_personWork => 'İş ya da okuldan biri';

  String get dreamsInterview_personStranger => 'Yabancılar';

  String get dreamsInterview_lifeWork => 'İş ya da okul';

  String get dreamsInterview_lifeRelationships => 'İlişkiler';

  String get dreamsInterview_lifeHealth => 'Sağlık';

  String get dreamsInterview_lifeChange => 'Değişim ya da karar';

  String get dreamsInterview_lifeLoneliness => 'Yalnızlık';

  String get dreamsInterview_lifePeace => 'Huzur arayışı';

  String get dreamsInterview_recurFirst => 'İlk kez';

  String get dreamsInterview_recurSometimes => 'Bazen';

  String get dreamsInterview_recurOften => 'Sık sık';

  String get dreamsInterview_sectionTheme => 'Genel tema';

  String get dreamsInterview_sectionLife => 'Duygu ve yaşam bağlantısı';

  String get dreamsInterview_sectionReflect => 'Kendine sorabileceklerin';

  String get dreamsInterview_sectionSuggestion => 'Küçük bir öneri';

  String get dreamsInterview_sectionSymbols => 'Semboller ve cevapların';

  String get dreamsInterview_sectionSleep => 'Uykunla ilişkisi';

  String get dreamsInterview_symbolsLockTitle => 'Semboller ve cevapların';

  String get dreamsInterview_symbolsLockBody =>
      'Her sembolün yorumu ve cevaplarına göre bağlamı Premium ile açılır.';

  String get dreamsInterview_sleepLockTitle => 'Uykunla ilişkisi';

  String get dreamsInterview_sleepLockBody =>
      'Rüyalı gecelerinin uykuna nasıl yansıdığı Premium ile görünür.';

  String dreamsInterview_sleepAverage(int nights, String duration) =>
      'Rüya not ettiğin $nights gecede ortalama $duration uyudun.';

  String dreamsInterview_sleepNeedMore(int needed) =>
      'Uykunla bağlantı kurmak için en az $needed rüyalı gece gerekli. Rüyalarını not ettikçe burada görünür.';

  String get dreamsInterview_openBreathe => '4-7-8 nefesi aç';

  String get dreamsInterview_openRoutine => 'Akşam rutinini aç';

  String get dreamsInterview_saveNight => 'Geceye kaydet';

  String get dreamsInterview_saveYesterday => 'Dün geceye kaydet';

  String get dreamsInterview_saved => 'Kaydedildi';

  String get dreamsInterview_noEntry =>
      'Dün gece için uyku kaydı yok. Rüya notun Kaydet ekranına taşındı; uykunu kaydettiğinde not alanında hazır olacak.';

  String get dreamsInterview_noEntryAction => 'Uykunu kaydet';

  String get dreamsInterview_restart => 'Yeni bir rüya yorumla';
}
