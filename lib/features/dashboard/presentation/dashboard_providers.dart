import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/repositories.dart';
import '../../leads/domain/lead.dart';
import '../../membership/domain/plan.dart';
import '../../profile/domain/partner.dart';

/// Everything the home screen renders.
///
/// The API exposes this as a single `GET /v1/partners/me/dashboard` so the
/// screen is one round trip; the mock composes it from the individual
/// repositories.
class DashboardData {
  const DashboardData({
    required this.partner,
    required this.membership,
    required this.recentLeads,
    required this.newLeadsToday,
  });

  final Partner partner;
  final Membership membership;
  final List<Lead> recentLeads;
  final int newLeadsToday;
}

final dashboardProvider = FutureProvider<DashboardData>((ref) async {
  final partner = await ref.watch(partnerRepositoryProvider).fetchPartner();
  final membership =
      await ref.watch(membershipRepositoryProvider).fetchMembership();
  final leads = await ref
      .watch(leadsRepositoryProvider)
      .fetchLeads(status: LeadStatus.newLead);
  final summary = await ref.watch(leadsRepositoryProvider).fetchSummary();

  return DashboardData(
    partner: partner,
    membership: membership,
    recentLeads: leads.take(2).toList(),
    newLeadsToday: summary.counts[LeadStatus.newLead] ?? leads.length,
  );
});

/// Toggles the "Online" availability pill in the header.
final availabilityProvider =
    AsyncNotifierProvider<AvailabilityController, bool>(
  AvailabilityController.new,
);

class AvailabilityController extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final partner = await ref.watch(partnerRepositoryProvider).fetchPartner();
    return partner.isOnline;
  }

  Future<void> toggle() async {
    final next = !(state.value ?? true);
    state = AsyncValue.data(next);
    await ref.read(partnerRepositoryProvider).setOnline(next);
    ref.invalidate(dashboardProvider);
  }
}
