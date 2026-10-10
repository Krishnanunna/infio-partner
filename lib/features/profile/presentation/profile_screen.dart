import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/di/repositories.dart';
import '../../../core/reference/reference_data.dart';
import '../../../core/theme/gradients.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/app_bars.dart';
import '../../../shared/widgets/chips.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../../shared/widgets/section_card.dart';
import '../../../shared/widgets/settings_row.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../membership/presentation/membership_providers.dart';
import '../../onboarding/presentation/onboarding_controller.dart';
import '../domain/partner.dart';

final profileProvider = FutureProvider<Partner>((ref) {
  return ref.watch(partnerRepositoryProvider).fetchPartner();
});

/// Account hub and the entry point to every edit flow.
///
/// Mirrors `partner_profile_account_native_mobile`.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  static const _appVersion = 'InFio Partner App v1.0.0 (Build 1)';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);

    return Scaffold(
      appBar: StandaloneAppBar(
        title: 'Account & Profile',
        showBack: false,
        titleStyle: AppText.titleMd.copyWith(fontWeight: FontWeight.w700),
        statusChip: const StatusChip(
          label: 'Partner',
          dense: true,
          radius: AppRadius.sm,
          background: Color(0x1A8A19D8),
          foreground: AppColors.primary,
        ),
        actions: [
          CircleIconButton(
            icon: Symbols.qr_code_2,
            background: Colors.transparent,
            onPressed: () {},
            tooltip: 'Share QR code',
          ),
          CircleIconButton(
            icon: Symbols.settings,
            background: Colors.transparent,
            onPressed: () {},
            tooltip: 'Settings',
          ),
        ],
      ),
      body: profile.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const Center(child: Text('Could not load profile.')),
        data: (partner) => ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.containerMargin,
            AppSpacing.stackMd,
            AppSpacing.containerMargin,
            100,
          ),
          children: [
            _IdentityCard(partner: partner),
            const SizedBox(height: AppSpacing.stackMd),
            if (!partner.onboarding.isComplete) ...[
              _OnboardingBanner(partner: partner),
              const SizedBox(height: AppSpacing.stackMd),
            ],
            _verificationGroup(context, partner),
            const SizedBox(height: AppSpacing.stackMd),
            _growthGroup(context, ref, partner),
            const SizedBox(height: AppSpacing.stackMd),
            _preferencesGroup(context, partner),
            const SizedBox(height: AppSpacing.stackMd),
            const _LogoutButton(),
            const SizedBox(height: AppSpacing.gridGutter),
            Text(
              '$_appVersion • Hyderabad, India',
              textAlign: TextAlign.center,
              style: AppText.label10.copyWith(
                fontWeight: FontWeight.w400,
                color: AppColors.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _group(List<Widget> rows) {
    return GlassCard(
      radius: AppRadius.lg,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            rows[i],
            if (i != rows.length - 1)
              Divider(
                height: 1,
                indent: 14,
                endIndent: 14,
                color: AppColors.outlineVariant.withValues(alpha: 0.4),
              ),
          ],
        ],
      ),
    );
  }

  Widget _verificationGroup(BuildContext context, Partner partner) {
    final address = partner.address;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel('Business Profile & Verification'),
        const SizedBox(height: 6),
        _group([
          SettingsRow(
            icon: Symbols.badge,
            title: 'Business Registration Info',
            subtitle: 'Step 1 details • ${partner.entityType.label}',
            trailing: const StatusChip(
              label: 'Verified',
              icon: Symbols.check_circle,
              iconFill: 1,
              dense: true,
              background: AppColors.surfaceContainer,
              foreground: AppColors.primary,
            ),
            onTap: () => context.push('/onboarding/step1'),
          ),
          SettingsRow(
            icon: Symbols.location_on,
            title: 'Service Area & Location',
            subtitle: address == null
                ? 'Not set'
                : '${address.locality ?? address.city} • '
                    '${address.serviceRadiusKm.round()} km coverage radius',
            onTap: () => context.push('/onboarding/step2'),
          ),
          SettingsRow(
            icon: Symbols.photo_library,
            title: 'Work Photos & Portfolio',
            subtitle: '${partner.photoCount} photos uploaded',
            trailing: StatusChip.neutral(
              label: '${partner.photoCount} Uploads',
              dense: true,
            ),
            onTap: () => context.push('/onboarding/step3'),
          ),
          SettingsRow(
            icon: Symbols.videocam,
            title: 'Video KYC & Identity',
            subtitle: partner.isVerified
                ? 'Aadhaar & Biometrics verified'
                : 'Pending verification',
            trailing: partner.isVerified
                ? const StatusChip(
                    label: 'Verified',
                    icon: Symbols.verified_user,
                    iconFill: 1,
                    dense: true,
                    background: Color(0x1A8A19D8),
                    foreground: AppColors.primary,
                  )
                : const StatusChip.warning(label: 'Action Needed', dense: true),
            onTap: () => context.push('/kyc'),
          ),
        ]),
      ],
    );
  }

  Widget _growthGroup(BuildContext context, WidgetRef ref, Partner partner) {
    final membership = ref.watch(membershipProvider).value;
    final renews = membership?.renewsOn;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel('Growth & Subscriptions'),
        const SizedBox(height: 6),
        _group([
          SettingsRow(
            icon: Symbols.workspace_premium,
            title: 'Membership Plan',
            titleBadge: const StatusChip.primarySolid(
              label: 'PRO',
              radius: AppRadius.sm,
            ),
            subtitle: membership == null
                ? 'Loading...'
                : '${membership.planName}'
                    '${renews == null ? '' : ' • Renews on '
                        '${DateFormat('d MMM y').format(renews)}'}',
            iconBackground: const Color(0x1A8A19D8),
            trailingText: 'Manage',
            onTap: () => context.push('/membership'),
          ),
          SettingsRow(
            icon: Symbols.home_repair_service,
            title: 'Service Offerings & Rates',
            subtitle: ReferenceData.categoryLabel(partner.categorySlug),
            trailing: StatusChip(
              label: '${partner.activeServiceCount} Active',
              dense: true,
              background: AppColors.surfaceContainer,
              foreground: AppColors.primary,
            ),
            onTap: () => context.push('/services'),
          ),
          SettingsRow(
            icon: Symbols.redeem,
            title: 'Refer a Partner & Earn',
            subtitle: 'Earn ₹${partner.referralCredits} credits per verified '
                'referee',
            iconBackground: AppColors.tertiaryFixed,
            iconForeground: AppColors.tertiary,
            trailing: StatusChip(
              label: '₹${partner.referralCredits}',
              dense: true,
              background: AppColors.tertiaryFixedDim.withValues(alpha: 0.4),
              foreground: AppColors.onTertiaryFixed,
            ),
            onTap: () {},
          ),
        ]),
      ],
    );
  }

  Widget _preferencesGroup(BuildContext context, Partner partner) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel('Preferences & Support'),
        const SizedBox(height: 6),
        _group([
          SettingsRow(
            icon: Symbols.notifications_active,
            title: 'Lead Notifications & Sound',
            subtitle: partner.whatsappAlerts
                ? 'Loud Lead Chime + WhatsApp Alerts On'
                : 'Loud Lead Chime On',
            onTap: () {},
          ),
          SettingsRow(
            icon: Symbols.translate,
            title: 'App Language',
            subtitle: 'Current: ${partner.language}',
            trailingText: 'Change',
            onTap: () {},
          ),
          SettingsRow(
            icon: Symbols.support_agent,
            title: 'Help Center & Partner Support',
            subtitle: '24/7 Dedicated Priority Hotline',
            onTap: () {},
          ),
        ]),
      ],
    );
  }
}

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({required this.partner});

  final Partner partner;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: AppRadius.lg,
      padding: const EdgeInsets.all(AppSpacing.stackMd),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.primaryFixed,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Text(
                      partner.initials,
                      style: AppText.headlineLg.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (partner.isVerified)
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Symbols.verified,
                          size: 11,
                          color: Colors.white,
                          fill: 1,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            partner.ownerName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.headlineLgMobile,
                          ),
                        ),
                        if (partner.isVerified)
                          const StatusChip.primary(
                            label: 'Pro Verified',
                            icon: Symbols.verified,
                            iconFill: 1,
                            dense: true,
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      partner.businessName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.bodySm,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerHigh,
                            borderRadius:
                                BorderRadius.circular(AppRadius.sm),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                partner.rating.toStringAsFixed(1),
                                style: AppText.label11.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.onSurface,
                                ),
                              ),
                              const SizedBox(width: 3),
                              const Icon(
                                Symbols.star,
                                size: 12,
                                color: AppColors.tertiaryContainer,
                                fill: 1,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            '${partner.reviewCount} reviews',
                            overflow: TextOverflow.ellipsis,
                            style: AppText.label11,
                          ),
                        ),
                        Text(' • ', style: AppText.label11),
                        Text(
                          '${partner.completionRate}% Completion',
                          style: AppText.label11.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Symbols.calendar_today,
                size: 15,
                color: AppColors.primary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  partner.memberSince == null
                      ? 'New partner'
                      : 'Partner since '
                          '${DateFormat('MMMM y').format(partner.memberSince!)}',
                  style: AppText.label11,
                ),
              ),
              GestureDetector(
                onTap: () {},
                child: Row(
                  children: [
                    Text(
                      'View Public Profile',
                      style: AppText.label11.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Icon(
                      Symbols.chevron_right,
                      size: 16,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OnboardingBanner extends ConsumerWidget {
  const _OnboardingBanner({required this.partner});

  final Partner partner;

  /// Step 4 is the membership plan, matching the wizard rather than the
  /// export's "Bank & KYC" label.
  static const _steps = ['Basic Info', 'Work Details', 'Photos', 'Plan'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(onboardingControllerProvider).value;
    final completed = draft?.completedSteps ?? partner.onboarding.completedSteps;
    final current = draft?.currentStep ?? partner.onboarding.currentStep;
    final percent = ((completed.length / 4) * 100).round();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.stackMd),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, AppColors.surfaceContainerLow],
        ),
        borderRadius: AppRadius.brLg,
        border: Border.all(
          color: AppColors.primaryContainer.withValues(alpha: 0.25),
        ),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const IconTile(
                icon: Symbols.assignment_turned_in,
                size: 32,
                iconSize: 17,
                background: AppColors.primaryContainer,
                foreground: Colors.white,
                radius: AppRadius.base,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ACTIVE SETUP TASK',
                      style: AppText.label10.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Partner Onboarding Flow',
                      style: AppText.title15.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              StatusChip(
                label: 'Step $current of 4',
                dense: true,
                background: AppColors.primary.withValues(alpha: 0.1),
                foreground: AppColors.primary,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Complete remaining business documents & KYC to unlock unlimited '
            'daily customer leads in your territory.',
            style: AppText.body13,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Registration Progress',
                  style: AppText.label11.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                '$percent% Done',
                style: AppText.label11.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.full),
            child: LinearProgressIndicator(
              value: completed.length / 4,
              minHeight: 8,
              backgroundColor: AppColors.surfaceContainerHighest,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (var i = 1; i <= 4; i++) ...[
                Expanded(
                  child: _StepPill(
                    index: i,
                    label: _steps[i - 1],
                    done: completed.contains(i),
                  ),
                ),
                if (i != 4) const SizedBox(width: 6),
              ],
            ],
          ),
          const SizedBox(height: 12),
          GradientButton(
            label: 'Resume Onboarding & Edit Details',
            icon: Symbols.arrow_forward,
            height: 44,
            shadows: const [],
            textStyle: AppText.label11,
            onPressed: () => context.push(
              '/onboarding/step${current.clamp(1, 4)}',
            ),
          ),
        ],
      ),
    );
  }
}

