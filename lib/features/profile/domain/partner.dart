/// Legal structure of the partner's business.
enum EntityType {
  soleProprietor('sole_proprietor', 'Sole Proprietor'),
  partnershipLlp('partnership_llp', 'Partnership / LLP'),
  individual('individual', 'Individual Freelance');

  const EntityType(this.wire, this.label);

  final String wire;
  final String label;

  static EntityType fromWire(String v) => EntityType.values.firstWhere(
        (e) => e.wire == v,
        orElse: () => EntityType.soleProprietor,
      );
}

/// Where the partner sits in admin review.
enum VerificationStatus {
  unverified('unverified', 'Unverified'),
  pendingAdminApproval('pending_admin_approval', 'Pending Admin Approval'),
  verified('verified', 'Verified'),
  rejected('rejected', 'Rejected');

  const VerificationStatus(this.wire, this.label);

  final String wire;
  final String label;

  static VerificationStatus fromWire(String v) =>
      VerificationStatus.values.firstWhere(
        (e) => e.wire == v,
        orElse: () => VerificationStatus.unverified,
      );
}

/// The workshop address plus the service-coverage settings from step 2.
class BusinessAddress {
  const BusinessAddress({
    required this.shopName,
    required this.street,
    required this.pincode,
    this.landmark,
    this.locality,
    this.city,
    this.latitude,
    this.longitude,
    this.serviceRadiusKm = 15,
  });

  final String shopName;
  final String street;
  final String? landmark;
  final String pincode;

  /// Reverse-geocoded label for the dropped pin, e.g. "KPHB Colony, Kukatpally".
  final String? locality;

  final String? city;
  final double? latitude;
  final double? longitude;

  /// 2-30 km, as the slider allows.
  final double serviceRadiusKm;

  String get formatted => [
        shopName,
        street,
        if (landmark != null && landmark!.isNotEmpty) landmark,
        pincode,
      ].join(', ');

  /// "17.4934° N, 78.3995° E"
  String get coordinateLabel {
    if (latitude == null || longitude == null) return '';
    final ns = latitude! >= 0 ? 'N' : 'S';
    final ew = longitude! >= 0 ? 'E' : 'W';
    return '${latitude!.abs().toStringAsFixed(4)}° $ns, '
        '${longitude!.abs().toStringAsFixed(4)}° $ew';
  }

  BusinessAddress copyWith({
    String? shopName,
    String? street,
    String? landmark,
    String? pincode,
    String? locality,
    String? city,
    double? latitude,
    double? longitude,
    double? serviceRadiusKm,
  }) {
    return BusinessAddress(
      shopName: shopName ?? this.shopName,
      street: street ?? this.street,
      landmark: landmark ?? this.landmark,
      pincode: pincode ?? this.pincode,
      locality: locality ?? this.locality,
      city: city ?? this.city,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      serviceRadiusKm: serviceRadiusKm ?? this.serviceRadiusKm,
    );
  }

  factory BusinessAddress.fromJson(Map<String, dynamic> json) =>
      BusinessAddress(
        shopName: json['shop_name'] as String? ?? '',
        street: json['street'] as String? ?? '',
        landmark: json['landmark'] as String?,
        pincode: json['pincode'] as String? ?? '',
        locality: json['locality'] as String?,
        city: json['city'] as String?,
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        serviceRadiusKm:
            (json['service_radius_km'] as num?)?.toDouble() ?? 15,
      );

  Map<String, dynamic> toJson() => {
        'shop_name': shopName,
        'street': street,
        'landmark': landmark,
        'pincode': pincode,
        'locality': locality,
        'city': city,
        'latitude': latitude,
        'longitude': longitude,
        'service_radius_km': serviceRadiusKm,
      };
}

/// How far through the 4-step wizard the partner is.
class OnboardingProgress {
  const OnboardingProgress({
    required this.currentStep,
    required this.completedSteps,
    this.totalSteps = 4,
  });

  final int currentStep;
  final Set<int> completedSteps;
  final int totalSteps;

  double get fraction => (completedSteps.length / totalSteps).clamp(0.0, 1.0);

  int get percent => (fraction * 100).round();

  bool get isComplete => completedSteps.length >= totalSteps;

  factory OnboardingProgress.fromJson(Map<String, dynamic> json) =>
      OnboardingProgress(
        currentStep: json['current_step'] as int? ?? 1,
        completedSteps: ((json['completed_steps'] as List<dynamic>?) ?? [])
            .map((e) => e as int)
            .toSet(),
        totalSteps: json['total_steps'] as int? ?? 4,
      );

  Map<String, dynamic> toJson() => {
        'current_step': currentStep,
        'completed_steps': completedSteps.toList()..sort(),
        'total_steps': totalSteps,
      };
}

/// The signed-in service professional.
class Partner {
  const Partner({
    required this.id,
    required this.ownerName,
    required this.businessName,
    required this.phone,
    required this.categorySlug,
    this.email,
    this.entityType = EntityType.soleProprietor,
    this.cityId,
    this.cityLabel,
    this.address,
    this.specializations = const [],
    this.experienceBand,
    this.serviceDescription,
    this.rating = 0,
    this.reviewCount = 0,
    this.completionRate = 0,
    this.memberSince,
    this.verification = VerificationStatus.unverified,
    this.phoneVerified = false,
    this.isOnline = true,
    this.whatsappAlerts = true,
    this.photoCount = 0,
    this.activeServiceCount = 0,
    this.referralCredits = 0,
    this.language = 'English (India)',
    this.onboarding = const OnboardingProgress(
      currentStep: 1,
      completedSteps: {},
    ),
  });

