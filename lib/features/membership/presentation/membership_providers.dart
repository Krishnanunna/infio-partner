import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/repositories.dart';
import '../../../core/di/value_provider.dart';
import '../domain/plan.dart';

final plansProvider = FutureProvider<List<MembershipPlan>>((ref) {
  return ref.watch(membershipRepositoryProvider).fetchPlans();
});

final membershipProvider = FutureProvider<Membership>((ref) {
  return ref.watch(membershipRepositoryProvider).fetchMembership();
});

/// The billing cycle the plan and checkout screens share.
final billingCycleProvider = valueProvider<BillingCycle>(BillingCycle.annual);

/// The plan the partner has selected but not yet paid for.
final selectedPlanProvider = valueProvider<String?>(null);

/// The promo code currently applied at checkout.
final appliedPromoProvider = valueProvider<String?>('WELCOMEPRO');

/// The chosen payment method.
final paymentMethodProvider = valueProvider<PaymentMethod>(PaymentMethod.upi);

/// Server-computed order totals for the current selection.
final orderPreviewProvider = FutureProvider<OrderPreview>((ref) async {
  final planId = ref.watch(selectedPlanProvider);
  final cycle = ref.watch(billingCycleProvider);
  final promo = ref.watch(appliedPromoProvider);

  final plans = await ref.watch(plansProvider.future);
  final resolved = planId ??
      plans.firstWhere((p) => p.isRecommended, orElse: () => plans.first).id;

  return ref.watch(membershipRepositoryProvider).previewOrder(
        planId: resolved,
        cycle: cycle,
        promoCode: promo,
      );
});
