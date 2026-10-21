import 'package:flutter/foundation.dart';
import 'package:uyku/features/dreams/domain/dream_insights.dart';
import 'package:uyku/features/dreams/domain/dream_reading.dart';
import 'package:uyku/features/dreams/domain/dream_symbols.dart';
import 'package:uyku/features/sleep_log/domain/sleep_entry.dart';

/// Sorulu rüya yorumunun altı sorusu, sırasıyla.
enum DreamQuestion { emotion, wake, control, people, life, recurrence }

/// (2) Uyandığında nasıl hissettin?
enum DreamWakeFeeling { relieved, uneasy, curious, tired, neutral }

/// (3) Rüyada kontrol sende miydi?
enum DreamControl { yes, partly, no }

/// (4) Tanıdık kişiler — çoklu seçim; "Hiçbiri" boş küme ile gösterilir.
enum DreamPerson { family, friend, ex, workSchool, stranger }

/// (5) Bu aralar hayatında en çok ne yer kaplıyor?
enum LifeFocus { workSchool, relationships, health, change, loneliness, peace }

/// (6) Bu rüya ya da benzeri tekrar ediyor mu?
enum DreamRecurrence { first, sometimes, often }

/// Sonuçtaki "Küçük bir öneri" türü.
enum DreamSuggestion {
  /// Kabus ya da sık tekrar eden rüya: sonunu yeniden yaz.
  rewriteEnding,

  /// Huzursuz uyanış: 4-7-8 nefes (`/breathe`).
  breathe,

  /// İş/okul yükü + gergin rüya: akşam kapanış ritüeli (`/routine`).
  windDown,

  /// Ara sıra tekrar: benzer rüyaları not etmeye devam et.
  notePattern,

  /// Sakin/sevinçli rüya: iyi hissi gün içine taşı.
  savor,
}

const Object _unset = Object();

/// Görüşme cevapları (elle yazılmış, değişmez). `null` cevaplanmadı demektir;
/// [people] için boş küme "Hiçbiri"dir.
@immutable
class DreamInterviewAnswers {
  const DreamInterviewAnswers({
    this.emotion,
    this.wake,
    this.control,
    this.people,
    this.life,
    this.recurrence,
  });

  final DreamEmotion? emotion;
  final DreamWakeFeeling? wake;
  final DreamControl? control;
  final Set<DreamPerson>? people;
  final LifeFocus? life;
  final DreamRecurrence? recurrence;

  bool isAnswered(DreamQuestion q) => switch (q) {
    DreamQuestion.emotion => emotion != null,
    DreamQuestion.wake => wake != null,
    DreamQuestion.control => control != null,
    DreamQuestion.people => people != null,
    DreamQuestion.life => life != null,
    DreamQuestion.recurrence => recurrence != null,
  };

  bool get isComplete => DreamQuestion.values.every(isAnswered);

  /// `null` vermek alanı temizler; vermemek korur.
  DreamInterviewAnswers copyWith({
    Object? emotion = _unset,
    Object? wake = _unset,
    Object? control = _unset,
    Object? people = _unset,
    Object? life = _unset,
    Object? recurrence = _unset,
  }) => DreamInterviewAnswers(
    emotion: identical(emotion, _unset)
        ? this.emotion
        : emotion as DreamEmotion?,
    wake: identical(wake, _unset) ? this.wake : wake as DreamWakeFeeling?,
    control: identical(control, _unset)
        ? this.control
        : control as DreamControl?,
    people: identical(people, _unset)
        ? this.people
        : people == null
        ? null
        : Set<DreamPerson>.unmodifiable(people as Set<DreamPerson>),
    life: identical(life, _unset) ? this.life : life as LifeFocus?,
    recurrence: identical(recurrence, _unset)
        ? this.recurrence
        : recurrence as DreamRecurrence?,
  );

