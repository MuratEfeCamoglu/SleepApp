import 'package:flutter_test/flutter_test.dart';
import 'package:uyku/features/settings/domain/csv_export.dart';
import 'package:uyku/features/sleep_log/domain/sleep_entry.dart';

SleepEntry _entry(
  String id, {
  String note = '',
  DreamKind? dreamKind,
  List<SleepFactor> factors = const [],
}) {
  final night = DateTime.parse(id);
  return SleepEntry(
    id: id,
    bedtime: DateTime(night.year, night.month, night.day, 23, 15),
    wake: DateTime(night.year, night.month, night.day + 1, 7),
    mood: WakeMood.refreshed,
    factors: factors,
    note: note,
    dreamKind: dreamKind,
  );
}

List<String> _lines(String csv) {
  expect(csv.endsWith('\r\n'), isTrue);
  return csv.substring(0, csv.length - 2).split('\r\n');
}

void main() {
  test('başlık tam olarak beklenen', () {
    expect(
      _lines(entriesToCsv([_entry('2026-09-24')])).first,
      'gece,yatis,uyanis,sure_dk,uyanis_hissi,etkenler,ruya_turu,not',
    );
  });

  test('boş liste → yalnız başlık', () {
    expect(
      entriesToCsv(const []),
      'gece,yatis,uyanis,sure_dk,uyanis_hissi,etkenler,ruya_turu,not\r\n',
    );
  });

  test('satır alanları ve geceye göre artan sıra', () {
    final csv = entriesToCsv([
      _entry(
        '2026-09-25',
        factors: [SleepFactor.caffeine, SleepFactor.screen],
        dreamKind: DreamKind.values.first,
        note: 'sakin',
      ),
      _entry('2026-09-24'),
    ]);
    final lines = _lines(csv);
    expect(lines, hasLength(3));
    expect(
      lines[1],
      '2026-09-24,2026-09-24T23:15,2026-09-25T07:00,465,refreshed,,,',
    );
    expect(
      lines[2],
      '2026-09-25,2026-09-25T23:15,2026-09-26T07:00,465,refreshed,'
      'caffeine;screen,${DreamKind.values.first.name},sakin',
    );
  });

  test('rüya alanı olmayan kayıt → boş ruya_turu ve not', () {
    final line = _lines(entriesToCsv([_entry('2026-09-24')]))[1];
    expect(line.split(','), hasLength(8));
    expect(line.endsWith(',,'), isTrue);
  });

  test('virgül içeren not tırnaklanır', () {
    final line = _lines(entriesToCsv([_entry('2026-09-24', note: 'a, b')]))[1];
    expect(line.endsWith(',"a, b"'), isTrue);
  });

  test('tırnak içeren not tırnaklanır, iç tırnak ikilenir', () {
    final line = _lines(
      entriesToCsv([_entry('2026-09-24', note: 'dedi ki "uç"')]),
    )[1];
    expect(line.endsWith(',"dedi ki ""uç"""'), isTrue);
  });

  test('satır sonu içeren not tırnaklanır', () {
    final csv = entriesToCsv([_entry('2026-09-24', note: 'bir\nikii')]);
    expect(csv.endsWith(',"bir\nikii"\r\n'), isTrue);
  });

  test('yalnız CR ve CRLF içeren not tırnaklanır', () {
    expect(
      entriesToCsv([_entry('2026-09-24', note: 'a\rb')]),
      endsWith(',"a\rb"\r\n'),
    );
    expect(
      entriesToCsv([_entry('2026-09-24', note: 'a\r\nb')]),
      endsWith(',"a\r\nb"\r\n'),
    );
  });

  test('baştaki/sondaki boşluk tırnakla korunur', () {
    expect(
      _lines(entriesToCsv([_entry('2026-09-24', note: ' a')]))[1],
      endsWith(',refreshed,,," a"'),
    );
    expect(
      _lines(entriesToCsv([_entry('2026-09-24', note: 'a ')]))[1],
      endsWith(',"a "'),
    );
    // Ortadaki boşluk tırnak gerektirmez.
    expect(
      _lines(entriesToCsv([_entry('2026-09-24', note: 'a b')]))[1],
      endsWith(',a b'),
    );
  });

  test('her satır CRLF ile biter; çıplak LF yalnız tırnak içinde', () {
    final csv = entriesToCsv([
      _entry('2026-09-24', note: 'x\ny'),
      _entry('2026-09-25'),
    ]);
    final outside = csv.replaceAll('"x\ny"', '');
    expect(RegExp(r'(?<!\r)\n').hasMatch(outside), isFalse);
    expect('\r\n'.allMatches(csv), hasLength(3));
  });

  test('karışık notlar RFC 4180 ayrıştırıcısıyla birebir geri okunur', () {
    const notes = [
      'düz',
      'a, b',
      '"tam tırnak"',
      'iç "tırnak", virgül\r\nve satır',
      ' boşluk ',
      ',',
      '""',
      '',
    ];
    final entries = [
      for (var i = 0; i < notes.length; i++)
        _entry('2026-09-${10 + i}', note: notes[i]),
    ];
    final rows = _parseCsv(entriesToCsv(entries));
    expect(rows.first, csvHeader.split(','));
    expect(rows, hasLength(notes.length + 1));
    for (var i = 0; i < notes.length; i++) {
      expect(rows[i + 1], hasLength(8));
      expect(rows[i + 1].last, notes[i]);
    }
  });

  test('sıralama girdi sırasından bağımsız, gece anahtarına göre artan', () {
    final ids = ['2026-10-02', '2025-12-31', '2026-01-15', '2026-10-01'];
    final rows = _parseCsv(entriesToCsv([for (final id in ids) _entry(id)]));
    expect(rows.skip(1).map((r) => r.first).toList(), [
      '2025-12-31',
      '2026-01-15',
      '2026-10-01',
      '2026-10-02',
    ]);
  });

  test('UTC saatler yerel saate çevrilir, süre dakikadır', () {
    final bed = DateTime(2026, 9, 24, 23, 15);
    final wake = DateTime(2026, 9, 25, 6, 40);
    final e = SleepEntry(
      id: '2026-09-24',
      bedtime: bed.toUtc(),
      wake: wake.toUtc(),
    );
    final row = _parseCsv(entriesToCsv([e]))[1];
    expect(row[1], '2026-09-24T23:15');
    expect(row[2], '2026-09-25T06:40');
    expect(row[3], '445');
    expect(row[4], WakeMood.normal.name);
  });
}

