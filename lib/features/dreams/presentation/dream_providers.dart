import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uyku/features/dreams/domain/dream_insights.dart';
import 'package:uyku/features/sleep_log/presentation/sleep_log_providers.dart';

/// Son 90 gecenin rüya içgörüleri (premium kart).
final FutureProvider<DreamInsights> dreamInsightsProvider =
    FutureProvider.autoDispose<DreamInsights>((ref) async {
      final entries = await ref.watch(sleepLogProvider.future);
      return computeDreamInsights(entries, ref.watch(todayProvider));
    });
