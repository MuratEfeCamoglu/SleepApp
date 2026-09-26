import 'package:flutter/widgets.dart';
import 'package:uyku/core/theme/app_sizes.dart';
import 'package:uyku/core/theme/app_theme.dart';
import 'package:uyku/core/theme/sleep_stage_colors.dart';
import 'package:uyku/core/widgets/app_icon.dart';
import 'package:uyku/core/widgets/pressable.dart';

/// Alt paneldeki honey daire (CLAUDE.md §7.8): espresso ikon, panel renginde
/// 4 pt halka.
class FloatingCenterAction extends StatelessWidget {
  const FloatingCenterAction({
    required this.icon,
    required this.semanticLabel,
    required this.onPressed,
    this.selected = false,
    super.key,
  });

  final AppIconData icon;
  final String semanticLabel;
  final VoidCallback onPressed;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onPressed: onPressed,
      semanticLabel: semanticLabel,
      selected: selected,
      excludeChildSemantics: true,
      child: Container(
        width: AppSizes.centerAction,
        height: AppSizes.centerAction,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: SleepStageColors.honey,
          shape: BoxShape.circle,
          border: Border.all(
            color: context.colors.panel,
            width: AppSizes.centerActionRing,
          ),
        ),
        child: AppIcon(
          icon,
          color: SleepStageColors.onHoney,
          size: AppSizes.iconCenter,
        ),
      ),
    );
  }
}
