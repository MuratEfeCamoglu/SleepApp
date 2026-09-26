import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:uyku/core/strings/app_strings.dart';
import 'package:uyku/core/theme/app_motion.dart';
import 'package:uyku/core/theme/app_sizes.dart';
import 'package:uyku/core/theme/app_spacing.dart';
import 'package:uyku/core/widgets/app_icon.dart';
import 'package:uyku/core/widgets/app_nav_panel.dart';
import 'package:uyku/core/widgets/entrance.dart';

/// Beş sekmeli kabuk: içerik + ekran altına yapışık panel.
class AppShell extends StatelessWidget {
  const AppShell({required this.shell, super.key});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: TabSwitchFade(index: shell.currentIndex, child: shell),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AppNavPanel(
              semanticLabel: strings.nav_label,
              items: [
                NavPanelItem(label: strings.nav_today, icon: AppIcons.home),
                NavPanelItem(label: strings.nav_trends, icon: AppIcons.bars),
                NavPanelItem(label: strings.nav_quality, icon: AppIcons.gauge),
                NavPanelItem(label: strings.nav_routine, icon: AppIcons.clock),
              ],
              center: NavPanelItem(
                label: strings.nav_log,
                icon: AppIcons.moonNav,
              ),
              centerSemantic: strings.nav_logSemantic,
              currentIndex: shell.currentIndex,
              onSelect: (i) =>
                  shell.goBranch(i, initialLocation: i == shell.currentIndex),
            ),
          ),
        ],
      ),
    );
  }
}

/// Sekme sayfası iskeleti: üstte güvenli alan + 8, yatayda 24, altta panel
/// yüksekliği kadar boşluk; içerik kaydırılabilir. İlk açılışta öğeler
/// sırayla belirir; sonradan kaydırılarak gelenler animasyonsuz görünür.
class TabPage extends StatefulWidget {
  const TabPage({
    required this.children,
    this.gap = AppSpacing.lgPlus,
    super.key,
  });

  final List<Widget> children;
  final double gap;

  @override
  State<TabPage> createState() => _TabPageState();
}

class _TabPageState extends State<TabPage> {
  final _shown = Stopwatch()..start();

  bool get _entering =>
      _shown.elapsed < AppMotion.entrance + AppMotion.entrance;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top + AppSpacing.sm;
    final bottom = AppNavPanel.heightOf(context) + AppSpacing.xl;
    return LayoutBuilder(
      builder: (context, constraints) {
        // Geniş ekranlarda içerik ortalanır; çocuklar her zaman tam genişlik.
        final side = math.max(
          AppSpacing.xl,
          (constraints.maxWidth - AppSizes.maxContentWidth) / 2,
        );
        return ListView.separated(
          padding: EdgeInsets.fromLTRB(side, top, side, bottom),
          itemCount: widget.children.length,
          separatorBuilder: (_, _) => SizedBox(height: widget.gap),
          itemBuilder: (_, i) => Entrance(
            index: i,
            animate: _entering,
            child: widget.children[i],
          ),
        );
      },
    );
  }
}
