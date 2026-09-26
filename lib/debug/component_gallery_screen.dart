import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:uyku/core/strings/app_strings.dart';
import 'package:uyku/core/theme/app_colors.dart';
import 'package:uyku/core/theme/app_radius.dart';
import 'package:uyku/core/theme/app_sizes.dart';
import 'package:uyku/core/theme/app_spacing.dart';
import 'package:uyku/core/theme/app_theme.dart';
import 'package:uyku/core/theme/sleep_stage_colors.dart';
import 'package:uyku/core/widgets/app_icon.dart';
import 'package:uyku/core/widgets/app_switch.dart';
import 'package:uyku/core/widgets/choice_pill.dart';
import 'package:uyku/core/widgets/circle_icon_button.dart';
import 'package:uyku/core/widgets/delta_badge.dart';
import 'package:uyku/core/widgets/floating_center_action.dart';
import 'package:uyku/core/widgets/legend_dot.dart';
import 'package:uyku/core/widgets/primary_pill_button.dart';
import 'package:uyku/core/widgets/screen_header.dart';
import 'package:uyku/core/widgets/segmented_pill.dart';
import 'package:uyku/core/widgets/sleep_quality_fan_chart.dart';
import 'package:uyku/core/widgets/sleep_ring_chart.dart';
import 'package:uyku/core/widgets/stage_metric_tile.dart';
import 'package:uyku/core/widgets/state_views.dart';

/// `/debug/gallery` — imza bileşenleri açık/koyu temada gösterir.
/// Yalnızca geliştirici içindir; örnek değerler gerçek veri değildir.
class ComponentGalleryScreen extends StatefulWidget {
  const ComponentGalleryScreen({super.key});

  @override
  State<ComponentGalleryScreen> createState() => _ComponentGalleryScreenState();
}

