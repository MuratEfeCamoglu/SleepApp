import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uyku/core/strings/app_strings.dart';
import 'package:uyku/core/theme/app_motion.dart';
import 'package:uyku/core/theme/app_theme.dart';
import 'package:uyku/core/widgets/entrance.dart';
import 'package:uyku/core/widgets/motion.dart';
import 'package:uyku/features/dreams/presentation/dreams_screen.dart';
import 'package:uyku/features/health/presentation/health_ui.dart';

const AppStrings _s = AppStrings.instance;

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  required bool reduced,
  bool tickers = true,
}) {
  return tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      locale: AppStrings.locale,
      supportedLocales: AppStrings.supportedLocales,
      localizationsDelegates: AppStrings.localizationsDelegates,
      builder: (context, app) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
        child: TickerMode(enabled: tickers, child: app!),
      ),
      home: Scaffold(body: Center(child: child)),
    ),
  );
}

/// Halka merkezindeki "NN/100" metni.
String _scoreText(WidgetTester tester) => tester
    .widgetList<RichText>(find.byType(RichText))
    .map((r) => r.text.toPlainText())
    .firstWhere((t) => t.endsWith(_s.health_scoreMax));

/// [AmbientBreath] içindeki ölçek.
double _ambientScale(WidgetTester tester) {
  final transform = tester.widget<Transform>(
    find
        .descendant(
          of: find.byType(AmbientBreath),
          matching: find.byType(Transform),
        )
        .first,
  );
  return transform.transform.getMaxScaleOnAxis();
}

void main() {
  group('CountUp / skor', () {
    testWidgets('hareket azaltmada ilk karede son değer görünür', (
      tester,
    ) async {
      await _pump(tester, const HealthScoreRing(score: 72), reduced: true);
      expect(_scoreText(tester), '72${_s.health_scoreMax}');
      await tester.pump(AppMotion.ringFill ~/ 3);
      expect(_scoreText(tester), '72${_s.health_scoreMax}');
    });

    testWidgets('normalde sıfırdan sayar ve ringFill sonunda değere ulaşır', (
      tester,
    ) async {
      await _pump(tester, const HealthScoreRing(score: 72), reduced: false);
      expect(_scoreText(tester), '0${_s.health_scoreMax}');
      await tester.pump(AppMotion.ringFill ~/ 2);
      final mid = int.parse(_scoreText(tester).split('/').first);
      expect(mid, inInclusiveRange(1, 71));
      await tester.pumpAndSettle();
      expect(_scoreText(tester), '72${_s.health_scoreMax}');
    });

    testWidgets('ekran okuyucu ara değeri değil son değeri okur', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, const HealthScoreRing(score: 72), reduced: false);
      await tester.pump(AppMotion.ringFill ~/ 3);
      final label = _s.health_ringSemantic(72, _s.health_bandGood);
      expect(
        find.bySemanticsLabel(RegExp('^${RegExp.escape(label)}')),
        findsOneWidget,
      );
      // Sayan merkez metni ("NN/100") hiçbir semantik düğümde yok.
      expect(find.bySemanticsLabel(RegExp(r'\d+/100')), findsNothing);
      await tester.pumpAndSettle();
      handle.dispose();
    });
  });

  group('AmbientBreath', () {
    testWidgets('hareket azaltmada durağan; pumpAndSettle tamamlanır', (
      tester,
    ) async {
      await _pump(tester, const DreamInterpretCard(), reduced: true);
      await tester.pumpAndSettle();
      expect(_ambientScale(tester), 1);
      expect(tester.binding.hasScheduledFrame, isFalse);
    });

    testWidgets('normalde 1 ↔ ambientScale arasında nefes alır', (
      tester,
    ) async {
      await _pump(
        tester,
        const AmbientBreath(child: SizedBox.square(dimension: 10)),
        reduced: false,
      );
      await tester.pump(AppMotion.ambient ~/ 2);
      expect(_ambientScale(tester), closeTo(AppMotion.ambientScale, 1e-6));
      expect(tester.binding.hasScheduledFrame, isTrue);
      await tester.pump(AppMotion.ambient ~/ 2);
      expect(_ambientScale(tester), closeTo(1, 1e-6));
      // Sonsuz döngü: ağacı kaldırınca controller dispose edilir.
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('TickerMode kapalıyken kare istemez', (tester) async {
      await _pump(
        tester,
        const AmbientBreath(child: SizedBox.square(dimension: 10)),
        reduced: false,
        tickers: false,
      );
      await tester.pumpAndSettle();
      expect(tester.binding.hasScheduledFrame, isFalse);
    });
  });

  testWidgets('Entrance hareket azaltmada ilk karede tam opak', (tester) async {
    await _pump(
      tester,
      const Entrance(index: 3, child: SizedBox.square(dimension: 10)),
      reduced: true,
    );
    final opacity = tester.widget<Opacity>(
      find.descendant(
        of: find.byType(Entrance),
        matching: find.byType(Opacity),
      ),
    );
    expect(opacity.opacity, 1);
  });

  testWidgets('CelebrateBounce hareket azaltmada oynamaz', (tester) async {
    await _pump(
      tester,
      const CelebrateBounce(child: SizedBox.square(dimension: 10)),
      reduced: true,
    );
    await tester.pump(AppMotion.celebrate ~/ 2);
    final transform = tester.widget<Transform>(
      find.descendant(
        of: find.byType(CelebrateBounce),
        matching: find.byType(Transform),
      ),
    );
    expect(transform.transform.getMaxScaleOnAxis(), 1);
  });

  testWidgets('CelebrateBounce normalde tepe ölçeğe çıkıp geri döner', (
    tester,
  ) async {
    await _pump(
      tester,
      const CelebrateBounce(child: SizedBox.square(dimension: 10)),
      reduced: false,
    );
    double scale() => tester
        .widget<Transform>(
          find.descendant(
            of: find.byType(CelebrateBounce),
            matching: find.byType(Transform),
          ),
        )
        .transform
        .getMaxScaleOnAxis();
    await tester.pump(AppMotion.celebrate ~/ 2);
    expect(scale(), closeTo(1 + CelebrateBounce.peak, 1e-6));
    await tester.pumpAndSettle();
    expect(scale(), 1);
  });
}
