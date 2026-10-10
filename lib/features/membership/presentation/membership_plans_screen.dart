import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/format/money.dart';
import '../../../core/theme/gradients.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/app_bars.dart';
import '../../../shared/widgets/bottom_dock.dart';
import '../../../shared/widgets/chips.dart';
import '../../../shared/widgets/corner_ribbon.dart';
import '../../../shared/widgets/feature_row.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../../shared/widgets/segmented_pill.dart';
import '../domain/plan.dart';
import 'membership_providers.dart';

/// Which of the two plan screens from the designs to render.
///
/// The exports differ only in the app bar, hero copy, default billing cycle,
/// CTA label and trailing banner, so one screen covers both.
enum PlanScreenMode { wizardStep4, manage }

class MembershipPlansScreen extends ConsumerStatefulWidget {
  const MembershipPlansScreen({super.key, required this.mode});

  final PlanScreenMode mode;

  @override
  ConsumerState<MembershipPlansScreen> createState() =>
      _MembershipPlansScreenState();
}

class _MembershipPlansScreenState extends ConsumerState<MembershipPlansScreen> {
  bool _appliedDefaultCycle = false;

  bool get _isWizard => widget.mode == PlanScreenMode.wizardStep4;

  @override
  Widget build(BuildContext context) {
    final plans = ref.watch(plansProvider);
    final cycle = ref.watch(billingCycleProvider);
    final selectedId = ref.watch(selectedPlanProvider);
    final membership = ref.watch(membershipProvider).value;

    // The wizard defaults to Monthly, the manage screen to Annual.
    if (!_appliedDefaultCycle) {
      _appliedDefaultCycle = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(billingCycleProvider.notifier).set(_isWizard ? BillingCycle.monthly : BillingCycle.annual);
      });
    }

    return Scaffold(
      appBar: _isWizard
          ? const WizardAppBar(title: 'Partner Onboarding', step: 4)
          : StandaloneAppBar(
              title: 'Membership & Growth',
              titleStyle: AppText.titleMd.copyWith(fontWeight: FontWeight.w700),
              statusChip: StatusChip.primary(
                label: 'Active: ${membership?.planName ?? 'Basic'}',
                dense: true,
              ),
            ),
      body: plans.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const Center(child: Text('Could not load plans.')),
        data: (list) {
          final selected = selectedId ??
              list
                  .firstWhere(
                    (p) => p.isRecommended,
                    orElse: () => list.first,
                  )
                  .id;

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.stackMd,
              AppSpacing.stackMd,
              AppSpacing.stackMd,
              AppSpacing.stackLg,
            ),
            children: [
              _hero(),
              const SizedBox(height: AppSpacing.stackMd),
              _billingToggle(cycle, list),
              const SizedBox(height: AppSpacing.stackLg),
              for (final plan in list) ...[
                _PlanCard(
                  plan: plan,
                  cycle: cycle,
                  selected: plan.id == selected,
                  onTap: () =>
                      ref.read(selectedPlanProvider.notifier).set(plan.id),
                ),
                const SizedBox(height: AppSpacing.stackMd),
              ],
              _trailingBanner(),
            ],
          );
        },
      ),
      bottomNavigationBar: plans.value == null
          ? null
          : _dock(plans.requireValue, selectedId, cycle),
    );
  }

  Widget _hero() {
    if (_isWizard) {
      return Column(
        children: [
          Text(
            'Choose Your Growth Plan',
            textAlign: TextAlign.center,
            style: AppText.headlineLgMobile.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 23,
            ),
          ),
          const SizedBox(height: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: Text(
              'Simple flat-fee pricing. Upgrade or pause anytime to scale '
              'your service reach.',
              textAlign: TextAlign.center,
              style: AppText.body13,
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Symbols.bolt,
                size: 14,
                color: AppColors.primary,
                fill: 1,
              ),
              const SizedBox(width: 4),
              Text(
                'InFio Business Growth',
                style: AppText.label11.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Accelerate Your Business',
          style: AppText.headlineLgMobile.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: 23,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Unlock unlimited customer leads and top search placement in '
          'your city.',
          style: AppText.bodySm,
        ),
      ],
    );
  }

  Widget _billingToggle(BillingCycle cycle, List<MembershipPlan> plans) {
    final savings = plans
        .firstWhere(
          (p) => !p.isFree,
          orElse: () => plans.first,
        )
        .annualSavingsPercent;

    final toggle = SegmentedPill<BillingCycle>(
      value: cycle,
      height: _isWizard ? 42 : 48,
      radius: _isWizard ? AppRadius.full : AppRadius.lg,
      trackColor: _isWizard
          ? AppColors.surfaceContainerLow
          : AppColors.surfaceContainerHigh,
      selectedGradient: _isWizard ? AppGradients.cta : null,
      onChanged: (v) => ref.read(billingCycleProvider.notifier).set(v),
      options: [
        const SegmentOption(value: BillingCycle.monthly, label: 'Monthly'),
        SegmentOption(
          value: BillingCycle.annual,
          label: _isWizard ? 'Annual' : 'Yearly',
          badge: savings > 0 ? 'Save $savings%' : null,
        ),
      ],
    );

    // The wizard centres a narrow pill; the manage screen spans full width.
    return _isWizard
        ? Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 280),
              child: toggle,
            ),
          )
        : toggle;
  }

  Widget _trailingBanner() {
    if (_isWizard) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.stackMd),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: AppRadius.brLg,
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Symbols.verified_user,
              size: 20,
              color: AppColors.primary,
              fill: 1,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Verification by Admin will be prioritized upon plan '
                'activation to fast-track your Pro badge and top search '
                'placement.',
                style: AppText.body13,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.stackMd),
      decoration: BoxDecoration(
        color: AppColors.primaryFixed.withValues(alpha: 0.4),
        borderRadius: AppRadius.brLg,
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const IconTile(
            icon: Symbols.verified_user,
            size: 34,
            iconSize: 18,
            shape: BoxShape.circle,
            background: AppColors.surfaceContainerLowest,
            foreground: AppColors.primary,
            fill: 1,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: AppText.body13,
                children: const [
                  TextSpan(
                    text: '100% money-back guarantee within 7 days. ',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                  ),
                  TextSpan(text: 'Cancel or change plan anytime.'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dock(
    List<MembershipPlan> plans,
    String? selectedId,
    BillingCycle cycle,
  ) {
    final plan = plans.firstWhere(
      (p) => p.id == (selectedId ?? ''),
      orElse: () => plans.firstWhere(
        (p) => p.isRecommended,
        orElse: () => plans.first,
      ),
    );

    final price = plan.priceFor(cycle);
    final label = _isWizard
        ? 'Select ${plan.name} (${Money.rupees(price)}/mo)'
        : 'Upgrade to ${plan.name}';

    return BottomDock(
      caption: _isWizard
          ? 'Instant activation • Cancel or switch plans anytime'
          : null,
      secondary: _isWizard
          ? null
          : TextButton(
              onPressed: () => context.canPop()
                  ? context.pop()
                  : context.go('/dashboard'),
              child: Text(
                'Keep Free Plan',
                style: AppText.body13.copyWith(
                  color: AppColors.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
      child: GradientButton(
        label: label,
        icon: Symbols.arrow_forward,
        height: 54,
        radius: _isWizard ? AppRadius.full : AppRadius.lg,
        gradient: _isWizard ? AppGradients.planCta : AppGradients.ctaDiagonal,
        enabled: !plan.isFree,
        onPressed: () {
          ref.read(selectedPlanProvider.notifier).set(plan.id);
          context.push('/checkout');
        },
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.cycle,
    required this.selected,
    required this.onTap,
  });

  final MembershipPlan plan;
  final BillingCycle cycle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final price = plan.priceFor(cycle);
    final showStrikethrough =
        cycle == BillingCycle.annual && plan.monthlyPrice > price;

    return Stack(
      children: [
        SolidCard(
          radius: AppRadius.lg,
          onTap: onTap,
          padding: const EdgeInsets.all(AppSpacing.stackMd),
          borderColor: selected
              ? AppColors.primary
              : AppColors.outlineVariant.withValues(alpha: 0.6),
          borderWidth: selected ? 2 : 1,
          gradient: selected
              ? LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.primaryFixed.withValues(alpha: 0.3),
                    AppColors.surfaceContainerLowest,
                  ],
                )
              : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (plan.eyebrow != null) ...[
                Text(
                  plan.eyebrow!.toUpperCase(),
                  style: AppText.label10.copyWith(
                    color: selected
                        ? AppColors.primary
                        : AppColors.onSurfaceVariant,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
              ],
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plan.name,
                          style: AppText.title20.copyWith(
                            fontWeight: FontWeight.w800,
                            fontSize: selected ? 20 : 18,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(plan.tagline, style: AppText.body13),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  _radio(),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 12),

              // Price row.
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Flexible(
                    child: Text(
                      Money.rupees(price),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.numeral.copyWith(
                        color: selected
                            ? AppColors.primary
                            : AppColors.onSurface,
                        fontSize: selected ? 28 : 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      cycle == BillingCycle.annual && !plan.isFree
                          ? '/month billed annually'
                          : '/month',
                      style: AppText.label11,
                    ),
                  ),
                  if (showStrikethrough) ...[
                    const SizedBox(width: 6),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        Money.rupees(plan.monthlyPrice),
                        style: AppText.label11.copyWith(
                          decoration: TextDecoration.lineThrough,
                          color: AppColors.outline,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 14),

              for (final feature in plan.features)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: FeatureRow(
                    text: feature.text,
                    boldPrefix: feature.boldPrefix,
                    included: feature.included,
                    highlighted: feature.highlighted,
                    badge: feature.badge,
                    icon: feature.highlighted ? Symbols.workspace_premium : null,
                  ),
                ),
            ],
          ),
        ),
        if (plan.ribbonLabel != null)
          Positioned(
            top: 0,
            right: 0,
            child: CornerRibbon(
              label: plan.ribbonLabel!,
              icon: Symbols.star,
              iconColor: AppColors.tertiaryFixedDim,
            ),
          ),
      ],
    );
  }

  Widget _radio() {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: selected ? AppColors.primary : Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(
          color: selected
              ? AppColors.primary
              : AppColors.outline.withValues(alpha: 0.5),
          width: 2,
        ),
      ),
      child: selected
          ? Center(
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            )
          : null,
    );
  }
}