  /// Kişi seçimini değiştirir: [person] null ise "Hiçbiri" (boş küme).
  /// Son kişi kaldırılınca soru cevapsız kalır.
  DreamInterviewAnswers togglePerson(DreamPerson? person) {
    if (person == null) {
      final isNone = people != null && people!.isEmpty;
      return copyWith(people: isNone ? null : <DreamPerson>{});
    }
    final next = {...?people};
    if (!next.remove(person)) next.add(person);
    return copyWith(people: next.isEmpty ? null : next);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DreamInterviewAnswers &&
          other.emotion == emotion &&
          other.wake == wake &&
          other.control == control &&
          setEquals(other.people, people) &&
          other.life == life &&
          other.recurrence == recurrence;

  @override
  int get hashCode => Object.hash(
    emotion,
    wake,
    control,
    people == null ? null : Object.hashAllUnordered(people!),
    life,
    recurrence,
  );

  @override
  String toString() =>
      'DreamInterviewAnswers(emotion: $emotion, wake: $wake, '
      'control: $control, people: $people, life: $life, '
      'recurrence: $recurrence)';
}

/// Rüyalı gecelerle uyku arasındaki bağ (premium bölüm). Veri yetersizse
/// [inferDream] bunu null döndürür.
@immutable
class DreamSleepLink {
  const DreamSleepLink({
    required this.dreamNights,
    required this.dreamAverage,
    required this.nightmareAverage,
    required this.otherAverage,
    required this.nightmareFactor,
    required this.isNightmare,
  });

  final int dreamNights;

  /// Rüyalı gecelerin ortalama uyku süresi (dk).
  final int dreamAverage;
  final int? nightmareAverage;
  final int? otherAverage;
  final FactorCount? nightmareFactor;

  /// Yorumlanan rüya kabus mu (kabus etkenini öne çıkarmak için).
  final bool isNightmare;

  int? get durationDelta => nightmareAverage == null || otherAverage == null
      ? null
      : nightmareAverage! - otherAverage!;
}

/// Sorulu yorumun sonucu (türetilir, saklanmaz).
@immutable
class DreamInference {
  const DreamInference({
    required this.symbols,
    required this.kind,
    required this.emotion,
    required this.theme,
    required this.lifeLink,
    required this.reflections,
    required this.suggestion,
    required this.suggestionText,
    required this.symbolNotes,
    required this.sleepLink,
  });

  /// Notta bulunan semboller, ilk geçiş sırasıyla.
  final List<DreamSymbol> symbols;

  /// Etkin tür: seçilen tür; seçilmediyse ve rüya sık tekrar ediyorsa
  /// tekrarlayan.
  final DreamKind? kind;
  final DreamEmotion? emotion;

  /// Genel tema (semboller + baskın duygu + tür).
  final String theme;

  /// Duygu ve yaşam bağlantısı, 1–2 cümle.
  final String lifeLink;

  /// Kendine sorabileceklerin, 2–3 soru.
  final List<String> reflections;

  final DreamSuggestion suggestion;
  final String suggestionText;

  /// Premium: her sembol için cevaplara göre bağlam cümlesi.
  final List<(DreamSymbol, String)> symbolNotes;

  /// Premium: uyku verisiyle ilişki; veri yetersizse null.
  final DreamSleepLink? sleepLink;
}

/// Notu, türü ve görüşme cevaplarını kural tabanlı olarak yorumlar. Saf ve
/// deterministiktir: aynı girdi her zaman aynı çıktıyı verir.
DreamInference inferDream({
  required String note,
  required DreamInterviewAnswers answers,
  DreamKind? kind,
  DreamInsights? insights,
}) {
  final symbols = findSymbols(note);
  final effectiveKind =
      kind ??
      (answers.recurrence == DreamRecurrence.often
          ? DreamKind.recurring
          : null);
  final emotion = answers.emotion;
  final tone = DreamInterviewTexts.toneFor(effectiveKind, emotion);

  final theme = [
    if (symbols.isNotEmpty)
      DreamInterviewTexts.symbolsLead([for (final s in symbols) s.title]),
    DreamThemes.themeFor(effectiveKind, [?emotion]) ??
        DreamInterviewTexts.fallbackTheme,
  ].join(' ');

  final suggestion = _suggestionFor(effectiveKind, answers, tone);

  return DreamInference(
    symbols: symbols,
    kind: effectiveKind,
    emotion: emotion,
    theme: theme,
    lifeLink: DreamInterviewTexts.lifeLink(answers, tone),
    reflections: DreamInterviewTexts.reflections(answers, tone: tone),
    suggestion: suggestion,
    suggestionText: DreamInterviewTexts.suggestions[suggestion]!,
    symbolNotes: [
      for (final s in symbols)
        (s, DreamInterviewTexts.symbolNote(s, answers, tone: tone)),
    ],
    sleepLink: _sleepLink(insights, isNightmare: kind == DreamKind.nightmare),
  );
}

DreamSuggestion _suggestionFor(
  DreamKind? kind,
  DreamInterviewAnswers a,
  DreamTone tone,
) {
  if (kind == DreamKind.nightmare ||
      kind == DreamKind.recurring ||
      a.recurrence == DreamRecurrence.often) {
    return DreamSuggestion.rewriteEnding;
  }
  if (a.wake == DreamWakeFeeling.uneasy) return DreamSuggestion.breathe;
  if (a.life == LifeFocus.workSchool && tone == DreamTone.tense) {
    return DreamSuggestion.windDown;
  }
  if (a.recurrence == DreamRecurrence.sometimes) {
    return DreamSuggestion.notePattern;
  }
  return tone == DreamTone.light
      ? DreamSuggestion.savor
      : DreamSuggestion.notePattern;
}

DreamSleepLink? _sleepLink(DreamInsights? i, {required bool isNightmare}) {
  final average = i?.dreamAverage;
  if (i == null || average == null) return null;
  return DreamSleepLink(
    dreamNights: i.dreamNights,
    dreamAverage: average,
    nightmareAverage: i.nightmareAverage,
    otherAverage: i.otherAverage,
    nightmareFactor: i.nightmareFactor,
    isNightmare: isNightmare,
  );
}

/// Duygunun genel tonu.
enum DreamTone { tense, low, light }

/// Sorulu yorumun metin şablonları. [DreamThemes] gibi alan verisidir;
/// temkinli dil kullanır ("olabilir", "belki"), kehanet veya teşhis içermez.
abstract final class DreamInterviewTexts {
  static DreamTone toneOf(DreamEmotion? e) => switch (e) {
    DreamEmotion.fear ||
    DreamEmotion.anger ||
    DreamEmotion.confusion => DreamTone.tense,
    DreamEmotion.sadness => DreamTone.low,
    DreamEmotion.calm || DreamEmotion.joy || null => DreamTone.light,
  };

