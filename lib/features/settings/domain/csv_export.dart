import 'package:uyku/features/sleep_log/domain/sleep_entry.dart';

/// CSV başlık satırı (makine okunur; sütun adları sabittir, çevrilmez).
const csvHeader =
    'gece,yatis,uyanis,sure_dk,uyanis_hissi,etkenler,ruya_turu,not';

/// Tüm kayıtları RFC 4180 CSV metnine çevirir: satırlar geceye göre artan,
/// satır sonu `\r\n`. Yatış ve uyanış yerel saatle ISO 8601
/// (`2026-09-24T23:15`), etkenler `;` ile birleşik enum adlarıdır.
/// Boş listede yalnızca başlık satırı döner.
String entriesToCsv(List<SleepEntry> entries) {
  final sorted = [...entries]..sort((a, b) => a.id.compareTo(b.id));
  final buffer = StringBuffer()
    ..write(csvHeader)
    ..write('\r\n');
  for (final e in sorted) {
    final fields = <String>[
      e.id,
      _localIso(e.bedtime),
      _localIso(e.wake),
      '${e.durationMinutes}',
      e.mood.name,
      e.factors.map((f) => f.name).join(';'),
      e.dreamKind?.name ?? '',
      e.note,
    ];
    buffer
      ..write(fields.map(_escape).join(','))
      ..write('\r\n');
  }
  return buffer.toString();
}

String _two(int n) => n.toString().padLeft(2, '0');

String _localIso(DateTime t) {
  final l = t.toLocal();
  return '${l.year}-${_two(l.month)}-${_two(l.day)}'
      'T${_two(l.hour)}:${_two(l.minute)}';
}

/// Virgül, tırnak veya satır sonu içeren alan tırnaklanır; iç tırnak ikilenir.
/// Baştaki/sondaki boşluk da tırnaklanır: RFC 4180'de boşluk alanın
/// parçasıdır, tırnak onu kırpan okuyuculara karşı korur.
String _escape(String field) {
  if (!_needsQuotes.hasMatch(field)) return field;
  return '"${field.replaceAll('"', '""')}"';
}

final _needsQuotes = RegExp(r'[,"\r\n]|^\s|\s$');
