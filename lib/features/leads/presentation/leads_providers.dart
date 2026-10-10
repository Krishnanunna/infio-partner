import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/repositories.dart';
import '../../../core/di/value_provider.dart';
import '../domain/lead.dart';

/// Aggregate counts for the inbox banner and the Leads tab badge.
final leadSummaryProvider = FutureProvider<LeadInboxSummary>((ref) {
  return ref.watch(leadsRepositoryProvider).fetchSummary();
});

/// Leads filtered by the selected inbox tab.
final leadsListProvider =
    FutureProvider.family<List<Lead>, LeadStatus?>((ref, status) {
  return ref.watch(leadsRepositoryProvider).fetchLeads(status: status);
});

/// A single lead, for the detail screen.
final leadDetailProvider = FutureProvider.family<Lead, String>((ref, id) {
  return ref.watch(leadsRepositoryProvider).fetchLead(id);
});

/// Which tab the inbox is showing.
final selectedLeadTabProvider = valueProvider<LeadStatus>(LeadStatus.newLead);

/// Mutations. Each refreshes the list and summary so counts stay honest.
class LeadActions {
  LeadActions(this._ref);

  final Ref _ref;

  Future<Lead> accept(String id) async {
    final lead = await _ref.read(leadsRepositoryProvider).acceptLead(id);
    _invalidate(id);
    return lead;
  }

  Future<Lead> decline(String id) async {
    final lead = await _ref.read(leadsRepositoryProvider).declineLead(id);
    _invalidate(id);
    return lead;
  }

  Future<Lead> submitQuote(String id, {required int amount, String? note}) async {
    final lead = await _ref
        .read(leadsRepositoryProvider)
        .submitQuote(id, amount: amount, note: note);
    _invalidate(id);
    return lead;
  }

  void _invalidate(String id) {
    _ref.invalidate(leadSummaryProvider);
    _ref.invalidate(leadsListProvider);
    _ref.invalidate(leadDetailProvider(id));
  }
}

final leadActionsProvider = Provider<LeadActions>(LeadActions.new);
