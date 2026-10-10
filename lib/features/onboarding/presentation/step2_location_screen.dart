import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/reference/reference_data.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/app_bars.dart';
import '../../../shared/widgets/bottom_dock.dart';
import '../../../shared/widgets/chips.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../../shared/widgets/mock_map.dart';
import '../../../shared/widgets/section_card.dart';
import '../../../shared/widgets/segmented_pill.dart';
import '../domain/onboarding_draft.dart';
import 'onboarding_controller.dart';
import 'widgets/next_step_callout.dart';

/// Step 2 of 4 — trade expertise plus workshop address and coverage radius.
///
/// Mirrors `partner_details_location_unified`.
class Step2LocationScreen extends ConsumerStatefulWidget {
  const Step2LocationScreen({super.key});

  @override
  ConsumerState<Step2LocationScreen> createState() =>
      _Step2LocationScreenState();
}

class _Step2LocationScreenState extends ConsumerState<Step2LocationScreen> {
  final _shop = TextEditingController();
  final _street = TextEditingController();
  final _landmark = TextEditingController();
  final _pincode = TextEditingController();
  final _description = TextEditingController();

  bool _hydrated = false;

  static const _maxDescription = 500;

  @override
  void dispose() {
    _shop.dispose();
    _street.dispose();
    _landmark.dispose();
    _pincode.dispose();
    _description.dispose();
    super.dispose();
  }

  void _hydrate(OnboardingDraft draft) {
    if (_hydrated) return;
    _hydrated = true;
    _shop.text = draft.shopName;
    _street.text = draft.street;
    _landmark.text = draft.landmark;
    _pincode.text = draft.pincode;
    _description.text = draft.serviceDescription;
  }

  OnboardingController get _controller =>
      ref.read(onboardingControllerProvider.notifier);

  Future<void> _continue() async {
    await _controller.submitStep(2);
    if (mounted) context.push('/onboarding/step3');
  }

  @override
  Widget build(BuildContext context) {
    final draftAsync = ref.watch(onboardingControllerProvider);

    return draftAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => const Scaffold(
        body: Center(child: Text('Could not load your details.')),
      ),
      data: (draft) {
        _hydrate(draft);
        final category = ReferenceData.categoryBySlug(draft.categorySlug ?? '');

        return Scaffold(
          appBar: const WizardAppBar(title: 'Partner Onboarding', step: 2),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.stackMd,
              AppSpacing.stackMd,
              AppSpacing.stackMd,
              AppSpacing.stackLg,
            ),
            children: [
              _title(),
              const SizedBox(height: AppSpacing.stackMd),
              _expertiseCard(draft, category),
              const SizedBox(height: AppSpacing.stackMd),
              _locationCard(draft),
              const SizedBox(height: AppSpacing.stackMd),
              const NextStepCallout(
                icon: Symbols.photo_camera,
                stepLabel: 'STEP 3',
                title: 'Next: Business & Work Photos',
                body: 'In the next step, you will upload photos of your '
                    'workshop, storefront banner, and previous service work '
                    'samples.',
              ),
            ],
          ),
          bottomNavigationBar: BottomDock(
            secondary: SaveDraftLink(
              onTap: () async {
                await _controller.saveDraft();
                if (context.mounted) context.go('/');
              },
            ),
            child: GradientButton(
              label: 'Save & Continue',
              icon: Symbols.arrow_forward,
              height: 50,
              enabled: draft.step2Valid,
              onPressed: _continue,
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
            Expanded(
              child: Text(
                'Business Details & Address',
                style: AppText.headlineLg.copyWith(fontSize: 22),
              ),
            ),
            const SizedBox(width: 8),
            const StatusChip.success(
              label: 'Pro Eligible',
              icon: Symbols.verified,
              iconFill: 1,
              dense: true,
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Help customers find, book, and trust your verified services.',
          style: AppText.bodySm,
        ),
      ],
    );
  }

