import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/format/relative_time.dart';
import '../../../core/theme/gradients.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/chips.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../domain/lead.dart';
import 'leads_providers.dart';

/// The lead feed with New / Contacted / Missed segmentation.
///
/// Mirrors `partner_lead_inbox_native_mobile`.
class LeadInboxScreen extends ConsumerWidget {
  const LeadInboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(selectedLeadTabProvider);
    final leads = ref.watch(leadsListProvider(tab));
    final summary = ref.watch(leadSummaryProvider).value;

    return Scaffold(
      body: Column(
        children: [
          const _InboxAppBar(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(leadsListProvider);
                ref.invalidate(leadSummaryProvider);
              },
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.containerMargin,
                  AppSpacing.stackMd,
                  AppSpacing.containerMargin,
                  100,
                ),
                children: [
                  _FilterTabs(
                    selected: tab,
                    counts: summary?.counts ?? const {},
                    onSelect: (s) =>
                        ref.read(selectedLeadTabProvider.notifier).set(s),
                  ),
                  const SizedBox(height: AppSpacing.stackMd),
                  if (summary != null) _QuickStatsBanner(summary: summary),
                  const SizedBox(height: AppSpacing.stackMd),
                  ...switch (leads) {
                    AsyncData(:final value) when value.isEmpty => [
                        _EmptyState(status: tab),
                      ],
                    AsyncData(:final value) => [
                        for (final lead in value) ...[
                          InboxLeadCard(lead: lead),
                          const SizedBox(height: AppSpacing.stackMd),
                        ],
                      ],
                    AsyncError() => [
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Center(
                            child: Text('Could not load leads.'),
                          ),
                        ),
                      ],
                    _ => [
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 60),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      ],
                  },
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InboxAppBar extends StatelessWidget {
  const _InboxAppBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        border: const Border(
          bottom: BorderSide(color: AppColors.outlineVariant),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 64,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                CircleIconButton(
                  icon: Symbols.menu,
                  background: Colors.transparent,
                  onPressed: () {},
                  tooltip: 'Menu',
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('Lead Inbox', style: AppText.headlineLgMobile),
                          const SizedBox(width: 8),
                          const PulsingDot(),
                        ],
                      ),
                      Text(
                        'InFio Business • Hyderabad',
                        style: AppText.label11.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                CircleIconButton(
                  icon: Symbols.search,
                  background: Colors.transparent,
                  onPressed: () {},
                  tooltip: 'Search leads',
                ),
                Stack(
                  children: [
                    CircleIconButton(
                      icon: Symbols.tune,
                      background: Colors.transparent,
                      onPressed: () {},
                      tooltip: 'Filter',
                    ),
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterTabs extends StatelessWidget {
  const _FilterTabs({
    required this.selected,
    required this.counts,
    required this.onSelect,
  });

  final LeadStatus selected;
  final Map<LeadStatus, int> counts;
  final ValueChanged<LeadStatus> onSelect;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          for (final status in LeadStatus.inboxTabs) ...[
            _Tab(
              status: status,
              count: counts[status] ?? 0,
              selected: status == selected,
              onTap: () => onSelect(status),
            ),
            const SizedBox(width: AppSpacing.stackSm),
          ],
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.status,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final LeadStatus status;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isMissed = status == LeadStatus.missed;

    final Color countBg;
    final Color countFg;
    if (selected) {
      countBg = Colors.white.withValues(alpha: 0.25);
      countFg = Colors.white;
    } else if (isMissed) {
      countBg = AppColors.errorContainer;
      countFg = AppColors.onErrorContainer;
    } else {
      countBg = AppColors.surfaceContainerHigh;
      countFg = AppColors.onSurfaceVariant;
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primaryContainer
              : AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(
            color: selected
                ? AppColors.primaryContainer
                : AppColors.outlineVariant,
          ),
          boxShadow: selected ? AppShadows.card : const [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              status.label,
              style: AppText.label11.copyWith(
                color: selected ? Colors.white : AppColors.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 7),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
              decoration: BoxDecoration(
                color: countBg,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: Text(
                '$count',
                style: AppText.label10.copyWith(
                  color: countFg,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickStatsBanner extends StatelessWidget {
  const _QuickStatsBanner({required this.summary});

  final LeadInboxSummary summary;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: AppRadius.md,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          const IconTile(
            icon: Symbols.bolt,
            size: 36,
            iconSize: 19,
            background: AppColors.primaryFixed,
            foreground: AppColors.primary,
            fill: 1,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        "Today's Inflow: ${summary.todayCount} Leads",
                        style: AppText.label11.copyWith(
                          color: AppColors.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Symbols.local_fire_department,
                      size: 14,
                      color: AppColors.error,
                      fill: 1,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${summary.urgentCount} Urgent',
                      style: AppText.label11.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Avg Response: ${summary.averageResponse} • '
                  '${summary.matchRate} Match Rate',
                  style: AppText.label10.copyWith(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          const Icon(
            Symbols.chevron_right,
            size: 20,
            color: AppColors.outline,
          ),
        ],
      ),
    );
  }
}

/// A lead card in the feed, with the accept-state machine from the design.
class InboxLeadCard extends ConsumerStatefulWidget {
  const InboxLeadCard({super.key, required this.lead});

  final Lead lead;

  @override
  ConsumerState<InboxLeadCard> createState() => _InboxLeadCardState();
}

enum _AcceptPhase { idle, accepting, accepted }

class _InboxLeadCardState extends ConsumerState<InboxLeadCard> {
  _AcceptPhase _phase = _AcceptPhase.idle;
  Timer? _ticker;
  Duration? _remaining;

  @override
  void initState() {
    super.initState();
    _syncCountdown();
    if (widget.lead.expiresAt != null) {
      _ticker = Timer.periodic(
        const Duration(seconds: 1),
        (_) => _syncCountdown(),
      );
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _syncCountdown() {
    if (!mounted) return;
    final left = widget.lead.remainingFrom(DateTime.now());
    setState(() => _remaining = left);
    if (left != null && left.isNegative) _ticker?.cancel();
  }

  Future<void> _accept() async {
    if (_phase != _AcceptPhase.idle) return;
    setState(() => _phase = _AcceptPhase.accepting);
    try {
      await ref.read(leadActionsProvider).accept(widget.lead.id);
      if (mounted) setState(() => _phase = _AcceptPhase.accepted);
    } catch (_) {
      if (mounted) setState(() => _phase = _AcceptPhase.idle);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lead = widget.lead;

    return GlassCard(
      radius: AppRadius.md,
      opacity: 0.85,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          // Urgency stripe sits flush to the card's top edge.
          if (lead.urgency.isUrgent)
            Container(
              height: 4,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.error,
                    AppColors.tertiaryContainer,
                    AppColors.primaryContainer,
                  ],
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _header(lead),
                const SizedBox(height: 12),
                _metrics(lead),
                const SizedBox(height: 10),
                _note(lead),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 12),
                _actions(lead),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(Lead lead) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconTile(
          icon: LeadVisuals.icon(lead.categorySlug),
          size: 44,
          iconSize: 22,
          background: LeadVisuals.background(lead.categorySlug),
          foreground: LeadVisuals.foreground(lead.categorySlug),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(lead.serviceName, style: AppText.titleMd),
              const SizedBox(height: 3),
              Row(
                children: [
                  const Icon(
                    Symbols.person,
                    size: 13,
                    color: AppColors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 3),
                  Flexible(
                    child: Text(
                      lead.customerName,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.label11,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Symbols.near_me,
                    size: 13,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    '${lead.distanceKm} km away',
                    style: AppText.label11.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        _badge(lead),
      ],
    );
  }

  Widget _badge(Lead lead) {
    // A live countdown wins over a static urgency label.
    final left = _remaining;
    if (left != null && !left.isNegative && left.inMinutes < 60) {
      return StatusChip.error(
        label: RelativeTime.countdown(left),
        icon: Symbols.timer,
        dense: true,
      );
    }
    if (lead.urgency == LeadUrgency.urgent) {
      return const StatusChip.urgent(label: 'Urgent');
    }
    return StatusChip.neutral(
      label: RelativeTime.format(lead.createdAt),
      dense: true,
      radius: AppRadius.base,
    );
  }

  Widget _metrics(Lead lead) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow.withValues(alpha: 0.75),
        borderRadius: AppRadius.brBase,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ESTIMATED BUDGET', style: AppText.label10),
                const SizedBox(height: 2),
                Text(
                  lead.budgetLabel,
                  style: AppText.title15.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          Container(width: 1, height: 32, color: AppColors.outlineVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('PREFERRED SLOT', style: AppText.label10),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      lead.urgency == LeadUrgency.immediate
                          ? Symbols.fmd_bad
                          : Symbols.calendar_today,
                      size: 14,
                      color: lead.urgency == LeadUrgency.immediate
                          ? AppColors.error
                          : AppColors.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        lead.preferredSlot ?? '—',
                        overflow: TextOverflow.ellipsis,
                        style: AppText.title15.copyWith(
                          fontWeight: FontWeight.w600,
                          color: lead.urgency == LeadUrgency.immediate
                              ? AppColors.error
                              : AppColors.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _note(Lead lead) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surfaceBright.withValues(alpha: 0.8),
        borderRadius: AppRadius.brBase,
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Text(
        '"${lead.description}"',
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        style: AppText.body13.copyWith(color: AppColors.onSurface),
      ),
    );
  }

  Widget _actions(Lead lead) {
    return Row(
      children: [
        CircleIconButton(
          icon: Symbols.call,
          size: 40,
          background: AppColors.surfaceContainer,
          foreground: AppColors.onSurface,
          tooltip: 'Call ${lead.customerName}',
          onPressed: () {},
        ),
        const SizedBox(width: 8),
        if (lead.urgency == LeadUrgency.urgent) ...[
          CircleIconButton(
            icon: Symbols.chat,
            size: 40,
            background: AppColors.successSurface,
            foreground: AppColors.onSuccessSurface,
            tooltip: 'WhatsApp ${lead.customerName}',
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
        Expanded(
          flex: 10,
          child: OutlineActionButton(
            label: 'Decline',
            height: 44,
            foreground: AppColors.onSurfaceVariant,
            onPressed: () => ref.read(leadActionsProvider).decline(lead.id),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 14,
          child: switch (_phase) {
            _AcceptPhase.idle => GradientButton(
                label: 'Accept Lead',
                leadingIcon: Symbols.bolt,
                height: 44,
                shadows: const [],
                onPressed: _accept,
              ),
            _AcceptPhase.accepting => const GradientButton(
                label: 'Accepting...',
                height: 44,
                busy: true,
                shadows: [],
              ),
            _AcceptPhase.accepted => GradientButton(
                label: 'Accepted!',
                leadingIcon: Symbols.check_circle,
                height: 44,
                fillColor: AppColors.success,
                shadows: const [],
                onPressed: () => context.push('/leads/${lead.id}'),
              ),
          },
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.status});

  final LeadStatus status;

  @override
  Widget build(BuildContext context) {
    final (icon, title, body) = switch (status) {
      LeadStatus.newLead => (
          Symbols.inbox,
          'No new leads right now',
          'Stay online and keep your services active. New requests in your '
              'area land here instantly.',
        ),
      LeadStatus.contacted => (
          Symbols.forum,
          'Nothing contacted yet',
          'Leads you accept or quote on will appear here.',
        ),
      _ => (
          Symbols.timer_off,
          'No missed leads',
          'Leads you did not respond to in time would show up here.',
        ),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          IconTile(
            icon: icon,
            size: 64,
            iconSize: 30,
            radius: AppRadius.lg,
            background: AppColors.surfaceContainer,
            foreground: AppColors.outline,
          ),
          const SizedBox(height: 16),
          Text(title, style: AppText.titleMd),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              body,
              textAlign: TextAlign.center,
              style: AppText.bodySm,
            ),
          ),
        ],
      ),
    );
  }
}
