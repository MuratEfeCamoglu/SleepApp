import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uyku/core/router/app_router.dart';
import 'package:uyku/core/strings/app_strings.dart';
import 'package:uyku/core/theme/app_motion.dart';
import 'package:uyku/core/theme/app_radius.dart';
import 'package:uyku/core/theme/app_sizes.dart';
import 'package:uyku/core/theme/app_spacing.dart';
import 'package:uyku/core/theme/app_theme.dart';
import 'package:uyku/core/widgets/app_icon.dart';
import 'package:uyku/core/widgets/entrance.dart';
import 'package:uyku/core/widgets/primary_pill_button.dart';
import 'package:uyku/features/premium/presentation/premium_providers.dart';

/// Premium yüzeyleri sarar. Premium açıksa [child] olduğu gibi görünür.
/// Kapalıyken:
/// - [preview] yoksa [child] yerini korur ama `surfaceMuted` örtüyle
///   gizlenir (blur yok); örtüde kilit ikonu, açıklama ve "Premium ile aç".
/// - [preview] varsa önce kısıtlı içerik ([preview]), altında kilit kartı.
class PremiumGate extends ConsumerWidget {
  const PremiumGate({
    required this.child,
    this.preview,
    this.title,
    this.message,
    super.key,
  });

  final Widget child;

  /// Ücretsiz kullanıcıya gösterilecek kısıtlı içerik (ör. ilk sembol).
  final Widget? preview;

  /// Varsayılan `premium_gateTitle`.
  final String? title;

  /// Varsayılan `premium_gateBody`.
  final String? message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final premium = ref.watch(isPremiumProvider);
    // Premium açılınca (veya kapanınca) kilitli görünüm solarak içeriğe döner.
    return AnimatedSwitcher(
      duration: AppMotion.of(context, AppMotion.swap),
      switchInCurve: AppMotion.entranceCurve,
      switchOutCurve: Curves.easeIn,
      // passthrough: içerik, kapının dışındaki gibi tam genişlik alır.
      layoutBuilder: (current, previous) => Stack(
        fit: StackFit.passthrough,
        alignment: Alignment.topCenter,
        children: [...previous, ?current],
      ),
      child: KeyedSubtree(
        key: ValueKey(premium),
        child: premium ? child : _locked(context),
      ),
    );
  }

  Widget _locked(BuildContext context) {
    final lock = PremiumLockCard(title: title, message: message);
    if (preview != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          preview!,
          const SizedBox(height: AppSpacing.smPlus),
          lock,
        ],
      );
    }
    return Stack(
      alignment: Alignment.center,
      children: [
        // Yer tutucu: boyutu korur, çizilmez, dokunulmaz, okunmaz.
        Visibility(
          visible: false,
          maintainSize: true,
          maintainAnimation: true,
          maintainState: true,
          child: child,
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: context.colors.surfaceMuted,
              borderRadius: AppRadius.lgAll,
            ),
          ),
        ),
        lock,
      ],
    );
  }
}

/// Kilit kartı: `surfaceMuted` zemin, kilit ikonu, kısa açıklama ve
/// `/premium`'a giden buton. [PremiumGate] kilitliyken bunu gösterir.
class PremiumLockCard extends StatelessWidget {
  const PremiumLockCard({this.title, this.message, super.key});

  final String? title;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final colors = context.colors;
    final text = context.text;
    // İlk görünüşte yumuşakça solar.
    return Entrance(
      offset: 0,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.lgPlus),
        decoration: BoxDecoration(
          color: colors.surfaceMuted,
          borderRadius: AppRadius.lgAll,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: AppSizes.tipIcon,
              height: AppSizes.tipIcon,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colors.honeyTint,
                shape: BoxShape.circle,
              ),
              child: AppIcon(AppIcons.lock, color: colors.honeyText),
            ),
            const SizedBox(height: AppSpacing.md),
            MergeSemantics(
              child: Column(
                children: [
                  Text(
                    title ?? strings.premium_gateTitle,
                    textAlign: TextAlign.center,
                    style: text.cardTitle,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    message ?? strings.premium_gateBody,
                    textAlign: TextAlign.center,
                    style: text.bodySmall.copyWith(color: colors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            PrimaryPillButton(
              label: strings.premium_unlock,
              icon: AppIcons.arrowRight,
              onPressed: () => context.push(AppRoutes.premium),
            ),
          ],
        ),
      ),
    );
  }
}
