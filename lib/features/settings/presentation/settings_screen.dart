import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uyku/core/router/app_router.dart';
import 'package:uyku/core/strings/app_strings.dart';
import 'package:uyku/core/theme/app_motion.dart';
import 'package:uyku/core/theme/app_sizes.dart';
import 'package:uyku/core/theme/app_spacing.dart';
import 'package:uyku/core/theme/app_theme.dart';
import 'package:uyku/core/theme/sleep_stage_colors.dart';
import 'package:uyku/core/utils/formatters.dart';
import 'package:uyku/core/widgets/app_icon.dart';
import 'package:uyku/core/widgets/app_sheet.dart';
import 'package:uyku/core/widgets/app_switch.dart';
import 'package:uyku/core/widgets/circle_icon_button.dart';
import 'package:uyku/core/widgets/screen_header.dart';
import 'package:uyku/core/widgets/segmented_pill.dart';
import 'package:uyku/core/widgets/settings_group.dart';
import 'package:uyku/features/chronotype/presentation/chronotype_screen.dart';
import 'package:uyku/features/routine/presentation/routine_providers.dart';
import 'package:uyku/features/settings/domain/user_settings.dart';
import 'package:uyku/features/settings/presentation/goals_screen.dart';
import 'package:uyku/features/settings/presentation/settings_controller.dart';
import 'package:uyku/features/sleep_log/presentation/sleep_log_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const version = '1.0.0';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    final colors = context.colors;
    final text = context.text;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final s = ref.watch(settingsControllerProvider);
    final controller = ref.read(settingsControllerProvider.notifier);

    String themeLabel(ThemePreference t) => switch (t) {
      ThemePreference.system => strings.settings_themeSystem,
      ThemePreference.light => strings.settings_themeLight,
      ThemePreference.dark => strings.settings_themeDark,
    };

    return Scaffold(
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.xl,
          MediaQuery.paddingOf(context).top + AppSpacing.sm,
          AppSpacing.xl,
          MediaQuery.paddingOf(context).bottom + AppSpacing.xxl,
        ),
        children: [
          ScreenHeader(
            leading: CircleIconButton(
              icon: AppIcons.back,
              semanticLabel: strings.common_back,
              onPressed: () => context.canPop()
                  ? context.pop()
                  : context.go(AppRoutes.today),
            ),
            eyebrow: strings.appTitle,
            title: strings.settings_title,
          ),
          const SizedBox(height: AppSpacing.xl),
          SettingsGroup(
            title: strings.settings_groupSleep,
            children: [
              SettingsRow(
                icon: AppIcons.target,
                iconColor: SleepStageColors.sageDeep,
                label: strings.settings_goal,
                value: formatGoal(strings, locale, s.goalMinutes),
                onPressed: () => context.push(AppRoutes.goals),
              ),
              SettingsRow(
                icon: AppIcons.moon,
                iconColor: SleepStageColors.lavenderDeep,
                label: strings.settings_bedtime,
                value: formatClock(s.bedtimeMinute),
                onPressed: () => context.push(AppRoutes.goals),
              ),
              SettingsRow(
                icon: AppIcons.sun,
                iconColor: SleepStageColors.honeyDeep,
                label: strings.settings_wake,
                value: formatClock(s.wakeMinute),
                onPressed: () => context.push(AppRoutes.goals),
              ),
              SettingsRow(
                icon: AppIcons.clock,
                iconColor: SleepStageColors.emberDeep,
                label: strings.goals_weekend,
                value: weekendShiftLabel(strings, locale, s.weekendShift),
                onPressed: () => context.push(AppRoutes.goals),
              ),
              SettingsRow(
                icon: AppIcons.bell,
                iconColor: SleepStageColors.honeyDeep,
                label: strings.smart_title,
                trailing: AppSwitch(
                  value: s.smartAlarm,
                  semanticLabel: strings.smart_title,
                  onChanged: (v) => controller.setSmartAlarm(enabled: v),
                ),
              ),
              SettingsRow(
                icon: AppIcons.sparkle,
                iconColor: SleepStageColors.lavenderDeep,
                label: strings.chrono_settingsRow,
                value: s.chronotype?.label(strings) ?? strings.chrono_notTaken,
                onPressed: () => context.push(AppRoutes.chronotype),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          SettingsGroup(
            title: strings.settings_groupApp,
            children: [
              SettingsRow(
                icon: AppIcons.bell,
                iconColor: SleepStageColors.emberDeep,
                label: strings.settings_reminder,
                trailing: AppSwitch(
                  value: s.reminderEnabled,
                  semanticLabel: strings.settings_reminder,
                  onChanged: (v) async {
                    await controller.setReminder(enabled: v);
                    ref.invalidate(notificationPermissionProvider);
                  },
                ),
              ),
              SettingsRow(
                icon: AppIcons.bars,
                iconColor: SleepStageColors.sageDeep,
                label: strings.report_setting,
                trailing: AppSwitch(
                  value: s.weeklyReport,
                  semanticLabel: strings.report_setting,
                  onChanged: (v) => controller.setWeeklyReport(enabled: v),
                ),
              ),
              SettingsRow(
                icon: AppIcons.sun,
                iconColor: colors.espressoDeep,
                label: strings.settings_theme,
                value: themeLabel(s.theme),
                onPressed: () => _pick<ThemePreference>(
                  context,
                  title: strings.settings_theme,
                  options: ThemePreference.values,
                  current: s.theme,
                  label: themeLabel,
                  onSelected: controller.setTheme,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          SettingsGroup(
            title: strings.settings_groupData,
            children: [
              SettingsRow(
                icon: AppIcons.trash,
                iconColor: SleepStageColors.emberDeep,
                label: strings.settings_clear,
                onPressed: () async {
                  final ok = await confirmSheet(
                    context,
                    title: strings.settings_clearTitle,
                    body: strings.settings_clearBody,
                    confirmLabel: strings.settings_clearConfirm,
                  );
                  if (!ok) return;
                  await ref.read(sleepLogProvider.notifier).clearAll();
                  await ref.read(routineRepositoryProvider).clear();
                  ref.invalidate(routineProgressProvider);
                },
              ),
              if (kDebugMode)
                SettingsRow(
                  icon: AppIcons.grid,
                  iconColor: SleepStageColors.lavenderDeep,
                  label: strings.settings_gallery,
                  onPressed: () => context.push(AppRoutes.gallery),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            strings.settings_estimateNote,
            textAlign: TextAlign.center,
            style: text.caption.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            strings.settings_version(version),
            textAlign: TextAlign.center,
            style: text.caption.copyWith(color: colors.textSecondary),
          ),
        ],
      ),
    );
  }

  Future<void> _pick<T>(
    BuildContext context, {
    required String title,
    required List<T> options,
    required T current,
    required String Function(T) label,
    required Future<void> Function(T) onSelected,
  }) {
    return showAppSheet<void>(
      context,
      builder: (context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: context.text.titleMedium),
          const SizedBox(height: AppSpacing.lg),
          SegmentedPill(
            semanticLabel: title,
            labels: [for (final o in options) label(o)],
            selected: options.indexOf(current),
            onChanged: (i) async {
              await onSelected(options[i]);
              if (context.mounted) Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}

/// 15 dakika aralıklı saat seçici. Seçili satır espresso bandın üstünde
/// krem ve kalın, diğer satırlar soluk; seçim renge bakmadan da okunur.
class BedtimePicker extends StatefulWidget {
  const BedtimePicker({
    required this.minute,
    required this.onChanged,
    super.key,
  });

  final int minute;
  final ValueChanged<int> onChanged;

  static const interval = 15;

  @override
  State<BedtimePicker> createState() => _BedtimePickerState();
}

class _BedtimePickerState extends State<BedtimePicker> {
  static const int _minuteSlots = 60 ~/ BedtimePicker.interval;

  late int _hour;
  late int _slot;
  bool _syncing = false;
  late final FixedExtentScrollController _hours;
  late final FixedExtentScrollController _minutes;

  @override
  void initState() {
    super.initState();
    final rounded =
        wrapMinute(widget.minute) ~/
        BedtimePicker.interval *
        BedtimePicker.interval;
    _hour = rounded ~/ 60;
    _slot = rounded % 60 ~/ BedtimePicker.interval;
    _hours = FixedExtentScrollController(initialItem: _hour);
    _minutes = FixedExtentScrollController(initialItem: _slot);
  }

  @override
  void didUpdateWidget(BedtimePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    final rounded =
        wrapMinute(widget.minute) ~/
        BedtimePicker.interval *
        BedtimePicker.interval;
    final hour = rounded ~/ 60;
    final slot = rounded % 60 ~/ BedtimePicker.interval;
    if (hour == _hour && slot == _slot) return;
    // Dışarıdan gelen değer (ör. kronotip önerisi): tekerleri oraya çevir.
    // Atlama seçim geri çağrısını tetikler; build bittikten sonra yap ve
    // değeri üst widget'a geri bildirme.
    _hour = hour;
    _slot = slot;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _syncing = true;
      _hours.jumpToItem(hour);
      _minutes.jumpToItem(slot);
      _syncing = false;
    });
  }

  @override
  void dispose() {
    _hours.dispose();
    _minutes.dispose();
    super.dispose();
  }

  void _emit() {
    if (_syncing) return;
    widget.onChanged(_hour * 60 + _slot * BedtimePicker.interval);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final style = context.text.clockValue;
    final selected = style.copyWith(color: colors.onEspresso);
    final idle = style.copyWith(
      color: colors.textSecondary,
      fontWeight: FontWeight.w700,
    );

    Widget column({
      required FixedExtentScrollController controller,
      required int count,
      required int current,
      required String Function(int) label,
      required ValueChanged<int> onSelected,
    }) => SizedBox(
      width: AppSizes.pickerColumn,
      child: CupertinoPicker(
        scrollController: controller,
        itemExtent: AppSizes.pickerRow,
        looping: true,
        selectionOverlay: null,
        onSelectedItemChanged: onSelected,
        children: [
          for (var i = 0; i < count; i++)
            Center(
              child: AnimatedDefaultTextStyle(
                duration: AppMotion.toggle,
                style: i == current ? selected : idle,
                child: Text(label(i)),
              ),
            ),
        ],
      ),
    );

    return Semantics(
      label: AppStrings.of(context).settings_bedtime,
      value: formatClock(_hour * 60 + _slot * BedtimePicker.interval),
      child: SizedBox(
        height: AppSizes.pickerHeight,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: AppSizes.pickerBandWidth,
              height: AppSizes.pickerRow,
              decoration: ShapeDecoration(
                color: colors.espresso,
                shape: const StadiumBorder(),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                column(
                  controller: _hours,
                  count: 24,
                  current: _hour,
                  label: (i) => i.toString().padLeft(2, '0'),
                  onSelected: (i) {
                    setState(() => _hour = i);
                    _emit();
                  },
                ),
                ExcludeSemantics(
                  child: Text(
                    AppStrings.of(context).time_separator,
                    style: selected,
                  ),
                ),
                column(
                  controller: _minutes,
                  count: _minuteSlots,
                  current: _slot,
                  label: (i) =>
                      (i * BedtimePicker.interval).toString().padLeft(2, '0'),
                  onSelected: (i) {
                    setState(() => _slot = i);
                    _emit();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