  /// Etkin ton: kabus, sakin/sevinçli duygu seçilse bile "rüyadaki sakinlik"
  /// gibi çelişkili cümle üretmesin diye gergin sayılır.
  static DreamTone toneFor(DreamKind? kind, DreamEmotion? e) {
    final tone = toneOf(e);
    return kind == DreamKind.nightmare && tone == DreamTone.light
        ? DreamTone.tense
        : tone;
  }

  static const fallbackTheme =
      'Bu rüya, gün içinde zihninde dolaşan düşünceleri sindirmenin bir '
      'yolu olabilir.';

  static String symbolsLead(List<String> titles) => titles.length == 1
      ? 'Rüyanda öne çıkan sembol: ${titles.first}.'
      : 'Rüyanda öne çıkan semboller: ${titles.join(', ')}.';

  // — Duygu ve yaşam bağlantısı —

  static const changeLostControl =
      'Bu rüya, belirsizlik karşısında kontrolü kaybetme hissiyle ilgili '
      'olabilir; '
      'önündeki değişim ya da karar, zihninde sandığından fazla yer '
      'kaplıyor olabilir.';

  static const workLostControl =
      'Rüyadaki çaresizlik hissi, iş ya da okuldaki yükün senin elinde '
      'olmayan yanlarıyla ilgili olabilir.';

