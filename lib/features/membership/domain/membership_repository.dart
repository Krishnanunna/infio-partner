import 'plan.dart';

/// Mirrors `/v1/plans` and `/v1/checkout` in `docs/API_SPEC.md`.
abstract interface class MembershipRepository {
  /// `GET /v1/plans`
  Future<List<MembershipPlan>> fetchPlans();

  /// `GET /v1/partners/me/membership`
  Future<Membership> fetchMembership();

  /// `POST /v1/checkout/preview` — the server computes every line item.
  Future<OrderPreview> previewOrder({
    required String planId,
    required BillingCycle cycle,
    String? promoCode,
  });

  /// `POST /v1/promo/validate`
  Future<PromoCode?> validatePromo(String code);

  /// `POST /v1/checkout/orders` then `/pay`.
  Future<Membership> purchase({
    required String planId,
    required BillingCycle cycle,
    required PaymentMethod method,
    String? promoCode,
  });
}
