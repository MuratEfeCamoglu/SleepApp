import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uyku/core/router/transitions.dart';
import 'package:uyku/debug/component_gallery_screen.dart';
import 'package:uyku/features/chronotype/presentation/chronotype_screen.dart';
import 'package:uyku/features/onboarding/presentation/onboarding_screen.dart';
import 'package:uyku/features/routine/presentation/routine_screen.dart';
import 'package:uyku/features/settings/presentation/goals_screen.dart';
import 'package:uyku/features/settings/presentation/settings_controller.dart';
import 'package:uyku/features/settings/presentation/settings_screen.dart';
import 'package:uyku/features/sleep_log/presentation/log_screen.dart';
import 'package:uyku/features/sleep_quality/presentation/quality_screen.dart';
import 'package:uyku/features/sleep_summary/presentation/app_shell.dart';
import 'package:uyku/features/sleep_summary/presentation/today_screen.dart';
import 'package:uyku/features/sounds/presentation/breathe_screen.dart';
import 'package:uyku/features/sounds/presentation/sounds_screen.dart';
import 'package:uyku/features/streaks/presentation/badges_screen.dart';
import 'package:uyku/features/track_sleep/presentation/track_screen.dart';
import 'package:uyku/features/trends/presentation/trends_screen.dart';
import 'package:uyku/features/weekly_report/presentation/weekly_report_screen.dart';

abstract final class AppRoutes {
  static const today = '/';
  static const trends = '/trends';
  static const log = '/log';
  static const quality = '/quality';
  static const routine = '/routine';
  static const onboarding = '/onboarding';
  static const track = '/track';
  static const settings = '/settings';
  static const gallery = '/debug/gallery';
  static const chronotype = '/chronotype';
  static const report = '/report';
  static const sounds = '/sounds';
  static const breathe = '/breathe';
  static const badges = '/badges';
  static const goals = '/goals';

  /// Kurulum bitmeden açılabilen rotalar.
  static const Set<String> beforeOnboarding = {onboarding, chronotype};

  /// Uyku modu açıkken açılabilen rotalar.
  static const Set<String> whileTracking = {track, sounds, breathe};

  /// `/log?night=2026-09-24`
  static String logNight(String nightKey) => '$log?night=$nightKey';
}

final appRouterProvider = Provider<GoRouter>((ref) {
  // Ayarlar değişince yönlendirmeyi yeniden değerlendir.
  final refresh = ValueNotifier<int>(0);
  ref
    ..listen(
      settingsControllerProvider.select(
        (s) => (s.onboardingDone, s.trackingStart != null),
      ),
      (_, _) => refresh.value++,
    )
    ..onDispose(refresh.dispose);

  final router = GoRouter(
    initialLocation: AppRoutes.today,
    refreshListenable: refresh,
    redirect: (context, state) {
      final settings = ref.read(settingsControllerProvider);
      final loc = state.matchedLocation;
      if (!settings.onboardingDone) {
        return AppRoutes.beforeOnboarding.contains(loc)
            ? null
            : AppRoutes.onboarding;
      }
      if (loc == AppRoutes.onboarding) return AppRoutes.today;
      if (settings.trackingStart != null &&
          !AppRoutes.whileTracking.contains(loc)) {
        return AppRoutes.track;
      }
      if (loc == AppRoutes.gallery && !kDebugMode) return AppRoutes.today;
      return null;
    },
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.today,
                builder: (context, state) => const TodayScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.trends,
                builder: (context, state) => const TrendsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.log,
                builder: (context, state) =>
                    LogScreen(night: state.uri.queryParameters['night']),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.quality,
                builder: (context, state) => const QualityScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.routine,
                builder: (context, state) => const RoutineScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        pageBuilder: (context, state) =>
            fadeSlidePage(state: state, child: const OnboardingScreen()),
      ),
      GoRoute(
        path: AppRoutes.track,
        pageBuilder: (context, state) =>
            fadeSlidePage(state: state, child: const TrackScreen()),
      ),
      GoRoute(
        path: AppRoutes.settings,
        pageBuilder: (context, state) =>
            fadeSlidePage(state: state, child: const SettingsScreen()),
      ),
      GoRoute(
        path: AppRoutes.chronotype,
        pageBuilder: (context, state) =>
            fadeSlidePage(state: state, child: const ChronotypeScreen()),
      ),
      GoRoute(
        path: AppRoutes.report,
        pageBuilder: (context, state) =>
            fadeSlidePage(state: state, child: const WeeklyReportScreen()),
      ),
      GoRoute(
        path: AppRoutes.sounds,
        pageBuilder: (context, state) =>
            fadeSlidePage(state: state, child: const SoundsScreen()),
      ),
      GoRoute(
        path: AppRoutes.breathe,
        pageBuilder: (context, state) =>
            fadeSlidePage(state: state, child: const BreatheScreen()),
      ),
      GoRoute(
        path: AppRoutes.badges,
        pageBuilder: (context, state) =>
            fadeSlidePage(state: state, child: const BadgesScreen()),
      ),
      GoRoute(
        path: AppRoutes.goals,
        pageBuilder: (context, state) =>
            fadeSlidePage(state: state, child: const GoalsScreen()),
      ),
      GoRoute(
        path: AppRoutes.gallery,
        pageBuilder: (context, state) =>
            fadeSlidePage(state: state, child: const ComponentGalleryScreen()),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
