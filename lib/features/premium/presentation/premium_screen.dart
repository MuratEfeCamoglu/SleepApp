import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uyku/core/strings/app_strings.dart';
import 'package:uyku/core/theme/app_radius.dart';
import 'package:uyku/core/theme/app_sizes.dart';
import 'package:uyku/core/theme/app_spacing.dart';
import 'package:uyku/core/theme/app_theme.dart';
import 'package:uyku/core/theme/sleep_stage_colors.dart';
import 'package:uyku/core/widgets/app_icon.dart';
import 'package:uyku/core/widgets/full_page.dart';
import 'package:uyku/core/widgets/motion.dart';
import 'package:uyku/core/widgets/primary_pill_button.dart';
import 'package:uyku/core/widgets/screen_header.dart';
import 'package:uyku/features/premium/domain/premium_status.dart';
import 'package:uyku/features/premium/presentation/premium_providers.dart';

/// `/premium` — tanıtım ekranı. Mağaza bağlanana kadar fiyat yerine açık
/// placeholder gösterilir; satın alma yalnızca debug'da yerel kilidi açar.
class PremiumScreen extends ConsumerStatefulWidget {
  const PremiumScreen({super.key});

  @override
  ConsumerState<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends ConsumerState<PremiumScreen> {
  /// Premium bu ekrandayken açıldıysa "Premium aktif" rozeti bir kez kutlar.
  bool _celebrate = false;

  @override
  Widget build(BuildContext context) {
    ref.listen(premiumProvider, (prev, next) {
      if (!(prev?.active ?? false) && next.active) {
        setState(() => _celebrate = true);
      } else if (!next.active) {
        _celebrate = false;
      }
    });
    final strings = AppStrings.of(context);
    final colors = context.colors;
    final text = context.text;
    final status = ref.watch(premiumProvider);
    final controller = ref.read(premiumProvider.notifier);

    final Widget? bottom;
    if (kDebugMode) {
      bottom = status.active
          ? PrimaryPillButton(
              label: strings.premium_disableDebug,
              onPressed: controller.deactivate,
            )
          : PrimaryPillButton(
              label: strings.premium_tryDebug,
              icon: AppIcons.arrowRight,
              onPressed: controller.activateDebug,
            );
    } else {
      bottom = status.active
          ? null
          : PrimaryPillButton(
              label: strings.premium_comingSoon,
              onPressed: null,
            );
    }

    return FullPage(
      eyebrow: strings.appTitle,
      title: strings.premium_title,
      bottom: bottom,
      children: [
        const IconBadge(
          icon: AppIcons.sparkle,
          background: SleepStageColors.honeyDeep,
          foreground: SleepStageColors.creamIcon,
        ),
        Text(
          strings.premium_lead,
          textAlign: TextAlign.center,
          style: text.bodyLarge.copyWith(color: colors.textSecondary),
        ),
        if (status.active) _ActiveCard(status: status, celebrate: _celebrate),
        const _CompareCard(),
        SurfaceCard(
          radius: AppRadius.lgAll,
          child: MergeSemantics(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(strings.premium_priceTitle, style: text.cardTitle),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  strings.premium_pricePlaceholder,
                  style: text.bodySmall.copyWith(color: colors.textSecondary),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ActiveCard extends StatelessWidget {
  const _ActiveCard({required this.status, required this.celebrate});

  final PremiumStatus status;
  final bool celebrate;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final colors = context.colors;
    final text = context.text;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final since = status.since;
    return MergeSemantics(
      child: SurfaceCard(
        radius: AppRadius.lgAll,
        child: Row(
          children: [
            CelebrateBounce(
              play: celebrate,
              child: Container(
                width: AppSizes.tipIcon,
                height: AppSizes.tipIcon,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.sageTint,
                  shape: BoxShape.circle,
                ),
                child: AppIcon(AppIcons.checkBold, color: colors.sageText),
              ),
            ),
            const SizedBox(width: AppSpacing.mdPlus),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(strings.premium_active, style: text.cardTitle),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    since == null
                        ? strings.premium_activeBody
                        : strings.premium_activeSince(
                            DateFormat('d MMMM y', locale).format(since),
                          ),
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

/// Ücretsiz ve Premium karşılaştırması; işaretler konumla da okunur.
class _CompareCard extends StatelessWidget {
  const _CompareCard();

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final colors = context.colors;
    final text = context.text;
    final rows = [
      (strings.premium_rowTracking, true),
      (strings.premium_rowRoutine, true),
      (strings.premium_rowHealthFree, true),
      (strings.premium_rowHealth, false),
      (strings.premium_rowDreamsFree, true),
      (strings.premium_rowDreamInterviewFree, true),
      (strings.premium_rowDreamReading, false),
      (strings.premium_rowDreamInterviewDeep, false),
      (strings.premium_rowDreamInsights, false),
      (strings.premium_rowExport, false),
    ];
    final columnLabel = text.tileLabel.copyWith(color: colors.textSecondary);

    Widget cell(Widget child) => SizedBox(
      width: AppSizes.compareColumn,
      child: Center(child: child),
    );

    Widget mark({required bool included}) => cell(
      included
          ? AppIcon(AppIcons.checkBold, color: colors.sageText)
          : AppIcon(AppIcons.minus, color: colors.textSecondary),
    );

    // Satır listesi: grup kartı (xl).
    return SurfaceCard(
      radius: AppRadius.xlAll,
      padding: const EdgeInsets.all(AppSpacing.lgPlus),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    strings.premium_compareTitle,
                    style: text.cardTitle,
                  ),
                ),
              ),
              // Kolon adları satır etiketlerinde zaten okunur.
              for (final label in [
                strings.premium_colFree,
                strings.premium_colPremium,
              ])
                ExcludeSemantics(
                  child: cell(
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(label, style: columnLabel),
                    ),
                  ),
                ),
            ],
          ),
          for (final (label, free) in rows) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Container(height: AppSizes.divider, color: colors.border),
            ),
            Semantics(
              label: strings.premium_rowSemantic(label, free: free),
              excludeSemantics: true,
              child: Row(
                children: [
                  Expanded(child: Text(label, style: text.bodyMedium)),
                  mark(included: free),
                  mark(included: true),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
