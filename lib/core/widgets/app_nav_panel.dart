import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:uyku/core/theme/app_radius.dart';
import 'package:uyku/core/theme/app_sizes.dart';
import 'package:uyku/core/theme/app_spacing.dart';
import 'package:uyku/core/theme/app_theme.dart';
import 'package:uyku/core/theme/sleep_stage_colors.dart';
import 'package:uyku/core/widgets/app_icon.dart';
import 'package:uyku/core/widgets/floating_center_action.dart';
import 'package:uyku/core/widgets/pressable.dart';

@immutable
class NavPanelItem {
  const NavPanelItem({required this.label, required this.icon});

  final String label;
  final AppIconData icon;
}

/// Ekran altına yapışık espresso panel: 2 sekme · ortada honey eylem ·
/// 2 sekme (CLAUDE.md §6).
class AppNavPanel extends StatelessWidget {
  const AppNavPanel({
    required this.items,
    required this.center,
    required this.centerSemantic,
    required this.currentIndex,
    required this.onSelect,
    required this.semanticLabel,
    super.key,
  }) : assert(items.length == 4, 'Panel 4 sekme + orta eylem içerir');

  /// Sol iki ve sağ iki sekme.
  final List<NavPanelItem> items;
  final NavPanelItem center;
  final String centerSemantic;

  /// 0–4; 2 orta eylemdir.
  final int currentIndex;
  final ValueChanged<int> onSelect;
  final String semanticLabel;

  /// Panelin ekranda kapladığı yükseklik (içerik alt boşluğu için).
  static double heightOf(BuildContext context) =>
      AppSizes.navContent + _bottomInset(context);

  static double _bottomInset(BuildContext context) =>
      math.max(MediaQuery.viewPaddingOf(context).bottom, AppSizes.navMinBottom);

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.text;

    Widget tab(int index, NavPanelItem item) {
      final selected = currentIndex == index;
      final color = selected ? SleepStageColors.honey : colors.onPanelMuted;
      return Expanded(
        child: Pressable(
          onPressed: () => onSelect(index),
          semanticLabel: item.label,
          selected: selected,
          excludeChildSemantics: true,
          child: SizedBox(
            height: AppSizes.navItem,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppIcon(item.icon, color: color, size: AppSizes.iconNav),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textScaler: MediaQuery.textScalerOf(
                    context,
                  ).clamp(maxScaleFactor: 1.2),
                  style: text.navLabel.copyWith(color: color),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final centerSelected = currentIndex == 2;
    return Semantics(
      container: true,
      label: semanticLabel,
      explicitChildNodes: true,
      child: Container(
        height: heightOf(context),
        padding: EdgeInsets.only(
          left: AppSpacing.xsPlus,
          right: AppSpacing.xsPlus,
          top: AppSpacing.sm,
          bottom: _bottomInset(context),
        ),
        decoration: BoxDecoration(
          color: colors.panel,
          borderRadius: AppRadius.xlTop,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            tab(0, items[0]),
            tab(1, items[1]),
            Expanded(
              child: OverflowBox(
                alignment: Alignment.topCenter,
                maxHeight: AppSizes.navItem + AppSizes.centerActionLift + 20,
                child: Transform.translate(
                  offset: const Offset(0, -AppSizes.centerActionLift),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FloatingCenterAction(
                        icon: center.icon,
                        semanticLabel: centerSemantic,
                        selected: centerSelected,
                        onPressed: () => onSelect(2),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => onSelect(2),
                        child: ExcludeSemantics(
                          child: Text(
                            center.label,
                            maxLines: 1,
                            textScaler: MediaQuery.textScalerOf(
                              context,
                            ).clamp(maxScaleFactor: 1.2),
                            style: text.navLabel.copyWith(
                              color: centerSelected
                                  ? SleepStageColors.honey
                                  : colors.onPanelMuted,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            tab(3, items[2]),
            tab(4, items[3]),
          ],
        ),
      ),
    );
  }
}
