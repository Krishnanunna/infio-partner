import '../domain/growth_repository.dart';
import '../domain/growth_stats.dart';

/// Growth figures from the business-stats design.
///
/// The export's bar heights (32/55/42/70/95/60/36 percent) do not reconcile
/// with its stated 46-lead week, so the bars are seeded as real counts that
/// sum correctly while preserving the Friday peak of 16.
class MockGrowthRepository implements GrowthRepository {
  MockGrowthRepository();

  static Duration get _latency => const Duration(milliseconds: 480);

  @override
  Future<GrowthStats> fetchStats(StatsRange range) async {
    await Future<void>.delayed(_latency);

    final now = DateTime.now();
    final scale = switch (range) {
      StatsRange.today => 0.08,
      StatsRange.thisWeek => 0.32,
      StatsRange.thisMonth => 1.0,
      StatsRange.lastThreeMonths => 2.85,
    };

    String scaled(int base) => (base * scale).round().toString();

    return GrowthStats(
      range: range,
      metrics: [
        MetricPoint(
          key: 'total_leads',
          label: 'Total Leads',
          value: scaled(142),
          delta: '+12%',
        ),
        MetricPoint(
          key: 'profile_views',
          label: 'Profile Views',
          value: scaled(890),
          delta: '+5%',
        ),
        MetricPoint(
          key: 'customer_calls',
          label: 'Customer Calls',
          value: scaled(34),
          delta: '92% conn.',
        ),
        const MetricPoint(
          key: 'avg_rating',
          label: 'Avg Rating',
          value: '4.8',
          delta: 'Top Rated',
          suffix: '(142)',
        ),
      ],
      velocity: const LeadVelocity(
        points: [
          VelocityPoint(label: 'M', value: 5),
          VelocityPoint(label: 'T', value: 9),
          VelocityPoint(label: 'W', value: 7),
          VelocityPoint(label: 'T', value: 12),
          VelocityPoint(label: 'F', value: 16, isPeak: true),
          VelocityPoint(label: 'S', value: 10),
          VelocityPoint(label: 'S', value: 6),
        ],
        total: 65,
        peakLabel: 'Peak on Fri',
        deltaLabel: '+18%',
        dailyAverage: 'Avg 9.3 leads/day',
      ),
      activity: [
        ActivityEvent(
          id: 'act_1',
          type: ActivityType.newLead,
          title: 'New Lead: John Doe',
          subtitle: 'Plumbing & Leakage Repair',
          occurredAt: now.subtract(const Duration(hours: 2)),
        ),
        ActivityEvent(
          id: 'act_2',
          type: ActivityType.quoteAccepted,
          title: 'Quote Accepted: Sarah S.',
          subtitle: '₹1,200 • Water Heater Service',
          occurredAt: now.subtract(const Duration(hours: 4)),
        ),
        ActivityEvent(
          id: 'act_3',
          type: ActivityType.reviewReceived,
          title: '5-Star Review: Mike T.',
          subtitle: '"Quick, punctual and very professional!"',
          occurredAt: now.subtract(const Duration(days: 1)),
        ),
      ],
    );
  }
}
