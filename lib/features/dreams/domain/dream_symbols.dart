import 'package:flutter/foundation.dart';

/// Rüya sözlüğünde bir sembol. Sözlük cihazdadır ve sabittir; başlık ve
/// yorumlar alan verisi olduğu için `AppStrings` yerine burada durur.
///
/// Eşleşme kuralı (ISKELET §5): not [normalizeTr] ile küçük harfe çevrilir,
/// noktalama atılır ve kelimelere bölünür. Bir kelime
/// - [keywords]'teki bir kökle **başlıyorsa** ("suda" → `su`) veya
/// - [words]'teki bir kelimeye **tam eşitse**
///
/// ve [excludes]'taki hiçbir kökle başlamıyorsa sembol eşleşir. Boşluk
/// içeren anahtarlar ardışık kelimelerle eşleşir: son parça kök, öncekiler
/// tam kelimedir ("eski sevgili" → "eski sevgilim").
@immutable
class DreamSymbol {
  const DreamSymbol({
    required this.id,
    required this.keywords,
    required this.title,
    required this.meaning,
    this.words = const [],
    this.excludes = const [],
  });

  final String id;

  /// Kelime başında aranan kökler (küçük harf).
  final List<String> keywords;

  /// Yalnızca tam kelime olarak eşleşenler; kısa ve çok anlamlı kökler için
  /// ("kan" → "kanepe" eşleşmesin).
  final List<String> words;

  /// Bu köklerle başlayan kelimeler sayılmaz ("su" ↛ "sustum").
  final List<String> excludes;

  final String title;

  /// 1–2 cümlelik yansıtıcı, temkinli yorum.
  final String meaning;

  /// [tokens] içinde ilk eşleşen kelimenin sırası; yoksa null.
  int? firstMatch(List<String> tokens) {
    for (var i = 0; i < tokens.length; i++) {
      if (_matchesAt(tokens, i)) return i;
    }
    return null;
  }

  bool _matchesAt(List<String> tokens, int i) {
    final token = tokens[i];
    if (words.contains(token)) return true;
    for (final keyword in keywords) {
      final parts = keyword.split(' ');
      if (i + parts.length > tokens.length) continue;
      var ok = true;
      for (var p = 0; p < parts.length - 1; p++) {
        if (tokens[i + p] != parts[p]) {
          ok = false;
          break;
        }
      }
      if (!ok) continue;
      final last = tokens[i + parts.length - 1];
      if (last.startsWith(parts.last) && !_excluded(last)) return true;
    }
    return false;
  }

  bool _excluded(String token) => excludes.any(token.startsWith);

  @override
  bool operator ==(Object other) => other is DreamSymbol && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'DreamSymbol($id)';
}

final _apostrophes = RegExp("['’‘`´ʼ]");
final _nonWord = RegExp(r'[^\p{L}\p{N}]+', unicode: true);

/// Türkçe kurallarıyla küçük harf (`İ→i`, `I→ı`); kesme işaretleri silinir
/// ("İstanbul'da" → "istanbulda"), diğer noktalama boşluğa döner.
String normalizeTr(String input) => input
    .replaceAll('İ', 'i')
    .replaceAll('I', 'ı')
    .toLowerCase()
    .replaceAll('̇', '')
    .replaceAll(_apostrophes, '')
    .replaceAll(_nonWord, ' ')
    .trim();

/// Normalleştirilmiş kelimeler.
List<String> tokenizeTr(String input) {
  final normalized = normalizeTr(input);
  return normalized.isEmpty ? const [] : normalized.split(' ');
}

/// Nottaki semboller, notta ilk geçtikleri sırayla; her sembol bir kez.
/// Aynı kelimede başlayanlar sözlük sırasını korur.
List<DreamSymbol> findSymbols(String note) {
  final tokens = tokenizeTr(note);
  if (tokens.isEmpty) return const [];
  final found = <(int, int, DreamSymbol)>[];
  for (var s = 0; s < dreamSymbols.length; s++) {
    final at = dreamSymbols[s].firstMatch(tokens);
    if (at != null) found.add((at, s, dreamSymbols[s]));
  }
  found.sort((a, b) {
    final byPosition = a.$1.compareTo(b.$1);
    return byPosition != 0 ? byPosition : a.$2.compareTo(b.$2);
  });
  return [for (final f in found) f.$3];
}