  static const Map<LifeFocus, Map<DreamTone, String>> lifeTone = {
    LifeFocus.workSchool: {
      DreamTone.tense:
          'Rüyadaki gerginlik, iş ya da okuldaki beklentilerin gece de '
          'zihninde dolaşmasıyla ilgili olabilir.',
      DreamTone.low:
          'Rüyadaki hüzün, iş ya da okulda emeğinin yeterince görülmediği '
          'hissiyle ilgili olabilir.',
      DreamTone.light:
          'Rüyadaki rahatlık, iş ya da okuldaki yükü şu sıralar dengeli '
          'taşıyabildiğini yansıtıyor olabilir.',
    },
    LifeFocus.relationships: {
      DreamTone.tense:
          'Rüyadaki gerginlik, bir ilişkide dile getirilmemiş bir '
          'beklenti ya da kırgınlıkla ilgili olabilir.',
      DreamTone.low:
          'Rüyadaki hüzün, bir ilişkide yakınlık ya da özlem ihtiyacını '
          'yansıtıyor olabilir.',
      DreamTone.light:
          'Rüyadaki sıcaklık, ilişkilerinde seni besleyen bir bağı '
          'yansıtıyor olabilir.',
    },
    LifeFocus.health: {
      DreamTone.tense:
          'Rüyadaki tedirginlik, bedenine ve iyi oluşuna dair taşıdığın '
          'kaygıların gece işlenmesiyle ilgili olabilir.',
      DreamTone.low:
          'Rüyadaki hüzün, kendine bakım ve dinlenme ihtiyacını '
          'yansıtıyor olabilir.',
      DreamTone.light:
          'Rüyadaki dinginlik, kendine iyi bakmaya ayırdığın alanın '
          'karşılığı olabilir.',
    },
    LifeFocus.change: {
      DreamTone.tense:
          'Rüyadaki gerginlik, önündeki bir karar ya da değişimin '
          'belirsizliğiyle ilgili olabilir.',
      DreamTone.low:
          'Rüyadaki hüzün, bir değişimle geride kalacak şeylere duyduğun '
          'vedalaşma hissini yansıtıyor olabilir.',
      DreamTone.light:
          'Rüyadaki iyi his, önündeki değişime içten içe hazır olduğunu '
          'düşündürebilir.',
    },
    LifeFocus.loneliness: {
      DreamTone.tense:
          'Rüyadaki tedirginlik, yalnız kalma ya da anlaşılmama '
          'kaygısıyla ilgili olabilir.',
      DreamTone.low:
          'Rüyadaki hüzün, bağ kurma ve yakınlık ihtiyacını yansıtıyor '
          'olabilir.',
      DreamTone.light:
          'Rüyadaki huzur, yalnız kaldığın anlarda kendinle iyi '
          'geçinebildiğini yansıtıyor olabilir.',
    },
    LifeFocus.peace: {
      DreamTone.tense:
          'Huzur aradığın bu dönemde rüyadaki gerginlik, henüz '
          'yatışmamış bir konunun sesini duyurmasıyla ilgili olabilir.',
      DreamTone.low:
          'Huzur aradığın bu dönemde rüyadaki hüzün, biraz yavaşlama ve '
          'kendine şefkat ihtiyacını yansıtıyor olabilir.',
      DreamTone.light:
          'Huzur aradığın bu dönemde rüyadaki iyi his, kendine ayırdığın '
          'sakin anların karşılığını buluyor olabilir.',
    },
  };

  /// Sakin ya da sevinçli rüyadan rahat uyanış: "duygu işlendi" demek
  /// olumlu bir his için anlamsız olur.
  static const relievedLight =
      'Uyandığında rahat hissetmen, bu iyi hissin sabaha da taşındığını '
      'düşündürebilir.';

  static const controlYesTense =
      'Rüyada kontrolün sende olması, zorlandığında bile yön '
      'bulabildiğini hatırlatıyor olabilir.';

  static const Map<DreamWakeFeeling, String> wakeLink = {
    DreamWakeFeeling.relieved:
        'Uyandığında rahatlamış olman, bu duygunun bir kısmının gece '
        'içinde işlendiğini düşündürebilir.',
    DreamWakeFeeling.uneasy:
        'Huzursuz uyanman, bu konunun gün içinde de biraz ilgi istediğini '
        'düşündürebilir.',
    DreamWakeFeeling.curious:
        'Merakla uyanman, bu rüyanın üzerine düşünmeye değer bir şey '
        'taşıdığını hissettiğini gösteriyor olabilir.',
    DreamWakeFeeling.tired:
        'Yorgun uyanman, zihninin gece boyunca epey meşgul olduğunu '
        'yansıtıyor olabilir.',
  };

  /// Soru 1 (duygu), 2 (uyanış), 3 (kontrol) ve 5 (yaşam) birleşiminden
  /// 1–2 cümle.
  static String lifeLink(DreamInterviewAnswers a, DreamTone tone) {
    final life = a.life ?? LifeFocus.peace;
    final lostControl = tone == DreamTone.tense && a.control == DreamControl.no;
    final first = lostControl && life == LifeFocus.change
        ? changeLostControl
        : lostControl && life == LifeFocus.workSchool
        ? workLostControl
        : lifeTone[life]![tone]!;
    final second = tone == DreamTone.tense && a.control == DreamControl.yes
        ? controlYesTense
        : tone == DreamTone.light && a.wake == DreamWakeFeeling.relieved
        ? relievedLight
        : wakeLink[a.wake];
    return second == null ? first : '$first $second';
  }

  // — Kendine sorabileceklerin —

