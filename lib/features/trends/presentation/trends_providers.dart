import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uyku/features/sleep_log/presentation/sleep_log_providers.dart';
import 'package:uyku/features/trends/domain/trend_aggregator.dart';

/// Seçili aralık ve bar.
final NotifierProvider<TrendSelection, ({int? bar, TrendRange range})>
trendSelectionProvider =
    NotifierProvider.autoDispose<
      TrendSelection,
      ({TrendRange range, int? bar})
    >(TrendSelection.new);

class TrendSelection extends Notifier<({TrendRange range, int? bar})> {
  @override
  ({TrendRange range, int? bar}) build() => (range: TrendRange.week, bar: null);

  void setRange(TrendRange range) => state = (range: range, bar: null);

  void selectBar(int index) => state = (range: state.range, bar: index);
}

// Aile tipi flutter_riverpod'dan dışa aktarılmıyor; çıkarımla bırakıldı.
// ignore: specify_nonobvious_property_types
final trendSeriesProvider = FutureProvider.autoDispose
    .family<TrendSeries, TrendRange>((ref, range) async {
      final entries = await ref.watch(sleepLogProvider.future);
      return TrendAggregator.build(entries, range, ref.watch(todayProvider));
    });
