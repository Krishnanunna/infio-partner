import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/di/repositories.dart';
import '../../../core/format/money.dart';
import '../../../core/theme/gradients.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/app_bars.dart';
import '../../../shared/widgets/chips.dart';
import '../../../shared/widgets/corner_ribbon.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../../shared/widgets/segmented_pill.dart';
import '../domain/plan.dart';
import 'membership_providers.dart';

/// Plan selection and checkout in one compact screen.
///
/// Mirrors `partner_plan_payment_compact_mobile`.
class PaymentScreen extends ConsumerStatefulWidget {
  const PaymentScreen({super.key});

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  bool _paying = false;

  Future<void> _pay(String planId, BillingCycle cycle) async {
    if (_paying) return;
    setState(() => _paying = true);

    try {
      await ref.read(membershipRepositoryProvider).purchase(
            planId: planId,
            cycle: cycle,
            method: ref.read(paymentMethodProvider),
            promoCode: ref.read(appliedPromoProvider),
          );
      if (!mounted) return;

      ref.invalidate(membershipProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Membership activated')),
      );
      context.go('/dashboard');
    } catch (_) {
      if (mounted) {
        setState(() => _paying = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment failed. Please try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final plans = ref.watch(plansProvider);
    final cycle = ref.watch(billingCycleProvider);
    final preview = ref.watch(orderPreviewProvider);
    final selectedId = ref.watch(selectedPlanProvider);
    final method = ref.watch(paymentMethodProvider);

    return Scaffold(
      appBar: StandaloneAppBar(
        title: 'Upgrade Membership',
        subtitle: 'InFio Partner Pro',
        titleStyle: AppText.title15.copyWith(fontWeight: FontWeight.w700),
        statusChip: const StatusChip.success(
          label: '100% Safe',
          icon: Symbols.verified_user,
          iconFill: 1,
          dense: true,
        ),
      ),
      body: plans.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const Center(child: Text('Could not load plans.')),
        data: (list) {
          final paid = list.where((p) => !p.isFree).toList();
          final free = list.where((p) => p.isFree).toList();
          final selected = selectedId ??
              paid
                  .firstWhere(
                    (p) => p.isRecommended,
                    orElse: () => paid.first,
                  )
                  .id;

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.stackMd,
              AppSpacing.gridGutter,
              AppSpacing.stackMd,
              AppSpacing.stackLg,
            ),
            children: [
              _heroRow(cycle, paid),
              const SizedBox(height: AppSpacing.gridGutter),
              for (final plan in paid) ...[
                _SelectablePlanRow(
                  plan: plan,
                  cycle: cycle,
                  selected: plan.id == selected,
                  compact: !plan.isRecommended,
                  onTap: () =>
                      ref.read(selectedPlanProvider.notifier).set(plan.id),
                ),
                const SizedBox(height: AppSpacing.stackSm),
              ],
              for (final plan in free) _CurrentPlanRow(plan: plan),
              const SizedBox(height: AppSpacing.gridGutter),
              preview.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) =>
                    const Text('Could not calculate your order total.'),
                data: (p) => _summaryCard(p),
              ),
              const SizedBox(height: AppSpacing.gridGutter),
              _paymentMethods(method),
              const SizedBox(height: AppSpacing.stackMd),
              _trustRow(),
            ],
          );
        },
      ),
      bottomNavigationBar: preview.value == null
          ? null
          : _dock(preview.requireValue, cycle),
    );
  }

  Widget _heroRow(BillingCycle cycle, List<MembershipPlan> paid) {
    final savings =
        paid.isEmpty ? 20 : paid.first.annualSavingsPercent;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choose your plan',
                style: AppText.titleMd.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '0% commission & verified direct leads',
                style: AppText.label11.copyWith(fontWeight: FontWeight.w400),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 170,
          child: SegmentedPill<BillingCycle>(
            value: cycle,
            height: 38,
            radius: AppRadius.md,
            padding: 3,
            trackColor: AppColors.surfaceContainerHigh,
            showBorder: false,
            onChanged: (v) => ref.read(billingCycleProvider.notifier).set(v),
            options: [
              const SegmentOption(value: BillingCycle.monthly, label: 'Monthly'),
              SegmentOption(
                value: BillingCycle.annual,
                label: 'Annual',
                badge: '-$savings%',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _summaryCard(OrderPreview preview) {
    return GlassCard(
      radius: AppRadius.md,
      padding: const EdgeInsets.all(AppSpacing.stackMd),
      child: Column(
        children: [
          if (preview.promo != null) ...[
            _promoBanner(preview.promo!),
            const SizedBox(height: 12),
          ],
          for (final line in preview.lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      line.label,
                      style: AppText.body13.copyWith(
                        color: line.isDiscount
                            ? AppColors.successDark
                            : AppColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Text(
                    line.isDiscount
                        ? '-${Money.rupeesPaise(line.amount.abs())}'
                        : Money.rupeesPaise(line.amount),
                    style: AppText.body13.copyWith(
                      color: line.isDiscount
                          ? AppColors.successDark
                          : AppColors.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          const Divider(),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 5,
                  children: [
                    Text(
                      'Total Payable',
                      style: AppText.title15.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text('(Incl. taxes)', style: AppText.label10),
                  ],
                ),
              ),
              Text(
                Money.rupeesPaise(preview.total),
                style: AppText.titleMd.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _promoBanner(PromoCode promo) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primaryFixed.withValues(alpha: 0.35),
        borderRadius: AppRadius.brBase,
        border: Border.all(
          color: AppColors.primaryFixedDim.withValues(alpha: 0.6),
        ),
      ),
      child: Row(
        children: [
          const IconTile(
            icon: Symbols.local_offer,
            size: 26,
            iconSize: 14,
            radius: AppRadius.sm,
            background: AppColors.surfaceContainerLowest,
            foreground: AppColors.primary,
            fill: 1,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              promo.code,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.label11.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.onSurface,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(width: 6),
          StatusChip.success(
            label: '-${Money.rupees(promo.discount)} APPLIED',
            dense: true,
            radius: AppRadius.sm,
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => ref.read(appliedPromoProvider.notifier).set(null),
            child: Text(
              'Change',
              style: AppText.label11.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _paymentMethods(PaymentMethod current) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Payment Method',
          style: AppText.label11.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        for (final m in PaymentMethod.values)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _PaymentMethodRow(
              method: m,
              selected: m == current,
              onTap: () => ref.read(paymentMethodProvider.notifier).set(m),
            ),
          ),
      ],
    );
  }

  Widget _trustRow() {
    Widget item(IconData icon, String label, Color color) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color, fill: 1),
            const SizedBox(width: 3),
            Text(
              label,
              style: AppText.label10.copyWith(
                fontSize: 9.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );

    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 4,
      children: [
        item(Symbols.lock, '256-bit SSL Encrypted', AppColors.success),
        Text('•', style: AppText.label10),
        item(Symbols.verified_user, 'RBI Compliant', AppColors.primary),
        Text('•', style: AppText.label10),
        Text(
          '7-Day Refund',
          style: AppText.label10.copyWith(
            fontSize: 9.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _dock(OrderPreview preview, BillingCycle cycle) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.97),
        border: const Border(
          top: BorderSide(color: AppColors.outlineVariant),
        ),
        boxShadow: AppShadows.dock,
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('TOTAL TO PAY', style: AppText.label10),
                  Text(
                    Money.rupeesPaise(preview.total),
                    style: AppText.titleMd.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: GradientButton(
                  label: 'Pay & Activate Membership',
                  icon: Symbols.arrow_forward,
                  height: 46,
                  busy: _paying,
                  textStyle: AppText.label11.copyWith(fontSize: 13.5),
                  onPressed: () => _pay(preview.planId, cycle),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectablePlanRow extends StatelessWidget {
  const _SelectablePlanRow({
    required this.plan,
    required this.cycle,
    required this.selected,
    required this.compact,
    required this.onTap,
  });

  final MembershipPlan plan;
  final BillingCycle cycle;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final price = plan.priceFor(cycle);

    if (compact) {
      return GlassCard(
        radius: AppRadius.md,
        onTap: onTap,
        padding: const EdgeInsets.all(12),
        borderColor: selected
            ? AppColors.primaryContainer
            : AppColors.outlineVariant.withValues(alpha: 0.6),
        borderWidth: selected ? 2 : 1,
        child: Row(
          children: [
            const IconTile(
              icon: Symbols.domain,
              size: 28,
              iconSize: 15,
              radius: AppRadius.base,
              background: AppColors.surfaceContainerHigh,
              foreground: AppColors.onSurfaceVariant,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          plan.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.body13.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurface,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        Money.rupees(price),
                        style: AppText.label11.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text('/mo', style: AppText.label10),
                    ],
                  ),
                  const SizedBox(height: 1),
                  Text(
                    plan.tagline,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.label10.copyWith(
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            _radio(selected),
          ],
        ),
      );
    }

    return Stack(
      children: [
        GlassCard(
          radius: AppRadius.md,
          onTap: onTap,
          padding: const EdgeInsets.all(12),
          borderColor: selected
              ? AppColors.primaryContainer
              : AppColors.outlineVariant.withValues(alpha: 0.6),
          borderWidth: selected ? 2 : 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const IconTile(
                    icon: Symbols.rocket_launch,
                    size: 28,
                    iconSize: 15,
                    radius: AppRadius.base,
                    background: AppColors.primaryFixed,
                    foreground: AppColors.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plan.name,
                          style: AppText.body13.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.onSurface,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          plan.tagline,
                          style: AppText.label10.copyWith(
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _radio(selected),
                ],
              ),
              const SizedBox(height: 10),
              const Divider(),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Flexible(
                    child: Text(
                      Money.rupees(price),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.title20.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Text('/mo', style: AppText.label11),
                  const SizedBox(width: 8),
                  if (cycle == BillingCycle.annual)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: StatusChip.primary(
                        label: 'Billed annually '
                            '(${Money.rupees(plan.annualTotal)})',
                        dense: true,
                        radius: AppRadius.sm,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              for (final feature in plan.features.take(3))
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Symbols.check_circle,
                        size: 15,
                        color: AppColors.primary,
                        fill: 1,
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            style: AppText.label11.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                            children: [
                              if (feature.boldPrefix != null)
                                TextSpan(
                                  text: '${feature.boldPrefix} ',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primary,
                                  ),
                                ),
                              TextSpan(text: feature.text),
                            ],
                          ),
                        ),
                      ),
                    ],
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
              icon: Symbols.local_fire_department,
              radius: AppRadius.base,
            ),
          ),
      ],
    );
  }

  Widget _radio(bool on) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: on ? AppColors.primary : AppColors.surfaceContainerLowest,
        shape: BoxShape.circle,
        border: Border.all(
          color: on ? AppColors.primary : AppColors.outlineVariant,
          width: 2,
        ),
      ),
      child: on
          ? const Icon(Symbols.check, size: 13, color: Colors.white)
          : null,
    );
  }
}

class _CurrentPlanRow extends StatelessWidget {
  const _CurrentPlanRow({required this.plan});

  final MembershipPlan plan;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.slate100.withValues(alpha: 0.7),
        borderRadius: AppRadius.brMd,
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Row(
        children: [
          const Icon(
            Symbols.badge,
            size: 17,
            color: AppColors.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              plan.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.label11.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
            ),
          ),
          const SizedBox(width: 8),
          StatusChip(
            label: 'Current Plan',
            dense: true,
            radius: AppRadius.sm,
            background: AppColors.surfaceContainerLowest,
            foreground: AppColors.secondary,
            borderColor: AppColors.outlineVariant,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              '${plan.leadQuota ?? 0} leads/mo • Free',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: AppText.label11.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentMethodRow extends StatelessWidget {
  const _PaymentMethodRow({
    required this.method,
    required this.selected,
    required this.onTap,
  });

  final PaymentMethod method;
  final bool selected;
  final VoidCallback onTap;

  IconData get _icon => switch (method) {
        PaymentMethod.upi => Symbols.qr_code_scanner,
        PaymentMethod.card => Symbols.credit_card,
        PaymentMethod.netbankingWallet => Symbols.account_balance,
      };

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: AppRadius.md,
      onTap: onTap,
      padding: const EdgeInsets.all(11),
      borderColor: selected
          ? AppColors.primaryContainer
          : AppColors.outlineVariant.withValues(alpha: 0.6),
      borderWidth: selected ? 2 : 1,
      child: Row(
        children: [
          IconTile(
            icon: _icon,
            size: 26,
            iconSize: 15,
            radius: AppRadius.sm,
            background: selected
                ? AppColors.primaryFixed
                : AppColors.surfaceContainerHigh,
            foreground:
                selected ? AppColors.primary : AppColors.onSurfaceVariant,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      method.label,
                      style: AppText.body13.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                    ),
                    if (method == PaymentMethod.upi) ...[
                      const SizedBox(width: 6),
                      const StatusChip.primarySolid(
                        label: 'Fastest',
                        radius: AppRadius.sm,
                      ),
                    ],
                  ],
                ),
                if (method.subtitle != null) ...[
                  const SizedBox(height: 1),
                  Text(
                    method.subtitle!,
                    style: AppText.label10.copyWith(
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.primary
                  : AppColors.surfaceContainerLowest,
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.outlineVariant,
                width: 2,
              ),
            ),
            child: selected
                ? const Icon(Symbols.check, size: 13, color: Colors.white)
                : null,
          ),
        ],
      ),
    );
  }
}