  static const Map<LifeFocus, String> lifeQuestion = {
    LifeFocus.workSchool:
        'İş ya da okulda şu an seni en çok zorlayan şey ne; bir kısmını '
        'bırakabilir misin?',
    LifeFocus.relationships:
        'Yakınlarından biriyle konuşmayı ertelediğin bir şey var mı?',
    LifeFocus.health:
        'Bedenin şu sıralar senden neye biraz daha fazla zaman ayırmanı '
        'istiyor olabilir?',
    LifeFocus.change:
        'Önündeki değişimde seni en çok ne düşündürüyor; en küçük ilk adım '
        'ne olabilir?',
    LifeFocus.loneliness:
        'Kendini en çok kimin yanında anlaşılmış hissediyorsun; ona bu '
        'hafta ulaşabilir misin?',
    LifeFocus.peace:
        'Gün içinde seni gerçekten dinlendiren anlar hangileri; onlara '
        'nasıl daha çok yer açabilirsin?',
  };

  static const Map<DreamEmotion, String> emotionQuestion = {
    DreamEmotion.fear:
        'Rüyadaki korku, uyanıkken tanıdığın bir kaygıya benziyor mu?',
    DreamEmotion.anger:
        'Son zamanlarda sınırının aşıldığını hissettiğin bir an oldu mu?',
    DreamEmotion.confusion:
        'Şu sıralar hangi konuda iki seçenek arasında kalmış '
        'hissediyorsun?',
    DreamEmotion.sadness:
        'Özlediğin ya da geride bıraktığın bir şey aklına geliyor mu?',
    DreamEmotion.joy:
        'Rüyadaki sevinci uyanık hayatında en son ne zaman hissettin?',
    DreamEmotion.calm: 'Rüyadaki sakinliği gün içinde nerede bulabilirsin?',
  };

  static const recurringQuestion =
      'Bu rüya en çok hangi günlerin ardından geliyor; o günlerde ortak '
      'bir şey var mı?';

  static const exQuestion =
      'O ilişkiden bugüne hâlâ taşıdığın bir duygu ya da ders var mı?';

  static const lostControlQuestion =
      'Uyanık hayatında biraz daha söz sahibi olmak istediğin bir alan '
      'var mı?';

  static const defaultQuestion =
      'Bu rüyadan uyandığında aklına ilk gelen kişi ya da durum neydi?';

  /// 2–3 yansıtıcı soru. Kontrol sorusu yalnız gergin ya da hüzünlü
  /// rüyada sorulur; [tone] verilmezse duygudan çıkarılır.
  static List<String> reflections(DreamInterviewAnswers a, {DreamTone? tone}) {
    final t = tone ?? toneOf(a.emotion);
    final third = a.recurrence == DreamRecurrence.often
        ? recurringQuestion
        : a.people?.contains(DreamPerson.ex) ?? false
        ? exQuestion
        : a.control == DreamControl.no && t != DreamTone.light
        ? lostControlQuestion
        : null;
    return [
      lifeQuestion[a.life ?? LifeFocus.peace]!,
      // Kabusta "rüyadaki sakinlik" sorusu çelişir: ton duygudan farklıysa
      // genel soru.
      if (a.emotion != null && toneOf(a.emotion) == t)
        emotionQuestion[a.emotion]!
      else
        defaultQuestion,
      ?third,
    ];
  }

  // — Küçük bir öneri —

  static const Map<DreamSuggestion, String> suggestions = {
    DreamSuggestion.rewriteEnding:
        'Rüyanın sonunu kendi istediğin gibi yeniden yazmayı dene: birkaç '
        'cümleyle yeni bir son yaz ve gün içinde sakin bir anda birkaç '
        'dakika zihninde canlandır. Korkutucu ya da tekrar eden rüyalarda '
        'bu iyi gelebilir.',
    DreamSuggestion.breathe:
        'Huzursuz uyandığın sabahlarda birkaç tur 4-7-8 nefes, bedenine '
        'güvende olduğunu hatırlatmanın kısa bir yolu olabilir.',
    DreamSuggestion.windDown:
        'Akşamları işi ya da dersi kapatan küçük bir ritüel — yarının '
        'listesini yazıp bırakmak gibi — zihnin geceye daha hafif girmesine '
        'yardımcı olabilir.',
    DreamSuggestion.notePattern:
        'Benzer rüyaları günlüğüne not etmeye devam et; örüntüler zamanla '
        'belirginleşebilir ve neyin tetiklediğini fark etmek kolaylaşır.',
    DreamSuggestion.savor:
        'Rüyadaki iyi hissi gün içinde bir an hatırla; ona eşlik eden bir '
        'görüntüyü ya da sesi zihninde birkaç nefes boyunca tut.',
  };

