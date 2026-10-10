import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/di/repositories.dart';
import '../../../core/reference/reference_data.dart';
import '../../../core/theme/gradients.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/app_bars.dart';
import '../../../shared/widgets/bottom_dock.dart';
import '../../../shared/widgets/chips.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../../shared/widgets/section_card.dart';
import '../../profile/domain/partner.dart';
import '../domain/onboarding_draft.dart';
import 'onboarding_controller.dart';
import 'widgets/next_step_callout.dart';

/// Step 1 of 4 — owner identity, contact details and operating city.
///
/// Mirrors `step_1_partner_basic_registration`.
class Step1BasicScreen extends ConsumerStatefulWidget {
  const Step1BasicScreen({super.key});

  @override
  ConsumerState<Step1BasicScreen> createState() => _Step1BasicScreenState();
}

class _Step1BasicScreenState extends ConsumerState<Step1BasicScreen> {
  final _business = TextEditingController();
  final _owner = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _referral = TextEditingController();

  bool _hydrated = false;
  String? _referralMessage;
  bool _referralValid = false;

  @override
  void dispose() {
    _business.dispose();
    _owner.dispose();
    _phone.dispose();
    _email.dispose();
    _referral.dispose();
    super.dispose();
  }

  void _hydrate(OnboardingDraft draft) {
    if (_hydrated) return;
    _hydrated = true;
    _business.text = draft.businessName;
    _owner.text = draft.ownerName;
    _phone.text = draft.phone.replaceAll('+91', '').trim();
    _email.text = draft.email;
    _referral.text = draft.referralCode;
  }

  OnboardingController get _controller =>
      ref.read(onboardingControllerProvider.notifier);

  Future<void> _validateReferral() async {
    final result = await ref
        .read(partnerRepositoryProvider)
        .validateReferral(_referral.text);
    if (!mounted) return;
    setState(() {
      _referralValid = result.valid;
      _referralMessage = result.message;
    });
  }

  Future<void> _continue(OnboardingDraft draft) async {
    await _controller.submitStep(1);
    if (mounted) context.push('/onboarding/step2');
  }

