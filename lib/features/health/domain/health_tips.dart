import 'package:uyku/features/health/domain/health_snapshot.dart';

/// Skor bileşenlerinden türeyen kural tabanlı öneriler (tıbbi değildir).
enum HealthTip {
  /// Borç yüksek: birkaç gece biraz erken yat.
  payDebt,

  /// Ortalama süre hedefin altında.
  moreSleep,

  /// Düzenlilik düşük: yatışı aynı aralıkta tut.
  steadyBedtime,

  /// Hafta sonu uyku saati çok kayıyor.
  weekendShift,

  /// Yatmadan önce sakinleşme rutini (genel öneri).
  windDown,

  /// Her şey yolunda: ritmi koru.
  keepGoing,
}

abstract final class HealthTipRules {
  /// Bu borçtan (dk) itibaren erken yatma önerilir.
  static const debtFrom = 120;

  /// SRI bunun altındaysa yatış düzenine öneri verilir.
  static const regularityBelow = 70;

  /// Bu sosyal jetlagdan (dk) itibaren hafta sonu uyarısı verilir.
  static const jetlagFrom = 60;

  /// Ortalama süre hedefin bu oranının altındaysa süre önerisi.
  static const durationBelow = 0.9;

  static const maxTips = 3;
  static const minTips = 2;
}

/// [snapshot]'tan 2–3 öneri, önem sırasıyla.
List<HealthTip> healthTips(HealthSnapshot snapshot) {
  final tips = <HealthTip>[
    if (snapshot.debtMinutes >= HealthTipRules.debtFrom)
      HealthTip.payDebt
    else if (snapshot.goalMinutes > 0 &&
        snapshot.averageMinutes / snapshot.goalMinutes <
            HealthTipRules.durationBelow)
      HealthTip.moreSleep,
    if (snapshot.regularity != null &&
        snapshot.regularity! < HealthTipRules.regularityBelow)
      HealthTip.steadyBedtime,
    if (snapshot.socialJetlagMinutes != null &&
        snapshot.socialJetlagMinutes! >= HealthTipRules.jetlagFrom)
      HealthTip.weekendShift,
  ];
  if (tips.isEmpty) tips.add(HealthTip.keepGoing);
  if (tips.length < HealthTipRules.minTips) tips.add(HealthTip.windDown);
  return tips.take(HealthTipRules.maxTips).toList();
}