  // — Semboller ve cevapların (premium) —

  /// Kişi cevabıyla bağlantılı semboller.
  static const Map<DreamPerson, Set<String>> personSymbols = {
    DreamPerson.family: {'anne', 'baba', 'kardes', 'ev', 'cocuk', 'bebek'},
    DreamPerson.friend: {'arkadas'},
    DreamPerson.ex: {'eski_sevgili', 'dugun', 'yuzuk'},
    DreamPerson.workSchool: {'is', 'okul', 'sinav'},
  };

  static const Map<DreamPerson, String> personPhrase = {
    DreamPerson.family: 'ailenden birinin',
    DreamPerson.friend: 'bir arkadaşının',
    DreamPerson.ex: 'eski bir ilişkinden birinin',
    DreamPerson.workSchool: 'iş ya da okuldan birinin',
  };

  /// Yaşam teması cevabıyla bağlantılı semboller.
  static const Map<LifeFocus, Set<String>> lifeSymbols = {
    LifeFocus.workSchool: {'is', 'okul', 'sinav', 'saat', 'merdiven'},
    LifeFocus.relationships: {
      'eski_sevgili',
      'dugun',
      'yuzuk',
      'telefon',
      'arkadas',
      'kopek',
    },
    LifeFocus.health: {'hastane', 'kan', 'dis', 'yemek'},
    LifeFocus.change: {
      'yol',
      'kapi',
      'kopru',
      'ucak',
      'tren',
      'olum',
      'deprem',
      'merdiven',
      'gemi',
    },
    LifeFocus.loneliness: {'kaybolmak', 'karanlik', 'orman', 'saklanmak'},
    LifeFocus.peace: {'su', 'deniz', 'bahce', 'cicek', 'isik', 'gunes'},
  };

  static const Map<LifeFocus, String> lifePhrase = {
    LifeFocus.workSchool: 'iş ya da okulun',
    LifeFocus.relationships: 'ilişkilerin',
    LifeFocus.health: 'sağlığın ve iyi oluşun',
    LifeFocus.change: 'bir değişim ya da kararın',
    LifeFocus.loneliness: 'yalnızlık hissinin',
    LifeFocus.peace: 'huzur arayışının',
  };

  static const Map<DreamTone, String> toneNote = {
    DreamTone.tense:
        'Bu sembol gergin bir rüyada geçti; yorumundaki soruya bir kaygı '
        'açısından bakmak işine yarayabilir.',
    DreamTone.low:
        'Bu sembol hüzünlü bir rüyada geçti; belki bir özlem ya da kayıpla '
        'bağını düşünebilirsin.',
    DreamTone.light:
        'Bu sembol sakin ya da sevinçli bir rüyada geçti; çağrıştırdığı '
        'konunun sende olumlu bir karşılığı olabilir.',
  };

  static const lostControlNote =
      'Bu sembol, kontrolün sende olmadığını hissettiğin bir rüyada geçti; '
      'çağrıştırdığı konuda kendini biraz savunmasız hissediyor olabilirsin.';

  /// Sembol için cevaplara göre bağlam cümlesi. Öncelik: tanıdık kişi →
  /// yaşam teması → kontrol → duygu tonu.
  static String symbolNote(
    DreamSymbol s,
    DreamInterviewAnswers a, {
    DreamTone? tone,
  }) {
    for (final p in DreamPerson.values) {
      if ((a.people?.contains(p) ?? false) &&
          (personSymbols[p]?.contains(s.id) ?? false)) {
        return 'Rüyada ${personPhrase[p]} olduğunu söyledin; bu sembol o '
            'ilişkideki bir ihtiyacı ya da beklentiyi yansıtıyor olabilir.';
      }
    }
    final life = a.life;
    if (life != null && lifeSymbols[life]!.contains(s.id)) {
      return 'Bu aralar hayatında en çok ${lifePhrase[life]} yer kapladığını '
          'söyledin; bu sembol belki bu temayla bağlantılıdır.';
    }
    final t = tone ?? toneOf(a.emotion);
    if (a.control == DreamControl.no && t == DreamTone.tense) {
      return lostControlNote;
    }
    return toneNote[t]!;
  }
}