  final String id;
  final String ownerName;
  final String businessName;
  final String phone;
  final String? email;
  final EntityType entityType;

  final String? cityId;
  final String? cityLabel;
  final BusinessAddress? address;

  final String categorySlug;
  final List<String> specializations;
  final String? experienceBand;
  final String? serviceDescription;

  final double rating;
  final int reviewCount;

  /// Percentage of accepted jobs completed, e.g. 98.
  final int completionRate;

  final DateTime? memberSince;
  final VerificationStatus verification;
  final bool phoneVerified;

  /// Drives the "Online" pill on the dashboard header.
  final bool isOnline;

  final bool whatsappAlerts;
  final int photoCount;
  final int activeServiceCount;
  final int referralCredits;
  final String language;
  final OnboardingProgress onboarding;

  bool get isVerified => verification == VerificationStatus.verified;

  /// "Ramesh Kumar" -> "RK", used where the design shows initials.
  String get initials {
    final parts =
        ownerName.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  /// "Rajesh" from "Rajesh Kumar" — the dashboard greeting.
  String get firstName => ownerName.trim().split(RegExp(r'\s+')).first;

  Partner copyWith({
    String? ownerName,
    String? businessName,
    String? phone,
    String? email,
    EntityType? entityType,
    String? cityId,
    String? cityLabel,
    BusinessAddress? address,
    String? categorySlug,
    List<String>? specializations,
    String? experienceBand,
    String? serviceDescription,
    bool? isOnline,
    bool? whatsappAlerts,
    bool? phoneVerified,
    int? photoCount,
    int? activeServiceCount,
    VerificationStatus? verification,
    OnboardingProgress? onboarding,
    String? language,
  }) {
    return Partner(
      id: id,
      ownerName: ownerName ?? this.ownerName,
      businessName: businessName ?? this.businessName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      entityType: entityType ?? this.entityType,
      cityId: cityId ?? this.cityId,
      cityLabel: cityLabel ?? this.cityLabel,
      address: address ?? this.address,
      categorySlug: categorySlug ?? this.categorySlug,
      specializations: specializations ?? this.specializations,
      experienceBand: experienceBand ?? this.experienceBand,
      serviceDescription: serviceDescription ?? this.serviceDescription,
      rating: rating,
      reviewCount: reviewCount,
      completionRate: completionRate,
      memberSince: memberSince,
      verification: verification ?? this.verification,
      phoneVerified: phoneVerified ?? this.phoneVerified,
      isOnline: isOnline ?? this.isOnline,
      whatsappAlerts: whatsappAlerts ?? this.whatsappAlerts,
      photoCount: photoCount ?? this.photoCount,
      activeServiceCount: activeServiceCount ?? this.activeServiceCount,
      referralCredits: referralCredits,
      language: language ?? this.language,
      onboarding: onboarding ?? this.onboarding,
    );
  }

  factory Partner.fromJson(Map<String, dynamic> json) => Partner(
        id: json['id'] as String,
        ownerName: json['owner_name'] as String,
        businessName: json['business_name'] as String,
        phone: json['phone'] as String,
        email: json['email'] as String?,
        entityType:
            EntityType.fromWire(json['entity_type'] as String? ?? 'sole_proprietor'),
        cityId: json['city_id'] as String?,
        cityLabel: json['city_label'] as String?,
        address: json['address'] == null
            ? null
            : BusinessAddress.fromJson(
                json['address'] as Map<String, dynamic>),
        categorySlug: json['category_slug'] as String? ?? '',
        specializations: ((json['specializations'] as List<dynamic>?) ?? [])
            .map((e) => e as String)
            .toList(),
        experienceBand: json['experience_band'] as String?,
        serviceDescription: json['service_description'] as String?,
        rating: (json['rating'] as num?)?.toDouble() ?? 0,
        reviewCount: json['review_count'] as int? ?? 0,
        completionRate: json['completion_rate'] as int? ?? 0,
        memberSince: json['member_since'] == null
            ? null
            : DateTime.parse(json['member_since'] as String),
        verification: VerificationStatus.fromWire(
          json['verification_status'] as String? ?? 'unverified',
        ),
        phoneVerified: json['phone_verified'] as bool? ?? false,
        isOnline: json['is_online'] as bool? ?? true,
        whatsappAlerts: json['whatsapp_alerts'] as bool? ?? true,
        photoCount: json['photo_count'] as int? ?? 0,
        activeServiceCount: json['active_service_count'] as int? ?? 0,
        referralCredits: json['referral_credits'] as int? ?? 0,
        language: json['language'] as String? ?? 'English (India)',
        onboarding: OnboardingProgress.fromJson(
          (json['onboarding'] as Map<String, dynamic>?) ?? const {},
        ),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'owner_name': ownerName,
        'business_name': businessName,
        'phone': phone,
        'email': email,
        'entity_type': entityType.wire,
        'city_id': cityId,
        'city_label': cityLabel,
        'address': address?.toJson(),
        'category_slug': categorySlug,
        'specializations': specializations,
        'experience_band': experienceBand,
        'service_description': serviceDescription,
        'rating': rating,
        'review_count': reviewCount,
        'completion_rate': completionRate,
        'member_since': memberSince?.toIso8601String(),
        'verification_status': verification.wire,
        'phone_verified': phoneVerified,
        'is_online': isOnline,
        'whatsapp_alerts': whatsappAlerts,
        'photo_count': photoCount,
        'active_service_count': activeServiceCount,
        'referral_credits': referralCredits,
        'language': language,
        'onboarding': onboarding.toJson(),
      };
}
