import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/leads/domain/lead.dart';
import '../../features/leads/presentation/leads_providers.dart';
import '../../shared/widgets/bottom_nav.dart';

/// Hosts the four tabs and keeps the bottom bar fixed while each branch
/// maintains its own stack.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // The Leads tab carries an unread count sourced from the inbox summary.
    final summary = ref.watch(leadSummaryProvider).value;
    final newLeads = summary?.counts[LeadStatus.newLead] ?? 0;

    return Scaffold(
      // The glass bars blur whatever scrolls beneath them.
      extendBody: true,
      body: shell,
      bottomNavigationBar: InfioBottomNav(
        current: InfioTab.values[shell.currentIndex],
        badges: {InfioTab.leads: newLeads},
        onSelect: (tab) => shell.goBranch(
          tab.index,
          // Tapping the active tab returns it to its root.
          initialLocation: tab.index == shell.currentIndex,
        ),
      ),
    );
  }
}
