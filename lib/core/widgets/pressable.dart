import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:uyku/core/theme/app_motion.dart';

/// Ripple'sız dokunma alanı: basılıyken hafifçe solar ve küçülür, klavye ile
/// odaklanabilir ve ekran okuyucuya buton olarak görünür.
class Pressable extends StatefulWidget {
  const Pressable({
    required this.child,
    required this.onPressed,
    this.semanticLabel,
    this.selected,
    this.toggled,
    this.onLongPress,
    this.excludeChildSemantics = false,
    super.key,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;
  final String? semanticLabel;
  final bool? selected;
  final bool? toggled;

  /// true ise yalnızca [semanticLabel] okunur.
  final bool excludeChildSemantics;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;
  bool _focused = false;

  void _set(bool down) {
    if (_down != down) setState(() => _down = down);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.semanticLabel,
      selected: widget.selected,
      toggled: widget.toggled,
      excludeSemantics: widget.excludeChildSemantics,
      onTap: widget.onPressed,
      onLongPress: widget.onLongPress,
      child: FocusableActionDetector(
        enabled: enabled,
        onShowFocusHighlight: (v) => setState(() => _focused = v),
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.onPressed?.call();
              return null;
            },
          ),
        },
        shortcuts: const {
          SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: enabled ? (_) => _set(true) : null,
          onTapUp: enabled ? (_) => _set(false) : null,
          onTapCancel: () => _set(false),
          onTap: widget.onPressed,
          onLongPress: widget.onLongPress,
          child: AnimatedScale(
            duration: AppMotion.toggle,
            curve: Curves.easeOut,
            scale: _down && !AppMotion.reduced(context)
                ? AppMotion.pressScale
                : 1,
            child: AnimatedOpacity(
              duration: AppMotion.toggle,
              opacity: _down ? 0.72 : (_focused ? 0.86 : 1),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
