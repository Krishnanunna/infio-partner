/// Reporting window for the growth screen.
enum StatsRange {
  today('today', 'Today'),
  thisWeek('this_week', 'This Week'),
  thisMonth('this_month', 'This Month'),
  lastThreeMonths('last_3_months', 'Last 3 Months');

  const StatsRange(this.wire, this.label);

  final String wire;
  final String label;

  static StatsRange fromWire(String v) => StatsRange.values.firstWhere(
        (e) => e.wire == v,
        orElse: () => StatsRange.thisMonth,
      );
}

/// What happened, for the recent-activity feed.
enum ActivityType {
  newLead('new_lead'),
  quoteAccepted('quote_accepted'),
  reviewReceived('review_received');

  const ActivityType(this.wire);

  final String wire;

  static ActivityType fromWire(String v) => ActivityType.values.firstWhere(
        (e) => e.wire == v,
        orElse: () => ActivityType.newLead,
      );
}

/// A headline number on the growth grid or dashboard.
class MetricPoint {
  const MetricPoint({
    required this.key,
    required this.label,
    required this.value,
    this.delta,
    this.suffix,
  });

  final String key;
  final String label;

  /// Already formatted for display, e.g. "142", "4.8".
  final String value;

  /// Trend chip text, e.g. "+12%", "Top Rated", "92% conn.".
  final String? delta;

  /// Trailing detail, e.g. "(142)" review count beside a rating.
  final String? suffix;

  factory MetricPoint.fromJson(Map<String, dynamic> json) => MetricPoint(
        key: json['key'] as String,
        label: json['label'] as String,
        value: json['value'].toString(),
        delta: json['delta'] as String?,
        suffix: json['suffix'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'key': key,
        'label': label,
        'value': value,
        'delta': delta,
        'suffix': suffix,
      };
}

/// One day in the lead-velocity series.
class VelocityPoint {
  const VelocityPoint({
    required this.label,
    required this.value,
    this.isPeak = false,
  });

  /// Weekday initial, e.g. "M".
  final String label;

  final int value;
  final bool isPeak;

  factory VelocityPoint.fromJson(Map<String, dynamic> json) => VelocityPoint(
        label: json['label'] as String,
        value: json['value'] as int,
        isPeak: json['is_peak'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'label': label,
        'value': value,
        'is_peak': isPeak,
      };
}

/// The weekly chart plus its header and footer copy.
class LeadVelocity {
  const LeadVelocity({
    required this.points,
    required this.total,
    required this.peakLabel,
    required this.deltaLabel,
    required this.dailyAverage,
  });

  final List<VelocityPoint> points;

  /// Leads in the window, e.g. 46.
  final int total;

  /// e.g. "Peak on Fri".
  final String peakLabel;

  /// e.g. "+18%".
  final String deltaLabel;

  /// e.g. "Avg 6.5 leads/day".
  final String dailyAverage;

  factory LeadVelocity.fromJson(Map<String, dynamic> json) => LeadVelocity(
        points: ((json['points'] as List<dynamic>?) ?? [])
            .map((p) => VelocityPoint.fromJson(p as Map<String, dynamic>))
            .toList(),
        total: json['total'] as int? ?? 0,
        peakLabel: json['peak_label'] as String? ?? '',
        deltaLabel: json['delta_label'] as String? ?? '',
        dailyAverage: json['daily_average'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'points': points.map((p) => p.toJson()).toList(),
        'total': total,
        'peak_label': peakLabel,
        'delta_label': deltaLabel,
        'daily_average': dailyAverage,
      };
}

/// A row in the recent-activity feed.
class ActivityEvent {
  const ActivityEvent({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.occurredAt,
  });

  final String id;
  final ActivityType type;
  final String title;
  final String subtitle;
  final DateTime occurredAt;

  factory ActivityEvent.fromJson(Map<String, dynamic> json) => ActivityEvent(
        id: json['id'] as String,
        type: ActivityType.fromWire(json['type'] as String? ?? 'new_lead'),
        title: json['title'] as String,
        subtitle: json['subtitle'] as String? ?? '',
        occurredAt: DateTime.parse(json['occurred_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.wire,
        'title': title,
        'subtitle': subtitle,
        'occurred_at': occurredAt.toIso8601String(),
      };
}

/// Everything the growth screen renders in one payload.
class GrowthStats {
  const GrowthStats({
    required this.range,
    required this.metrics,
    required this.velocity,
    required this.activity,
  });

  final StatsRange range;
  final List<MetricPoint> metrics;
  final LeadVelocity velocity;
  final List<ActivityEvent> activity;

  factory GrowthStats.fromJson(Map<String, dynamic> json) => GrowthStats(
        range: StatsRange.fromWire(json['range'] as String? ?? 'this_month'),
        metrics: ((json['metrics'] as List<dynamic>?) ?? [])
            .map((m) => MetricPoint.fromJson(m as Map<String, dynamic>))
            .toList(),
        velocity: LeadVelocity.fromJson(
          (json['velocity'] as Map<String, dynamic>?) ?? const {},
        ),
        activity: ((json['activity'] as List<dynamic>?) ?? [])
            .map((a) => ActivityEvent.fromJson(a as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'range': range.wire,
        'metrics': metrics.map((m) => m.toJson()).toList(),
        'velocity': velocity.toJson(),
        'activity': activity.map((a) => a.toJson()).toList(),
      };
}
