import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/reference/reference_data.dart';
import '../../../core/theme/gradients.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/app_bars.dart';
import '../../../shared/widgets/chips.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../../shared/widgets/section_card.dart';
import '../../../shared/widgets/segmented_pill.dart';
import '../domain/partner_service.dart';
import 'services_providers.dart';

/// The partner's service catalogue.
///
/// Mirrors `partner_service_manager_native_mobile`. Reached from the
/// dashboard rather than a bottom tab, per the navigation normalization.
class ServiceManagerScreen extends ConsumerWidget {
  const ServiceManagerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final services = ref.watch(filteredServicesProvider);
    final all = ref.watch(allServicesProvider).value ?? const [];
    final filter = ref.watch(serviceCategoryFilterProvider);
    final activeCount = all.where((s) => s.isActive).length;

    return Scaffold(
      appBar: StandaloneAppBar(
        title: 'Manage Services',
        subtitle: '$activeCount Active Services • InFio Partner',
        actions: [
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: GradientButton(
              label: 'Add',
              leadingIcon: Symbols.add,
              height: 36,
              radius: AppRadius.full,
              shadows: const [],
              textStyle: AppText.label11,
              onPressed: () => context.push('/services/new'),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/services/new'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Symbols.add_circle, fill: 1),
        label: Text(
          'Add New Service',
          style: AppText.title15.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.containerMargin,
          AppSpacing.stackMd,
          AppSpacing.containerMargin,
          100,
        ),
        children: [
          _searchRow(ref),
          const SizedBox(height: AppSpacing.gridGutter),
          _categoryPills(ref, all, filter),
          const SizedBox(height: AppSpacing.stackMd),
          const _VisibilityBanner(),
          const SizedBox(height: AppSpacing.stackMd),
          SectionLabel(
            'Service Catalog (${all.length})',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Sort by: Recommended',
                  style: AppText.label11.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Icon(
                  Symbols.expand_more,
                  size: 16,
                  color: AppColors.onSurfaceVariant,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.gridGutter),
          ...switch (services) {
            AsyncData(:final value) when value.isEmpty => [
                const _EmptyCatalog(),
              ],
            AsyncData(:final value) => [
                for (final service in value) ...[
                  _ServiceCard(service: service),
                  const SizedBox(height: AppSpacing.gridGutter),
                ],
              ],
            AsyncError() => [
                const Center(child: Text('Could not load your catalogue.')),
              ],
            _ => [
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 60),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ],
          },
        ],
      ),
    );
  }

  Widget _searchRow(WidgetRef ref) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'Search catalog services...',
              prefixIcon: Icon(Symbols.search, size: 19),
            ),
            onChanged: (v) =>
                ref.read(serviceQueryProvider.notifier).set(v),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: AppRadius.brMd,
            border: Border.all(color: AppColors.outlineVariant),
          ),
          child: IconButton(
            onPressed: () {},
            icon: const Icon(Symbols.tune, size: 20),
            tooltip: 'Filter',
          ),
        ),
      ],
    );
  }

  Widget _categoryPills(
    WidgetRef ref,
    List<PartnerService> all,
    String? filter,
  ) {
    // Counts come from the partner's own catalogue, not a static list.
    final counts = <String, int>{};
    for (final s in all) {
      counts[s.categorySlug] = (counts[s.categorySlug] ?? 0) + 1;
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ChoicePill(
            label: 'All',
            count: all.length,
            selected: filter == null,
            showLeadingIcon: false,
            dense: true,
            onTap: () =>
                ref.read(serviceCategoryFilterProvider.notifier).set(null),
          ),
          for (final entry in counts.entries) ...[
            const SizedBox(width: AppSpacing.stackSm),
            ChoicePill(
              label: ReferenceData.categoryTag(entry.key),
              count: entry.value,
              selected: filter == entry.key,
              showLeadingIcon: false,
              dense: true,
              onTap: () => ref
                  .read(serviceCategoryFilterProvider.notifier)
                  .set(entry.key),
            ),
          ],
        ],
      ),
    );
  }
}

class _VisibilityBanner extends ConsumerWidget {
  const _VisibilityBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visible = ref.watch(catalogVisibilityProvider).value ?? true;

