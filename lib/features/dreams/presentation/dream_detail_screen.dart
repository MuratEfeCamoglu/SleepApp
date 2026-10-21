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
import 'package:uyku/core/widgets/entrance.dart';
import 'package:uyku/core/widgets/full_page.dart';
import 'package:uyku/core/widgets/primary_pill_button.dart';
import 'package:uyku/core/widgets/screen_header.dart';
import 'package:uyku/core/widgets/state_views.dart';
import 'package:uyku/features/dreams/domain/dream_journal.dart';
import 'package:uyku/features/dreams/domain/dream_reading.dart';
import 'package:uyku/features/dreams/domain/dream_symbols.dart';
import 'package:uyku/features/dreams/presentation/dream_ui.dart';
import 'package:uyku/features/premium/presentation/premium_gate.dart';
import 'package:uyku/features/sleep_log/domain/sleep_entry.dart';
import 'package:uyku/features/sleep_log/presentation/sleep_log_providers.dart';

/// `/dreams/:night` — notun tamamı ve yorumu. Ücretsizde ilk sembol açık;
/// kalan semboller ve genel tema Premium. Uyarı metni her durumda görünür.
class DreamDetailScreen extends ConsumerWidget {
  const DreamDetailScreen({required this.night, super.key});

  /// `2026-09-24`
  final String night;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final parsed = DateTime.tryParse(night);
    final eyebrow = parsed == null
        ? strings.dreams_title
        : strings.dreams_nightOf(
            DateFormat('d MMMM y, EEEE', locale).format(parsed),
          );
    final entries = ref.watch(sleepLogProvider);

    FullPage page(List<Widget> children) => FullPage(
      eyebrow: eyebrow,
      title: strings.dreams_detailTitle,
      children: children,
    );

    return entries.when(
      loading: () => page(const [
        SkeletonBlock(height: AppSizes.skeletonMedium),
        SkeletonBlock(height: AppSizes.skeletonCard),
      ]),
      error: (_, _) => page([
        ErrorState(onRetry: () => ref.read(sleepLogProvider.notifier).retry()),
      ]),
      data: (list) {
        SleepEntry? entry;
        for (final e in list) {
          if (e.id == night) entry = e;
        }
        if (entry == null || !entry.hasDreamNote) {
          final hasEntry = entry != null;
          return page([
            EmptyState(
              icon: AppIcons.pen,
              title: strings.dreams_missingTitle,
              body: strings.dreams_missingBody,
              actionLabel: hasEntry
                  ? strings.dreams_editNote
                  : strings.dreams_openJournal,
              onAction: () => hasEntry
                  ? context.go(AppRoutes.logNight(night))
                  : context.go(AppRoutes.dreams),
            ),
          ]);
        }
        final reading = readDream(entry);
        return page([
          if (entry.dreamKind != null || entry.dreamEmotions.isNotEmpty)
            DreamTags(entry: entry),
          _NoteCard(note: entry.note.trim()),
          _SectionLabel(strings.dreams_readingTitle),
          ..._reading(strings, reading),
          if (reading.suggestion != null)
            _SuggestionCard(text: reading.suggestion!),
          Text(
            strings.dreams_disclaimer,
            textAlign: TextAlign.center,
            style: context.text.caption.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
          PrimaryPillButton(
            label: strings.dreamsInterview_detailCta,
            icon: AppIcons.arrowRight,
            onPressed: () => context.push(AppRoutes.dreamInterpretNight(night)),
          ),
          Center(
            child: OutlinePillButton(
              label: strings.dreams_editNote,
              onPressed: () => context.go(AppRoutes.logNight(night)),
            ),
          ),
        ]);
      },
    );
  }

  List<Widget> _reading(AppStrings strings, DreamReading reading) {
    final theme = _ThemeCard(theme: reading.theme);
    if (!reading.hasSymbols) {
      return [
        _InfoCard(text: strings.dreams_noSymbols),
        PremiumGate(
          title: strings.dreams_readingLockTitle,
          message: strings.dreams_readingLockBody(0),
          child: theme,
        ),
      ];
    }
    final symbols = reading.symbols;
    return [
      PremiumGate(
        title: strings.dreams_readingLockTitle,
        message: strings.dreams_readingLockBody(symbols.length - 1),
        preview: _SymbolCard(symbol: symbols.first),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Semboller sırayla belirir.
            for (var i = 0; i < symbols.length; i++) ...[
              Entrance(
                index: i,
                child: _SymbolCard(symbol: symbols[i]),
              ),
              const SizedBox(height: AppSpacing.smPlus),
            ],
            theme,
          ],
        ),
      ),
    ];
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Text(
        label.toUpperCase(),
        style: context.text.label.copyWith(color: context.colors.textSecondary),
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({required this.note});

  final String note;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final colors = context.colors;
    final text = context.text;
    return SurfaceCard(
      radius: AppRadius.lgPlusAll,
      padding: const EdgeInsets.all(AppSpacing.lgPlus),
      child: MergeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                AppIcon(
                  AppIcons.pen,
                  color: colors.textSecondary,
                  size: AppSizes.iconSmall,
                ),
                const SizedBox(width: AppSpacing.xsPlus),
                Text(strings.dreams_noteTitle, style: text.cardTitle),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(note, style: text.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _SymbolCard extends StatelessWidget {
  const _SymbolCard({required this.symbol});

  final DreamSymbol symbol;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.text;
    return MergeSemantics(
      child: SurfaceCard(
        radius: AppRadius.lgAll,
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
              child: AppIcon(AppIcons.sparkle, color: colors.honeyText),
            ),
            const SizedBox(width: AppSpacing.mdPlus),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(symbol.title, style: text.cardTitle),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    symbol.meaning,
                    style: text.bodySmall.copyWith(color: colors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeCard extends StatelessWidget {
  const _ThemeCard({required this.theme});

  final String? theme;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final colors = context.colors;
    final text = context.text;
    return MergeSemantics(
      child: SurfaceCard(
        radius: AppRadius.lgAll,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(strings.dreams_themeTitle, style: text.cardTitle),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              theme ?? strings.dreams_noTheme,
              style: text.bodySmall.copyWith(
                color: theme == null ? colors.textSecondary : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      radius: AppRadius.lgAll,
      child: Text(
        text,
        style: context.text.bodySmall.copyWith(
          color: context.colors.textSecondary,
        ),
      ),
    );
  }
}

/// Kabus sonrası sakinleştirici öneri; güvenlik bilgisi olduğu için ücretsiz.
class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final colors = context.colors;
    final styles = context.text;
    return MergeSemantics(
      child: SurfaceCard(
        radius: AppRadius.lgAll,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: AppSizes.tipIcon,
              height: AppSizes.tipIcon,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colors.sageTint,
                shape: BoxShape.circle,
              ),
              child: AppIcon(AppIcons.breath, color: colors.sageText),
            ),
            const SizedBox(width: AppSpacing.mdPlus),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(strings.dreams_suggestionTitle, style: styles.cardTitle),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(text, style: styles.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
