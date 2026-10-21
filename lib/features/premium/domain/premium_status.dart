import 'package:flutter/foundation.dart';

/// Premium hakkının nereden geldiği.
enum PremiumSource {
  /// Premium yok.
  none,

  /// Geliştirici derlemesinde yerel olarak açıldı.
  debug,

  /// Mağaza satın alımı (RevenueCat/StoreKit bağlanınca).
  store,
}

/// Kullanıcının premium durumu.
@immutable
class PremiumStatus {
  const PremiumStatus({
    this.active = false,
    this.since,
    this.source = PremiumSource.none,
  });

  /// Yanlış tipli alanlarda [FormatException] fırlatır (TypeError değil),
  /// böylece depo bozuk kaydı güvenle kapalıya düşürebilir.
  factory PremiumStatus.fromJson(Map<String, dynamic> json) => PremiumStatus(
    active: switch (json['active']) {
      null => false,
      final bool v => v,
      final v => throw FormatException('premium.active', v),
    },
    since: switch (json['since']) {
      null => null,
      final String v => DateTime.parse(v),
      final v => throw FormatException('premium.since', v),
    },
    source:
        PremiumSource.values.asNameMap()[json['source']] ?? PremiumSource.none,
  );

  final bool active;

  /// Premium'un açıldığı an; kapalıyken null.
  final DateTime? since;
  final PremiumSource source;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'active': active,
    'since': since?.toIso8601String(),
    'source': source.name,
  };

  static const _unset = Object();

  /// [since] için `null` vermek alanı temizler; vermemek korur.
  PremiumStatus copyWith({
    bool? active,
    Object? since = _unset,
    PremiumSource? source,
  }) => PremiumStatus(
    active: active ?? this.active,
    since: identical(since, _unset) ? this.since : since as DateTime?,
    source: source ?? this.source,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PremiumStatus &&
          other.active == active &&
          other.since == since &&
          other.source == source;

  @override
  int get hashCode => Object.hash(active, since, source);

  @override
  String toString() =>
      'PremiumStatus(active: $active, since: $since, source: $source)';
}