  Widget _expertiseCard(OnboardingDraft draft, ServiceCategory? category) {
    return SectionCard(
      icon: Symbols.handyman,
      title: 'Professional Expertise',
      subtitle: 'Selected trade and core competencies',
      glass: false,
      iconBackground: AppColors.primaryFixed,
      children: [
        FieldLabel(
          label: 'Service Category',
          required: true,
          child: DropdownButtonFormField<String>(
            initialValue: draft.categorySlug,
            isExpanded: true,
            decoration: const InputDecoration(
              prefixIcon: Icon(Symbols.hvac, size: 19),
            ),
            icon: const Icon(Symbols.unfold_more),
            items: [
              for (final c in ReferenceData.categories)
                DropdownMenuItem(
                  value: c.slug,
                  child: Text(
                    c.label,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.body13.copyWith(color: AppColors.onSurface),
                  ),
                ),
            ],
            onChanged: (v) => _controller.edit(
              // Switching category clears specializations, which are scoped
              // to it.
              (d) => d.copyWith(categorySlug: v, specializations: {}),
            ),
          ),
        ),
        if (category != null)
          FieldLabel(
            label: 'Specializations',
            hint: 'Select all that apply',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final spec in category.specializations)
                  ChoicePill(
                    label: spec,
                    dense: true,
                    selected: draft.specializations.contains(spec),
                    onTap: () => _controller.edit((d) {
                      final next = {...d.specializations};
                      next.contains(spec) ? next.remove(spec) : next.add(spec);
                      return d.copyWith(specializations: next);
                    }),
                  ),
              ],
            ),
          ),
        FieldLabel(
          label: 'Years of Experience',
          required: true,
          child: SegmentedPill<String>(
            radius: AppRadius.md,
            trackColor: AppColors.slate100,
            value: draft.experienceBand ?? ReferenceData.experienceBands[1],
            onChanged: (v) =>
                _controller.edit((d) => d.copyWith(experienceBand: v)),
            options: [
              for (final band in ReferenceData.experienceBands)
                SegmentOption(value: band, label: band),
            ],
          ),
        ),
        FieldLabel(
          label: 'Service Description',
          hint: '${_description.text.length}/$_maxDescription',
          child: TextField(
            controller: _description,
            maxLines: 3,
            maxLength: _maxDescription,
            decoration: const InputDecoration(
              counterText: '',
              hintText: 'E.g., 5+ years specializing in multi-brand inverter '
                  'AC installation, jet cleaning, and compressor repair...',
            ),
            onChanged: (v) {
              setState(() {});
              _controller.edit((d) => d.copyWith(serviceDescription: v));
            },
          ),
        ),
      ],
    );
  }

  Widget _locationCard(OnboardingDraft draft) {
    return SectionCard(
      icon: Symbols.location_on,
      title: 'Workshop & Service Location',
      subtitle: 'Physical base, pin accuracy & service radius',
      glass: false,
      trailing: const StatusChip.success(
        label: 'GPS Ready',
        icon: Symbols.gps_fixed,
        dense: true,
      ),
      children: [
        // Auto-detect.
        OutlineActionButton(
          label: 'Auto-Detect Address via GPS',
          icon: Symbols.my_location,
          height: 46,
          background: AppColors.primaryFixed.withValues(alpha: 0.3),
          borderColor: AppColors.primaryContainer.withValues(alpha: 0.4),
          onPressed: () => _controller.edit(
            (d) => d.copyWith(
              latitude: 17.4934,
              longitude: 78.3995,
              locality: 'KPHB Colony, Kukatpally',
            ),
          ),
        ),
        FieldLabel(
          label: 'Building / Workshop / Shop Name',
          required: true,
          child: TextField(
            controller: _shop,
            decoration: const InputDecoration(
              hintText: 'e.g. Shop #4, Metro Complex',
              prefixIcon: Icon(Symbols.storefront, size: 19),
            ),
            onChanged: (v) => _controller.edit((d) => d.copyWith(shopName: v)),
          ),
        ),
        FieldLabel(
          label: 'Street Address & Sector',
          required: true,
          child: TextField(
            controller: _street,
            decoration: const InputDecoration(
              hintText: 'e.g. 14th Main Rd, Sector 4',
              prefixIcon: Icon(Symbols.signpost, size: 19),
            ),
            onChanged: (v) => _controller.edit((d) => d.copyWith(street: v)),
          ),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: FieldLabel(
                label: 'Landmark',
                child: TextField(
                  controller: _landmark,
                  decoration: const InputDecoration(
                    hintText: 'Near metro station',
                    prefixIcon: Icon(Symbols.flag, size: 19),
                  ),
                  onChanged: (v) =>
                      _controller.edit((d) => d.copyWith(landmark: v)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FieldLabel(
                label: 'Area Pincode',
                required: true,
                child: TextField(
                  controller: _pincode,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    counterText: '',
                    hintText: '6 digits',
                    prefixIcon: Icon(Symbols.pin, size: 19),
                  ),
                  onChanged: (v) =>
                      _controller.edit((d) => d.copyWith(pincode: v)),
                ),
              ),
            ),
          ],
        ),
        _mapPin(draft),
        _radiusSlider(draft),
      ],
    );
  }

  Widget _mapPin(OnboardingDraft draft) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MockMapView.coverage(
          radiusKm: draft.serviceRadiusKm,
          onAdjust: () {},
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(
              Symbols.check_circle,
              size: 15,
              color: AppColors.success,
              fill: 1,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                draft.locality == null
                    ? 'Drop a pin to confirm your base'
                    : 'Pin verified: ${draft.locality}',
                style: AppText.label11.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
                ),
              ),
            ),
          ],
        ),
        if (draft.latitude != null && draft.longitude != null)
          Padding(
            padding: const EdgeInsets.only(left: 21, top: 2),
            child: Text(
              '${draft.latitude!.toStringAsFixed(4)}° N, '
              '${draft.longitude!.toStringAsFixed(4)}° E',
              style: AppText.label10.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
      ],
    );
  }

  Widget _radiusSlider(OnboardingDraft draft) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Symbols.radar, size: 17, color: AppColors.primary),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Service Coverage Radius',
                style: AppText.labelMd.copyWith(
                  color: AppColors.onSurfaceVariant,
                  letterSpacing: 0.2,
                ),
              ),
            ),
            StatusChip.primary(
              label: '${draft.serviceRadiusKm.round()} km reach',
              dense: true,
            ),
          ],
        ),
        Slider(
          value: draft.serviceRadiusKm,
          min: ReferenceData.minRadiusKm,
          max: ReferenceData.maxRadiusKm,
          divisions: 28,
          onChanged: (v) =>
              _controller.edit((d) => d.copyWith(serviceRadiusKm: v)),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                '2 km (Local)',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.label10,
              ),
            ),
            Flexible(
              child: Text(
                '15 km (Optimal)',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: AppText.label10,
              ),
            ),
            Flexible(
              child: Text(
                '30 km (City-wide)',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
                style: AppText.label10,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
