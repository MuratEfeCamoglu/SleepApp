import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uyku/features/settings/presentation/settings_controller.dart';
import 'package:uyku/features/sleep_log/presentation/sleep_log_providers.dart';
import 'package:uyku/features/sleep_quality/domain/quality_distribution.dart';

final FutureProvider<QualityDistribution> qualityDistributionProvider =
    FutureProvider.autoDispose<QualityDistribution>((ref) async {
      final entries = await ref.watch(sleepLogProvider.future);
      final goal = ref.watch(
        settingsControllerProvider.select((s) => s.goalMinutes),
      );
      return QualityDistribution.fromEntries(
        entries,
        goal,
        ref.watch(todayProvider),
      );
    });

/// Seçili dilim; varsayılan ilk grup (tasarımdaki gibi).
final NotifierProvider<QualitySelection, int?> qualitySelectionProvider =
    NotifierProvider.autoDispose<QualitySelection, int?>(QualitySelection.new);

class QualitySelection extends Notifier<int?> {
  @override
  int? build() => 0;

  void toggle(int? index) => state = index == state ? null : index;
}
