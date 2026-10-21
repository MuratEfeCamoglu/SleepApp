import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:uyku/core/theme/app_motion.dart';

/// Tam sayıyı 0'dan [value]'ya sayarak gösterir; süre ve eğri halka dolumuyla
/// aynıdır ([AppMotion.ringFill], [AppMotion.ringCurve]). Değer değişince
/// eski değerden yeniye akar. Hareket azaltmada ilk karede son değer görünür.
///
/// Ara değerler ekran okuyucuya verilmez: [semanticLabel] verilirse yalnız o
/// okunur, verilmezse alt ağaç semantikten çıkarılır (son değeri üstteki
/// `Semantics` söyler).
class CountUp extends StatelessWidget {
  const CountUp({
    required this.value,
    required this.builder,
    this.semanticLabel,
    super.key,
  });

  final int value;
  final Widget Function(BuildContext context, int value) builder;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final reduced = AppMotion.reduced(context);
    final counter = TweenAnimationBuilder<int>(
      tween: IntTween(begin: reduced ? value : 0, end: value),
      duration: reduced ? Duration.zero : AppMotion.ringFill,
      curve: AppMotion.ringCurve,
      builder: (context, v, _) => builder(context, v),
    );
    final label = semanticLabel;
    return label == null
        ? ExcludeSemantics(child: counter)
        : Semantics(label: label, excludeSemantics: true, child: counter);
  }
}

/// Çok yavaş "nefes alan" ölçek (1 ↔ [AppMotion.ambientScale], bir döngü
/// [AppMotion.ambient]). Hareket azaltmada durağandır; `TickerMode` kapalıyken
/// (ekran dışı sekme, üstü kapanmış rota) ticker susturulur, kare istenmez.
class AmbientBreath extends StatefulWidget {
  const AmbientBreath({required this.child, super.key});

  final Widget child;

  @override
  State<AmbientBreath> createState() => _AmbientBreathState();
}

class _AmbientBreathState extends State<AmbientBreath>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: AppMotion.ambient,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AppMotion.reduced(context)) {
      _c
        ..stop()
        ..value = 0;
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, child) {
          // 0 → 1 → 0 yumuşak sinüs; döngü başı ve sonu 1 ölçektedir.
          final wave = (1 - math.cos(2 * math.pi * _c.value)) / 2;
          return Transform.scale(
            scale: 1 + (AppMotion.ambientScale - 1) * wave,
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }
}

/// Kutlama: kurulduğunda [play] true ise bir kez 1 → 1.35 → 1 ölçek
/// ([AppMotion.celebrate]) ve hafif titreşim. Hareket azaltmada oynamaz.
class CelebrateBounce extends StatefulWidget {
  const CelebrateBounce({required this.child, this.play = true, super.key});

  final Widget child;
  final bool play;

  /// Halka uç rozetiyle aynı tepe ölçeği.
  static const double peak = 0.35;

  @override
  State<CelebrateBounce> createState() => _CelebrateBounceState();
}

class _CelebrateBounceState extends State<CelebrateBounce>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: AppMotion.celebrate,
  );
  bool _played = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _maybePlay();
  }

  @override
  void didUpdateWidget(CelebrateBounce oldWidget) {
    super.didUpdateWidget(oldWidget);
    _maybePlay();
  }

  void _maybePlay() {
    if (_played || !widget.play || AppMotion.reduced(context)) return;
    _played = true;
    unawaited(HapticFeedback.lightImpact());
    _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) => Transform.scale(
        scale: 1 + CelebrateBounce.peak * math.sin(_c.value * math.pi),
        child: child,
      ),
      child: widget.child,
    );
  }
}

/// İlk kurulduğunda alttan büyüyen değerler için: ilk karede `factor` 0,
/// sonraki karede 1 verir (implicit grafik animasyonu 0'dan değere akar).
/// Hareket azaltmada baştan 1.
class GrowIn extends StatefulWidget {
  const GrowIn({required this.builder, super.key});

  final Widget Function(BuildContext context, double factor) builder;

  @override
  State<GrowIn> createState() => _GrowInState();
}

class _GrowInState extends State<GrowIn> {
  bool _grown = false;
  bool _scheduled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_grown || _scheduled) return;
    if (AppMotion.reduced(context)) {
      _grown = true;
      return;
    }
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _grown = true);
    });
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _grown ? 1 : 0);
}
