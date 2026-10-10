import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/app_bars.dart';
import '../../../shared/widgets/bottom_dock.dart';
import '../../../shared/widgets/chips.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../../shared/widgets/upload_slot.dart';
import '../domain/onboarding_draft.dart';
import 'onboarding_controller.dart';
import 'widgets/next_step_callout.dart';

/// Step 3 of 4 — cover photo plus up to five portfolio images.
///
/// Mirrors `step_3_business_photos_clean_dedicated`.
class Step3PhotosScreen extends ConsumerStatefulWidget {
  const Step3PhotosScreen({super.key});

  @override
  ConsumerState<Step3PhotosScreen> createState() => _Step3PhotosScreenState();
}

class _Step3PhotosScreenState extends ConsumerState<Step3PhotosScreen> {
  final _picker = ImagePicker();

  OnboardingController get _controller =>
      ref.read(onboardingControllerProvider.notifier);

  Future<void> _pickCover() async {
    final file = await _pick();
    if (file != null) {
      _controller.edit((d) => d.copyWith(coverPhotoPath: file.path));
    }
  }

  Future<void> _addPortfolio() async {
    final file = await _pick();
    if (file == null) return;
    _controller.edit((d) {
      if (d.portfolioPaths.length >= OnboardingDraft.portfolioSlots) return d;
      return d.copyWith(portfolioPaths: [...d.portfolioPaths, file.path]);
    });
  }

  void _removePortfolio(int index) {
    _controller.edit((d) {
      final next = [...d.portfolioPaths]..removeAt(index);
      return d.copyWith(portfolioPaths: next);
    });
  }

  Future<XFile?> _pick() async {
    try {
      return await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
    } catch (_) {
      // No gallery available (simulator without photos, permission denied).
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the photo picker.')),
        );
      }
      return null;
    }
  }

  Future<void> _continue() async {
    await _controller.submitStep(3);
    if (mounted) context.push('/onboarding/step4');
  }

  @override
  Widget build(BuildContext context) {
    final draftAsync = ref.watch(onboardingControllerProvider);

    return draftAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => const Scaffold(
        body: Center(child: Text('Could not load your photos.')),
      ),
      data: (draft) => Scaffold(
        appBar: const WizardAppBar(title: 'Partner Onboarding', step: 3),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.containerMargin,
            AppSpacing.stackMd,
            AppSpacing.containerMargin,
            AppSpacing.stackLg,
          ),
          children: [
            _title(),
            const SizedBox(height: AppSpacing.stackMd),
            _coverCard(draft),
            const SizedBox(height: AppSpacing.stackMd),
            _portfolioCard(draft),
            const SizedBox(height: AppSpacing.stackMd),
            _guidelinesCard(),
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
            label: 'Save & Continue to Plans',
            icon: Symbols.arrow_forward,
            enabled: draft.step3Valid,
            onPressed: _continue,
          ),
        ),
      ),
    );
  }

  Widget _title() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Symbols.photo_camera,
              size: 15,
              color: AppColors.primary,
            ),
            const SizedBox(width: 5),
            Text(
              'Step 3 • Visual Identity',
              style: AppText.label11.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Business Photos',
          style: AppText.headlineLgMobile.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          'High-quality photos build customer trust and get up to 3x more '
          'bookings.',
          style: AppText.bodySm,
        ),
      ],
    );
  }

  Widget _coverCard(OnboardingDraft draft) {
    final path = draft.coverPhotoPath;

    return GlassCard(
      radius: AppRadius.md,
      opacity: 0.85,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Storefront or Service Vehicle',
                  style: AppText.title15.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              const StatusChip.primary(label: 'Required', dense: true),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Help customers recognize your business or service vehicle when '
            'arriving for work.',
            style: AppText.label11.copyWith(fontWeight: FontWeight.w400),
          ),
          const SizedBox(height: 12),

          if (path == null)
            UploadSlot(
              height: 176,
              emphasised: true,
              emptyLabel: 'Add Cover Photo',
              emptyIcon: Symbols.add_a_photo,
              radius: AppRadius.base,
              onTap: _pickCover,
            )
          else ...[
            Stack(
              children: [
                ClipRRect(
                  borderRadius: AppRadius.brBase,
                  child: Image.file(
                    File(path),
                    height: 176,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  left: 8,
                  top: 8,
                  child: StatusChip.success(
                    label: 'Primary Cover Photo',
                    icon: Symbols.verified,
                    iconFill: 1,
                    dense: true,
                  ),
                ),
                Positioned(
                  right: 8,
                  bottom: 8,
                  child: GestureDetector(
                    onTap: _pickCover,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(AppRadius.base),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Symbols.sync,
                            size: 14,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Replace Photo',
                            style: AppText.label11.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(
                  Symbols.check_circle,
                  size: 15,
                  color: AppColors.primary,
                  fill: 1,
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    'Uploaded and ready',
                    style: AppText.label11.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text('Verified preview', style: AppText.label10),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _portfolioCard(OnboardingDraft draft) {
    final paths = draft.portfolioPaths;
    const slots = OnboardingDraft.portfolioSlots;

    return GlassCard(
      radius: AppRadius.md,
      opacity: 0.85,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Work Portfolio Showcase',
                  style: AppText.title15.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              StatusChip.primary(
                label: '${paths.length} of $slots uploaded',
                dense: true,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Showcase actual repairs, installations, or tools.',
            style: AppText.label11.copyWith(fontWeight: FontWeight.w400),
          ),
          const SizedBox(height: 12),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: slots,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: AppSpacing.gridGutter,
              mainAxisSpacing: AppSpacing.gridGutter,
            ),
            itemBuilder: (context, index) {
              final filled = index < paths.length;
              return UploadSlot(
                file: filled ? File(paths[index]) : null,
                caption: filled ? 'Work ${index + 1}' : null,
                slotLabel: 'Slot ${index + 1}',
                // The next slot to fill gets the purple treatment.
                emphasised: !filled && index == paths.length,
                onTap: filled ? null : _addPortfolio,
                onDelete: filled ? () => _removePortfolio(index) : null,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _guidelinesCard() {
    const items = [
      'Good natural lighting & clear angles',
      'Real completed jobs (no internet stock photos)',
      'Clear view of tools, service vehicle, or work gear',
    ];

    return Container(
      padding: const EdgeInsets.all(AppSpacing.stackMd),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: AppRadius.brMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Symbols.checklist,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Photo Quality Guidelines',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.title15.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Symbols.check_circle,
                    size: 16,
                    color: AppColors.success,
                    fill: 1,
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(item, style: AppText.body13)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
