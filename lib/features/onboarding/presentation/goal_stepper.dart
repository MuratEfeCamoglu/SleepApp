import 'package:flutter/widgets.dart';
import 'package:uyku/core/strings/app_strings.dart';
import 'package:uyku/core/theme/app_sizes.dart';
import 'package:uyku/core/theme/app_spacing.dart';
import 'package:uyku/core/theme/app_theme.dart';
import 'package:uyku/core/widgets/app_icon.dart';
import 'package:uyku/core/widgets/circle_icon_button.dart';
import 'package:uyku/features/settings/domain/user_settings.dart';

/// Hedef süre: − büyük değer + (15 dk adım, 5–11 saat).
class GoalStepper extends StatelessWidget {
  const GoalStepper({
    required this.minutes,
    required this.onChanged,
    super.key,
  });

  final int minutes;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final colors = context.colors;
    final text = context.text;
    final unit = text.displayUnit.copyWith(color: colors.textSecondary);
    return Row(
      children: [
        CircleIconButton(
          icon: AppIcons.minus,
          size: AppSizes.iconButtonLarge,
          semanticLabel: strings.onboarding_goalMinus,
          onPressed: minutes > UserSettings.minGoal
              ? () => onChanged(minutes - UserSettings.goalStep)
              : null,
        ),
        Expanded(
          child: Semantics(
            liveRegion: true,
            label: strings.duration_hm(minutes ~/ 60, minutes % 60),
            excludeSemantics: true,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                child: Text.rich(
                  TextSpan(
                    style: text.displayNumber,
                    children: [
                      TextSpan(text: '${minutes ~/ 60}'),
                      TextSpan(text: '${strings.unit_hour} ', style: unit),
                      TextSpan(text: (minutes % 60).toString().padLeft(2, '0')),
                      TextSpan(text: strings.unit_minute, style: unit),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        CircleIconButton(
          icon: AppIcons.plus,
          size: AppSizes.iconButtonLarge,
          semanticLabel: strings.onboarding_goalPlus,
          onPressed: minutes < UserSettings.maxGoal
              ? () => onChanged(minutes + UserSettings.goalStep)
              : null,
        ),
      ],
    );
  }
}
