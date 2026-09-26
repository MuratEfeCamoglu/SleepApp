import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uyku/features/settings/presentation/settings_controller.dart';
import 'package:uyku/features/sleep_log/presentation/sleep_log_providers.dart';
import 'package:uyku/features/sleep_summary/domain/today_summary.dart';

final FutureProvider<TodaySummary> todaySummaryProvider =
    FutureProvider.autoDispose<TodaySummary>((ref) async {
      final entries = await ref.watch(sleepLogProvider.future);
      final settings = ref.watch(settingsControllerProvider);
      return TodaySummary.fromEntries(
        entries: entries,
        goalMinutes: settings.goalMinutes,
        targetBedFor: settings.bedtimeFor,
        today: ref.watch(todayProvider),
      );
    });
