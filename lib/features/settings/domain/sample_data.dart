import 'dart:math' as math;

import 'package:uyku/features/settings/domain/user_settings.dart';
import 'package:uyku/features/sleep_log/domain/sleep_entry.dart';

/// Ayarlar → "Örnek verilerle doldur" (yalnız geliştirici derlemesi):
/// dolu ekranları görmek için son [nights] geceye örnek kayıt üretir.
///
/// Aynı [seed] aynı listeyi verir. Gecelerin yaklaşık %40'ında rüya notu
/// vardır; bunların yaklaşık %15'i kabustur. Notlar rüya sözlüğündeki
/// sembolleri içerir. Kullanıcıya gerçek veri gibi sunulmaz: yalnız açıkça
/// istendiğinde yazılır.
List<SleepEntry> buildSampleEntries(
  DateTime today,
  UserSettings settings, {
  int nights = 60,
  int seed = 7,
}) {
  final rng = math.Random(seed);
  final lastNight = addDays(dateOnly(today), -1);
  final entries = <SleepEntry>[];
  var dreamIndex = 0;

  for (var i = nights - 1; i >= 0; i--) {
    final night = addDays(lastNight, -i);
    final hasDream = rng.nextDouble() < 0.4;
    // Her 7 rüyanın biri kabus (~%15).
    final nightmare = hasDream && dreamIndex % 7 == 3;

    var target = settings.bedtimeFor(night);
    // Gece yarısından sonraki hedef yatış ertesi güne düşer.
    if (target < 12 * 60) target += 24 * 60;
    final bedMinute = target + rng.nextInt(61) - 25 + (nightmare ? 20 : 0);
    final bedtime = DateTime(night.year, night.month, night.day, 0, bedMinute);
    var minutes = settings.goalMinutes - 75 + rng.nextInt(121);
    if (nightmare) minutes -= 35;
    final wake = bedtime.add(Duration(minutes: minutes));

    final ratio = minutes / settings.goalMinutes;
    final mood = nightmare
        ? WakeMood.tired
        : ratio >= 1.0
        ? (rng.nextBool() ? WakeMood.great : WakeMood.refreshed)
        : ratio >= 0.9
        ? WakeMood.normal
        : (rng.nextBool() ? WakeMood.tired : WakeMood.exhausted);

    final factors = <SleepFactor>{
      for (final f in SleepFactor.values)
        if (rng.nextDouble() < _factorOdds[f]!) f,
      if (nightmare) SleepFactor.stress,
    };

    var entry = SleepEntry(
      id: nightKey(night),
      bedtime: bedtime,
      wake: wake,
      mood: mood,
      factors: SleepFactor.values.where(factors.contains).toList(),
    );

    if (hasDream) {
      final pool = nightmare ? _nightmareNotes : _dreamNotes;
      final emotions = nightmare
          ? _nightmareEmotions[rng.nextInt(_nightmareEmotions.length)]
          : _dreamEmotions[rng.nextInt(_dreamEmotions.length)];
      entry = entry.copyWith(
        note: pool[rng.nextInt(pool.length)],
        dreamKind: nightmare
            ? DreamKind.nightmare
            : _dreamKinds[rng.nextInt(_dreamKinds.length)],
        dreamEmotions: DreamEmotion.values.where(emotions.contains).toList(),
      );
      dreamIndex++;
    }
    entries.add(entry);
  }
  return entries;
}

const _factorOdds = <SleepFactor, double>{
  SleepFactor.caffeine: 0.3,
  SleepFactor.alcohol: 0.1,
  SleepFactor.lateMeal: 0.2,
  SleepFactor.exercise: 0.35,
  SleepFactor.screen: 0.45,
  SleepFactor.stress: 0.25,
  SleepFactor.noise: 0.1,
};

/// Kabus dışı rüyalarda tür; bazen girilmemiş.
const _dreamKinds = <DreamKind?>[
  DreamKind.normal,
  DreamKind.normal,
  DreamKind.normal,
  DreamKind.lucid,
  DreamKind.recurring,
  null,
];

const _dreamEmotions = <List<DreamEmotion>>[
  [DreamEmotion.calm],
  [DreamEmotion.joy],
  [DreamEmotion.calm, DreamEmotion.joy],
  [DreamEmotion.confusion],
  [DreamEmotion.sadness],
  [DreamEmotion.joy, DreamEmotion.confusion],
  [],
];

const _nightmareEmotions = <List<DreamEmotion>>[
  [DreamEmotion.fear],
  [DreamEmotion.fear, DreamEmotion.confusion],
  [DreamEmotion.fear, DreamEmotion.anger],
  [DreamEmotion.sadness, DreamEmotion.fear],
];

const _dreamNotes = [
  'Denizde uzun uzun yüzdüm, su çok berraktı ve sıcacıktı.',
  'Eski evimizdeydik, annem yemek yapıyordu. Bahçede bir kedi vardı.',
  'Uçuyordum! Şehrin üstünden geçtim, aşağıda köprü ve tren görünüyordu.',
  'Okulda sınava giriyordum ama sorular boştu. Öğretmen gülüyordu.',
  'Ormanda bir yol buldum, sonunda küçük bir kapı vardı. Anahtar cebimdeydi.',
  'Arkadaşlarımla bir düğündeydik, herkes dans ediyordu, müzik çok güzeldi.',
  'Dağın tepesine tırmandım, güneş doğuyordu. Bulutlar ayağımın altındaydı.',
  'Babamla arabayla yolculuk yapıyorduk, radyoda eski bir şarkı çalıyordu.',
  'Kar yağıyordu, sokakta kardan adam yaptık. Kardeşim çok mutluydu.',
  'Kocaman bir kütüphanedeydim, rafta adı olmayan bir kitap buldum.',
  'Bir bebeği kucağımda tutuyordum, odada yumuşak bir ışık vardı.',
  'Uçağa yetişmeye çalışıyordum ama saat sürekli ileri gidiyordu.',
  'Yağmur yağarken bir köprünün altında saklandım, yanımda bir köpek vardı.',
  'Telefonum çalıyordu ama açamıyordum. Sonra bir aynada kendimi gördüm.',
  'Çiçeklerle dolu bir bahçede yürüyordum, ağaçlarda kuşlar ötüyordu.',
  'Eski sevgilimle bir kafede karşılaştık, sadece konuştuk.',
  'Yerde altın bir yüzük buldum, sahibini arıyordum.',
  'Bir gemiyle denizde ilerliyorduk, balıklar suyun üstüne sıçrıyordu.',
];

const _nightmareNotes = [
  'Karanlık bir sokakta biri beni kovalıyordu, koştukça yol uzuyordu.',
  'Dişlerim tek tek dökülüyordu, aynaya bakamıyordum.',
  'Yüksek bir yerden düşüyordum, tam yere çarpacakken uyandım.',
  'Evde yangın çıkmıştı, kapıyı açamıyordum.',
  'Deprem oldu, merdivenlerden inmeye çalışırken kayboldum.',
  'Büyük bir yılan odaya girdi, saklanacak yer arıyordum.',
  'Sel geldi, su hızla yükseliyordu ve arabam sürükleniyordu.',
];
