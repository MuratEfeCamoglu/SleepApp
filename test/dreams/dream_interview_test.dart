import 'package:flutter_test/flutter_test.dart';
import 'package:uyku/features/dreams/domain/dream_insights.dart';
import 'package:uyku/features/dreams/domain/dream_interview.dart';
import 'package:uyku/features/dreams/domain/dream_reading.dart';
import 'package:uyku/features/sleep_log/domain/sleep_entry.dart';

const _full = DreamInterviewAnswers(
  emotion: DreamEmotion.calm,
  wake: DreamWakeFeeling.neutral,
  control: DreamControl.partly,
  people: {},
  life: LifeFocus.peace,
  recurrence: DreamRecurrence.first,
);

DreamInsights _insights({
  int dreamNights = 6,
  int? dreamAverage = 450,
  int? nightmareAverage,
  int? otherAverage,
  FactorCount? factor,
}) => DreamInsights(
  dreamNights: dreamNights,
  topSymbols: const [],
  kindedNights: dreamNights,
  nightmareNights: 3,
  nightmareRate: null,
  nightmareAverage: nightmareAverage,
  otherAverage: otherAverage,
  nightmareFactor: factor,
  dreamAverage: dreamAverage,
);

void main() {
  group('DreamInterviewAnswers', () {
    test('copyWith korur, null verince temizler; == değer eşitliği', () {
      final a = _full.copyWith(wake: DreamWakeFeeling.tired);
      expect(a.wake, DreamWakeFeeling.tired);
      expect(a.emotion, DreamEmotion.calm);
      expect(a.copyWith(life: null).life, isNull);
      expect(
        _full.copyWith(people: {DreamPerson.ex}),
        _full.copyWith(people: {DreamPerson.ex}),
      );
      expect(
        _full.copyWith(people: {DreamPerson.ex}).hashCode,
        _full.copyWith(people: {DreamPerson.ex}).hashCode,
      );
      expect(_full, isNot(_full.copyWith(people: {DreamPerson.ex})));
    });

    test('"Hiçbiri" boş küme; kişi seçince kalkar, son kişi çıkınca '
        'cevapsız', () {
      const empty = DreamInterviewAnswers();
      expect(empty.isAnswered(DreamQuestion.people), isFalse);

      final none = empty.togglePerson(null);
      expect(none.people, isEmpty);
      expect(none.isAnswered(DreamQuestion.people), isTrue);

      final family = none.togglePerson(DreamPerson.family);
      expect(family.people, {DreamPerson.family});

      expect(family.togglePerson(DreamPerson.family).people, isNull);
      // Kişiler seçiliyken "Hiçbiri" diğerlerini temizler.
      expect(family.togglePerson(null).people, isEmpty);
      // "Hiçbiri"ne tekrar dokunmak cevabı kaldırır.
      expect(none.togglePerson(null).people, isNull);
    });

    test('isComplete yalnız altı soru cevaplanınca true', () {
      expect(_full.isComplete, isTrue);
      expect(_full.copyWith(recurrence: null).isComplete, isFalse);
    });
  });

  group('inferDream', () {
    test('deterministik: aynı girdi aynı çıktıyı verir', () {
      const answers = DreamInterviewAnswers(
        emotion: DreamEmotion.fear,
        wake: DreamWakeFeeling.uneasy,
        control: DreamControl.no,
        people: {DreamPerson.family},
        life: LifeFocus.change,
        recurrence: DreamRecurrence.sometimes,
      );
      const note = 'Annemle bir köprüden geçiyorduk, sonra düştüm';
      final a = inferDream(note: note, answers: answers);
      final b = inferDream(note: note, answers: answers);
      expect(a.theme, b.theme);
      expect(a.lifeLink, b.lifeLink);
      expect(a.reflections, b.reflections);
      expect(a.suggestion, b.suggestion);
      expect(a.suggestionText, b.suggestionText);
      expect(
        [for (final n in a.symbolNotes) (n.$1.id, n.$2)],
        [for (final n in b.symbolNotes) (n.$1.id, n.$2)],
      );
    });

    test('en az üç bölüm dolu: tema, yaşam bağlantısı, 2–3 soru, öneri', () {
      final r = inferDream(note: 'Bir rüya', answers: _full);
      expect(r.theme, isNotEmpty);
      expect(r.lifeLink, isNotEmpty);
      expect(r.reflections.length, inInclusiveRange(2, 3));
      expect(r.suggestionText, isNotEmpty);
    });

    test('kabus → sonunu yeniden yazma önerisi', () {
      final r = inferDream(
        note: 'Karanlık bir koridor',
        kind: DreamKind.nightmare,
        answers: _full.copyWith(wake: DreamWakeFeeling.uneasy),
      );
      expect(r.suggestion, DreamSuggestion.rewriteEnding);
      expect(r.suggestionText, contains('yeniden yaz'));
    });

    test('sık tekrar eden rüya türü seçilmese de tekrarlayan sayılır', () {
      final r = inferDream(
        note: 'Yine aynı ev',
        answers: _full.copyWith(recurrence: DreamRecurrence.often),
      );
      expect(r.kind, DreamKind.recurring);
      expect(r.suggestion, DreamSuggestion.rewriteEnding);
      expect(r.reflections, contains(DreamInterviewTexts.recurringQuestion));
    });

    test('huzursuz uyanış → 4-7-8 nefes önerisi', () {
      final r = inferDream(
        note: 'Bir rüya',
        answers: _full.copyWith(wake: DreamWakeFeeling.uneasy),
      );
      expect(r.suggestion, DreamSuggestion.breathe);
    });

    test('korku + kontrol yok + değişim → kontrolü kaybetme bağlantısı', () {
      final r = inferDream(
        note: 'Bir rüya',
        answers: _full.copyWith(
          emotion: DreamEmotion.fear,
          control: DreamControl.no,
          life: LifeFocus.change,
        ),
      );
      expect(r.lifeLink, startsWith(DreamInterviewTexts.changeLostControl));
      expect(r.lifeLink, contains('kontrolü kaybetme'));
      expect(r.reflections, contains(DreamInterviewTexts.lostControlQuestion));
    });

    test('kontrol sendeyse aynı korku kontrolü kaybetme demez', () {
      final r = inferDream(
        note: 'Bir rüya',
        answers: _full.copyWith(
          emotion: DreamEmotion.fear,
          control: DreamControl.yes,
          life: LifeFocus.change,
        ),
      );
      expect(r.lifeLink, isNot(contains('kontrolü kaybetme')));
      expect(r.lifeLink, contains(DreamInterviewTexts.controlYesTense));
    });

    test('uyanış hissi ikinci cümleyi ekler, nötr eklemez', () {
      final neutral = inferDream(note: 'x', answers: _full);
      final tired = inferDream(
        note: 'x',
        answers: _full.copyWith(wake: DreamWakeFeeling.tired),
      );
      expect(
        neutral.lifeLink,
        DreamInterviewTexts.lifeTone[LifeFocus.peace]![DreamTone.light],
      );
      expect(
        tired.lifeLink,
        endsWith(DreamInterviewTexts.wakeLink[DreamWakeFeeling.tired]!),
      );
    });

    test('sembolsüz not: sembol bölümü boş, tema yine de var', () {
      final r = inferDream(note: 'Hiçbir şey hatırlamıyorum', answers: _full);
      expect(r.symbols, isEmpty);
      expect(r.symbolNotes, isEmpty);
      expect(r.theme, isNot(contains('öne çıkan')));
      expect(r.theme, isNotEmpty);
    });

    test('semboller temada ilk geçiş sırasıyla listelenir', () {
      final r = inferDream(note: 'Denizde bir ev gördüm', answers: _full);
      expect([for (final s in r.symbols) s.id], ['deniz', 'ev']);
      expect(r.theme, startsWith('Rüyanda öne çıkan semboller: Deniz, Ev.'));
    });

    test('semboller × cevap: tanıdık kişi, yaşam teması ve ton bağlamı', () {
      final r = inferDream(
        note: 'Annem köprüde duruyordu, yanında bir kedi vardı',
        answers: _full.copyWith(
          emotion: DreamEmotion.sadness,
          people: {DreamPerson.family},
          life: LifeFocus.change,
        ),
      );
      final notes = {for (final n in r.symbolNotes) n.$1.id: n.$2};
      expect(notes.keys, ['anne', 'kopru', 'kedi']);
      expect(notes['anne'], contains('ailenden birinin'));
      expect(notes['kopru'], contains('bir değişim ya da kararın'));
      expect(notes['kedi'], DreamInterviewTexts.toneNote[DreamTone.low]);
    });

    test('"Hiçbiri" seçilince kişi bağlamı kullanılmaz', () {
      final r = inferDream(
        note: 'Annemi gördüm',
        answers: _full.copyWith(people: <DreamPerson>{}),
      );
      expect(r.symbolNotes.single.$2, isNot(contains('ailenden')));
      expect(r.reflections, isNot(contains(DreamInterviewTexts.exQuestion)));
    });

    test('eski ilişki seçimi yansıtıcı soruya eklenir', () {
      final r = inferDream(
        note: 'x',
        answers: _full.copyWith(people: {DreamPerson.ex}),
      );
      expect(r.reflections, contains(DreamInterviewTexts.exQuestion));
      expect(r.reflections.length, 3);
    });

    test('içgörü yok ya da yetersizse sleepLink null', () {
      expect(inferDream(note: 'x', answers: _full).sleepLink, isNull);
      expect(
        inferDream(
          note: 'x',
          answers: _full,
          insights: _insights(dreamNights: 2, dreamAverage: null),
        ).sleepLink,
        isNull,
      );
    });

    test('içgörü varsa sleepLink taşınır; kabus işaretlenir', () {
      final link = inferDream(
        note: 'x',
        kind: DreamKind.nightmare,
        answers: _full,
        insights: _insights(
          nightmareAverage: 400,
          otherAverage: 460,
          factor: (factor: SleepFactor.stress, nights: 3),
        ),
      ).sleepLink!;
      expect(link.dreamAverage, 450);
      expect(link.durationDelta, -60);
      expect(link.nightmareFactor?.factor, SleepFactor.stress);
      expect(link.isNightmare, isTrue);
    });

    test('metinler temkinli: kehanet ya da teşhis dili yok', () {
      final all = <String>[
        ...DreamInterviewTexts.suggestions.values,
        ...DreamInterviewTexts.lifeQuestion.values,
        ...DreamInterviewTexts.emotionQuestion.values,
        ...DreamInterviewTexts.wakeLink.values,
        ...DreamInterviewTexts.toneNote.values,
        for (final m in DreamInterviewTexts.lifeTone.values) ...m.values,
      ];
      for (final t in all) {
        expect(t.toLowerCase(), isNot(contains('kesinlikle')));
        expect(t.toLowerCase(), isNot(contains('teşhis')));
        expect(t.toLowerCase(), isNot(contains('hastalı')));
      }
    });
  });

  group('inferDream çelişkili kombinasyonlar (regresyon)', () {
    const lightWords = [
      'sakinlik',
      'sevinç',
      'rahatlık',
      'dinginlik',
      'sıcaklık',
      'iyi his',
      'sakin ya da sevinçli',
    ];

    test('kabus + sakin duygu: sakinlikten söz etmez, gergin ton kullanır', () {
      final r = inferDream(
        note: 'evde kediyi arıyordum',
        kind: DreamKind.nightmare,
        answers: _full.copyWith(
          control: DreamControl.no,
          life: LifeFocus.workSchool,
        ),
      );
      for (final w in lightWords) {
        expect(r.lifeLink.toLowerCase(), isNot(contains(w)));
        for (final (_, note) in r.symbolNotes) {
          expect(note.toLowerCase(), isNot(contains(w)));
        }
      }
      expect(
        r.reflections,
        isNot(contains(DreamInterviewTexts.emotionQuestion[DreamEmotion.calm])),
      );
      expect(r.reflections, contains(DreamInterviewTexts.defaultQuestion));
      expect(r.lifeLink, DreamInterviewTexts.workLostControl);
      expect(r.suggestion, DreamSuggestion.rewriteEnding);
    });

    test('kabus + sevinç + huzur: yaşam bağlantısı gergin şablondan', () {
      final r = inferDream(
        note: 'x',
        kind: DreamKind.nightmare,
        answers: _full.copyWith(emotion: DreamEmotion.joy),
      );
      expect(
        r.lifeLink,
        DreamInterviewTexts.lifeTone[LifeFocus.peace]![DreamTone.tense],
      );
    });

    test(
      'sakin + huzur: tema ve yaşam bağlantısı aynı cümleyi tekrarlamaz',
      () {
        final r = inferDream(note: 'x', answers: _full);
        final theme = DreamThemes.themeFor(null, const [DreamEmotion.calm])!;
        expect(r.lifeLink, isNot(contains('dengeye')));
        expect(r.theme, contains(theme));
        expect(r.lifeLink, isNot(contains(theme)));
      },
    );

    test('sakin rüyadan rahat uyanış "duygu işlendi" demez', () {
      final r = inferDream(
        note: 'x',
        answers: _full.copyWith(wake: DreamWakeFeeling.relieved),
      );
      expect(r.lifeLink, endsWith(DreamInterviewTexts.relievedLight));
      expect(r.lifeLink, isNot(contains('işlendiğini')));

      final tense = inferDream(
        note: 'x',
        answers: _full.copyWith(
          emotion: DreamEmotion.anger,
          wake: DreamWakeFeeling.relieved,
        ),
      );
      expect(
        tense.lifeLink,
        endsWith(DreamInterviewTexts.wakeLink[DreamWakeFeeling.relieved]!),
      );
    });

    test('sakin rüyada kontrol yok: kontrol sorusu sorulmaz', () {
      final calm = inferDream(
        note: 'x',
        answers: _full.copyWith(control: DreamControl.no),
      );
      expect(
        calm.reflections,
        isNot(contains(DreamInterviewTexts.lostControlQuestion)),
      );
      final sad = inferDream(
        note: 'x',
        answers: _full.copyWith(
          emotion: DreamEmotion.sadness,
          control: DreamControl.no,
        ),
      );
      expect(
        sad.reflections,
        contains(DreamInterviewTexts.lostControlQuestion),
      );
    });

    test('tüm cevap kombinasyonlarında yapı ve dil tutarlı', () {
      const forbidden = ['kesinlikle', 'teşhis', 'hastalı', 'mutlaka'];
      var count = 0;
      for (final kind in [null, ...DreamKind.values]) {
        for (final emotion in DreamEmotion.values) {
          for (final wake in DreamWakeFeeling.values) {
            for (final control in DreamControl.values) {
              for (final life in LifeFocus.values) {
                for (final recurrence in DreamRecurrence.values) {
                  final r = inferDream(
                    note: 'denizde annemle köprüden geçtik',
                    kind: kind,
                    answers: DreamInterviewAnswers(
                      emotion: emotion,
                      wake: wake,
                      control: control,
                      people: const {DreamPerson.family},
                      life: life,
                      recurrence: recurrence,
                    ),
                  );
                  count++;
                  expect(r.theme, isNotEmpty);
                  expect(r.lifeLink, isNotEmpty);
                  expect(r.reflections.length, inInclusiveRange(2, 3));
                  expect(r.reflections.toSet().length, r.reflections.length);
                  expect(r.suggestionText, isNotEmpty);
                  final all = [
                    r.theme,
                    r.lifeLink,
                    ...r.reflections,
                    r.suggestionText,
                    for (final (_, n) in r.symbolNotes) n,
                  ].join(' ').toLowerCase();
                  for (final f in forbidden) {
                    expect(all, isNot(contains(f)));
                  }
                  if (kind == DreamKind.nightmare) {
                    final rest = [
                      r.lifeLink,
                      ...r.reflections,
                      for (final (_, n) in r.symbolNotes) n,
                    ].join(' ').toLowerCase();
                    for (final w in lightWords) {
                      expect(rest, isNot(contains(w)), reason: '$emotion $w');
                    }
                  }
                }
              }
            }
          }
        }
      }
      expect(count, 5 * 6 * 5 * 3 * 6 * 3);
    });
  });

  test(
    'computeDreamInsights rüyalı gece ortalamasını en az 3 gecede verir',
    () {
      final today = DateTime(2026, 10, 21);
      SleepEntry e(int daysAgo, int minutes) {
        final night = addDays(today, -daysAgo);
        final bed = night.add(const Duration(hours: 23));
        return SleepEntry(
          id: nightKey(night),
          bedtime: bed,
          wake: bed.add(Duration(minutes: minutes)),
          note: 'Rüya',
        );
      }

      expect(
        computeDreamInsights([e(1, 420), e(2, 480)], today).dreamAverage,
        isNull,
      );
      expect(
        computeDreamInsights([
          e(1, 420),
          e(2, 480),
          e(3, 450),
        ], today).dreamAverage,
        450,
      );
    },
  );
}
