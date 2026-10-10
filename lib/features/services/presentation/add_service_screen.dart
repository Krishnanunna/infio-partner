import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/format/money.dart';
import '../../../core/reference/reference_data.dart';
import '../../../core/theme/gradients.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/app_bars.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../../shared/widgets/section_card.dart';
import '../../../shared/widgets/segmented_pill.dart';
import '../../../shared/widgets/upload_slot.dart';
import '../domain/partner_service.dart';
import 'services_providers.dart';

/// Creates a catalogue entry.
///
/// Mirrors `add_new_service_native_mobile`. It is one scrolling form, though
/// the sections are labelled "Step N of 3" as in the design.
class AddServiceScreen extends ConsumerStatefulWidget {
  const AddServiceScreen({super.key});

  @override
  ConsumerState<AddServiceScreen> createState() => _AddServiceScreenState();
}

class _AddServiceScreenState extends ConsumerState<AddServiceScreen> {
  final _picker = ImagePicker();
  final _name = TextEditingController();
  final _price = TextEditingController();
  final _description = TextEditingController();

  String _categorySlug = ReferenceData.categories.first.slug;
  String? _subType;
  PricingType _pricingType = PricingType.fixed;
  String _duration = ReferenceData.durations[1];
  bool _active = true;
  String? _imagePath;
  bool _saving = false;

