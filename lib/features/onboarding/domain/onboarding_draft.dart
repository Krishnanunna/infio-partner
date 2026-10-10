import '../../profile/domain/partner.dart';

/// Everything the 4-step wizard collects, persisted between steps so
/// "Save Draft & Exit" can resume later.
class OnboardingDraft {
  const OnboardingDraft({
    this.businessName = '',
    this.ownerName = '',
    this.entityType = EntityType.soleProprietor,
    this.phone = '',
    this.phoneVerified = false,
    this.whatsappAlerts = true,
    this.email = '',
    this.cityId,
    this.referralCode = '',
    this.categorySlug,
    this.specializations = const {},
    this.experienceBand,
    this.serviceDescription = '',
    this.shopName = '',
    this.street = '',
    this.landmark = '',
    this.pincode = '',
    this.latitude,
    this.longitude,
    this.locality,
    this.serviceRadiusKm = 15,
    this.coverPhotoPath,
    this.portfolioPaths = const [],
    this.selectedPlanId,
    this.currentStep = 1,
    this.completedSteps = const {},
  });

  // Step 1 — basic registration
  final String businessName;
  final String ownerName;
  final EntityType entityType;
  final String phone;
  final bool phoneVerified;
  final bool whatsappAlerts;
  final String email;
  final String? cityId;
  final String referralCode;

  // Step 2 — expertise, address, coverage
  final String? categorySlug;
  final Set<String> specializations;
  final String? experienceBand;
  final String serviceDescription;
  final String shopName;
  final String street;
  final String landmark;
  final String pincode;
  final double? latitude;
  final double? longitude;
  final String? locality;
  final double serviceRadiusKm;

  // Step 3 — photos
  final String? coverPhotoPath;
  final List<String> portfolioPaths;

  // Step 4 — plan
  final String? selectedPlanId;

  final int currentStep;
  final Set<int> completedSteps;

  /// Max portfolio slots, per the design's five-slot grid.
  static const portfolioSlots = 5;

  bool get step1Valid =>
      businessName.trim().isNotEmpty &&
      ownerName.trim().isNotEmpty &&
      phone.trim().isNotEmpty &&
      cityId != null;

  bool get step2Valid =>
      categorySlug != null &&
      experienceBand != null &&
      shopName.trim().isNotEmpty &&
      street.trim().isNotEmpty &&
      pincode.trim().length == 6;

  bool get step3Valid => coverPhotoPath != null;

  bool get step4Valid => selectedPlanId != null;

  OnboardingDraft copyWith({
    String? businessName,
    String? ownerName,
    EntityType? entityType,
    String? phone,
    bool? phoneVerified,
    bool? whatsappAlerts,
    String? email,
    String? cityId,
    String? referralCode,
    String? categorySlug,
    Set<String>? specializations,
    String? experienceBand,
    String? serviceDescription,
    String? shopName,
    String? street,
    String? landmark,
    String? pincode,
    double? latitude,
    double? longitude,
    String? locality,
    double? serviceRadiusKm,
    String? coverPhotoPath,
    List<String>? portfolioPaths,
    String? selectedPlanId,
    int? currentStep,
    Set<int>? completedSteps,
  }) {
    return OnboardingDraft(
      businessName: businessName ?? this.businessName,
      ownerName: ownerName ?? this.ownerName,
      entityType: entityType ?? this.entityType,
      phone: phone ?? this.phone,
      phoneVerified: phoneVerified ?? this.phoneVerified,
      whatsappAlerts: whatsappAlerts ?? this.whatsappAlerts,
      email: email ?? this.email,
      cityId: cityId ?? this.cityId,
      referralCode: referralCode ?? this.referralCode,
      categorySlug: categorySlug ?? this.categorySlug,
      specializations: specializations ?? this.specializations,
      experienceBand: experienceBand ?? this.experienceBand,
      serviceDescription: serviceDescription ?? this.serviceDescription,
      shopName: shopName ?? this.shopName,
      street: street ?? this.street,
      landmark: landmark ?? this.landmark,
      pincode: pincode ?? this.pincode,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      locality: locality ?? this.locality,
      serviceRadiusKm: serviceRadiusKm ?? this.serviceRadiusKm,
      coverPhotoPath: coverPhotoPath ?? this.coverPhotoPath,
      portfolioPaths: portfolioPaths ?? this.portfolioPaths,
      selectedPlanId: selectedPlanId ?? this.selectedPlanId,
      currentStep: currentStep ?? this.currentStep,
      completedSteps: completedSteps ?? this.completedSteps,
    );
  }

