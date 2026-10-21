import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uyku/core/router/app_router.dart';
import 'package:uyku/core/strings/app_strings.dart';
import 'package:uyku/core/theme/app_radius.dart';
import 'package:uyku/core/theme/app_sizes.dart';
import 'package:uyku/core/theme/app_spacing.dart';
import 'package:uyku/core/theme/app_theme.dart';
import 'package:uyku/core/widgets/app_icon.dart';
import 'package:uyku/core/widgets/choice_pill.dart';
import 'package:uyku/core/widgets/motion.dart';
import 'package:uyku/core/widgets/pressable.dart';
import 'package:uyku/core/widgets/primary_pill_button.dart';
import 'package:uyku/core/widgets/screen_header.dart';
import 'package:uyku/core/widgets/state_views.dart';
import 'package:uyku/features/dreams/domain/dream_journal.dart';
import 'package:uyku/features/dreams/presentation/dream_insights_card.dart';
import 'package:uyku/features/dreams/presentation/dream_ui.dart';
import 'package:uyku/features/sleep_log/domain/sleep_entry.dart';
import 'package:uyku/features/sleep_log/presentation/sleep_log_providers.dart';
import 'package:uyku/features/sleep_summary/presentation/app_shell.dart';

/// `/dreams` sekmesi — üstte "Rüyanı yorumla" girişi, Premium içgörü kartı,
/// altında rüya notu olan geceler yeniden eskiye; arama + tür filtresi.
class DreamsScreen extends ConsumerStatefulWidget {
  const DreamsScreen({super.key});

  @override
  ConsumerState<DreamsScreen> createState() => _DreamsScreenState();
}

class _DreamsScreenState extends ConsumerState<DreamsScreen> {
  final _search = TextEditingController();
  String _query = '';
  DreamKind? _kind;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final entries = ref.watch(sleepLogProvider);

    // Sekme sayfası: üstte başlık ve her durumda "Rüyanı yorumla" girişi.
    TabPage page(List<Widget> children) => TabPage(
      children: [
        ScreenHeader(
          eyebrow: strings.dreams_eyebrow,
          title: strings.dreams_title,
        ),
        const DreamInterpretCard(),
        ...children,
      ],
    );

    return entries.when(
      loading: () => page(const [
        SkeletonBlock(height: AppSizes.skeletonCard),
        SkeletonBlock(),
        SkeletonBlock(height: AppSizes.skeletonRow),
        SkeletonBlock(height: AppSizes.skeletonRow),
      ]),
      error: (_, _) => page([
        ErrorState(onRetry: () => ref.read(sleepLogProvider.notifier).retry()),
      ]),
      data: (list) {
        if (dreamJournal(list).isEmpty) {
          return page([
            EmptyState(
              icon: AppIcons.pen,
              title: strings.dreams_emptyTitle,
              body: strings.dreams_emptyBody,
              actionLabel: strings.dreams_emptyAction,
              onAction: () => context.go(AppRoutes.log),
            ),
          ]);
        }
        final visible = dreamJournal(list, query: _query, kind: _kind);
        return page([
          const DreamInsightsCard(),
          _SearchField(
            controller: _search,
            onChanged: (v) => setState(() => _query = v),
          ),
          _KindFilter(
            selected: _kind,
            onSelected: (k) => setState(() => _kind = k),
          ),
          Text(
            strings.dreams_count(visible.length),
            style: context.text.caption.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
          if (visible.isEmpty)
            EmptyState(
              icon: AppIcons.pen,
              title: strings.dreams_noResultsTitle,
              body: strings.dreams_noResultsBody,
            ),
          for (final e in visible) _DreamRow(entry: e),
        ]);
      },
    );
  }
}

/// Kaydet ekranındaki rüya notu alanıyla aynı görünüm.
class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final colors = context.colors;
    final text = context.text;
    return Semantics(
      textField: true,
      label: strings.dreams_searchLabel,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: AppRadius.lgAll,
        ),
        child: TextField(
          controller: controller,
          textInputAction: TextInputAction.search,
          style: text.bodyMedium,
          cursorColor: colors.espresso,
          decoration: InputDecoration.collapsed(
            hintText: strings.dreams_searchHint,
            hintStyle: text.bodyMedium.copyWith(color: colors.textSecondary),
          ),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _KindFilter extends StatelessWidget {
  const _KindFilter({required this.selected, required this.onSelected});

  final DreamKind? selected;
  final ValueChanged<DreamKind?> onSelected;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Semantics(
      container: true,
      label: strings.dreams_filterLabel,
      explicitChildNodes: true,
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          ChoicePill(
            label: strings.dreams_filterAll,
            selected: selected == null,
            onPressed: () => onSelected(null),
          ),
          for (final k in DreamKind.values)
            ChoicePill(
              label: k.label(strings),
              selected: selected == k,
              onPressed: () => onSelected(k),
            ),
        ],
      ),
    );
  }
}

class _DreamRow extends StatelessWidget {
  const _DreamRow({required this.entry});

  final SleepEntry entry;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final colors = context.colors;
    final text = context.text;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final date = DateFormat('d MMMM y, EEEE', locale).format(entry.night);
    final kind = entry.dreamKind;
    return Pressable(
      onPressed: () => context.push(AppRoutes.dreamNight(entry.id)),
      semanticLabel: [
        date,
        if (kind != null) kind.label(strings),
        entry.note.trim(),
      ].join(', '),
      excludeChildSemantics: true,
      child: SurfaceCard(
        radius: AppRadius.lgAll,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.xs,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(date, style: text.cardTitle),
                      if (kind != null) DreamTag.kind(kind),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    entry.note.trim(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodySmall.copyWith(color: colors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            AppIcon(AppIcons.chevronRight, color: colors.textSecondary),
          ],
        ),
      ),
    );
  }
}

/// Sekmenin en üstündeki belirgin giriş: honey ikon dairesi, kısa açıklama
/// ve `/dreams/interpret`'e giden buton.
class DreamInterpretCard extends StatelessWidget {
  const DreamInterpretCard({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final colors = context.colors;
    final text = context.text;
    return SurfaceCard(
      radius: AppRadius.lgPlusAll,
      padding: const EdgeInsets.all(AppSpacing.lgPlus),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MergeSemantics(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: AppSizes.tipIcon,
                  height: AppSizes.tipIcon,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: colors.honeyTint,
                    shape: BoxShape.circle,
                  ),
                  // Ay/bulut ikonu çok yavaş nefes alır (AppMotion.ambient).
                  child: AmbientBreath(
                    child: AppIcon(AppIcons.dream, color: colors.honeyText),
                  ),
                ),
                const SizedBox(width: AppSpacing.mdPlus),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Semantics(
                        header: true,
                        child: Text(
                          strings.dreamsInterview_cardTitle,
                          style: text.cardTitle,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        strings.dreamsInterview_cardBody,
                        style: text.bodySmall.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          PrimaryPillButton(
            label: strings.dreamsInterview_cardCta,
            icon: AppIcons.arrowRight,
            onPressed: () => context.push(AppRoutes.dreamInterpret),
          ),
        ],
      ),
    );
  }
}
