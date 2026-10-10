import 'partner.dart';

/// Mirrors `/v1/partners/me` in `docs/API_SPEC.md`.
abstract interface class PartnerRepository {
  /// `GET /v1/partners/me`
  Future<Partner> fetchPartner();

  /// `PATCH /v1/partners/me`
  Future<Partner> updatePartner(Partner partner);

  /// `PATCH /v1/partners/me/availability`
  Future<Partner> setOnline(bool online);

  /// `POST /v1/referrals/validate` — the Apply button beside a referral code.
  Future<ReferralValidation> validateReferral(String code);
}

/// Result of checking a referral code before submit.
class ReferralValidation {
  const ReferralValidation({
    required this.valid,
    this.bonusAmount,
    this.message,
  });

  final bool valid;
  final int? bonusAmount;
  final String? message;

  factory ReferralValidation.fromJson(Map<String, dynamic> json) =>
      ReferralValidation(
        valid: json['valid'] as bool? ?? false,
        bonusAmount: json['bonus_amount'] as int?,
        message: json['message'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'valid': valid,
        'bonus_amount': bonusAmount,
        'message': message,
      };
}
