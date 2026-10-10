import 'partner_service.dart';

/// Mirrors `/v1/partners/me/services` in `docs/API_SPEC.md`.
abstract interface class ServicesRepository {
  /// `GET /v1/partners/me/services`
  Future<List<PartnerService>> fetchServices({String? categorySlug, String? query});

  /// `POST /v1/partners/me/services`
  Future<PartnerService> createService(PartnerService service);

  /// `PATCH /v1/partners/me/services/{id}`
  Future<PartnerService> updateService(PartnerService service);

  /// `PATCH /v1/partners/me/services/{id}/status`
  Future<PartnerService> setStatus(String id, ServiceStatus status);

  /// `DELETE /v1/partners/me/services/{id}`
  Future<void> deleteService(String id);

  /// `GET` / `PATCH /v1/partners/me/catalog-visibility`
  Future<bool> fetchCatalogVisibility();
  Future<bool> setCatalogVisibility(bool visible);
}