/// Rüya sembol sözlüğü. Yorumlar kehanet değil, kendine soru sormaya
/// davettir; sağlık veya kader iddiası içermez.
const List<DreamSymbol> dreamSymbols = [
  DreamSymbol(
    id: 'su',
    title: 'Su',
    keywords: ['su', 'nehir', 'nehr', 'ırmak', 'göl'],
    excludes: [
      'sus',
      'suç',
      'sun',
      'sur',
      'sult',
      'suni',
      'sucuk',
      'subay',
      'sual',
      'gölge',
    ],
    meaning:
        'Su çoğu zaman duygularla ilişkilendirilir; durgun mu, dalgalı mı '
        'olduğu o günlerdeki iç hâlini yansıtıyor olabilir. Kendine sor: '
        'Son zamanlarda neyi hissetmeye alan açıyorsun?',
  ),
  DreamSymbol(
    id: 'deniz',
    title: 'Deniz',
    keywords: ['deniz', 'okyanus', 'dalga'],
    meaning:
        'Deniz genişliği ve bilinmeyeni çağrıştırabilir. Hayatında sınırları '
        'belli olmayan, seni hem çeken hem ürküten bir konu olup olmadığını '
        'düşünebilirsin.',
  ),
  DreamSymbol(
    id: 'yuzmek',
    title: 'Yüzmek',
    keywords: ['yüzüy', 'yüzdü', 'yüzm', 'yüzer', 'yüzücü'],
    meaning:
        'Yüzmek, bir durumun içinde kendi yolunu bulma çabasıyla ilgili '
        'düşüncelerini yansıtıyor olabilir. Rahat mı yüzüyordun, yoksa '
        'zorlanıyor muydun?',
  ),
  DreamSymbol(
    id: 'yilan',
    title: 'Yılan',
    keywords: ['yılan'],
    meaning:
        'Yılan bazen tedirginlik, bazen de değişim ve yenilenme temasıyla '
        'anılır. Kendine sor: Şu sıralar neye karşı temkinli davranıyorsun?',
  ),
  DreamSymbol(
    id: 'kopek',
    title: 'Köpek',
    keywords: ['köpek', 'köpeğ'],
    meaning:
        'Köpek sadakat ve yakınlıkla ilişkilendirilebilir. Hayatındaki güven '
        'bağlarını ya da birine duyduğun bağlılığı düşünüyor olabilirsin.',
  ),
  DreamSymbol(
    id: 'kedi',
    title: 'Kedi',
    keywords: ['kedi'],
    meaning:
        'Kedi bağımsızlık ve sezgiyle anılabilir. Kendi alanına ve '
        'özgürlüğüne ne kadar yer açtığını sorgulamak isteyebilirsin.',
  ),
  DreamSymbol(
    id: 'ev',
    title: 'Ev',
    keywords: ['ev'],
    excludes: [
      'evet',
      'evren',
      'evlen',
      'evli',
      'evrak',
      'evcil',
      'evvel',
      'evlat',
      'evre',
      'evrim',
    ],
    meaning:
        'Ev çoğu zaman benlik ve güvenli alanla ilişkilendirilir; odalar, iç '
        'dünyanın farklı yönleri gibi düşünülebilir. Rüyadaki ev sana nasıl '
        'hissettirdi?',
  ),
  DreamSymbol(
    id: 'dusmek',
    title: 'Düşmek',
    keywords: [
      'düştü',
      'düşüy',
      'düşme',
      'düşer',
      'düşec',
      'düşüş',
      'düşen',
      'düşmü',
      'düşüp',
      'uçurum',
    ],
    meaning:
        'Düşmek, kontrolün elinden kaydığı hissiyle ilgili düşüncelerini '
        'yansıtıyor olabilir. Kendine sor: Şu an hangi konuda daha fazla '
        'zemine ihtiyaç duyuyorsun?',
  ),
  DreamSymbol(
    id: 'ucmak',
    title: 'Uçmak',
    keywords: ['uçuy', 'uçtu', 'uçm', 'uçar', 'uçan', 'uçab', 'uçuş'],
    meaning:
        'Uçmak özgürlük, hafiflik ya da bir durumun üstüne çıkma isteğiyle '
        'ilişkilendirilebilir. Neyin üstünden bakmak, neyi geride bırakmak '
        'istiyorsun?',
  ),
  DreamSymbol(
    id: 'kovalanmak',
    title: 'Kovalanmak',
    keywords: [
      'koval',
      'peşimde',
      'peşimden',
      'peşime',
      'takip edil',
      'beni takip',
    ],
    meaning:
        'Kovalanmak, ertelediğin ya da kaçındığın bir konunun aklını '
        'meşgul ettiğini yansıtıyor olabilir. Kendine sor: Yüzleşmekten '
        'kaçındığın bir şey var mı?',
  ),
  DreamSymbol(
    id: 'dis',
    title: 'Diş',
    keywords: ['diş'],
    excludes: ['dişil'],
    meaning:
        'Diş rüyaları sık görülür ve çoğu zaman görünüş, kendini ifade etme '
        'ya da bir şeyi kaybetme kaygısıyla ilişkilendirilir. Son '
        'zamanlarda nasıl göründüğünü dert ettiğin bir durum oldu mu?',
  ),
  DreamSymbol(
    id: 'okul',
    title: 'Okul',
    keywords: ['okul', 'sınıf', 'öğretmen'],
    meaning:
        'Okul, öğrenme ve değerlendirilme duygularıyla ilgili olabilir. '
        'Hayatında şu sıralar neyi öğrenmeye çalıştığını düşünebilirsin.',
  ),
  DreamSymbol(
    id: 'sinav',
    title: 'Sınav',
    keywords: ['sınav', 'imtihan'],
    meaning:
        'Sınav rüyaları çoğu zaman hazır olmama ya da yargılanma kaygısıyla '
        'ilişkilendirilir. Kendine sor: Şu an kendini hangi konuda kanıtlaman '
        'gerekiyormuş gibi hissediyorsun?',
  ),
  DreamSymbol(
    id: 'bebek',
    title: 'Bebek',
    keywords: ['bebe'],
    meaning:
        'Bebek yeni bir başlangıç, filizlenen bir fikir ya da özen gösterme '
        'ihtiyacıyla ilişkilendirilebilir. Hayatında büyütmek istediğin yeni '
        'bir şey var mı?',
  ),
  DreamSymbol(
    id: 'cocuk',
    title: 'Çocuk',
    keywords: ['çocuk', 'çocuğ'],
    meaning:
        'Çocuk, oyunbazlık, merak ya da geçmişe ait anılarla ilgili '
        'düşüncelerini yansıtıyor olabilir. İçindeki çocuk bugün neye '
        'ihtiyaç duyuyor olabilir?',
  ),
  DreamSymbol(
    id: 'olum',
    title: 'Ölüm',
    keywords: ['ölü', 'öld', 'ölm', 'ölec', 'ölen', 'cenaze', 'mezar'],
    meaning:
        'Rüyada ölüm çoğu zaman gerçek bir ölümle değil, bir dönemin '
        'kapanması ya da değişimle ilişkilendirilir; bir şeyin olacağını '
        'haber vermez. Hayatında sona eren ya da dönüşen bir şey var mı?',
  ),
  DreamSymbol(
    id: 'araba',
    title: 'Araba',
    keywords: ['araba', 'otomobil', 'direksiyon'],
    meaning:
        'Araba, hayatının yönünü kimin belirlediğiyle ilgili olabilir. '
        'Direksiyonda sen miydin, yoksa yolcu muydun?',
  ),
  DreamSymbol(
    id: 'yol',
    title: 'Yol',
    keywords: ['yol'],
    // "yolla-" fiili hariç; "yollar" (yol + çoğul) sayılır.
    excludes: ['yollad', 'yollam', 'yollay', 'yolluy', 'yoldaş'],
    meaning:
        'Yol, verdiğin kararları ve gittiğin yönü yansıtıyor olabilir. '
        'Yol açık mıydı, yoksa önünde engeller mi vardı?',
  ),
  DreamSymbol(
    id: 'kapi',
    title: 'Kapı',
    keywords: ['kapı'],
    // "kapılmak" fiili; "kapılar" (kapı + çoğul) sayılır.
    excludes: ['kapıld', 'kapılıy', 'kapılm', 'kapılac', 'kapılır'],
    meaning:
        'Kapı yeni fırsatları ya da önündeki bir geçişi çağrıştırabilir. '
        'Kapı açık mıydı, kapalı mı; ve onu açmak istedin mi?',
  ),
  DreamSymbol(
    id: 'merdiven',
    title: 'Merdiven',
    keywords: ['merdiven', 'basamak'],
    meaning:
        'Merdiven ilerleme ya da geri çekilme duygusuyla ilişkilendirilebilir. '
        'Çıkıyor muydun, iniyor muydun?',
  ),
  DreamSymbol(
    id: 'ates',
    title: 'Ateş',
    keywords: ['ateş', 'alev', 'yangın'],
    excludes: ['ateşkes'],
    meaning:
        'Ateş tutku, öfke ya da dönüşümle ilişkilendirilebilir. Son '
        'zamanlarda içinde güçlü bir şekilde yanan bir duygu var mı?',
  ),
  DreamSymbol(
    id: 'yagmur',
    title: 'Yağmur',
    keywords: ['yağmur', 'sağanak'],
    meaning:
        'Yağmur arınma ya da birikmiş duyguların boşalmasıyla ilgili '
        'olabilir. Yağmur sana huzur mu verdi, yoksa üşüttü mü?',
  ),
  DreamSymbol(
    id: 'ayna',
    title: 'Ayna',
    keywords: ['ayna'],
    meaning:
        'Ayna kendine bakışını ve kendini nasıl gördüğünü yansıtıyor '
        'olabilir. Aynada gördüğün sana tanıdık geldi mi?',
  ),
  DreamSymbol(
    id: 'para',
    title: 'Para',
    keywords: ['para', 'cüzdan'],
    excludes: [
      'paralel',
      'paraşüt',
      'parantez',
      'paragraf',
      'paramparça',
      'parazit',
      'parametre',
    ],
    meaning:
        'Para çoğu zaman değer, güven ve öz-değer duygusuyla ilişkilendirilir. '
        'Kendine sor: Şu sıralar neye değer veriyorsun, neyi kaybetmekten '
        'çekiniyorsun?',
  ),
  DreamSymbol(
    id: 'kaybolmak',
    title: 'Kaybolmak',
    keywords: ['kaybol', 'kaybet', 'kayıp', 'yolumu bul'],
    meaning:
        'Kaybolmak, yön arayışı ya da bir konuda kararsız kalmakla ilgili '
        'düşüncelerini yansıtıyor olabilir. Şu an hangi konuda bir harita '
        'isterdin?',
  ),
  DreamSymbol(
    id: 'ciplaklik',
    title: 'Çıplaklık',
    keywords: ['çıplak', 'çıplağ'],
    meaning:
        'Çıplaklık, açığa çıkma ya da yargılanma kaygısıyla ilişkilendirilir. '
        'Son zamanlarda kendini savunmasız hissettiğin bir an oldu mu?',
  ),
  DreamSymbol(
    id: 'telefon',
    title: 'Telefon',
    keywords: ['telefon', 'mesaj'],
    meaning:
        'Telefon iletişim kurma ya da birine ulaşamama hissiyle ilgili '
        'olabilir. Söylemek isteyip de söyleyemediğin bir şey var mı?',
  ),
  DreamSymbol(
    id: 'ucak',
    title: 'Uçak',
    keywords: ['uçak', 'uçağ', 'havaalan', 'havalima'],
    meaning:
        'Uçak büyük bir geçişi, yolculuğu ya da hedeflerini çağrıştırabilir. '
        'Hayatında yakında başlayacak bir yeni dönem var mı?',
  ),
  DreamSymbol(
    id: 'tren',
    title: 'Tren',
    keywords: ['tren', 'istasyon', 'vagon'],
    excludes: ['trend'],
    meaning:
        'Tren, belirli bir rotada ilerleyen bir süreci düşündürebilir. Treni '
        'yakaladın mı, kaçırdın mı?',
  ),
  DreamSymbol(
    id: 'kopru',
    title: 'Köprü',
    keywords: ['köprü'],
    meaning:
        'Köprü iki durum arasındaki geçişle ilişkilendirilebilir. Hayatında '
        'bir yerden başka bir yere geçmeye hazırlandığın bir şey var mı?',
  ),
  DreamSymbol(
    id: 'orman',
    title: 'Orman',
    keywords: ['orman'],
    meaning:
        'Orman bilinmeyeni ve keşfedilmeyi bekleyen yönlerini çağrıştırabilir. '
        'Ormanda kendini güvende mi, tedirgin mi hissettin?',
  ),
  DreamSymbol(
    id: 'dag',
    title: 'Dağ',
    keywords: ['dağ', 'zirve'],
    excludes: ['dağıl', 'dağını', 'dağıt'],
    meaning:
        'Dağ bir hedefi ya da aşılması gereken bir engeli temsil ediyor '
        'olabilir. Tırmanırken ne hissettin?',
  ),
  DreamSymbol(
    id: 'isik',
    title: 'Işık',
    keywords: ['ışık', 'ışığ', 'ışıl', 'aydınlı'],
    meaning:
        'Işık, netlik ve umutla ilişkilendirilebilir. Son zamanlarda bir '
        'konuyu daha açık görmeye başladığını hissediyor musun?',
  ),
  DreamSymbol(
    id: 'karanlik',
    title: 'Karanlık',
    keywords: ['karanlı', 'zifiri'],
    meaning:
        'Karanlık, belirsizlik ya da henüz bakmaya hazır olmadığın konularla '
        'ilgili olabilir. Karanlıkta ne aradığını hatırlıyor musun?',
  ),
  DreamSymbol(
    id: 'gunes',
    title: 'Güneş',
    keywords: ['güneş', 'gün doğumu'],
    meaning:
        'Güneş enerji, sıcaklık ve canlılıkla ilişkilendirilebilir. Seni '
        'şu sıralar neyin ısıttığını düşünebilirsin.',
  ),
  DreamSymbol(
    id: 'anne',
    title: 'Anne',
    keywords: ['anne'],
    meaning:
        'Anne figürü şefkat, bakım ve korunma ihtiyacıyla '
        'ilişkilendirilebilir. Kendine sor: Şu sıralar kendine yeterince '
        'özen gösteriyor musun?',
  ),
  DreamSymbol(
    id: 'baba',
    title: 'Baba',
    keywords: ['baba'],
    meaning:
        'Baba figürü otorite, rehberlik ya da beklentilerle ilgili olabilir. '
        'Kimin onayını önemsediğini düşünmek isteyebilirsin.',
  ),
  DreamSymbol(
    id: 'kardes',
    title: 'Kardeş',
    keywords: ['kardeş', 'abla', 'ağabey', 'abim'],
    meaning:
        'Kardeş, rekabet, dayanışma ya da paylaşılan geçmişle '
        'ilişkilendirilebilir. Bu ilişkide şu an seni düşündüren bir şey '
        'var mı?',
  ),
  DreamSymbol(
    id: 'eski_sevgili',
    title: 'Eski sevgili',
    keywords: [
      'eski sevgili',
      'eski erkek arkadaş',
      'eski kız arkadaş',
      'eski eşim',
    ],
    meaning:
        'Eski bir sevgili çoğu zaman o kişiyi değil, o dönemde hissettiğin '
        'bir duyguyu ya da kapanmamış bir konuyu temsil ediyor olabilir. O '
        'ilişkiden bugüne taşıdığın bir ders var mı?',
  ),
  DreamSymbol(
    id: 'arkadas',
    title: 'Arkadaş',
    keywords: ['arkadaş', 'dost'],
    meaning:
        'Arkadaş, aidiyet ve destek ihtiyacıyla ilgili olabilir. Rüyadaki '
        'arkadaşın sende hangi özelliği hatırlatıyor?',
  ),
  DreamSymbol(
    id: 'dugun',
    title: 'Düğün',
    keywords: ['düğün', 'gelinlik', 'nikah', 'nikâh', 'evlen'],
    meaning:
        'Düğün bir birleşmeyi, bağlılığı ya da yeni bir dönemi '
        'çağrıştırabilir. Hayatında kendini adamaya hazırlandığın bir şey '
        'var mı?',
  ),
  DreamSymbol(
    id: 'hamilelik',
    title: 'Hamilelik',
    keywords: ['hamile', 'gebe'],
    excludes: ['geber'],
    meaning:
        'Hamilelik rüyası çoğu zaman gelişmekte olan bir fikir ya da proje '
        'ile ilişkilendirilir. İçinde büyüyen, zamanı gelince ortaya çıkacak '
        'bir şey var mı?',
  ),
  DreamSymbol(
    id: 'kan',
    title: 'Kan',
    keywords: ['kanlı', 'kanama', 'kanıyor'],
    words: [
      'kan',
      'kana',
      'kanı',
      'kanım',
      'kanın',
      'kanda',
      'kandan',
      'kanla',
      'kanlar',
    ],
    meaning:
        'Rüyada kan yoğun bir duyguyu, yorgunluğu ya da bir şeye verdiğin '
        'emeği simgeleyebilir; bir sağlık işareti olarak okunmamalı. Son '
        'zamanlarda seni tüketen bir şey var mı?',
  ),
  DreamSymbol(
    id: 'hastane',
    title: 'Hastane',
    keywords: ['hastane', 'doktor', 'ameliyat'],
    meaning:
        'Hastane, iyileşme ve bakım ihtiyacıyla ilişkilendirilebilir. '
        'Kendine sor: Dinlenmeye ya da desteğe ihtiyaç duyduğun bir alan '
        'var mı?',
  ),
  DreamSymbol(
    id: 'aglamak',
    title: 'Ağlamak',
    keywords: ['ağla', 'ağlı', 'gözyaş'],
    meaning:
        'Ağlamak birikmiş duyguların dışarı çıkmasıyla ilgili olabilir. Uyanık '
        'hayatında ifade etmeye fırsat bulamadığın bir duygu var mı?',
  ),
  DreamSymbol(
    id: 'gulmek',
    title: 'Gülmek',
    keywords: ['gülü', 'güldü', 'gülm', 'güler', 'kahkaha'],
    meaning:
        'Gülmek rahatlama ve hafiflik hissini yansıtıyor olabilir. Seni '
        'son zamanlarda içten güldüren ne oldu?',
  ),
  DreamSymbol(
    id: 'kus',
    title: 'Kuş',
    keywords: ['kuş', 'martı', 'güvercin'],
    excludes: ['kuşak', 'kuşku', 'kuşat', 'kuşan'],
    meaning:
        'Kuş özgürlük ve haberle ilişkilendirilebilir. Hayatında beklediğin '
        'ya da duymak istediğin bir haber var mı?',
  ),
  DreamSymbol(
    id: 'balik',
    title: 'Balık',
    keywords: ['balık', 'balığ'],
    meaning:
        'Balık, derinlerde duran duygu ya da fikirlerle ilişkilendirilebilir. '
        'Yüzeye çıkmayı bekleyen bir düşüncen var mı?',
  ),
  DreamSymbol(
    id: 'at',
    title: 'At',
    keywords: ['aygır', 'kısrak'],
    words: [
      'at',
      'atı',
      'atın',
      'atım',
      'atta',
      'atlar',
      'atları',
      'atların',
      'atlara',
    ],
    meaning:
        'At güç, enerji ve ilerleme isteğiyle ilişkilendirilebilir. Bu '
        'enerjiyi hayatında nereye yönlendirmek istiyorsun?',
  ),
  DreamSymbol(
    id: 'orumcek',
    title: 'Örümcek',
    keywords: ['örümc'],
    meaning:
        'Örümcek, sabırla örülen planları ya da içinde sıkışmış hissettiğin '
        'bir durumu çağrıştırabilir. Kendine sor: Hangi ağın içindesin?',
  ),
  DreamSymbol(
    id: 'bocek',
    title: 'Böcek',
    keywords: ['böce', 'böceğ', 'karınca', 'sinek'],
    meaning:
        'Böcekler, küçük ama rahatsız eden kaygılarla ilişkilendirilebilir. '
        'Aklını kurcalayan, küçük görünen bir konu var mı?',
  ),
  DreamSymbol(
    id: 'bahce',
    title: 'Bahçe',
    keywords: ['bahçe', 'park'],
    excludes: ['parke', 'parka'],
    meaning:
        'Bahçe emek verdiğin ve büyüttüğün şeyleri temsil edebilir. Şu sıralar '
        'neye özen gösteriyorsun?',
  ),
  DreamSymbol(
    id: 'cicek',
    title: 'Çiçek',
    keywords: ['çiçe'],
    meaning:
        'Çiçek güzellik, açılma ve gelişimle ilişkilendirilebilir. Hayatında '
        'yeni yeni filizlenen bir şey var mı?',
  ),
  DreamSymbol(
    id: 'agac',
    title: 'Ağaç',
    keywords: ['ağaç', 'ağac'],
    meaning:
        'Ağaç kökleri ve büyümeyi çağrıştırabilir. Seni bugün ayakta tutan '
        'kökler neler?',
  ),
  DreamSymbol(
    id: 'kar',
    title: 'Kar',
    keywords: ['karlı', 'kartop'],
    words: ['kar', 'karda', 'kardan', 'karla', 'karlar', 'karları'],
    meaning:
        'Kar sükûnet, temiz bir sayfa ya da donmuş duygularla '
        'ilişkilendirilebilir. Rüyadaki kar sana huzur mu verdi, yoksa '
        'yalnızlık mı?',
  ),
  DreamSymbol(
    id: 'firtina',
    title: 'Fırtına',
    keywords: ['fırtına', 'kasırga', 'şimşek', 'gök gürültü'],
    meaning:
        'Fırtına, hayatındaki çalkantılı bir dönemi ya da içinde biriken '
        'gerginliği yansıtıyor olabilir. Fırtınanın dinmesi için neye '
        'ihtiyacın var?',
  ),
  DreamSymbol(
    id: 'deprem',
    title: 'Deprem',
    keywords: ['deprem', 'sarsıntı', 'sallanıy'],
    meaning:
        'Deprem, güvendiğin bir zeminin değiştiği hissiyle ilgili olabilir. '
        'Son zamanlarda alışkanlıklarını sarsan bir gelişme oldu mu?',
  ),
  DreamSymbol(
    id: 'sel',
    title: 'Sel',
    keywords: ['taşkın', 'su bastı'],
    words: ['sel', 'sele', 'selde', 'selin', 'seller'],
    meaning:
        'Sel, baş etmekte zorlandığın yoğun duygular ya da işlerle '
        'ilişkilendirilebilir. Şu an üzerine gelen bir şeyi biraz '
        'hafifletebilir misin?',
  ),
  DreamSymbol(
    id: 'savas',
    title: 'Savaş',
    keywords: ['savaş', 'çatışma', 'bomba', 'asker'],
    meaning:
        'Savaş, içsel ya da ilişkisel bir çatışmayı yansıtıyor olabilir. '
        'Kendine sor: Şu sıralar kiminle ya da neyle mücadele ediyorsun?',
  ),
  DreamSymbol(
    id: 'hirsiz',
    title: 'Hırsız',
    keywords: ['hırsız', 'soygun', 'soyuldu'],
    meaning:
        'Hırsız, zamanının, enerjinin ya da bir şeyin elinden alındığı '
        'hissiyle ilgili olabilir. Neyi korumaya ihtiyaç duyuyorsun?',
  ),
  DreamSymbol(
    id: 'kaza',
    title: 'Kaza',
    keywords: ['kaza', 'çarpış', 'çarptı'],
    excludes: ['kazan', 'kazak', 'kazara'],
    meaning:
        'Kaza rüyaları beklenmedik değişimlere ya da aceleye dair kaygıyı '
        'yansıtıyor olabilir; geleceği haber vermez. Biraz yavaşlamaya '
        'ihtiyacın var mı?',
  ),
  DreamSymbol(
    id: 'yemek',
    title: 'Yemek',
    keywords: ['yemek', 'yemeğ', 'yiyor', 'yedim', 'sofra'],
    meaning:
        'Yemek, beslenme ve doyum ihtiyacını çağrıştırabilir; bu bazen '
        'duygusal bir doyum da olabilir. Seni şu sıralar ne besliyor?',
  ),
  DreamSymbol(
    id: 'ekmek',
    title: 'Ekmek',
    keywords: ['ekmek', 'ekmeğ', 'fırın'],
    meaning:
        'Ekmek temel ihtiyaçları, emeği ve paylaşmayı çağrıştırabilir. '
        'Hayatında yeterince şeyin olduğunu hissediyor musun?',
  ),
  DreamSymbol(
    id: 'altin',
    title: 'Altın',
    keywords: ['mücevher', 'hazine'],
    words: ['altın', 'altınlar', 'altınları', 'altınlara', 'altınlarla'],
    meaning:
        'Altın, değerli bulduğun şeyleri ya da kendi değerini fark etmeyi '
        'çağrıştırabilir. Kendinde değerli bulduğun bir yön hangisi?',
  ),
  DreamSymbol(
    id: 'yuzuk',
    title: 'Yüzük',
    keywords: ['yüzük', 'yüzüğ'],
    meaning:
        'Yüzük bağlılık ve sözlerle ilişkilendirilebilir. Verdiğin ya da '
        'sana verilen bir sözü düşünüyor olabilir misin?',
  ),
  DreamSymbol(
    id: 'saat',
    title: 'Saat',
    keywords: ['saat', 'geç kal', 'yetişemedi', 'yetişemiy'],
    meaning:
        'Saat ve geç kalma, zamanın yetmediği hissini yansıtıyor olabilir. '
        'Kendine sor: Gerçekten acele etmen gereken bir şey var mı?',
  ),
  DreamSymbol(
    id: 'anahtar',
    title: 'Anahtar',
    keywords: ['anahtar', 'kilit'],
    meaning:
        'Anahtar, bir sorunun çözümünü ya da erişmek istediğin bir alanı '
        'çağrıştırabilir. Şu an hangi kapıyı açmak istiyorsun?',
  ),
  DreamSymbol(
    id: 'kitap',
    title: 'Kitap',
    keywords: ['kitap', 'kitab', 'defter'],
    meaning:
        'Kitap merak, bilgi ya da hayatının yazılmakta olan hikâyesiyle '
        'ilgili olabilir. Şu sıralar hangi sayfayı çevirmek istiyorsun?',
  ),
  DreamSymbol(
    id: 'muzik',
    title: 'Müzik',
    keywords: ['müzi', 'şarkı', 'melodi'],
    meaning:
        'Müzik uyum ve duygusal ifadeyle ilişkilendirilebilir. Rüyadaki '
        'müzik sana nasıl hissettirdi?',
  ),
  DreamSymbol(
    id: 'dans',
    title: 'Dans',
    keywords: ['dans'],
    meaning:
        'Dans, akışa bırakmak ve bedeninle uyum içinde olmakla ilgili '
        'olabilir. Hayatında biraz daha akışta kalmak istediğin bir alan '
        'var mı?',
  ),
  DreamSymbol(
    id: 'kosmak',
    title: 'Koşmak',
    keywords: ['koşu', 'koştu', 'koşm', 'koşar'],
    excludes: ['koşul'],
    meaning:
        'Koşmak, bir şeye yetişme ya da bir şeyden uzaklaşma isteğini '
        'yansıtıyor olabilir. Neye doğru ya da neden uzağa koşuyordun?',
  ),
  DreamSymbol(
    id: 'saklanmak',
    title: 'Saklanmak',
    keywords: ['saklan', 'saklambaç', 'gizlen'],
    meaning:
        'Saklanmak, görünür olmaktan çekinme ya da biraz geri çekilip '
        'dinlenme ihtiyacıyla ilgili olabilir. Şu an kendine nasıl bir '
        'sığınak isterdin?',
  ),
  DreamSymbol(
    id: 'gemi',
    title: 'Gemi',
    keywords: ['gemi', 'tekne', 'vapur', 'sandal'],
    excludes: ['sandalye'],
    meaning:
        'Gemi, hayatın akışında bir yolculuğu ve dümeni kimin tuttuğunu '
        'çağrıştırabilir. Bu yolculukta kendini kaptan gibi mi hissediyorsun?',
  ),
  DreamSymbol(
    id: 'is',
    title: 'İş yeri',
    keywords: ['patron', 'ofis', 'toplantı', 'iş yeri', 'işyeri'],
    meaning:
        'İş yeri rüyaları çoğu zaman gün içindeki sorumlulukların zihninde '
        'dolaşmaya devam ettiğini yansıtıyor olabilir. Akşamları işi geride '
        'bırakmak için küçük bir kapanış ritüeli işine yarayabilir mi?',
  ),
  DreamSymbol(
    id: 'bulut',
    title: 'Bulut',
    keywords: ['bulut'],
    meaning:
        'Bulutlar geçici düşünceleri ya da belirsizliği çağrıştırabilir. '
        'Aklındaki hangi bulut zamanla dağılabilir?',
  ),
];
