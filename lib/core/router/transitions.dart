import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:uyku/core/theme/app_motion.dart';

/// 280 ms fade + 16 pt dikey kayma (CLAUDE.md §5.7).
CustomTransitionPage<void> fadeSlidePage({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: AppMotion.pageTransition,
    reverseTransitionDuration: AppMotion.pageTransition,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      if (AppMotion.reduced(context)) return child;
      final curved = CurvedAnimation(
        parent: animation,
        curve: AppMotion.ringCurve,
      );
      return FadeTransition(
        opacity: curved,
        child: AnimatedBuilder(
          animation: curved,
          builder: (context, child) => Transform.translate(
            offset: Offset(0, AppMotion.pageOffset * (1 - curved.value)),
            child: child,
          ),
          child: child,
        ),
      );
    },
  );
}
