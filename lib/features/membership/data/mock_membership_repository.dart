import '../../../core/reference/reference_data.dart';
import '../domain/membership_repository.dart';
import '../domain/plan.dart';

/// Plan catalogue and checkout maths.
///
/// The three Stitch membership screens each name and price the tiers
/// differently; the catalogue is modelled as server-driven and seeded with
/// the payment screen's set, which is the most complete of the three.
class MockMembershipRepository implements MembershipRepository {
  MockMembershipRepository();

  static Duration get _latency => const Duration(milliseconds: 420);

  /// Promo codes the mock accepts.
  static const _promos = <String, PromoCode>{
    'WELCOMEPRO': PromoCode(
      code: 'WELCOMEPRO',
      discount: 200,
      description: 'Welcome offer',
    ),
    'INFIO500': PromoCode(
      code: 'INFIO500',
      discount: 500,
      description: 'Referral bonus',
    ),
  };

  static final _plans = <MembershipPlan>[
    const MembershipPlan(
      id: 'plan_basic',
      name: 'Basic Starter',
      eyebrow: 'Free Tier',
      tagline: 'Standard profile with basic visibility',
      monthlyPrice: 0,
      annualMonthlyPrice: 0,
      isFree: true,
      leadQuota: 5,
      features: [
        PlanFeature(text: 'customer leads / month', boldPrefix: '5'),
        PlanFeature(text: 'Standard directory profile listing'),
        PlanFeature(text: 'Standard support'),
        PlanFeature(text: 'Verified Pro Badge', included: false),
        PlanFeature(text: 'Detailed Analytics & Instant Alerts', included: false),
      ],
    ),
    const MembershipPlan(
      id: 'plan_growth_pro',
      name: 'Growth Pro',
      eyebrow: 'Signature Tier',
      tagline: 'Recommended for solo service pros',
      monthlyPrice: 999,
      annualMonthlyPrice: 799,
      isRecommended: true,
      ribbonLabel: 'Most Popular',
      features: [
        PlanFeature(text: 'direct customer lead inquiries', boldPrefix: 'Unlimited'),
        PlanFeature(
          text: 'Verified Pro Trust Badge on search profile',
          highlighted: true,
          badge: 'PRO',
        ),
        PlanFeature(text: 'priority lead dispatch', boldPrefix: '15-min'),
        PlanFeature(text: 'on all completed bookings', boldPrefix: '0% Commission'),
        PlanFeature(text: 'Detailed growth & performance analytics'),
      ],
    ),
    const MembershipPlan(
      id: 'plan_elite',
      name: 'Elite Enterprise',
      eyebrow: 'Enterprise',
      tagline: 'Top #1 listing, up to 5 staff accounts & WhatsApp CRM',
      monthlyPrice: 2499,
      annualMonthlyPrice: 1999,
      features: [
        PlanFeature(text: 'Everything in Growth Pro'),
        PlanFeature(
          text: 'Top #1 placement in your locality',
          highlighted: true,
          badge: 'Top Tier',
        ),
        PlanFeature(text: 'staff accounts', boldPrefix: 'Up to 5'),
        PlanFeature(text: 'WhatsApp CRM integration'),
        PlanFeature(text: 'Dedicated account manager'),
      ],
    ),
  ];

  Membership _membership = Membership(
    planId: 'plan_growth_pro',
    planName: 'Pro Growth Plan',
    cycle: BillingCycle.monthly,
    leadsUsed: 12,
    leadQuota: 20,
    renewsOn: DateTime(2023, 10, 15),
  );

  @override
  Future<List<MembershipPlan>> fetchPlans() async {
    await Future<void>.delayed(_latency);
    return List.unmodifiable(_plans);
  }

  @override
  Future<Membership> fetchMembership() async {
    await Future<void>.delayed(_latency);
    return _membership;
  }

  @override
  Future<PromoCode?> validatePromo(String code) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    return _promos[code.trim().toUpperCase()];
  }

  @override
  Future<OrderPreview> previewOrder({
    required String planId,
    required BillingCycle cycle,
    String? promoCode,
  }) async {
    await Future<void>.delayed(_latency);

    final plan = _plans.firstWhere(
      (p) => p.id == planId,
      orElse: () => throw StateError('Plan $planId not found'),
    );

    final promo = promoCode == null
        ? null
        : _promos[promoCode.trim().toUpperCase()];

    // List price before any discount. The annual cycle is billed up front
    // but quoted against the monthly list price, matching the design.
    final subtotal = plan.monthlyPrice.toDouble();
    final discount = promo?.discount ?? 0;
    final taxable = (subtotal - discount).clamp(0, double.infinity).toDouble();
    final gst = taxable * ReferenceData.gstPercent / 100;
    final total = taxable + gst;

    final cycleLabel = cycle == BillingCycle.annual ? 'Annual Access' : 'Monthly';

    return OrderPreview(
      planId: plan.id,
      cycle: cycle,
      promo: promo,
      lines: [
        OrderLine(label: '${plan.name} ($cycleLabel)', amount: subtotal),
        if (promo != null)
          OrderLine(
            label: 'Promo Discount',
            amount: -discount,
            isDiscount: true,
          ),
        OrderLine(
          label: 'Statutory GST (${ReferenceData.gstPercent}%)',
          amount: double.parse(gst.toStringAsFixed(2)),
        ),
      ],
      total: double.parse(total.toStringAsFixed(2)),
    );
  }

  @override
  Future<Membership> purchase({
    required String planId,
    required BillingCycle cycle,
    required PaymentMethod method,
    String? promoCode,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 1100));

    final plan = _plans.firstWhere((p) => p.id == planId);
    final now = DateTime.now();

    _membership = Membership(
      planId: plan.id,
      planName: plan.name,
      cycle: cycle,
      leadsUsed: 0,
      leadQuota: plan.leadQuota,
      renewsOn: cycle == BillingCycle.annual
          ? DateTime(now.year + 1, now.month, now.day)
          : DateTime(now.year, now.month + 1, now.day),
    );
    return _membership;
  }
}