  static const _maxDescription = 500;

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _description.dispose();
    super.dispose();
  }

  int get _priceValue => Money.parse(_price.text) ?? 0;

  bool get _valid =>
      _name.text.trim().isNotEmpty &&
      _priceValue > 0 &&
      _description.text.trim().isNotEmpty;

  Future<void> _pickImage() async {
    try {
      final file = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (file != null && mounted) setState(() => _imagePath = file.path);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the photo picker.')),
        );
      }
    }
  }

  Future<void> _save() async {
    if (!_valid || _saving) return;
    setState(() => _saving = true);

    try {
      await ref.read(serviceActionsProvider).create(
            PartnerService(
              id: '',
              name: _name.text.trim(),
              description: _description.text.trim(),
              categorySlug: _categorySlug,
              categoryTag: ReferenceData.categoryTag(_categorySlug),
              price: _priceValue,
              pricingType: _pricingType,
              status: _active ? ServiceStatus.active : ServiceStatus.draft,
              duration: _duration,
              subType: _subType,
              imagePath: _imagePath,
            ),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${_name.text.trim()} added to your catalogue')),
      );
      context.pop();
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save. Please try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final category = ReferenceData.categoryBySlug(_categorySlug);

    return Scaffold(
      appBar: StandaloneAppBar(
        title: 'Add New Service',
        subtitle: 'Service Partner Catalog',
        titleStyle: AppText.title15.copyWith(fontWeight: FontWeight.w700),
        actions: [
          TextButton(onPressed: () {}, child: const Text('Guidelines')),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.stackMd,
          AppSpacing.stackMd,
          AppSpacing.stackMd,
          AppSpacing.stackLg,
        ),
        children: [
          _introBanner(),
          const SizedBox(height: AppSpacing.stackMd),
          _classificationCard(category),
          const SizedBox(height: AppSpacing.stackMd),
          _pricingCard(),
          const SizedBox(height: AppSpacing.stackMd),
          _detailsCard(),
        ],
      ),
      bottomNavigationBar: _dock(),
    );
  }

  Widget _introBanner() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.stackMd),
      decoration: BoxDecoration(
        gradient: AppGradients.serviceBanner,
        borderRadius: AppRadius.brLg,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppRadius.base),
            ),
            child: const Icon(
              Symbols.storefront,
              size: 19,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Grow Your InFio Reach',
                  style: AppText.title15.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Provide verified details for your catalog. Clear '
                  'descriptions and upfront pricing attract up to 3x more '
                  'bookings.',
                  style: AppText.label11.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _classificationCard(ServiceCategory? category) {
    return SectionCard(
      icon: Symbols.category,
      title: 'Service Classification',
      glass: false,
      trailing: Text('Step 1 of 3', style: AppText.label10),
      children: [
        FieldLabel(
          label: 'Service Category',
          required: true,
          child: DropdownButtonFormField<String>(
            initialValue: _categorySlug,
            isExpanded: true,
            icon: const Icon(Symbols.expand_more),
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
            onChanged: (v) => setState(() {
              _categorySlug = v ?? _categorySlug;
              // Sub-types belong to the category, so reset on change.
              _subType = null;
            }),
          ),
        ),
        if (category != null)
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: category.specializations.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final spec = category.specializations[i];
                return ChoicePill(
                  label: spec,
                  dense: true,
                  selected: _subType == spec,
                  showLeadingIcon: _subType == spec,
                  onTap: () => setState(
                    () => _subType = _subType == spec ? null : spec,
                  ),
                );
              },
            ),
          ),
        FieldLabel(
          label: 'Service Name',
          required: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _name,
                decoration: const InputDecoration(
                  hintText: 'e.g., Split AC Deep Cleaning / Jet Wash',
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 5),
              Text(
                'A clear, descriptive name increases customer trust on the '
                'InFio marketplace.',
                style: AppText.label10.copyWith(fontWeight: FontWeight.w400),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _pricingCard() {
    final commission = _priceValue * ReferenceData.commissionPercent / 100;
    final takeHome = _priceValue - commission;

    return SectionCard(
      icon: Symbols.payments,
      title: 'Pricing & Duration',
      glass: false,
      trailing: Text('Step 2 of 3', style: AppText.label10),
      children: [
        FieldLabel(
          label: 'Pricing Structure',
          child: SegmentedPill<PricingType>(
            value: _pricingType,
            radius: AppRadius.md,
            trackColor: AppColors.slate100,
            onChanged: (v) => setState(() => _pricingType = v),
            options: const [
              SegmentOption(
                value: PricingType.fixed,
                label: 'Fixed Price',
                icon: Symbols.sell,
              ),
              SegmentOption(
                value: PricingType.startingFrom,
                label: 'Starting From',
                icon: Symbols.trending_up,
              ),
            ],
          ),
        ),
        FieldLabel(
          label: 'Customer Price (INR)',
          required: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _price,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  hintText: '0.00',
                  prefixIcon: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14),
                    child: Center(widthFactor: 1, child: Text('₹')),
                  ),
                  suffixIcon: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14),
                    child: Center(widthFactor: 1, child: Text('INR')),
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 6),
              // Commission maths, computed live as the design does.
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'InFio partner commission: '
                      '${ReferenceData.commissionPercent}% '
                      '(${Money.rupeesPaise(commission)})',
                      style: AppText.label10.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Text(
                    'You take home: ${Money.rupeesPaise(takeHome)}',
                    style: AppText.label10.copyWith(
                      color: AppColors.successDark,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        FieldLabel(
          label: 'Estimated Service Duration',
          child: Row(
            children: [
              for (final d in ReferenceData.durations) ...[
                Expanded(
                  child: ChoicePill(
                    label: d,
                    dense: true,
                    radius: AppRadius.md,
                    selected: _duration == d,
                    showLeadingIcon: false,
                    onTap: () => setState(() => _duration = d),
                  ),
                ),
                if (d != ReferenceData.durations.last)
                  const SizedBox(width: 8),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _detailsCard() {
    return SectionCard(
      icon: Symbols.description,
      title: 'Details & Media',
      glass: false,
      trailing: Text('Step 3 of 3', style: AppText.label10),
      children: [
        FieldLabel(
          label: 'Service Description',
          required: true,
          hint: '${_description.text.length} / $_maxDescription characters',
          child: TextField(
            controller: _description,
            maxLines: 3,
            maxLength: _maxDescription,
            decoration: const InputDecoration(
              counterText: '',
              hintText: "Specify what's included, inspection details, "
                  'cleaning process, and warranty on spares...',
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
        FieldLabel(
          label: 'Cover Photo / Showcase',
          child: UploadSlot(
            file: _imagePath == null ? null : File(_imagePath!),
            height: 128,
            emphasised: true,
            radius: AppRadius.lg,
            emptyIcon: Symbols.add_photo_alternate,
            emptyLabel: 'Tap to upload service photo',
            slotLabel: 'PNG, JPG or WEBP up to 5MB (16:9 recommended)',
            onTap: _pickImage,
            onDelete:
                _imagePath == null ? null : () => setState(() => _imagePath = null),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: AppRadius.brMd,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Active on InFio Marketplace',
                      style: AppText.title15.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Customers can find & book this service right away',
                      style: AppText.label10.copyWith(
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _active,
                onChanged: (v) => setState(() => _active = v),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _dock() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.97),
        border: Border(
          top: BorderSide(color: AppColors.primaryFixedDim.withValues(alpha: 0.6)),
        ),
        boxShadow: AppShadows.dock,
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Row(
            children: [
              Expanded(
                child: GradientButton(
                  label: 'Save & Add Service',
                  leadingIcon: Symbols.save,
                  enabled: _valid,
                  busy: _saving,
                  onPressed: _save,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primaryFixed.withValues(alpha: 0.5),
                  borderRadius: AppRadius.brMd,
                ),
                child: IconButton(
                  onPressed: () {},
                  icon: const Icon(
                    Symbols.bookmark_border,
                    color: AppColors.primary,
                  ),
                  tooltip: 'Save as draft',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
