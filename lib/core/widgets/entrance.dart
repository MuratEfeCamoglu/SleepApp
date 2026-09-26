import 'package:flutter/widgets.dart';
import 'package:uyku/core/theme/app_motion.dart';

/// İlk kurulduğunda bir kez solup [AppMotion.entranceOffset] yükselerek
/// belirir. [index] sıralı gecikmeyi belirler; [AppMotion.entranceMaxStagger]
/// sonrası aynı anda gelir. [animate] false ise doğrudan görünür.
class Entrance extends StatefulWidget {
  const Entrance({
    required this.child,
    this.index = 0,
    this.animate = true,
    super.key,
  });

  final Widget child;
  final int index;
  final bool animate;

  @override
  State<Entrance> createState() => _EntranceState();
}

class _EntranceState extends State<Entrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _curve;

  @override
  void initState() {
    super.initState();
    final delay =
        AppMotion.entranceStagger *
        widget.index.clamp(0, AppMotion.entranceMaxStagger);
    final total = AppMotion.entrance + delay;
    _controller = AnimationController(vsync: this, duration: total);
    _curve = CurvedAnimation(
      parent: _controller,
      curve: Interval(
        delay.inMicroseconds / total.inMicroseconds,
        1,
        curve: AppMotion.entranceCurve,
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller.isAnimating || _controller.isCompleted) return;
    if (!widget.animate || AppMotion.reduced(context)) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _curve,
      builder: (context, child) => Opacity(
        opacity: _curve.value,
        child: Transform.translate(
          offset: Offset(0, AppMotion.entranceOffset * (1 - _curve.value)),
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}

/// Sekme değişince içeriği kısa bir solma + hafif yükselme ile getirir.
class TabSwitchFade extends StatefulWidget {
  const TabSwitchFade({required this.index, required this.child, super.key});

  final int index;
  final Widget child;

  @override
  State<TabSwitchFade> createState() => _TabSwitchFadeState();
}

class _TabSwitchFadeState extends State<TabSwitchFade>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.tabSwitch,
    value: 1,
  );
  late final Animation<double> _curve = CurvedAnimation(
    parent: _controller,
    curve: AppMotion.entranceCurve,
  );

  @override
  void didUpdateWidget(TabSwitchFade old) {
    super.didUpdateWidget(old);
    if (old.index != widget.index && !AppMotion.reduced(context)) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _curve,
      builder: (context, child) => Opacity(
        // Tamamen kaybolmasın: 0.4'ten başlar, geçiş boşluk gibi görünmez.
        opacity: 0.4 + 0.6 * _curve.value,
        child: Transform.translate(
          offset: Offset(0, AppMotion.pageOffset / 2 * (1 - _curve.value)),
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}
