import 'lead.dart';

/// The contract the lead screens depend on.
///
/// Mirrors the `/v1/leads` endpoints in `docs/API_SPEC.md` one-to-one, so
/// the HTTP implementation is a drop-in replacement for the mock.
abstract interface class LeadsRepository {
  /// `GET /v1/leads?status=&page=`
  Future<List<Lead>> fetchLeads({LeadStatus? status, int page = 1});

  /// `GET /v1/leads/{id}`
  Future<Lead> fetchLead(String id);

  /// `GET /v1/leads/summary`
  Future<LeadInboxSummary> fetchSummary();

  /// `POST /v1/leads/{id}/accept` — reveals the customer phone number.
  Future<Lead> acceptLead(String id);

  /// `POST /v1/leads/{id}/decline`
  Future<Lead> declineLead(String id, {String? reason});

  /// `POST /v1/leads/{id}/quote`
  Future<Lead> submitQuote(String id, {required int amount, String? note});
}
