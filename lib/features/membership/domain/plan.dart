/// Billing period for a membership plan.
enum BillingCycle {
  monthly('monthly', 'Monthly'),
  annual('annual', 'Annual');

  const BillingCycle(this.wire, this.label);

  final String wire;
  final String label;

  static BillingCycle fromWire(String v) => BillingCycle.values.firstWhere(
        (e) => e.wire == v,
        orElse: () => BillingCycle.monthly,
      );
}

/// How the customer pays.
enum PaymentMethod {
  upi('upi', 'Instant UPI', 'GPay, PhonePe, Paytm & QR'),
  card('card', 'Credit & Debit Cards', 'Visa, Mastercard, RuPay'),
  netbankingWallet('netbanking_wallet', 'Net Banking & Wallets', null);

  const PaymentMethod(this.wire, this.label, this.subtitle);

  final String wire;
  final String label;
  final String? subtitle;

  static PaymentMethod fromWire(String v) => PaymentMethod.values.firstWhere(
        (e) => e.wire == v,
        orElse: () => PaymentMethod.upi,
      );
}

/// A single bullet in a plan's feature list.
class PlanFeature {
  const PlanFeature({
    required this.text,
    this.boldPrefix,
    this.included = true,
    this.highlighted = false,
    this.badge,
  });

  final String text;

  /// Emphasised leading run, e.g. "Unlimited".
  final String? boldPrefix;

  final bool included;

  /// Renders in its own tinted sub-row.
  final bool highlighted;

  /// Trailing tier badge, e.g. "PRO", "Top Tier".
  final String? badge;

  factory PlanFeature.fromJson(Map<String, dynamic> json) => PlanFeature(
        text: json['text'] as String,
        boldPrefix: json['bold_prefix'] as String?,
        included: json['included'] as bool? ?? true,
        highlighted: json['highlighted'] as bool? ?? false,
        badge: json['badge'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'text': text,
        'bold_prefix': boldPrefix,
        'included': included,
        'highlighted': highlighted,
        'badge': badge,
      };
}

/// A membership tier from the server-driven catalogue.
///
/// The three Stitch screens each invent their own plan names and prices;
/// treating the catalogue as server-driven is what lets one screen render
/// all of them.
class MembershipPlan {
  const MembershipPlan({
    required this.id,
    required this.name,
    required this.tagline,
    required this.monthlyPrice,
    required this.annualMonthlyPrice,
    required this.features,
    this.eyebrow,
    this.ribbonLabel,
    this.isRecommended = false,
    this.isFree = false,
    this.leadQuota,
  });

  final String id;
  final String name;

  /// One-line descriptor under the name.
  final String tagline;

  /// Price per month when billed monthly.
  final int monthlyPrice;

  /// Effective per-month price when billed annually.
  final int annualMonthlyPrice;

  final List<PlanFeature> features;

  /// Small label above the name, e.g. "Signature Tier", "Free Tier".
  final String? eyebrow;

  /// Corner ribbon text, e.g. "MOST POPULAR".
  final String? ribbonLabel;

  final bool isRecommended;
  final bool isFree;

  /// Monthly lead allowance; null means unlimited.
  final int? leadQuota;

  /// Total charged up front for an annual subscription.
  int get annualTotal => annualMonthlyPrice * 12;

  /// Percentage saved by paying annually.
  int get annualSavingsPercent {
    if (monthlyPrice == 0) return 0;
    return (((monthlyPrice - annualMonthlyPrice) / monthlyPrice) * 100).round();
  }

  int priceFor(BillingCycle cycle) =>
      cycle == BillingCycle.annual ? annualMonthlyPrice : monthlyPrice;

  factory MembershipPlan.fromJson(Map<String, dynamic> json) => MembershipPlan(
        id: json['id'] as String,
        name: json['name'] as String,
        tagline: json['tagline'] as String? ?? '',
        monthlyPrice: json['monthly_price'] as int? ?? 0,
        annualMonthlyPrice: json['annual_monthly_price'] as int? ?? 0,
        features: ((json['features'] as List<dynamic>?) ?? [])
            .map((f) => PlanFeature.fromJson(f as Map<String, dynamic>))
            .toList(),
        eyebrow: json['eyebrow'] as String?,
        ribbonLabel: json['ribbon_label'] as String?,
        isRecommended: json['is_recommended'] as bool? ?? false,
        isFree: json['is_free'] as bool? ?? false,
        leadQuota: json['lead_quota'] as int?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'tagline': tagline,
        'monthly_price': monthlyPrice,
        'annual_monthly_price': annualMonthlyPrice,
        'features': features.map((f) => f.toJson()).toList(),
        'eyebrow': eyebrow,
        'ribbon_label': ribbonLabel,
        'is_recommended': isRecommended,
        'is_free': isFree,
        'lead_quota': leadQuota,
      };
}

/// The partner's live subscription.
class Membership {
  const Membership({
    required this.planId,
    required this.planName,
    required this.cycle,
    required this.leadsUsed,
    this.leadQuota,
    this.renewsOn,
    this.isActive = true,
  });

