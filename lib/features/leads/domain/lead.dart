import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/tokens.dart';

/// Where a lead sits in the partner's pipeline. Drives the inbox filter tabs.
enum LeadStatus {
  newLead('new', 'New'),
  contacted('contacted', 'Contacted'),
  missed('missed', 'Missed'),
  accepted('accepted', 'Accepted'),
  declined('declined', 'Declined'),
  quoted('quoted', 'Quoted');

  const LeadStatus(this.wire, this.label);

  /// The value exchanged with the API.
  final String wire;
  final String label;

  static LeadStatus fromWire(String value) => LeadStatus.values.firstWhere(
        (s) => s.wire == value,
        orElse: () => LeadStatus.newLead,
      );

  /// The three tabs the inbox exposes.
  static const inboxTabs = [newLead, contacted, missed];
}

/// How time-critical the job is. A separate axis from [LeadStatus].
enum LeadUrgency {
  urgent('urgent', 'Urgent'),
  standard('standard', 'Standard'),
  immediate('immediate', 'Immediate');

  const LeadUrgency(this.wire, this.label);

  final String wire;
  final String label;

  static LeadUrgency fromWire(String value) => LeadUrgency.values.firstWhere(
        (u) => u.wire == value,
        orElse: () => LeadUrgency.standard,
      );

  bool get isUrgent => this != LeadUrgency.standard;
}

/// A photo the customer attached to their request.
class LeadPhoto {
  const LeadPhoto({required this.id, required this.caption, this.url});

  final String id;

  /// Overlay chip text, e.g. "Unit 1".
  final String caption;

  final String? url;

  factory LeadPhoto.fromJson(Map<String, dynamic> json) => LeadPhoto(
        id: json['id'] as String,
        caption: json['caption'] as String? ?? '',
        url: json['url'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'caption': caption,
        if (url != null) 'url': url,
      };
}

/// A customer enquiry routed to the partner.
class Lead {
  const Lead({
    required this.id,
    required this.reference,
    required this.customerName,
    required this.serviceName,
    required this.categorySlug,
    required this.description,
    required this.locality,
    required this.distanceKm,
    required this.status,
    required this.urgency,
    required this.createdAt,
    this.customerVerified = false,
    this.customerPhone,
    this.contactRevealed = false,
    this.budgetMin,
    this.budgetMax,
    this.budgetIsFixed = false,
    this.suggestedQuote,
    this.preferredSlot,
    this.fullAddress,
    this.driveTime,
    this.expiresAt,
    this.photos = const [],
    this.viewedByOtherPros = 0,
    this.matchRate,
    this.quotedAmount,
  });

  final String id;

  /// Human-facing reference, e.g. "LD-8924".
  final String reference;

  /// Already abbreviated by the server for privacy, e.g. "John D.".
  final String customerName;

  final bool customerVerified;

  /// Null until the lead is accepted — the design gates this explicitly.
  final String? customerPhone;
  final bool contactRevealed;

  final String serviceName;
  final String categorySlug;

  /// The customer's own words, rendered as a quote.
  final String description;

  final String locality;
  final String? fullAddress;
  final double distanceKm;
  final String? driveTime;

  final int? budgetMin;
  final int? budgetMax;

  /// True when the customer named one price rather than a range.
  final bool budgetIsFixed;

  /// What the marketplace suggests the partner quote.
  final int? suggestedQuote;

  final String? preferredSlot;

  final LeadStatus status;
  final LeadUrgency urgency;

  final DateTime createdAt;

  /// Drives the mm:ss countdown badge on the inbox card.
  final DateTime? expiresAt;

  final List<LeadPhoto> photos;

  /// Competition signal: "3 other pros viewed this".
  final int viewedByOtherPros;

  /// e.g. "High Match Rate".
  final String? matchRate;

  /// Set once the partner submits a quote.
  final int? quotedAmount;

  Duration? remainingFrom(DateTime now) => expiresAt?.difference(now);

  /// Budget rendered the way the designs do: a range, or a single fixed value.
  String get budgetLabel {
    if (budgetMin == null) return '—';
    if (budgetIsFixed || budgetMax == null || budgetMax == budgetMin) {
      return '₹$budgetMin';
    }
    return '₹$budgetMin - ₹$budgetMax';
  }

  Lead copyWith({
    LeadStatus? status,
    bool? contactRevealed,
    String? customerPhone,
    int? quotedAmount,
  }) {
    return Lead(
      id: id,
      reference: reference,
      customerName: customerName,
      customerVerified: customerVerified,
      customerPhone: customerPhone ?? this.customerPhone,
      contactRevealed: contactRevealed ?? this.contactRevealed,
      serviceName: serviceName,
      categorySlug: categorySlug,
      description: description,
      locality: locality,
      fullAddress: fullAddress,
      distanceKm: distanceKm,
      driveTime: driveTime,
      budgetMin: budgetMin,
      budgetMax: budgetMax,
      budgetIsFixed: budgetIsFixed,
      suggestedQuote: suggestedQuote,
      preferredSlot: preferredSlot,
      status: status ?? this.status,
      urgency: urgency,
      createdAt: createdAt,
      expiresAt: expiresAt,
      photos: photos,
      viewedByOtherPros: viewedByOtherPros,
      matchRate: matchRate,
      quotedAmount: quotedAmount ?? this.quotedAmount,
    );
  }

