import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/format/relative_time.dart';
import '../../../core/theme/gradients.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/chips.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../leads/domain/lead.dart';
import '../../membership/domain/plan.dart';
import '../../profile/domain/partner.dart';
import 'dashboard_providers.dart';

/// The partner home screen.
///
/// Mirrors `partner_dashboard_native_mobile`.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(dashboardProvider);

    return Scaffold(
      body: data.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorView(
          message: 'Could not load your dashboard.',
          onRetry: () => ref.invalidate(dashboardProvider),
        ),
        data: (d) => Column(
          children: [
            _Header(partner: d.partner),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async => ref.invalidate(dashboardProvider),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.stackMd,
                    AppSpacing.stackMd,
                    AppSpacing.stackMd,
                    100,
                  ),
                  children: [
                    _MembershipCard(
                      membership: d.membership,
                      newLeads: d.newLeadsToday,
                      rating: d.partner.rating,
                    ),
                    const SizedBox(height: AppSpacing.stackMd),
                    _QuickActions(partner: d.partner),
                    const SizedBox(height: AppSpacing.stackLg),
                    _RecentLeadsHeader(count: d.newLeadsToday),
                    const SizedBox(height: AppSpacing.gridGutter),
                    for (final lead in d.recentLeads) ...[
                      _DashboardLeadCard(lead: lead),
                      const SizedBox(height: AppSpacing.gridGutter),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header({required this.partner});

  final Partner partner;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final online = ref.watch(availabilityProvider).value ?? true;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        border: const Border(
          bottom: BorderSide(color: AppColors.outlineVariant),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              // Avatar with presence dot.
              Stack(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.primaryFixed,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primaryContainer.withValues(alpha: 0.25),
                        width: 2,
                      ),
                    ),
                    child: Text(
                      partner.initials,
                      style: AppText.title15.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (online)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 13,
                        height: 13,
                        decoration: BoxDecoration(
                          color: AppColors.successBright,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'INFIO PARTNER',
                          style: AppText.label10.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: StatusChip(
                            label: partner.businessName,
                            icon: Symbols.verified,
                            iconFill: 1,
                            dense: true,
                            background: AppColors.tertiaryFixed,
                            foreground: AppColors.onTertiaryFixedVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Hello, ${partner.firstName}',
                      style: AppText.title15.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),

              // Availability toggle.
              GestureDetector(
                onTap: () => ref.read(availabilityProvider.notifier).toggle(),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: online
                        ? AppColors.successSurface
                        : AppColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    border: Border.all(
                      color: online
                          ? AppColors.successBorder
                          : AppColors.outlineVariant,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (online)
                        const PulsingDot(size: 7)
                      else
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: AppColors.outline,
                            shape: BoxShape.circle,
                          ),
                        ),
                      const SizedBox(width: 5),
                      Text(
                        online ? 'Online' : 'Offline',
                        style: AppText.label11.copyWith(
                          fontWeight: FontWeight.w700,
                          color: online
                              ? AppColors.onSuccessSurface
                              : AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),

              Stack(
                children: [
                  CircleIconButton(
                    icon: Symbols.notifications,
                    size: 36,
                    iconSize: 19,
                    borderColor: AppColors.outlineVariant,
                    tooltip: 'Notifications',
                    onPressed: () {},
                  ),
                  Positioned(
                    right: 2,
                    top: 2,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MembershipCard extends StatelessWidget {
  const _MembershipCard({
    required this.membership,
    required this.newLeads,
    required this.rating,
  });

  final Membership membership;
  final int newLeads;
  final double rating;

  @override
  Widget build(BuildContext context) {
    final renews = membership.renewsOn;

    return Container(
      decoration: BoxDecoration(
        gradient: AppGradients.membershipCard,
        borderRadius: AppRadius.brLg,
        boxShadow: AppShadows.primaryGlow,
      ),
      child: Stack(
        children: [
          // Decorative blurred corner highlights.
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.stackMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius:
                                  BorderRadius.circular(AppRadius.full),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Symbols.workspace_premium,
                                  size: 14,
                                  color: Colors.white,
                                  fill: 1,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  membership.planName,
                                  style: AppText.label11.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (renews != null)
                            RichText(
                              text: TextSpan(
                                style: AppText.label11.copyWith(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  fontWeight: FontWeight.w400,
                                ),
                                children: [
                                  const TextSpan(text: 'Renews on '),
                                  TextSpan(
                                    text: DateFormat('MMM d, y').format(renews),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    FilledButton(
                      onPressed: () => context.push('/membership'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primary,
                        minimumSize: const Size(0, 38),
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.full),
                        ),
                      ),
                      child: Text(
                        'Upgrade',
                        style: AppText.title15.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.stackMd),

                // Three glass metric tiles.
                Row(
                  children: [
                    Expanded(
                      child: _MiniStat(
                        label: 'NEW LEADS',
                        value: '$newLeads',
                        trailing: '+3 today',
                        trailingColor: const Color(0xFF86EFAC),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.stackSm),
                    Expanded(
                      child: _MiniStat(
                        label: 'QUOTA',
                        value: '${membership.leadsUsed}',
                        trailing: membership.leadQuota == null
                            ? 'Unlimited'
                            : '/${membership.leadQuota}',
                      ),
                    ),
                    const SizedBox(width: AppSpacing.stackSm),
                    Expanded(
                      child: _MiniStat(
                        label: 'RATING',
                        value: rating.toStringAsFixed(1),
                        trailingIcon: Symbols.star,
                      ),
                    ),
                  ],
                ),

                if (membership.leadQuota != null) ...[
                  const SizedBox(height: AppSpacing.stackMd),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Quota Used (${membership.quotaPercent}%)',
                          style: AppText.label11.copyWith(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Text(
                        '${membership.leadsRemaining} Remaining',
                        style: AppText.label11.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    child: LinearProgressIndicator(
                      value: membership.quotaFraction,
                      minHeight: 6,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      valueColor: const AlwaysStoppedAnimation(Colors.white),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    this.trailing,
    this.trailingColor,
    this.trailingIcon,
  });

  final String label;
  final String value;
  final String? trailing;
  final Color? trailingColor;
  final IconData? trailingIcon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: AppRadius.brMd,
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppText.label10.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 9.5,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.title20.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 3),
              if (trailingIcon != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Icon(
                    trailingIcon,
                    size: 13,
                    color: AppColors.tertiaryFixedDim,
                    fill: 1,
                  ),
                )
              else if (trailing != null)
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      trailing!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.label10.copyWith(
                        color: trailingColor ??
                            Colors.white.withValues(alpha: 0.75),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.partner});

  final Partner partner;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _ActionTile(
                icon: Symbols.add_business,
                title: 'Add Service',
                subtitle: '+ New Offering',
                highlighted: true,
                onTap: () => context.push('/services/new'),
              ),
            ),
            const SizedBox(width: AppSpacing.gridGutter),
            Expanded(
              child: _ActionTile(
                icon: Symbols.home_repair_service,
                title: 'My Services',
                subtitle: '${partner.activeServiceCount} Active',
                onTap: () => context.push('/services'),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.gridGutter),
        Row(
          children: [
            Expanded(
              child: _ActionTile(
                icon: Symbols.trending_up,
                title: 'Growth & Stats',
                subtitle: '+15% views',
                subtitleColor: AppColors.success,
                iconBackground: AppColors.analyticsBlueSurface,
                iconForeground: AppColors.analyticsBlue,
                onTap: () => context.go('/growth'),
              ),
            ),
            const SizedBox(width: AppSpacing.gridGutter),
            Expanded(
              child: _ActionTile(
                icon: Symbols.verified,
                title: 'Reviews',
                subtitle: '${partner.reviewCount} verified',
                iconBackground: AppColors.amberSurface,
                iconForeground: AppColors.amber,
                onTap: () {},
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.highlighted = false,
    this.subtitleColor,
    this.iconBackground,
    this.iconForeground,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool highlighted;
  final Color? subtitleColor;
  final Color? iconBackground;
  final Color? iconForeground;

  @override
  Widget build(BuildContext context) {
    return SolidCard(
      radius: AppRadius.lg,
      padding: const EdgeInsets.all(12),
      onTap: onTap,
      color: AppColors.surfaceContainerLowest,
      gradient: highlighted
          ? const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primaryFixed, Colors.white],
            )
          : null,
      borderColor: highlighted
          ? AppColors.primaryContainer.withValues(alpha: 0.5)
          : null,
      child: Row(
        children: [
          IconTile(
            icon: icon,
            size: 42,
            iconSize: 21,
            radius: AppRadius.md,
            background: iconBackground ??
                (highlighted ? AppColors.primary : AppColors.primaryFixed),
            foreground: iconForeground ??
                (highlighted ? Colors.white : AppColors.primary),
            fill: highlighted ? 0 : 0,
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
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.title15.copyWith(
                          fontWeight: FontWeight.w700,
                          // 13.5 keeps "Growth & Stats" on one line in a
                          // half-width tile on a 390pt handset.
                          fontSize: 13.5,
                        ),
                      ),
                    ),
                    if (highlighted) ...[
                      const SizedBox(width: 4),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.label11.copyWith(
                    color: subtitleColor ?? AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentLeadsHeader extends StatelessWidget {
  const _RecentLeadsHeader({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // The title and badge share one Expanded so the trailing action
        // cannot steal half the row from the heading.
        Expanded(
          child: Row(
            children: [
              Flexible(
                child: Text(
                  'Recent New Leads',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.titleMd,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: const BoxDecoration(
                  color: AppColors.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$count',
                  style: AppText.label11.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => context.go('/leads'),
          child: Row(
            children: [
              Text(
                'View All',
                style: AppText.label11.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Symbols.arrow_forward,
                size: 15,
                color: AppColors.primary,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DashboardLeadCard extends StatelessWidget {
  const _DashboardLeadCard({required this.lead});

  final Lead lead;

  @override
  Widget build(BuildContext context) {
    return SolidCard(
      radius: AppRadius.lg,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconTile(
                icon: LeadVisuals.icon(lead.categorySlug),
                size: 40,
                iconSize: 20,
                background: LeadVisuals.background(lead.categorySlug),
                foreground: LeadVisuals.foreground(lead.categorySlug),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lead.serviceName,
                      style: AppText.titleMd.copyWith(fontSize: 16),
                    ),
                    const SizedBox(height: 2),
                    Text.rich(
                      TextSpan(
                        style: AppText.body13,
                        children: [
                          TextSpan(text: lead.customerName),
                          const TextSpan(text: ' • '),
                          TextSpan(
                            text: 'Est. ${lead.budgetLabel}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              if (lead.urgency.isUrgent)
                StatusChip(
                  label: 'Urgent',
                  uppercase: true,
                  dense: true,
                  background: AppColors.roseSurface,
                  foreground: AppColors.rose,
                  borderColor: AppColors.roseBorder,
                  showDot: true,
                )
              else
                const StatusChip.neutral(
                  label: 'Standard',
                  uppercase: true,
                  dense: true,
                ),
            ],
          ),
          const SizedBox(height: 12),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: AppRadius.brBase,
            ),
            child: Text(
              '"${lead.description}"',
              style: AppText.body13.copyWith(color: AppColors.onSurface),
            ),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              const Icon(Symbols.near_me, size: 15, color: AppColors.primary),
              const SizedBox(width: 4),
              Text(
                '${lead.distanceKm} km away',
                style: AppText.label11.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 14),
              const Icon(
                Symbols.schedule,
                size: 15,
                color: AppColors.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                RelativeTime.format(lead.createdAt),
                style: AppText.label11,
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: OutlineActionButton(
                  label: 'Call Now',
                  icon: Symbols.call,
                  height: 44,
                  foreground: AppColors.onSurface,
                  onPressed: () {},
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GradientButton(
                  label: 'View Details',
                  icon: Symbols.chevron_right,
                  height: 44,
                  shadows: const [],
                  onPressed: () => context.push('/leads/${lead.id}'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Shared failure state for the tab screens.
class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.containerMargin),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Symbols.cloud_off,
              size: 40,
              color: AppColors.outline,
            ),
            const SizedBox(height: 12),
            Text(message, style: AppText.bodySm, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
