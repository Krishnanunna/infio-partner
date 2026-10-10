import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/di/repositories.dart';
import '../../../core/di/value_provider.dart';
import '../../../core/format/relative_time.dart';
import '../../../core/theme/gradients.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/bar_chart.dart';
import '../../../shared/widgets/chips.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../../shared/widgets/infio_logo.dart';
import '../../profile/domain/partner.dart';
import '../domain/growth_stats.dart';

final statsRangeProvider = valueProvider<StatsRange>(StatsRange.thisMonth);

final growthStatsProvider = FutureProvider<GrowthStats>((ref) {
  return ref.watch(growthRepositoryProvider).fetchStats(
        ref.watch(statsRangeProvider),
      );
});

final _partnerProvider = FutureProvider<Partner>((ref) {
  return ref.watch(partnerRepositoryProvider).fetchPartner();
});

/// Business performance.
///
/// Mirrors `partner_business_growth_stats_native_mobile`.
class GrowthScreen extends ConsumerWidget {
  const GrowthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(growthStatsProvider);
    final partner = ref.watch(_partnerProvider).value;
    final range = ref.watch(statsRangeProvider);

    return Scaffold(
      body: Column(
        children: [
          _Header(partner: partner),
          Expanded(
            child: stats.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) =>
                  const Center(child: Text('Could not load your stats.')),
              data: (s) => RefreshIndicator(
                onRefresh: () async => ref.invalidate(growthStatsProvider),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.stackMd,
                    AppSpacing.stackMd,
                    AppSpacing.stackMd,
                    100,
                  ),
                  children: [
                    // Only shown while admin review is outstanding.
                    if (partner != null &&
                        partner.verification !=
                            VerificationStatus.verified) ...[
                      _VerificationCard(status: partner.verification),
                      const SizedBox(height: 14),
                    ],
                    _titleRow(context, ref, range),
                    const SizedBox(height: 14),
                    _metricsGrid(s.metrics),
                    const SizedBox(height: 14),
                    _chartCard(s.velocity),
                    const SizedBox(height: 14),
                    _activityCard(s.activity),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _titleRow(BuildContext context, WidgetRef ref, StatsRange range) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Business Growth',
                style: AppText.title20.copyWith(fontWeight: FontWeight.w700),
              ),
              Text('Performance metrics & leads', style: AppText.label11),
            ],
          ),
        ),
        PopupMenuButton<StatsRange>(
          initialValue: range,
          padding: EdgeInsets.zero,
          onSelected: (v) => ref.read(statsRangeProvider.notifier).set(v),
          itemBuilder: (context) => [
            for (final r in StatsRange.values)
              PopupMenuItem(value: r, child: Text(r.label)),
          ],
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(AppRadius.full),
              border: Border.all(color: AppColors.outlineVariant),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Symbols.calendar_today,
                  size: 15,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  range.label,
                  style: AppText.label11.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
                const Icon(Symbols.expand_more, size: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _metricsGrid(List<MetricPoint> metrics) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: metrics.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.55,
      ),
      itemBuilder: (context, i) => _MetricTile(metric: metrics[i]),
    );
  }

  Widget _chartCard(LeadVelocity velocity) {
    return SolidCard(
      radius: AppRadius.md,
      padding: const EdgeInsets.all(AppSpacing.stackMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Weekly Lead Velocity',
                      style: AppText.title15.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${velocity.total} Leads this week • '
                      '${velocity.peakLabel}',
                      style: AppText.label10.copyWith(
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              StatusChip.primary(label: velocity.deltaLabel, dense: true),
            ],
          ),
          const SizedBox(height: AppSpacing.stackMd),
          WeeklyBarChart(
            bars: [
              for (final p in velocity.points)
                ChartBar(label: p.label, value: p.value, isPeak: p.isPeak),
            ],
          ),
          const SizedBox(height: AppSpacing.gridGutter),
          Row(
            children: [
              Expanded(
                child: Text(
                  velocity.dailyAverage,
                  style: AppText.label11.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                'Detailed Report',
                style: AppText.label11.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Icon(
                Symbols.chevron_right,
                size: 16,
                color: AppColors.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _activityCard(List<ActivityEvent> activity) {
    return SolidCard(
      radius: AppRadius.md,
      padding: const EdgeInsets.all(AppSpacing.stackMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Recent Activity',
                  style: AppText.title15.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              Text('Real-time', style: AppText.label10),
            ],
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < activity.length; i++) ...[
            _ActivityRow(event: activity[i]),
            if (i != activity.length - 1) const Divider(height: 20),
          ],
          const SizedBox(height: AppSpacing.stackMd),
          OutlineActionButton(
            label: 'View All Activity',
            height: 44,
            borderColor: AppColors.primary,
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.partner});

  final Partner? partner;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.95),
        border: const Border(
          bottom: BorderSide(color: AppColors.outlineVariant),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
          child: Row(
            children: [
              const InfioLogo(size: 36, shape: BoxShape.circle),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            partner?.businessName ?? 'InFio Partner',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.title15.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const StatusChip.primarySolid(
                          label: 'PRO',
                          radius: AppRadius.sm,
                        ),
                      ],
                    ),
                    const SizedBox(height: 1),
                    Text(
                      'Verified AC & Appliance Repair',
                      style: AppText.label10.copyWith(
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              Stack(
                children: [
                  CircleIconButton(
                    icon: Symbols.notifications,
                    size: 34,
                    iconSize: 18,
                    background: Colors.transparent,
                    onPressed: () {},
                    tooltip: 'Notifications',
                  ),
                  Positioned(
                    right: 4,
                    top: 4,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () => context.go('/account'),
                child: Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryFixed,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    partner?.initials ?? '',
                    style: AppText.label11.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VerificationCard extends StatelessWidget {
  const _VerificationCard({required this.status});

  final VerificationStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.stackMd),
      decoration: BoxDecoration(
        color: AppColors.amberSurface,
        borderRadius: AppRadius.brMd,
        border: Border.all(color: AppColors.amberBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const IconTile(
                icon: Symbols.verified_user,
                size: 36,
                iconSize: 19,
                background: AppColors.amberSurfaceAlt,
                foreground: AppColors.amber,
                fill: 1,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Status: ${status.label}',
                  style: AppText.title15.copyWith(
                    color: AppColors.amberText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const StatusChip.warning(label: 'In Review', dense: true),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Your business profile is under manual verification. Public '
            'visibility will turn on once approved by the InFio team.',
            style: AppText.body13.copyWith(color: AppColors.amberText),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => context.push('/kyc'),
            child: Row(
              children: [
                Text(
                  'Check Video KYC Status',
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
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.metric});

  final MetricPoint metric;

  bool get _isRating => metric.key == 'avg_rating';

  @override
  Widget build(BuildContext context) {
    return SolidCard(
      radius: AppRadius.md,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: _isRating ? null : AppGradients.ctaDiagonal,
                  color: _isRating ? AppColors.amberSurface : null,
                  borderRadius: BorderRadius.circular(AppRadius.base),
                ),
                child: Icon(
                  switch (metric.key) {
                    'total_leads' => Symbols.leaderboard,
                    'profile_views' => Symbols.visibility,
                    'customer_calls' => Symbols.call,
                    _ => Symbols.star,
                  },
                  size: 17,
                  color: _isRating ? AppColors.amber : Colors.white,
                  fill: _isRating ? 1 : 0,
                ),
              ),
              const Spacer(),
              if (metric.delta != null)
                _isRating
                    ? StatusChip.warning(label: metric.delta!, dense: true)
                    : StatusChip.primary(label: metric.delta!, dense: true),
            ],
          ),
          const Spacer(),
          Text(metric.label, style: AppText.label10),
          const SizedBox(height: 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                metric.value,
                style: AppText.title20.copyWith(fontWeight: FontWeight.w800),
              ),
              if (metric.suffix != null) ...[
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(metric.suffix!, style: AppText.label10),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.event});

  final ActivityEvent event;

  @override
  Widget build(BuildContext context) {
    final (icon, bg, fg) = switch (event.type) {
      ActivityType.newLead => (
          Symbols.person_add,
          AppColors.primaryFixed,
          AppColors.primary,
        ),
      ActivityType.quoteAccepted => (
          Symbols.request_quote,
          AppColors.amberSurfaceAlt,
          AppColors.amberText,
        ),
      ActivityType.reviewReceived => (
          Symbols.star,
          const Color(0xFFFEF08A),
          const Color(0xFF854D0E),
        ),
    };

    return Row(
      children: [
        IconTile(
          icon: icon,
          size: 32,
          iconSize: 17,
          shape: BoxShape.circle,
          background: bg,
          foreground: fg,
          fill: event.type == ActivityType.reviewReceived ? 1 : 0,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                event.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.body13.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                event.subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.label10.copyWith(fontWeight: FontWeight.w400),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(RelativeTime.format(event.occurredAt), style: AppText.label10),
        const Icon(
          Symbols.chevron_right,
          size: 17,
          color: AppColors.outline,
        ),
      ],
    );
  }
}