class _StepPill extends StatelessWidget {
  const _StepPill({
    required this.index,
    required this.label,
    required this.done,
  });

  final int index;
  final String label;
  final bool done;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
      decoration: BoxDecoration(
        color: done
            ? Colors.white.withValues(alpha: 0.85)
            : AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppRadius.base),
        border: done
            ? Border.all(color: AppColors.primary.withValues(alpha: 0.3))
            : null,
        boxShadow: done ? AppShadows.card : const [],
      ),
      child: Column(
        children: [
          Text(
            done ? '✓ Step $index' : 'Step $index',
            style: AppText.label10.copyWith(
              fontSize: 9.5,
              color: done ? AppColors.primary : AppColors.onSurfaceVariant,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.label10.copyWith(
              fontSize: 9,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class _LogoutButton extends ConsumerWidget {
  const _LogoutButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GlassCard(
      radius: AppRadius.lg,
      padding: const EdgeInsets.symmetric(vertical: 14),
      onTap: () async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Log out?'),
            content: const Text(
              'You will need your mobile number to sign back in.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Log out'),
              ),
            ],
          ),
        );

        if (confirmed != true) return;
        await ref.read(authControllerProvider.notifier).logout();
        if (context.mounted) context.go('/');
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Symbols.logout, size: 19, color: AppColors.error),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              'Log Out of Partner Account',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.bodySm.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