  @override
  Widget build(BuildContext context) {
    final draftAsync = ref.watch(onboardingControllerProvider);

    return draftAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => const Scaffold(
        body: Center(child: Text('Could not start onboarding.')),
      ),
      data: (draft) {
        _hydrate(draft);

        return Scaffold(
          appBar: const WizardAppBar(title: 'Partner Onboarding', step: 1),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.containerMargin,
              AppSpacing.stackMd,
              AppSpacing.containerMargin,
              AppSpacing.stackLg,
            ),
            children: [
              _title(),
              const SizedBox(height: AppSpacing.containerMargin),
              _identityCard(draft),
              const SizedBox(height: AppSpacing.containerMargin),
              _contactCard(draft),
              const SizedBox(height: AppSpacing.containerMargin),
              _referralCard(draft),
              const SizedBox(height: AppSpacing.containerMargin),
              const NextStepCallout(
                icon: Symbols.alt_route,
                stepLabel: 'STEP 2',
                title: 'Next: Business Details & Address',
                body: "In the next step, you'll specify your trade categories, "
                    'address, and service radius.',
              ),
              const SizedBox(height: AppSpacing.stackMd),
              _signInRow(context),
            ],
          ),
          bottomNavigationBar: BottomDock(
            child: GradientButton(
              label: 'Continue to Step 2',
              icon: Symbols.arrow_forward,
              gradient: AppGradients.ctaVertical,
              enabled: draft.step1Valid,
              onPressed: () => _continue(draft),
            ),
          ),
        );
      },
    );
  }

  Widget _title() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Symbols.verified_user,
              size: 15,
              color: AppColors.primary,
            ),
            const SizedBox(width: 5),
            Text(
              'Verified Partner Network',
              style: AppText.label11.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Basic Details & Account',
          style: AppText.headlineLgMobile.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          'Register your business identity to start receiving high-paying '
          'local customer leads.',
          style: AppText.bodySm,
        ),
      ],
    );
  }

  Widget _identityCard(OnboardingDraft draft) {
    return SectionCard(
      icon: Symbols.domain_verification,
      title: 'Owner & Business Identity',
      subtitle: 'Core commercial registration',
      children: [
        FieldLabel(
          label: 'Business / Agency Name',
          required: true,
          hint: 'Publicly displayed',
          child: TextField(
            controller: _business,
            decoration: const InputDecoration(
              hintText: 'e.g., Apex Aircon Works',
              prefixIcon: Icon(Symbols.storefront, size: 19),
            ),
            onChanged: (v) => _controller.edit((d) => d.copyWith(businessName: v)),
          ),
        ),
        FieldLabel(
          label: 'Owner / Partner Full Name',
          required: true,
          child: TextField(
            controller: _owner,
            decoration: const InputDecoration(
              hintText: 'e.g., Ramesh Kumar',
              prefixIcon: Icon(Symbols.person, size: 19),
            ),
            onChanged: (v) => _controller.edit((d) => d.copyWith(ownerName: v)),
          ),
        ),
        FieldLabel(
          label: 'Business Entity Type',
          child: Row(
            children: [
              for (final type in EntityType.values) ...[
                Expanded(
                  child: _EntityChip(
                    type: type,
                    selected: draft.entityType == type,
                    onTap: () =>
                        _controller.edit((d) => d.copyWith(entityType: type)),
                  ),
                ),
                if (type != EntityType.values.last) const SizedBox(width: 8),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _contactCard(OnboardingDraft draft) {
    return SectionCard(
      icon: Symbols.chat_bubble_outline,
      title: 'Contact & Communications',
      subtitle: 'Direct consumer lead routing',
      children: [
        FieldLabel(
          label: 'Mobile Number',
          required: true,
          hint: 'Primary Login & SMS',
          child: TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            maxLength: 10,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              counterText: '',
              prefixIcon: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Center(
                  widthFactor: 1,
                  child: Text('🇮🇳 +91'),
                ),
              ),
              suffixIcon: draft.phoneVerified
                  ? const Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: Center(
                        widthFactor: 1,
                        child: StatusChip.success(
                          label: 'Verified',
                          icon: Symbols.check_circle,
                          iconFill: 1,
                          dense: true,
                        ),
                      ),
                    )
                  : null,
            ),
            onChanged: (v) => _controller.edit((d) => d.copyWith(phone: v)),
          ),
        ),
        _whatsappOptIn(draft),
        FieldLabel(
          label: 'Email Address',
          hint: 'Monthly GST Invoices',
          child: TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              hintText: 'e.g., ramesh.apex@gmail.com',
              prefixIcon: Icon(Symbols.mail, size: 19),
            ),
            onChanged: (v) => _controller.edit((d) => d.copyWith(email: v)),
          ),
        ),
      ],
    );
  }

  Widget _whatsappOptIn(OnboardingDraft draft) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow.withValues(alpha: 0.7),
        borderRadius: AppRadius.brMd,
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Symbols.forum,
                size: 20,
                color: AppColors.whatsapp,
                fill: 1,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Instant WhatsApp Alerts',
                      style: AppText.title15.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Receive new booking requests, emergency repair chats, '
                      'and daily earnings on WhatsApp.',
                      style: AppText.label10.copyWith(
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: draft.whatsappAlerts,
                onChanged: (v) =>
                    _controller.edit((d) => d.copyWith(whatsappAlerts: v)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Symbols.done_all,
                size: 14,
                color: AppColors.onSurfaceVariant,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  'Same as registered phone',
                  style: AppText.label10.copyWith(fontWeight: FontWeight.w500),
                ),
              ),
              GestureDetector(
                onTap: () {},
                child: Text(
                  'Change Number',
                  style: AppText.label10.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _referralCard(OnboardingDraft draft) {
    return SectionCard(
      icon: Symbols.location_city,
      title: 'Referral & City Hub',
      subtitle: 'Regional partner dispatch center',
      children: [
        FieldLabel(
          label: 'Operating City / Region',
          required: true,
          child: DropdownButtonFormField<String>(
            initialValue: draft.cityId,
            isExpanded: true,
            decoration: const InputDecoration(
              prefixIcon: Icon(Symbols.near_me, size: 19),
            ),
            icon: const Icon(Symbols.expand_more),
            items: [
              for (final city in ReferenceData.cities)
                DropdownMenuItem(
                  value: city.id,
                  child: Text(
                    city.label,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.body13.copyWith(color: AppColors.onSurface),
                  ),
                ),
            ],
            onChanged: (v) => _controller.edit((d) => d.copyWith(cityId: v)),
          ),
        ),
        FieldLabel(
          label: 'Referral Code (Optional)',
          badge: const StatusChip(
            label: 'Earn ₹500 bonus',
            icon: Symbols.redeem,
            dense: true,
            background: AppColors.tertiaryFixed,
            foreground: AppColors.onTertiaryFixedVariant,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _referral,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  hintText: 'Enter 6-digit partner code',
                  prefixIcon: const Icon(Symbols.confirmation_number, size: 19),
                  suffixIcon: TextButton(
                    onPressed: _validateReferral,
                    child: const Text('Apply'),
                  ),
                ),
                onChanged: (v) =>
                    _controller.edit((d) => d.copyWith(referralCode: v)),
              ),
              if (_referralMessage != null) ...[
                const SizedBox(height: 6),
                Text(
                  _referralMessage!,
                  style: AppText.label11.copyWith(
                    color: _referralValid
                        ? AppColors.success
                        : AppColors.error,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _signInRow(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text('Already registered as a partner? ', style: AppText.body13),
        GestureDetector(
          onTap: () => context.push('/login'),
          child: Text(
            'Sign In',
            style: AppText.body13.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _EntityChip extends StatelessWidget {
  const _EntityChip({
    required this.type,
    required this.selected,
    required this.onTap,
  });

  final EntityType type;
  final bool selected;
  final VoidCallback onTap;

  IconData get _icon => switch (type) {
        EntityType.soleProprietor => Symbols.person_pin,
        EntityType.partnershipLlp => Symbols.corporate_fare,
        EntityType.individual => Symbols.handyman,
      };

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primaryFixed.withValues(alpha: 0.5)
              : AppColors.surfaceContainerLowest,
          borderRadius: AppRadius.brBase,
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              _icon,
              size: 20,
              color: selected ? AppColors.primary : AppColors.onSurfaceVariant,
            ),
            const SizedBox(height: 5),
            Text(
              type.label,
              textAlign: TextAlign.center,
              style: AppText.label10.copyWith(
                fontSize: 9.5,
                color:
                    selected ? AppColors.primary : AppColors.onSurfaceVariant,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