    return GlassCard(
      radius: AppRadius.lg,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          IconTile(
            icon: Symbols.storefront,
            size: 40,
            iconSize: 20,
            background: visible
                ? AppColors.primaryFixed
                : AppColors.surfaceContainerHigh,
            foreground:
                visible ? AppColors.primary : AppColors.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Active Catalog Visibility',
                  style: AppText.title15.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  visible
                      ? 'Accepting bookings automatically'
                      : 'Hidden from customer search',
                  style: AppText.label11.copyWith(fontWeight: FontWeight.w400),
                ),
              ],
            ),
          ),
          Switch(
            value: visible,
            onChanged: (_) =>
                ref.read(catalogVisibilityProvider.notifier).toggle(),
          ),
        ],
      ),
    );
  }
}

class _ServiceCard extends ConsumerWidget {
  const _ServiceCard({required this.service});

  final PartnerService service;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paused = !service.isActive;

    return Opacity(
      opacity: paused ? 0.9 : 1,
      child: GlassCard(
        radius: AppRadius.lg,
        opacity: paused ? 0.7 : 0.85,
        shadows: paused ? const [] : AppShadows.card,
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          StatusChip(
                            label: service.categoryTag,
                            dense: true,
                            radius: AppRadius.base,
                            background: paused
                                ? AppColors.surfaceContainerHigh
                                : AppColors.primaryFixed,
                            foreground: paused
                                ? AppColors.onSurfaceVariant
                                : AppColors.onPrimaryFixed,
                          ),
                          if (paused) ...[
                            const SizedBox(width: 6),
                            const StatusChip.error(
                              label: 'PAUSED',
                              dense: true,
                              radius: AppRadius.base,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(service.name, style: AppText.titleMd),
                      const SizedBox(height: 3),
                      Text(service.description, style: AppText.body13),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Switch(
                  value: service.isActive,
                  onChanged: (on) => ref.read(serviceActionsProvider).setStatus(
                        service.id,
                        on ? ServiceStatus.active : ServiceStatus.paused,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _metrics(paused),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlineActionButton(
                    label: paused ? 'Resume Listing' : 'View Details',
                    height: 42,
                    foreground:
                        paused ? AppColors.onSurfaceVariant : AppColors.primary,
                    onPressed: paused
                        ? () => ref.read(serviceActionsProvider).setStatus(
                              service.id,
                              ServiceStatus.active,
                            )
                        : () {},
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: AppRadius.brBase,
                    border: Border.all(color: AppColors.outlineVariant),
                  ),
                  child: IconButton(
                    onPressed: () {},
                    icon: const Icon(Symbols.edit, size: 18),
                    tooltip: 'Edit ${service.name}',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _metrics(bool paused) {
    final entries = <(String, String, Color?)>[
      ('Base Price', service.priceLabel, null),
      if (paused)
        ('Current Status', 'Paused', AppColors.error)
      else ...[
        ('Commission', '${service.commissionPercent}%', null),
        if (service.duration != null)
          ('Est. Time', service.duration!, null)
        else if (service.turnaround != null)
          ('Turnaround', service.turnaround!, null),
      ],
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow.withValues(alpha: 0.7),
        borderRadius: AppRadius.brMd,
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            for (var i = 0; i < entries.length; i++) ...[
              Expanded(
                child: Column(
                  children: [
                    Text(
                      entries[i].$1.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: AppText.label10.copyWith(fontSize: 9.5),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      entries[i].$2,
                      textAlign: TextAlign.center,
                      style: AppText.label11.copyWith(
                        color: entries[i].$3 ?? AppColors.onSurface,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              if (i != entries.length - 1)
                const VerticalDivider(
                  width: 1,
                  thickness: 1,
                  indent: 4,
                  endIndent: 4,
                  color: AppColors.outlineVariant,
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyCatalog extends StatelessWidget {
  const _EmptyCatalog();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          const IconTile(
            icon: Symbols.home_repair_service,
            size: 64,
            iconSize: 30,
            radius: AppRadius.lg,
            background: AppColors.surfaceContainer,
            foreground: AppColors.outline,
          ),
          const SizedBox(height: 16),
          Text('No services match', style: AppText.titleMd),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Try a different category, or add a new offering to your '
              'catalogue.',
              textAlign: TextAlign.center,
              style: AppText.bodySm,
            ),
          ),
        ],
      ),
    );
  }
}
