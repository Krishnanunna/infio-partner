import '../domain/partner.dart';
import '../domain/partner_repository.dart';

/// The seed partner, taken verbatim from the Stitch screens so the built UI
/// matches the renders.
///
/// The exports name the business both "Apex Aircon Works" (onboarding) and
/// "FixIt Pro" (dashboard, growth). Reconciled to Apex Aircon Works, per the
/// plan's normalization decision.
class MockPartnerRepository implements PartnerRepository {
  MockPartnerRepository() : _partner = _seed();

  Partner _partner;

  static Duration get _latency => const Duration(milliseconds: 380);

  static Partner _seed() => Partner(
        id: 'ptr_1001',
        ownerName: 'Ramesh Kumar',
        businessName: 'Apex Aircon Works',
        phone: '+91 98490 23114',
        email: 'ramesh.apex@gmail.com',
        entityType: EntityType.soleProprietor,
        cityId: 'hyderabad',
        cityLabel: 'Hyderabad & Secunderabad, Telangana',
        address: const BusinessAddress(
          shopName: 'Apex Aircon Works',
          street: 'Plot 28, Road No. 3, KPHB Phase 1',
          landmark: 'Opposite Metro Pillar 742',
          pincode: '500072',
          locality: 'KPHB Colony, Kukatpally',
          city: 'Hyderabad',
          latitude: 17.4934,
          longitude: 78.3995,
          serviceRadiusKm: 15,
        ),
        categorySlug: 'ac_repair',
        specializations: const [
          'Split AC',
          'Window AC',
          'Gas Charging',
          'PCB Diagnostics',
        ],
        experienceBand: '3-5 Years',
        serviceDescription:
            '5+ years specializing in multi-brand inverter AC installation, '
            'jet cleaning, and compressor repair.',
        rating: 4.9,
        reviewCount: 142,
        completionRate: 98,
        memberSince: DateTime(2023, 5, 1),
        verification: VerificationStatus.verified,
        phoneVerified: true,
        isOnline: true,
        whatsappAlerts: true,
        photoCount: 8,
        activeServiceCount: 4,
        referralCredits: 500,
        onboarding: const OnboardingProgress(
          currentStep: 2,
          completedSteps: {1},
        ),
      );

  @override
  Future<Partner> fetchPartner() async {
    await Future<void>.delayed(_latency);
    return _partner;
  }

  @override
  Future<Partner> updatePartner(Partner partner) async {
    await Future<void>.delayed(_latency);
    _partner = partner;
    return _partner;
  }

  @override
  Future<Partner> setOnline(bool online) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    _partner = _partner.copyWith(isOnline: online);
    return _partner;
  }

  @override
  Future<ReferralValidation> validateReferral(String code) async {
    await Future<void>.delayed(_latency);
    final normalized = code.trim().toUpperCase();
    if (normalized.isEmpty) {
      return const ReferralValidation(
        valid: false,
        message: 'Enter a referral code',
      );
    }
    // The design promises a ₹500 bonus for a valid partner code.
    if (normalized.length >= 6) {
      return const ReferralValidation(
        valid: true,
        bonusAmount: 500,
        message: '₹500 bonus applied',
      );
    }
    return const ReferralValidation(
      valid: false,
      message: 'That code is not recognised',
    );
  }
}
