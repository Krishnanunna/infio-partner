import 'growth_stats.dart';

/// Mirrors `/v1/partners/me/stats` in `docs/API_SPEC.md`.
abstract interface class GrowthRepository {
  /// `GET /v1/partners/me/stats?range=`
  Future<GrowthStats> fetchStats(StatsRange range);
}
