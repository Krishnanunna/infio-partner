import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/gradients.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/chips.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../../shared/widgets/infio_logo.dart';

/// App entry point: the partner marketing landing.
///
/// Mirrors `infio_business_partner_mobile_landing`.
class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(
            child: AmbientBlobs(blobs: AmbientBlobs.partner),
          ),
          Column(
            children: [
              const _LandingHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.containerMargin,
                    AppSpacing.stackLg,
                    AppSpacing.containerMargin,
                    AppSpacing.stackLg,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _Hero(),
                          SizedBox(height: AppSpacing.stackLg),
                          _BenefitsGrid(),
                          SizedBox(height: AppSpacing.stackMd),
                          _HighlightBanner(),
                          SizedBox(height: AppSpacing.stackLg),
                          _CallToAction(),
                          SizedBox(height: AppSpacing.stackMd),
                          _Footer(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LandingHeader extends StatelessWidget {
  const _LandingHeader();

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.8),
            border: const Border(
              bottom: BorderSide(color: AppColors.outlineVariant),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: SizedBox(
              height: 64,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.containerMargin,
                ),
                child: Row(
                  children: [
                    const InfioLogo(size: 36),
                    const SizedBox(width: 10),
                    const InfioWordmark(),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(AppRadius.full),
                        border: Border.all(
                          color: AppColors.outlineVariant.withValues(alpha: 0.6),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const PulsingDot(),
                          const SizedBox(width: 6),
                          Text(
                            'Partner Portal',
                            style: AppText.label11.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Eyebrow chip.
        GlassCard(
          radius: AppRadius.full,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          opacity: 0.75,
          shadows: const [],
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Symbols.bolt, size: 14, color: AppColors.primary, fill: 1),
              const SizedBox(width: 5),
              Text(
                'HYPERLOCAL PRO NETWORK',
                style: AppText.label10.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.stackMd),

        // Two-line headline, second line in primary.
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: AppText.headlineLgMobile.copyWith(
              fontWeight: FontWeight.w800,
              height: 1.25,
            ),
            children: const [
              TextSpan(text: 'Get Direct Leads.\n'),
              TextSpan(
                text: 'Zero Commission.',
                style: TextStyle(color: AppColors.primary),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.stackSm),

        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 340),
          child: Text(
            'Verified neighborhood customers contact you directly with urgent '
            'requirements. Keep 100% of your earnings.',
            textAlign: TextAlign.center,
            style: AppText.bodySm,
          ),
        ),
        const SizedBox(height: AppSpacing.stackMd),

        // Social proof.
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const StatusChip.success(label: '+34% MoM'),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                '₹4.8L+ earned by partners this month',
                style: AppText.label11.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _BenefitsGrid extends StatelessWidget {
  const _BenefitsGrid();

  static const _items = [
    (
      icon: Symbols.notifications_active,
      title: '100% Direct',
      body: 'Instant verified customer calls',
      color: AppColors.primary,
    ),
    (
      icon: Symbols.percent,
      title: '0% Cut',
      body: 'Flat fee, no commission cuts',
      color: AppColors.primaryContainer,
    ),
    (
      icon: Symbols.chat,
      title: 'WhatsApp & Call',
      body: 'One-tap quick quotes',
      color: AppColors.success,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < _items.length; i++) ...[
            Expanded(
              child: GlassCard(
                radius: AppRadius.md,
                opacity: 0.75,
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconTile(
                      icon: _items[i].icon,
                      size: 34,
                      iconSize: 18,
                      background: _items[i].color.withValues(alpha: 0.12),
                      foreground: _items[i].color,
                      radius: AppRadius.base,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _items[i].title,
                      style: AppText.label11.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _items[i].body,
                      style: AppText.label10.copyWith(
                        fontWeight: FontWeight.w400,
                        color: AppColors.onSurfaceVariant,
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (i != _items.length - 1)
              const SizedBox(width: AppSpacing.stackSm),
          ],
        ],
      ),
    );
  }
}

class _HighlightBanner extends StatelessWidget {
  const _HighlightBanner();

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: AppRadius.md,
      opacity: 0.75,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              gradient: AppGradients.ctaDiagonal,
              borderRadius: BorderRadius.circular(AppRadius.base),
            ),
            child: const Icon(
              Symbols.verified,
              size: 18,
              color: Colors.white,
              fill: 1,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Fast 24-hr Onboarding',
                  style: AppText.label11.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  'Get verified & start receiving bookings today',
                  style: AppText.label10.copyWith(
                    fontWeight: FontWeight.w400,
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          ),
          Text(
            'Free Setup',
            style: AppText.label11.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _CallToAction extends StatelessWidget {
  const _CallToAction();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GradientButton(
          label: 'Register as Partner',
          icon: Symbols.arrow_forward,
          gradient: AppGradients.heroPro,
          radius: AppRadius.md,
          height: 54,
          textStyle: AppText.titleMd,
          onPressed: () => context.push('/onboarding/step1'),
        ),
        const SizedBox(height: AppSpacing.stackMd),
        TextButton(
          onPressed: () => context.push('/login'),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  'Existing Partner? Sign In Here',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.body13.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 5),
              const Icon(Symbols.login, size: 16, color: AppColors.primary),
            ],
          ),
        ),
      ],
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return Text(
      'InFio Business • Hyperlocal Service Marketplace Partner OS',
      textAlign: TextAlign.center,
      style: AppText.label10.copyWith(
        fontWeight: FontWeight.w400,
        color: AppColors.secondary,
      ),
    );
  }
}