  /// Clears the cover photo, which [copyWith] cannot express.
  OnboardingDraft withoutCoverPhoto() => OnboardingDraft(
        businessName: businessName,
        ownerName: ownerName,
        entityType: entityType,
        phone: phone,
        phoneVerified: phoneVerified,
        whatsappAlerts: whatsappAlerts,
        email: email,
        cityId: cityId,
        referralCode: referralCode,
        categorySlug: categorySlug,
        specializations: specializations,
        experienceBand: experienceBand,
        serviceDescription: serviceDescription,
        shopName: shopName,
        street: street,
        landmark: landmark,
        pincode: pincode,
        latitude: latitude,
        longitude: longitude,
        locality: locality,
        serviceRadiusKm: serviceRadiusKm,
        coverPhotoPath: null,
        portfolioPaths: portfolioPaths,
        selectedPlanId: selectedPlanId,
        currentStep: currentStep,
        completedSteps: completedSteps,
      );

  factory OnboardingDraft.fromJson(Map<String, dynamic> json) =>
      OnboardingDraft(
        businessName: json['business_name'] as String? ?? '',
        ownerName: json['owner_name'] as String? ?? '',
        entityType: EntityType.fromWire(
          json['entity_type'] as String? ?? 'sole_proprietor',
        ),
        phone: json['phone'] as String? ?? '',
        phoneVerified: json['phone_verified'] as bool? ?? false,
        whatsappAlerts: json['whatsapp_alerts'] as bool? ?? true,
        email: json['email'] as String? ?? '',
        cityId: json['city_id'] as String?,
        referralCode: json['referral_code'] as String? ?? '',
        categorySlug: json['category_slug'] as String?,
        specializations: ((json['specializations'] as List<dynamic>?) ?? [])
            .map((e) => e as String)
            .toSet(),
        experienceBand: json['experience_band'] as String?,
        serviceDescription: json['service_description'] as String? ?? '',
        shopName: json['shop_name'] as String? ?? '',
        street: json['street'] as String? ?? '',
        landmark: json['landmark'] as String? ?? '',
        pincode: json['pincode'] as String? ?? '',
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        locality: json['locality'] as String?,
        serviceRadiusKm: (json['service_radius_km'] as num?)?.toDouble() ?? 15,
        coverPhotoPath: json['cover_photo_path'] as String?,
        portfolioPaths: ((json['portfolio_paths'] as List<dynamic>?) ?? [])
            .map((e) => e as String)
            .toList(),
        selectedPlanId: json['selected_plan_id'] as String?,
        currentStep: json['current_step'] as int? ?? 1,
        completedSteps: ((json['completed_steps'] as List<dynamic>?) ?? [])
            .map((e) => e as int)
            .toSet(),
      );

  Map<String, dynamic> toJson() => {
        'business_name': businessName,
        'owner_name': ownerName,
        'entity_type': entityType.wire,
        'phone': phone,
        'phone_verified': phoneVerified,
        'whatsapp_alerts': whatsappAlerts,
        'email': email,
        'city_id': cityId,
        'referral_code': referralCode,
        'category_slug': categorySlug,
        'specializations': specializations.toList(),
        'experience_band': experienceBand,
        'service_description': serviceDescription,
        'shop_name': shopName,
        'street': street,
        'landmark': landmark,
        'pincode': pincode,
        'latitude': latitude,
        'longitude': longitude,
        'locality': locality,
        'service_radius_km': serviceRadiusKm,
        'cover_photo_path': coverPhotoPath,
        'portfolio_paths': portfolioPaths,
        'selected_plan_id': selectedPlanId,
        'current_step': currentStep,
        'completed_steps': completedSteps.toList()..sort(),
      };
}

/// Mirrors `/v1/partners/me/onboarding` in `docs/API_SPEC.md`.
abstract interface class OnboardingRepository {
  /// `GET /v1/partners/me/onboarding`
  Future<OnboardingDraft> loadDraft();

  /// `PATCH /v1/partners/me/onboarding`
  Future<void> saveDraft(OnboardingDraft draft);

  /// `POST /v1/partners/me/onboarding/steps/{n}`
  Future<OnboardingDraft> submitStep(int step, OnboardingDraft draft);

  /// `POST /v1/partners/me/onboarding/complete`
  Future<void> complete(OnboardingDraft draft);

  /// Clears the locally cached draft.
  Future<void> clear();
}