class _ComponentGalleryScreenState extends State<ComponentGalleryScreen> {
  int _tab = 0;
  bool _dark = false;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final tabs = [
      strings.gallery_rings,
      strings.gallery_controls,
      strings.gallery_fan,
      strings.gallery_colors,
      strings.gallery_sizes,
    ];
    return Theme(
      data: _dark ? AppTheme.dark : AppTheme.light,
      child: Builder(
        builder: (context) => Scaffold(
          body: ListView(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.xl,
              MediaQuery.paddingOf(context).top + AppSpacing.sm,
              AppSpacing.xl,
              AppSpacing.xxl,
            ),
            children: [
              ScreenHeader(
                leading: CircleIconButton(
                  icon: AppIcons.back,
                  semanticLabel: strings.common_back,
                  onPressed: () => context.pop(),
                ),
                eyebrow: tabs[_tab],
                title: strings.gallery_title,
                trailing: AppSwitch(
                  value: _dark,
                  semanticLabel: strings.gallery_darkTheme,
                  onChanged: (v) => setState(() => _dark = v),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: 420,
                  child: SegmentedPill(
                    semanticLabel: strings.gallery_title,
                    labels: tabs,
                    selected: _tab,
                    onChanged: (i) => setState(() => _tab = i),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              switch (_tab) {
                0 => const GalleryRings(),
                1 => const GalleryControls(),
                2 => const GalleryFan(),
                3 => const GalleryColors(),
                _ => const GallerySizes(),
              },
            ],
          ),
        ),
      ),
    );
  }
}

class GalleryRings extends StatelessWidget {
  const GalleryRings({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final colors = context.colors;
    final text = context.text;
    return Column(
      children: [
        SleepRingChart(
          size: AppSizes.todayRing,
          semanticLabel: strings.gallery_rings,
          rings: [
            RingSegment(
              value: 0.96,
              color: colors.espressoSoft,
              badgeColor: colors.espressoDeep,
              icon: AppIcons.badgeMoon,
            ),
            const RingSegment(
              value: 0.86,
              color: SleepStageColors.sage,
              badgeColor: SleepStageColors.sageDeep,
              icon: AppIcons.badgeEye,
            ),
            const RingSegment(
              value: 0.76,
              color: SleepStageColors.ember,
              badgeColor: SleepStageColors.emberDeep,
              icon: AppIcons.badgeWave,
            ),
          ],
          center: Text(strings.duration_hm(7, 42), style: text.ringValue),
        ),
        const SizedBox(height: AppSpacing.xl),
        Row(
          children: [
            Expanded(
              child: StageMetricTile(
                label: strings.stage_rem,
                value: '1:54',
                unit: strings.unit_stage,
                color: SleepStageColors.sage,
              ),
            ),
            const SizedBox(width: AppSpacing.smPlus),
            Expanded(
              child: StageMetricTile(
                label: strings.stage_deep,
                value: '1:28',
                unit: strings.unit_stage,
                color: SleepStageColors.ember,
              ),
            ),
            const SizedBox(width: AppSpacing.smPlus),
            Expanded(
              child: StageMetricTile(
                label: strings.stage_light,
                value: '4:20',
                unit: strings.unit_stage,
                color: colors.espressoSoft,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class GalleryControls extends StatefulWidget {
  const GalleryControls({super.key});

  @override
  State<GalleryControls> createState() => _GalleryControlsState();
}

class _GalleryControlsState extends State<GalleryControls> {
  bool _switch = true;
  bool _chip = true;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PrimaryPillButton(
          label: strings.log_save,
          icon: AppIcons.arrowRight,
          onPressed: () {},
        ),
        const SizedBox(height: AppSpacing.md),
        PrimaryPillButton(label: strings.log_save, onPressed: null),
        const SizedBox(height: AppSpacing.md),
        HoldToConfirmButton(
          label: strings.track_wake,
          semanticLabel: strings.track_holdSemantic,
          onConfirmed: () {},
        ),
        const SizedBox(height: AppSpacing.lg),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            CircleIconButton(
              icon: AppIcons.back,
              semanticLabel: strings.common_back,
              onPressed: () {},
            ),
            CircleIconButton(
              icon: AppIcons.plus,
              variant: CircleIconButtonVariant.filled,
              semanticLabel: strings.log_startSleepMode,
              onPressed: () {},
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                color: context.colors.panel,
                borderRadius: AppRadius.lgAll,
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: FloatingCenterAction(
                  icon: AppIcons.moonNav,
                  semanticLabel: strings.nav_logSemantic,
                  onPressed: () {},
                ),
              ),
            ),
            AppSwitch(
              value: _switch,
              semanticLabel: strings.settings_reminder,
              onChanged: (v) => setState(() => _switch = v),
            ),
            ChoicePill(
              label: strings.log_factorCaffeine,
              selected: _chip,
              onPressed: () => setState(() => _chip = !_chip),
            ),
            DeltaBadge(
              label: strings.today_deltaWeek('+24 dk'),
              positive: true,
            ),
            DeltaBadge(
              label: strings.today_deltaWeek('−18 dk'),
              positive: false,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        SegmentedPill(
          semanticLabel: strings.trends_rangeLabel,
          labels: [
            strings.trends_week,
            strings.trends_month,
            strings.trends_year,
          ],
          selected: 0,
          onChanged: (_) {},
        ),
        const SizedBox(height: AppSpacing.lg),
        const SkeletonBlock(height: 64),
      ],
    );
  }
}

class GalleryFan extends StatefulWidget {
  const GalleryFan({super.key});

  @override
  State<GalleryFan> createState() => _GalleryFanState();
}

class _GalleryFanState extends State<GalleryFan> {
  int? _selected = 0;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final colors = context.colors;
    final slices = [
      (strings.quality_restorative, 11.0, SleepStageColors.sage),
      (strings.quality_good, 7.0, colors.espressoSlice),
      (strings.quality_fair, 6.0, SleepStageColors.honey),
      (strings.quality_fragmented, 4.0, SleepStageColors.ember),
      (strings.quality_sleepless, 2.0, SleepStageColors.lavender),
    ];
    return Column(
      children: [
        const SizedBox(height: AppSpacing.xxl),
        SleepQualityFanChart(
          semanticLabel: strings.gallery_fan,
          centerValue: strings.quality_percent(60),
          centerLabel: strings.quality_goodNights,
          selected: _selected,
          onSelect: (i) => setState(() => _selected = i),
          slices: [
            for (final s in slices)
              FanSlice(
                label: s.$1,
                value: s.$2,
                color: s.$3,
                tooltip: strings.quality_tooltip(
                  s.$1,
                  strings.quality_nights(s.$2.round()),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Wrap(
          spacing: 18,
          runSpacing: AppSpacing.smPlus,
          children: [
            for (final s in slices) LegendDot(label: s.$1, color: s.$3),
          ],
        ),
      ],
    );
  }
}

class GalleryColors extends StatelessWidget {
  const GalleryColors({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final swatches = <(String, Color)>[
      ('background', c.background),
      ('surface', c.surface),
      ('surfaceMuted', c.surfaceMuted),
      ('border', c.border),
      ('textPrimary', c.textPrimary),
      ('textSecondary', c.textSecondary),
      ('espresso', c.espresso),
      ('espressoSoft', c.espressoSoft),
      ('espressoDeep', c.espressoDeep),
      ('panel', c.panel),
      ('sageTint', c.sageTint),
      ('emberTint', c.emberTint),
      ('honeyTint', c.honeyTint),
      ('sage', SleepStageColors.sage),
      ('sageDeep', SleepStageColors.sageDeep),
      ('ember', SleepStageColors.ember),
      ('emberDeep', SleepStageColors.emberDeep),
      ('honey', SleepStageColors.honey),
      ('honeyDeep', SleepStageColors.honeyDeep),
      ('lavender', SleepStageColors.lavender),
      ('lavenderDeep', SleepStageColors.lavenderDeep),
    ];
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      children: [
        for (final (name, color) in swatches)
          SizedBox(
            width: 96,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: AppRadius.mdAll,
                    border: Border.all(color: c.border),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(name, style: context.text.caption),
              ],
            ),
          ),
      ],
    );
  }
}

class GallerySizes extends StatelessWidget {
  const GallerySizes({super.key});

  @override
  Widget build(BuildContext context) {
    final text = context.text;
    final colors = context.colors;
    final styles = <(String, TextStyle)>[
      ('displayClock', text.displayClock),
      ('displayNumber', text.displayNumber),
      ('titleLarge', text.titleLarge),
      ('clockValue', text.clockValue),
      ('ringValue', text.ringValue),
      ('metric', text.metric),
      ('titleMedium', text.titleMedium),
      ('button', text.button),
      ('cardTitle', text.cardTitle),
      ('bodyLarge', text.bodyLarge),
      ('bodyMedium', text.bodyMedium),
      ('bodySmall', text.bodySmall),
      ('caption', text.caption),
      ('navLabel', text.navLabel),
    ];
    const spacing = <(String, double)>[
      ('xs', AppSpacing.xs),
      ('sm', AppSpacing.sm),
      ('md', AppSpacing.md),
      ('lg', AppSpacing.lg),
      ('lgPlus', AppSpacing.lgPlus),
      ('xl', AppSpacing.xl),
      ('xxl', AppSpacing.xxl),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (name, style) in styles) ...[
          Text(name, style: text.caption.copyWith(color: colors.textSecondary)),
          FittedBox(child: Text('07:42 Uyku', style: style)),
          const SizedBox(height: AppSpacing.md),
        ],
        for (final (name, value) in spacing)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              children: [
                SizedBox(width: 64, child: Text(name, style: text.caption)),
                Container(
                  width: value * 4,
                  height: AppSpacing.md,
                  color: AppColors.light.espressoSoft,
                ),
              ],
            ),
          ),
      ],
    );
  }
}