  final String planId;
  final String planName;
  final BillingCycle cycle;

  final int leadsUsed;

  /// Null means unlimited.
  final int? leadQuota;

  final DateTime? renewsOn;
  final bool isActive;

  int get leadsRemaining =>
      leadQuota == null ? 0 : (leadQuota! - leadsUsed).clamp(0, leadQuota!);

  double get quotaFraction =>
      leadQuota == null || leadQuota == 0 ? 0 : (leadsUsed / leadQuota!).clamp(0.0, 1.0);

  int get quotaPercent => (quotaFraction * 100).round();

  factory Membership.fromJson(Map<String, dynamic> json) => Membership(
        planId: json['plan_id'] as String,
        planName: json['plan_name'] as String,
        cycle: BillingCycle.fromWire(json['cycle'] as String? ?? 'monthly'),
        leadsUsed: json['leads_used'] as int? ?? 0,
        leadQuota: json['lead_quota'] as int?,
        renewsOn: json['renews_on'] == null
            ? null
            : DateTime.parse(json['renews_on'] as String),
        isActive: json['is_active'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {
        'plan_id': planId,
        'plan_name': planName,
        'cycle': cycle.wire,
        'leads_used': leadsUsed,
        'lead_quota': leadQuota,
        'renews_on': renewsOn?.toIso8601String(),
        'is_active': isActive,
      };
}

/// One row of the checkout order summary.
class OrderLine {
  const OrderLine({
    required this.label,
    required this.amount,
    this.isDiscount = false,
  });

  final String label;
  final double amount;
  final bool isDiscount;

  factory OrderLine.fromJson(Map<String, dynamic> json) => OrderLine(
        label: json['label'] as String,
        amount: (json['amount'] as num).toDouble(),
        isDiscount: json['is_discount'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'label': label,
        'amount': amount,
        'is_discount': isDiscount,
      };
}

/// A promo code the partner has applied.
class PromoCode {
  const PromoCode({
    required this.code,
    required this.discount,
    this.description,
  });

  final String code;
  final double discount;
  final String? description;

  factory PromoCode.fromJson(Map<String, dynamic> json) => PromoCode(
        code: json['code'] as String,
        discount: (json['discount'] as num).toDouble(),
        description: json['description'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'code': code,
        'discount': discount,
        'description': description,
      };
}

/// Server-computed checkout totals.
///
/// The payment mock's own figures are internally inconsistent, so the app
/// never derives these client-side.
class OrderPreview {
  const OrderPreview({
    required this.planId,
    required this.cycle,
    required this.lines,
    required this.total,
    this.promo,
    this.taxPercent = 18,
  });

  final String planId;
  final BillingCycle cycle;
  final List<OrderLine> lines;
  final double total;
  final PromoCode? promo;
  final int taxPercent;

  factory OrderPreview.fromJson(Map<String, dynamic> json) => OrderPreview(
        planId: json['plan_id'] as String,
        cycle: BillingCycle.fromWire(json['cycle'] as String? ?? 'monthly'),
        lines: ((json['lines'] as List<dynamic>?) ?? [])
            .map((l) => OrderLine.fromJson(l as Map<String, dynamic>))
            .toList(),
        total: (json['total'] as num).toDouble(),
        promo: json['promo'] == null
            ? null
            : PromoCode.fromJson(json['promo'] as Map<String, dynamic>),
        taxPercent: json['tax_percent'] as int? ?? 18,
      );

  Map<String, dynamic> toJson() => {
        'plan_id': planId,
        'cycle': cycle.wire,
        'lines': lines.map((l) => l.toJson()).toList(),
        'total': total,
        'promo': promo?.toJson(),
        'tax_percent': taxPercent,
      };
}
