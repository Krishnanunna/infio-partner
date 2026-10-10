import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/theme/gradients.dart';
import '../../core/theme/text_styles.dart';
import '../../core/theme/tokens.dart';

/// The canonical tab set.
///
/// The Stitch exports disagree across four variants; this follows the
/// content-lock comment in the lead inbox markup, which is the closest thing
/// to a spec. "Services" is a pushed route from the dashboard rather than a
/// fifth tab, matching its own back-arrow app bar.
enum InfioTab {
  dashboard(label: 'Dashboard', icon: Symbols.dashboard, route: '/dashboard'),
  leads(label: 'Leads', icon: Symbols.bolt, route: '/leads'),
  growth(label: 'Growth', icon: Symbols.trending_up, route: '/growth'),
  account(label: 'Account', icon: Symbols.person, route: '/account');

  const InfioTab({
    required this.label,
    required this.icon,
    required this.route,
  });

  final String label;
  final IconData icon;
  final String route;
}

/// The glass bottom bar. The active tab wraps its icon in a filled purple
/// pill, matching the dashboard and profile treatments.
class InfioBottomNav extends StatelessWidget {
  const InfioBottomNav({
    super.key,
    required this.current,
    required this.onSelect,
    this.badges = const {},
  });

  final InfioTab current;
  final ValueChanged<InfioTab> onSelect;

  /// Numeric badges per tab, e.g. `{InfioTab.leads: 5}`.
  final Map<InfioTab, int> badges;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(AppRadius.lg),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.88),
            border: Border(
              top: BorderSide(
                color: AppColors.outlineVariant.withValues(alpha: 0.6),
              ),
            ),
            boxShadow: AppShadows.dock,
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 64,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  for (final tab in InfioTab.values)
                    _NavItem(
                      tab: tab,
                      selected: tab == current,
                      badge: badges[tab],
                      onTap: () => onSelect(tab),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.tab,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  final InfioTab tab;
  final bool selected;
  final VoidCallback onTap;
  final int? badge;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.onSurfaceVariant;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.brMd,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.primaryFixed : Colors.transparent,
                    borderRadius: AppRadius.brMd,
                  ),
                  child: Icon(
                    tab.icon,
                    size: 22,
                    color: color,
                    fill: selected ? 1 : 0,
                  ),
                ),
                if (badge != null && badge! > 0)
                  Positioned(
                    right: 6,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      constraints: const BoxConstraints(minWidth: 18),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.rectangle,
                        borderRadius: BorderRadius.circular(AppRadius.full),
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: Text(
                        '$badge',
                        textAlign: TextAlign.center,
                        style: AppText.label10.copyWith(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              tab.label,
              style: AppText.label11.copyWith(
                color: color,
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