  factory Lead.fromJson(Map<String, dynamic> json) => Lead(
        id: json['id'] as String,
        reference: json['reference'] as String,
        customerName: json['customer_name'] as String,
        customerVerified: json['customer_verified'] as bool? ?? false,
        customerPhone: json['customer_phone'] as String?,
        contactRevealed: json['contact_revealed'] as bool? ?? false,
        serviceName: json['service_name'] as String,
        categorySlug: json['category_slug'] as String,
        description: json['description'] as String? ?? '',
        locality: json['locality'] as String? ?? '',
        fullAddress: json['full_address'] as String?,
        distanceKm: (json['distance_km'] as num?)?.toDouble() ?? 0,
        driveTime: json['drive_time'] as String?,
        budgetMin: json['budget_min'] as int?,
        budgetMax: json['budget_max'] as int?,
        budgetIsFixed: json['budget_is_fixed'] as bool? ?? false,
        suggestedQuote: json['suggested_quote'] as int?,
        preferredSlot: json['preferred_slot'] as String?,
        status: LeadStatus.fromWire(json['status'] as String? ?? 'new'),
        urgency: LeadUrgency.fromWire(json['urgency'] as String? ?? 'standard'),
        createdAt: DateTime.parse(json['created_at'] as String),
        expiresAt: json['expires_at'] == null
            ? null
            : DateTime.parse(json['expires_at'] as String),
        photos: (json['photos'] as List<dynamic>? ?? [])
            .map((p) => LeadPhoto.fromJson(p as Map<String, dynamic>))
            .toList(),
        viewedByOtherPros: json['viewed_by_other_pros'] as int? ?? 0,
        matchRate: json['match_rate'] as String?,
        quotedAmount: json['quoted_amount'] as int?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'reference': reference,
        'customer_name': customerName,
        'customer_verified': customerVerified,
        'customer_phone': customerPhone,
        'contact_revealed': contactRevealed,
        'service_name': serviceName,
        'category_slug': categorySlug,
        'description': description,
        'locality': locality,
        'full_address': fullAddress,
        'distance_km': distanceKm,
        'drive_time': driveTime,
        'budget_min': budgetMin,
        'budget_max': budgetMax,
        'budget_is_fixed': budgetIsFixed,
        'suggested_quote': suggestedQuote,
        'preferred_slot': preferredSlot,
        'status': status.wire,
        'urgency': urgency.wire,
        'created_at': createdAt.toIso8601String(),
        'expires_at': expiresAt?.toIso8601String(),
        'photos': photos.map((p) => p.toJson()).toList(),
        'viewed_by_other_pros': viewedByOtherPros,
        'match_rate': matchRate,
        'quoted_amount': quotedAmount,
      };
}

/// The aggregate strip above the inbox feed.
class LeadInboxSummary {
  const LeadInboxSummary({
    required this.todayCount,
    required this.urgentCount,
    required this.averageResponse,
    required this.matchRate,
    required this.counts,
  });

  final int todayCount;
  final int urgentCount;

  /// e.g. "4 mins".
  final String averageResponse;

  /// e.g. "98%".
  final String matchRate;

  /// Per-status counts powering the filter tab badges.
  final Map<LeadStatus, int> counts;

  factory LeadInboxSummary.fromJson(Map<String, dynamic> json) {
    final raw = json['counts'] as Map<String, dynamic>? ?? {};
    return LeadInboxSummary(
      todayCount: json['today_count'] as int? ?? 0,
      urgentCount: json['urgent_count'] as int? ?? 0,
      averageResponse: json['average_response'] as String? ?? '—',
      matchRate: json['match_rate'] as String? ?? '—',
      counts: {
        for (final entry in raw.entries)
          LeadStatus.fromWire(entry.key): entry.value as int,
      },
    );
  }

  Map<String, dynamic> toJson() => {
        'today_count': todayCount,
        'urgent_count': urgentCount,
        'average_response': averageResponse,
        'match_rate': matchRate,
        'counts': {
          for (final entry in counts.entries) entry.key.wire: entry.value,
        },
      };
}

/// Presentation helpers that map a category slug to the icon and tint the
/// designs use. Kept beside the model so every screen renders a category
/// identically.
abstract final class LeadVisuals {
  static IconData icon(String categorySlug) => switch (categorySlug) {
        'ac_repair' => Symbols.ac_unit,
        'plumbing' => Symbols.plumbing,
        'electrical' => Symbols.electrical_services,
        'appliance_care' => Symbols.water_heater,
        'deep_cleaning' => Symbols.cleaning_services,
        'painting' => Symbols.format_paint,
        _ => Symbols.handyman,
      };

  static Color background(String categorySlug) => switch (categorySlug) {
        'ac_repair' => AppColors.primaryFixed,
        'plumbing' => AppColors.amberSurfaceAlt,
        'electrical' => AppColors.analyticsBlueSurface,
        'appliance_care' => AppColors.analyticsBlueSurface,
        _ => AppColors.surfaceContainer,
      };

  static Color foreground(String categorySlug) => switch (categorySlug) {
        'ac_repair' => AppColors.primary,
        'plumbing' => AppColors.amberText,
        'electrical' => AppColors.analyticsBlueDark,
        'appliance_care' => AppColors.analyticsBlueDark,
        _ => AppColors.primary,
      };
}
