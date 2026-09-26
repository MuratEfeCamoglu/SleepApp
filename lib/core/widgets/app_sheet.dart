import 'package:flutter/material.dart';
import 'package:uyku/core/strings/app_strings.dart';
import 'package:uyku/core/theme/app_radius.dart';
import 'package:uyku/core/theme/app_sizes.dart';
import 'package:uyku/core/theme/app_spacing.dart';
import 'package:uyku/core/theme/app_theme.dart';
import 'package:uyku/core/widgets/primary_pill_button.dart';
import 'package:uyku/core/widgets/state_views.dart';

/// Düz, gölgesiz alt sayfa.
Future<T?> showAppSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) {
  final colors = context.colors;
  return showModalBottomSheet<T>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: colors.background,
    barrierColor: colors.espresso.withValues(alpha: 0.32),
    elevation: 0,
    shape: const RoundedRectangleBorder(borderRadius: AppRadius.xlTop),
    builder: (context) => AppSheetFrame(child: builder(context)),
  );
}

class AppSheetFrame extends StatelessWidget {
  const AppSheetFrame({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.md,
          AppSpacing.xl,
          AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: AppSizes.sheetHandleWidth,
                height: AppSizes.sheetHandleHeight,
                decoration: ShapeDecoration(
                  color: context.colors.border,
                  shape: const StadiumBorder(),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            child,
          ],
        ),
      ),
    );
  }
}

/// Onay sayfası; onaylanırsa true döner.
Future<bool> confirmSheet(
  BuildContext context, {
  required String title,
  required String body,
  required String confirmLabel,
}) async {
  final result = await showAppSheet<bool>(
    context,
    builder: (context) {
      final colors = context.colors;
      final text = context.text;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: text.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Text(
            body,
            style: text.bodyMedium.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xl),
          PrimaryPillButton(
            label: confirmLabel,
            onPressed: () => Navigator.of(context).pop(true),
          ),
          const SizedBox(height: AppSpacing.md),
          OutlinePillButton(
            label: AppStrings.of(context).common_cancel,
            onPressed: () => Navigator.of(context).pop(false),
          ),
        ],
      );
    },
  );
  return result ?? false;
}

/// Kısa bilgi mesajı (espresso pill).
void showAppToast(BuildContext context, String message) {
  final colors = context.colors;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: context.text.bodyMedium.copyWith(color: colors.onEspresso),
        ),
        backgroundColor: colors.espresso,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        shape: const StadiumBorder(),
        margin: const EdgeInsets.all(AppSpacing.xl),
      ),
    );
}