/// Testler için küçük RFC 4180 ayrıştırıcı (CRLF satır sonu).
List<List<String>> _parseCsv(String csv) {
  final rows = <List<String>>[];
  var row = <String>[];
  final field = StringBuffer();
  var quoted = false;
  var i = 0;
  while (i < csv.length) {
    final c = csv[i];
    if (quoted) {
      if (c == '"') {
        if (i + 1 < csv.length && csv[i + 1] == '"') {
          field.write('"');
          i += 2;
          continue;
        }
        quoted = false;
      } else {
        field.write(c);
      }
      i++;
      continue;
    }
    if (c == '"') {
      expect(field.isEmpty, isTrue, reason: 'tırnak alan ortasında');
      quoted = true;
    } else if (c == ',') {
      row.add(field.toString());
      field.clear();
    } else if (c == '\r' && i + 1 < csv.length && csv[i + 1] == '\n') {
      row.add(field.toString());
      field.clear();
      rows.add(row);
      row = <String>[];
      i++;
    } else {
      expect(c, isNot(anyOf('\r', '\n')), reason: 'tırnaksız satır sonu');
      field.write(c);
    }
    i++;
  }
  expect(quoted, isFalse);
  expect(row, isEmpty, reason: 'son satır CRLF ile bitmeli');
  return rows;
}
