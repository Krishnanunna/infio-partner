/// Static lookup data the forms depend on.
///
/// In production every list here comes from `/v1/ref/*`. They are seeded
/// locally so the app runs without a backend, and the shapes match the
/// documented endpoints exactly.
library;

/// An operating city the marketplace dispatches in.
class City {
  const City({required this.id, required this.label});

  final String id;
  final String label;

  factory City.fromJson(Map<String, dynamic> json) =>
      City(id: json['id'] as String, label: json['label'] as String);

  Map<String, dynamic> toJson() => {'id': id, 'label': label};
}

/// A trade category. The slug is the canonical taxonomy key — the Stitch
/// exports carried three competing vocabularies, and this is the one that
/// wins because it has stable machine values.
class ServiceCategory {
  const ServiceCategory({
    required this.slug,
    required this.label,
    required this.shortTag,
    this.specializations = const [],
  });

  final String slug;
  final String label;

  /// Compact chip label used on service cards, e.g. "AC Repair".
  final String shortTag;

  final List<String> specializations;

  factory ServiceCategory.fromJson(Map<String, dynamic> json) =>
      ServiceCategory(
        slug: json['slug'] as String,
        label: json['label'] as String,
        shortTag: json['short_tag'] as String? ?? json['label'] as String,
        specializations: ((json['specializations'] as List<dynamic>?) ?? [])
            .map((e) => e as String)
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'slug': slug,
        'label': label,
        'short_tag': shortTag,
        'specializations': specializations,
      };
}

abstract final class ReferenceData {
  static const cities = <City>[
    City(id: 'hyderabad', label: 'Hyderabad & Secunderabad, Telangana'),
    City(id: 'bengaluru', label: 'Bengaluru Urban, Karnataka'),
    City(id: 'chennai', label: 'Chennai Metropolitan, Tamil Nadu'),
    City(id: 'pune', label: 'Pune & PCMC, Maharashtra'),
  ];

  static const categories = <ServiceCategory>[
    ServiceCategory(
      slug: 'ac_repair',
      label: 'AC Repair & Maintenance',
      shortTag: 'AC Repair',
      specializations: [
        'Split AC',
        'Window AC',
        'Gas Charging',
        'PCB Diagnostics',
        'Inverter Systems',
        'Jet Pump Wash',
      ],
    ),
    ServiceCategory(
      slug: 'plumbing',
      label: 'Plumbing Solutions',
      shortTag: 'Plumbing',
      specializations: [
        'Pipe Leakage',
        'Sanitary Fitting',
        'Water Heater',
        'Motor & Pump',
        'Drain Cleaning',
      ],
    ),
    ServiceCategory(
      slug: 'electrical',
      label: 'Electrical & Wiring',
      shortTag: 'Electrical',
      specializations: [
        'House Wiring',
        'Switchboard',
        'Inverter & UPS',
        'Fan & Light',
        'MCB & Fuse',
      ],
    ),
    ServiceCategory(
      slug: 'deep_cleaning',
      label: 'Deep Cleaning & Sanitization',
      shortTag: 'Cleaning',
      specializations: [
        'Full Home',
        'Kitchen',
        'Bathroom',
        'Sofa & Carpet',
        'Pest Control',
      ],
    ),
    ServiceCategory(
      slug: 'appliance_care',
      label: 'Home Appliance Care',
      shortTag: 'Appliances',
      specializations: [
        'Washing Machine',
        'Refrigerator',
        'Microwave',
        'Water Purifier',
        'Geyser',
      ],
    ),
    ServiceCategory(
      slug: 'painting',
      label: 'Painting & Waterproofing',
      shortTag: 'Painting',
      specializations: [
        'Interior Painting',
        'Exterior Painting',
        'Waterproofing',
        'Texture & Stencil',
        'Wood Polish',
      ],
    ),
  ];

  /// Years-of-experience bands from the location step.
  static const experienceBands = <String>['1-2 Years', '3-5 Years', '5+ Years'];

  /// Estimated service durations from the add-service form.
  static const durations = <String>['30 mins', '45 mins', '1 hr', '2+ hrs'];

  /// Radius slider bounds, in km.
  static const minRadiusKm = 2.0;
  static const maxRadiusKm = 30.0;
  static const defaultRadiusKm = 15.0;

  /// Marketplace commission applied to a service price.
  static const commissionPercent = 10;

  /// GST applied at checkout.
  static const gstPercent = 18;

  static ServiceCategory? categoryBySlug(String slug) {
    for (final c in categories) {
      if (c.slug == slug) return c;
    }
    return null;
  }

  static String categoryLabel(String slug) =>
      categoryBySlug(slug)?.label ?? slug;

  static String categoryTag(String slug) =>
      categoryBySlug(slug)?.shortTag ?? slug;

  static City? cityById(String id) {
    for (final c in cities) {
      if (c.id == id) return c;
    }
    return null;
  }
}
