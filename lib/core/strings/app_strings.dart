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

  String get log_startTitle => 'Bu gece için kayıt yok';

  String get log_startBody =>
      'Yatarken Uyku modunu başlat, uyanınca bitir. Süreyi yalnızca saat ölçer; sonra nasıl uyandığını eklersin.';

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
}
