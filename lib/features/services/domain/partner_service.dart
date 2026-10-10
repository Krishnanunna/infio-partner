/// Whether the listed price is exact or a starting point.
enum PricingType {
  fixed('fixed', 'Fixed Price'),
  startingFrom('starting_from', 'Starting From');

  const PricingType(this.wire, this.label);

  final String wire;
  final String label;

  static PricingType fromWire(String v) => PricingType.values.firstWhere(
        (e) => e.wire == v,
        orElse: () => PricingType.fixed,
      );
}

/// Marketplace visibility of a single catalogue entry.
enum ServiceStatus {
  active('active', 'Active'),
  paused('paused', 'Paused'),
  draft('draft', 'Draft');

  const ServiceStatus(this.wire, this.label);

  final String wire;
  final String label;

  static ServiceStatus fromWire(String v) => ServiceStatus.values.firstWhere(
        (e) => e.wire == v,
        orElse: () => ServiceStatus.active,
      );
}

/// One offering in the partner's catalogue.
class PartnerService {
  const PartnerService({
    required this.id,
    required this.name,
    required this.description,
    required this.categorySlug,
    required this.categoryTag,
    required this.price,
    this.pricingType = PricingType.startingFrom,
    this.status = ServiceStatus.active,
    this.commissionPercent = 10,
    this.duration,
    this.turnaround,
    this.subType,
    this.imagePath,
  });

  final String id;
  final String name;
  final String description;

  /// Slug from the canonical category taxonomy, e.g. `ac_repair`.
  final String categorySlug;

  /// Short chip label shown on the card, e.g. "AC Repair", "Installation".
  final String categoryTag;

  final int price;
  final PricingType pricingType;
  final ServiceStatus status;

  /// Marketplace cut, shown live on the add-service form.
  final int commissionPercent;

  /// e.g. "45 mins", "1 hr".
  final String? duration;

  /// e.g. "Same Day".
  final String? turnaround;

  /// Sub-type chip, e.g. "Split AC".
  final String? subType;

  final String? imagePath;

  bool get isActive => status == ServiceStatus.active;

  /// "Starts at ₹499" or "₹499", matching the card treatment.
  String get priceLabel => pricingType == PricingType.startingFrom
      ? 'Starts at ₹$price'
      : '₹$price';

  /// What the partner keeps after commission.
  double get takeHome => price * (1 - commissionPercent / 100);

  double get commissionAmount => price * commissionPercent / 100;

  PartnerService copyWith({
    String? name,
    String? description,
    String? categorySlug,
    String? categoryTag,
    int? price,
    PricingType? pricingType,
    ServiceStatus? status,
    String? duration,
    String? turnaround,
    String? subType,
    String? imagePath,
  }) {
    return PartnerService(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      categorySlug: categorySlug ?? this.categorySlug,
      categoryTag: categoryTag ?? this.categoryTag,
      price: price ?? this.price,
      pricingType: pricingType ?? this.pricingType,
      status: status ?? this.status,
      commissionPercent: commissionPercent,
      duration: duration ?? this.duration,
      turnaround: turnaround ?? this.turnaround,
      subType: subType ?? this.subType,
      imagePath: imagePath ?? this.imagePath,
    );
  }

  factory PartnerService.fromJson(Map<String, dynamic> json) => PartnerService(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String? ?? '',
        categorySlug: json['category_slug'] as String? ?? '',
        categoryTag: json['category_tag'] as String? ?? '',
        price: json['price'] as int? ?? 0,
        pricingType:
            PricingType.fromWire(json['pricing_type'] as String? ?? 'fixed'),
        status: ServiceStatus.fromWire(json['status'] as String? ?? 'active'),
        commissionPercent: json['commission_percent'] as int? ?? 10,
        duration: json['duration'] as String?,
        turnaround: json['turnaround'] as String?,
        subType: json['sub_type'] as String?,
        imagePath: json['image_url'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'category_slug': categorySlug,
        'category_tag': categoryTag,
        'price': price,
        'pricing_type': pricingType.wire,
        'status': status.wire,
        'commission_percent': commissionPercent,
        'duration': duration,
        'turnaround': turnaround,
        'sub_type': subType,
        'image_url': imagePath,
      };
}
