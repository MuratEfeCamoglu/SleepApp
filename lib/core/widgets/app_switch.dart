import 'package:flutter/widgets.dart';
import 'package:uyku/core/theme/app_motion.dart';
import 'package:uyku/core/theme/app_sizes.dart';
import 'package:uyku/core/theme/app_theme.dart';
import 'package:uyku/core/theme/sleep_stage_colors.dart';
import 'package:uyku/core/widgets/pressable.dart';

/// Tasarımdaki switch: açıkken sage-deep, kapalıyken `chipLine`.
class AppSwitch extends StatelessWidget {
  const AppSwitch({
    required this.value,
    required this.onChanged,
    required this.semanticLabel,
    super.key,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onPressed: () => onChanged(!value),
      semanticLabel: semanticLabel,
      toggled: value,
      excludeChildSemantics: true,
      child: SizedBox(
        width: AppSizes.switchHitWidth,
        height: AppSizes.touch,
        child: Center(
          child: AnimatedContainer(
            duration: AppMotion.toggle,
            width: AppSizes.switchWidth,
            height: AppSizes.switchHeight,
            padding: const EdgeInsets.all(
              (AppSizes.switchHeight - AppSizes.switchKnob) / 2,
            ),
            decoration: ShapeDecoration(
              color: value
                  ? SleepStageColors.sageDeep
                  : context.colors.chipLine,
              shape: const StadiumBorder(),
            ),
            child: AnimatedAlign(
              duration: AppMotion.toggle,
              curve: Curves.easeOut,
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: AppSizes.switchKnob,
                height: AppSizes.switchKnob,
                decoration: const BoxDecoration(
                  color: SleepStageColors.cream,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
