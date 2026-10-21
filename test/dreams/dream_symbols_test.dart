import 'package:flutter_test/flutter_test.dart';
import 'package:uyku/features/dreams/domain/dream_symbols.dart';

List<String> _ids(String note) => [for (final s in findSymbols(note)) s.id];

void main() {
  group('sözlük', () {
    test('en az 60 sembol var', () {
      expect(dreamSymbols.length, greaterThanOrEqualTo(60));
    });

    test("id'ler benzersiz", () {
      final ids = dreamSymbols.map((s) => s.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('her sembolün başlığı, yorumu ve anahtarı var', () {
      for (final s in dreamSymbols) {
        expect(s.title, isNotEmpty, reason: s.id);
        expect(s.meaning, isNotEmpty, reason: s.id);
        expect([...s.keywords, ...s.words], isNotEmpty, reason: s.id);
      }
    });

    test('anahtarlar normalleştirilmiş küçük harftir', () {
      for (final s in dreamSymbols) {
        for (final k in [...s.keywords, ...s.words, ...s.excludes]) {
          expect(normalizeTr(k), k, reason: '${s.id}: $k');
        }
      }
    });
  });

  group('normalizeTr', () {
    test('Türkçe büyük harfler doğru küçülür', () {
      expect(normalizeTr("İstanbul'da IŞIK!"), 'istanbulda ışık');
      expect(normalizeTr('ÇOK ŞEKER ĞÜÖ'), 'çok şeker ğüö');
    });

    test('noktalama boşluğa döner, boşluklar tekleşir', () {
      expect(normalizeTr('Su, deniz...  yılan?'), 'su deniz yılan');
    });

    test('kesme işaretinin türleri silinir', () {
      expect(normalizeTr('Ankara’ya'), 'ankaraya');
    });
  });

  group('findSymbols', () {
    test('"Suda yüzüyordum, sonra yılan gördüm" → su, yüzmek, yılan', () {
      expect(_ids('Suda yüzüyordum, sonra yılan gördüm'), [
        'su',
        'yuzmek',
        'yilan',
      ]);
    });

    test('ekli biçimler kelime başından eşleşir', () {
      expect(_ids('suyun'), ['su']);
      expect(_ids('Denizin'), ['deniz']);
      expect(_ids('köpeğim'), ['kopek']);
      expect(_ids('müziği'), ['muzik']);
    });

    test('büyük harfli ve noktalamalı not', () {
      expect(_ids('YILAN! Işıklar söndü.'), ['yilan', 'isik']);
    });

    test('aynı sembol bir kez sayılır', () {
      expect(_ids('Su, su ve yine suda'), ['su']);
    });

    test('ilk geçiş sırasıyla döner', () {
      expect(_ids('Yılan gördüm, sonra denize girdim'), ['yilan', 'deniz']);
    });

    test('kelimenin ortasında geçen kök eşleşmez', () {
      expect(_ids('Masum bir oyundu'), isEmpty);
    });

    group('yanlış pozitif yok', () {
      test('"uçak" uçmak değildir', () {
        expect(_ids('Uçakla gittik'), ['ucak']);
        expect(_ids('uçağa bindim'), ['ucak']);
        expect(_ids('Uçuyordum'), ['ucmak']);
      });

      test('"sınır" sınav değildir', () {
        expect(_ids('Sınırda bekliyordum'), isEmpty);
        expect(_ids('Sınava geç kaldım'), contains('sinav'));
      });

      test('"düşündüm" düşmek değildir', () {
        expect(_ids('Çok düşündüm'), isEmpty);
        expect(_ids('Düştüm'), ['dusmek']);
      });

      test('"evet" ve "evlenmek" ev değildir', () {
        expect(_ids('Evet dedim'), isEmpty);
        expect(_ids('Evlendik'), ['dugun']);
        expect(_ids('Evde kaldım'), ['ev']);
      });

      test('"sustum" su değildir', () {
        expect(_ids('Sustum'), isEmpty);
      });

      test('"kanepe", "kanıt" kan değildir; "kan" ve "kanlı" kandır', () {
        expect(_ids('Kanepede oturuyordum, kanıt arıyordum'), isEmpty);
        expect(_ids('Her yer kan olmuştu'), ['kan']);
        expect(_ids('kanlı bir gömlek'), ['kan']);
      });

      test('"altında" altın değildir', () {
        expect(_ids('Masanın altında saklandım'), ['saklanmak']);
        expect(_ids('Altın buldum'), ['altin']);
      });

      test('"kardeş" ve "karanlık" kar değildir', () {
        expect(_ids('Kardeşim'), ['kardes']);
        expect(_ids('Kar yağıyordu'), ['kar']);
      });

      test('"dağınık" dağ değildir', () {
        expect(_ids('Oda dağınıktı'), isEmpty);
        expect(_ids('Dağa tırmandım'), ['dag']);
      });

      test('"bu yüzden" yüzmek değildir', () {
        expect(_ids('Bu yüzden gittim'), isEmpty);
      });
    });

    test('çok kelimeli anahtar ardışık kelimelerle eşleşir', () {
      expect(_ids('Eski sevgilimi gördüm'), ['eski_sevgili']);
      expect(_ids('Sevgilim eski bir evdeydi'), ['ev']);
    });

    test('boş not', () {
      expect(findSymbols(''), isEmpty);
      expect(findSymbols('  ...  '), isEmpty);
    });
  });
  // Testçi turu: gerçekçi notlarla yanlış pozitif / negatif regresyonları.
  group('gerçekçi notlar (regresyon)', () {
    test('"yollar" yol sayılır, "yolladım" sayılmaz', () {
      expect(_ids('Yollarda kaybolmuştum'), ['yol', 'kaybolmak']);
      expect(_ids('Ona mesaj yolladım'), ['telefon']);
    });

    test('"kapılar" kapı sayılır, "kapıldım" sayılmaz', () {
      expect(_ids('Korkuya kapıldım'), isEmpty);
      expect(_ids('Kapılar kilitliydi'), ['kapi', 'anahtar']);
    });

    test('"evrim" ev değildir', () {
      expect(_ids('Evet, evrimi anlatan bir belgesel'), isEmpty);
      expect(_ids('Eski evimizin bahçesindeydik'), ['ev', 'bahce']);
    });

    test('"paramparça" ve "paragraf" para değildir', () {
      expect(_ids('Paramparça bir paragraf'), isEmpty);
      expect(_ids('Param kayboldu'), ['para', 'kaybolmak']);
    });

    test('"trend" tren değildir', () {
      expect(_ids('Trendleri konuşuyorduk'), isEmpty);
      expect(_ids('Trene yetişemedim'), ['tren', 'saat']);
    });

    test('"tipi" (görünüş) kar değildir', () {
      expect(_ids('Onun tipi tuhaftı'), isEmpty);
    });

    test('"kazara" kaza değildir', () {
      expect(_ids('Kazara bardağı devirdim'), isEmpty);
      expect(_ids('Kaza yaptık'), ['kaza']);
    });

    test('düşmek fiilinin -mış ve -ıp biçimleri', () {
      expect(_ids('Düşmüştüm'), ['dusmek']);
      expect(_ids('Düşüp uyandım'), ['dusmek']);
      expect(_ids('Çok düşündüm'), isEmpty);
    });

    test('"beni takip ediyordu" kovalanmak sayılır', () {
      expect(_ids('Biri beni takip ediyordu'), ['kovalanmak']);
    });

    test('büyük İ/I ve kesme işaretli not', () {
      expect(_ids("İSTANBUL'DA KÖPRÜDEN geçtik, IŞIKLAR yanıyordu"), [
        'kopru',
        'isik',
      ]);
      expect(_ids("Ev'de Kedi'yi aradım"), ['ev', 'kedi']);
    });

    test('kısa kökler: su/sus, kan/kanepe, göl/gölge, sandal/sandalye', () {
      expect(_ids('Susadım, sonra sustum'), isEmpty);
      expect(_ids('Kanepede oturdum'), isEmpty);
      expect(_ids('Gölgemi gördüm'), isEmpty);
      expect(_ids('Sandalyede oturdum'), isEmpty);
      expect(_ids('Gölde sandalla gezdik'), ['su', 'gemi']);
    });

    test('çoğul ve -yordum ekleri', () {
      expect(_ids('Yılanlar vardı, atlar koşuyordu'), [
        'yilan',
        'at',
        'kosmak',
      ]);
      expect(_ids('Uçakla uçuyorduk'), ['ucak', 'ucmak']);
      expect(_ids('Koridorda ağlıyordum'), ['aglamak']);
    });
  });

  group('yorum dili', () {
    // Kehanet, kader, kesinlik veya sağlık/ölüm iddiası kuran kalıplar.
    const banned = [
      'kesinlikle',
      'mutlaka',
      'kehanet',
      'kader',
      'uğursuz',
      'uğur',
      'müjde',
      'hastalı',
      'teşhis',
      'tanı koy',
      'tedavi',
      'öleceğ',
      'temsil eder',
      'simgeler',
      'yansıtır',
    ];

    test('sembol yorumları temkinli dildedir', () {
      for (final s in dreamSymbols) {
        final meaning = normalizeTr(s.meaning);
        for (final word in banned) {
          expect(
            RegExp('(^| )${normalizeTr(word)}').hasMatch(meaning),
            isFalse,
            reason: '${s.id}: "$word"',
          );
        }
      }
    });

    test('ölüm ve kan yorumları gerçek olay/sağlık iddiasını reddeder', () {
      String meaning(String id) =>
          dreamSymbols.firstWhere((s) => s.id == id).meaning;
      expect(meaning('olum'), contains('haber vermez'));
      expect(meaning('kan'), contains('sağlık işareti olarak okunmamalı'));
    });
  });
}
