import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/format/money.dart';
import '../../../core/format/relative_time.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/app_bars.dart';
import '../../../shared/widgets/bottom_dock.dart';
import '../../../shared/widgets/chips.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../../shared/widgets/mock_map.dart';
import '../domain/lead.dart';
import 'leads_providers.dart';

/// Full lead view with the quote composer.
///
/// Mirrors `partner_lead_detail_native_mobile`.
class LeadDetailScreen extends ConsumerStatefulWidget {
  const LeadDetailScreen({super.key, required this.leadId});

  final String leadId;

  @override
  ConsumerState<LeadDetailScreen> createState() => _LeadDetailScreenState();
}

enum _QuotePhase { idle, submitting, sent }

class _LeadDetailScreenState extends ConsumerState<LeadDetailScreen> {
  final _amount = TextEditingController();
  final _note = TextEditingController();

  _QuotePhase _phase = _QuotePhase.idle;
  bool _seeded = false;

  /// The design clamps the quote to a ₹100 floor.
  static const _minQuote = 100;

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  int get _amountValue => Money.parse(_amount.text) ?? 0;

  void _setAmount(int value) {
    final clamped = value < _minQuote ? _minQuote : value;
    _amount.value = TextEditingValue(
      text: Money.plain(clamped),
      selection: TextSelection.collapsed(
        offset: Money.plain(clamped).length,
      ),
    );
    setState(() {});
  }

  Future<void> _send() async {
    if (_phase != _QuotePhase.idle || _amountValue < _minQuote) return;
    setState(() => _phase = _QuotePhase.submitting);

    try {
      await ref.read(leadActionsProvider).submitQuote(
            widget.leadId,
            amount: _amountValue,
            note: _note.text.trim().isEmpty ? null : _note.text.trim(),
          );
      if (!mounted) return;
      setState(() => _phase = _QuotePhase.sent);

      // The design reverts the button after a beat.
      await Future<void>.delayed(const Duration(milliseconds: 2500));
      if (mounted) setState(() => _phase = _QuotePhase.idle);
    } catch (_) {
      if (mounted) setState(() => _phase = _QuotePhase.idle);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lead = ref.watch(leadDetailProvider(widget.leadId));

    return Scaffold(
      appBar: StandaloneAppBar(
        title: 'Lead Details',
        subtitle: lead.value == null
            ? 'InFio Business'
            : 'InFio Business • Ref #${lead.value!.reference}',
        actions: [
          CircleIconButton(
            icon: Symbols.share,
            background: Colors.transparent,
            onPressed: () {},
            tooltip: 'Share lead',
          ),
          CircleIconButton(
            icon: Symbols.more_vert,
            background: Colors.transparent,
            onPressed: () {},
            tooltip: 'More',
          ),
        ],
      ),
      body: lead.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const Center(child: Text('Could not load this lead.')),
        data: (l) {
          // Seed the quote field from the server's suggestion once.
          if (!_seeded) {
            _seeded = true;
            _amount.text = Money.plain(l.suggestedQuote ?? l.budgetMin ?? 0);
            _note.text = 'Can visit by 5:30 PM with genuine refrigerant gas';
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.containerMargin,
              AppSpacing.stackMd,
              AppSpacing.containerMargin,
              AppSpacing.stackLg,
            ),
            children: [
              if (l.urgency.isUrgent) ...[
                _UrgentBanner(lead: l),
                const SizedBox(height: AppSpacing.stackMd),
              ],
              _CustomerCard(lead: l),
              const SizedBox(height: AppSpacing.stackMd),
              _ServiceCard(lead: l),
              if (l.photos.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.stackMd),
                _PhotosCard(lead: l),
              ],
              const SizedBox(height: AppSpacing.stackMd),
              _quoteCard(l),
              const SizedBox(height: AppSpacing.stackMd),
              _LocationCard(lead: l),
            ],
          );
        },
      ),
      bottomNavigationBar: lead.value == null
          ? null
          : _dock(lead.requireValue),
    );
  }

  Widget _quoteCard(Lead lead) {
    return GlassCard(
      radius: AppRadius.lg,
      borderColor: AppColors.primary.withValues(alpha: 0.2),
      padding: const EdgeInsets.all(AppSpacing.stackMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Symbols.payments,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Enter Your Quote / Estimate',
                  style: AppText.title15.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              if (lead.suggestedQuote != null)
                StatusChip.primary(
                  label: 'Suggested: ${Money.rupees(lead.suggestedQuote!)}',
                  dense: true,
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Amount field with a large rupee prefix.
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: AppRadius.brMd,
              border: Border.all(color: AppColors.primaryContainer, width: 1.5),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                Text(
                  '₹',
                  style: AppText.headlineLg.copyWith(
                    color: AppColors.primary,
                    fontSize: 22,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _amount,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: AppText.headlineLg.copyWith(fontSize: 22),
                    decoration: const InputDecoration(
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 14),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                Text('INR Total', style: AppText.label11),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Quick adjust.
          Row(
            children: [
              Expanded(
                child: _AdjustPill(
                  label: '- ₹50',
                  onTap: () => _setAmount(_amountValue - 50),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _AdjustPill(
                  label: '+ ₹50',
                  onTap: () => _setAmount(_amountValue + 50),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _AdjustPill(
                  label: 'Match Budget',
                  emphasised: true,
                  onTap: () => _setAmount(
                    lead.budgetMin ?? lead.suggestedQuote ?? _minQuote,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          Row(
            children: [
              const Icon(
                Symbols.edit_note,
                size: 17,
                color: AppColors.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  'Message / Visit Note to Customer',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.label11.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _note,
            style: AppText.body13.copyWith(color: AppColors.onSurface),
            decoration: const InputDecoration(
              hintText: 'e.g. Free inspection included or parts extra...',
            ),
          ),
        ],
      ),
    );
  }

  Widget _dock(Lead lead) {
    return BottomDock(
      caption: lead.contactRevealed
          ? null
          : 'Customer phone number revealed upon accepting lead',
      child: Column(
        children: [
          switch (_phase) {
            _QuotePhase.idle => GradientButton(
                label: 'Send Quote (${Money.rupees(_amountValue)})',
                leadingIcon: Symbols.bolt,
                height: 52,
                enabled: _amountValue >= _minQuote,
                onPressed: _send,
              ),
            _QuotePhase.submitting => const GradientButton(
                label: 'Submitting Quote...',
                height: 52,
                busy: true,
              ),
            _QuotePhase.sent => const GradientButton(
                label: 'Quote Sent Successfully',
                leadingIcon: Symbols.check_circle,
                height: 52,
                fillColor: AppColors.success,
              ),
          },
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlineActionButton(
                  label: 'Call Now',
                  icon: Symbols.call,
                  height: 46,
                  foreground: AppColors.primary,
                  onPressed: () {},
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlineActionButton(
                  label: 'WhatsApp',
                  icon: Symbols.chat,
                  height: 46,
                  foreground: AppColors.successDark,
                  background: AppColors.successBright.withValues(alpha: 0.1),
                  borderColor: AppColors.successBright.withValues(alpha: 0.3),
                  onPressed: () {},
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UrgentBanner extends StatelessWidget {
  const _UrgentBanner({required this.lead});

  final Lead lead;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.roseSurface,
        borderRadius: AppRadius.brMd,
        border: Border.all(color: AppColors.roseBorder),
      ),
      child: Row(
        children: [
          const PulsingDot(color: AppColors.error, size: 8),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'URGENT REQUIREMENT',
              style: AppText.label11.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
              ),
            ),
          ),
          const Icon(
            Symbols.schedule,
            size: 14,
            color: AppColors.onErrorContainer,
          ),
          const SizedBox(width: 4),
          Text(
            RelativeTime.format(lead.createdAt),
            style: AppText.label11.copyWith(
              color: AppColors.onErrorContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  const _CustomerCard({required this.lead});

  final Lead lead;

  @override
  Widget build(BuildContext context) {
    final initials = lead.customerName
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => p[0].toUpperCase())
        .join();

    return GlassCard(
      radius: AppRadius.lg,
      padding: const EdgeInsets.all(AppSpacing.stackMd),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.primaryFixed,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  initials,
                  style: AppText.titleMd.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            lead.customerName,
                            style: AppText.titleMd.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (lead.customerVerified) ...[
                          const SizedBox(width: 8),
                          const StatusChip.success(
                            label: 'Verified',
                            icon: Symbols.check_circle,
                            iconFill: 1,
                            dense: true,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(
                          Symbols.location_on,
                          size: 15,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            '${lead.locality} (${lead.distanceKm} km away)',
                            style: AppText.label11,
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

          // Budget.
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primaryFixed.withValues(alpha: 0.45),
              borderRadius: AppRadius.brMd,
            ),
            child: Row(
              children: [
                const Icon(
                  Symbols.account_balance_wallet,
                  size: 17,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Customer Budget',
                    style: AppText.label11.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                  ),
                ),
                Text(
                  lead.budgetLabel,
                  style: AppText.titleMd.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (lead.budgetIsFixed)
                  Text(' (Fixed)', style: AppText.label10),
              ],
            ),
          ),

          if (lead.viewedByOtherPros > 0) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: AppRadius.brMd,
              ),
              child: Row(
                children: [
                  const Icon(
                    Symbols.visibility,
                    size: 16,
                    color: AppColors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        style: AppText.label11,
                        children: [
                          TextSpan(
                            text: '${lead.viewedByOtherPros} other pros '
                                'viewed this',
                          ),
                          if (lead.matchRate != null) ...[
                            const TextSpan(text: ' • '),
                            TextSpan(
                              text: lead.matchRate,
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({required this.lead});

  final Lead lead;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: AppRadius.lg,
      padding: const EdgeInsets.all(AppSpacing.stackMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconTile(
                icon: LeadVisuals.icon(lead.categorySlug),
                size: 34,
                iconSize: 18,
                background: LeadVisuals.background(lead.categorySlug),
                foreground: LeadVisuals.foreground(lead.categorySlug),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Requested Service', style: AppText.label10),
                    const SizedBox(height: 1),
                    Text(
                      lead.serviceName,
                      style: AppText.titleMd,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 12),

          // Job description, rendered as a quote.
          Stack(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: AppRadius.brMd,
                  border: Border.all(
                    color: AppColors.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                child: Text(
                  '"${lead.description}"',
                  style: AppText.body13.copyWith(
                    color: AppColors.onSurface,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              Positioned(
                right: 8,
                top: 4,
                child: Icon(
                  Symbols.format_quote,
                  size: 22,
                  color: AppColors.outlineVariant.withValues(alpha: 0.7),
                  fill: 1,
                ),
              ),
            ],
          ),

          if (lead.preferredSlot != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: AppRadius.brMd,
              ),
              child: Row(
                children: [
                  const Icon(
                    Symbols.event_available,
                    size: 17,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Text('Preferred Slot: ', style: AppText.label11),
                  Expanded(
                    child: Text(
                      lead.preferredSlot!,
                      style: AppText.label11.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PhotosCard extends StatelessWidget {
  const _PhotosCard({required this.lead});

  final Lead lead;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: AppRadius.lg,
      padding: const EdgeInsets.all(AppSpacing.stackMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Symbols.photo_library,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Customer Photos (${lead.photos.length})',
                  style: AppText.title15.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              const Icon(
                Symbols.zoom_in,
                size: 15,
                color: AppColors.onSurfaceVariant,
              ),
              const SizedBox(width: 3),
              Text('Tap to zoom', style: AppText.label10),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (var i = 0; i < lead.photos.length; i++) ...[
                Expanded(child: _PhotoTile(photo: lead.photos[i])),
                if (i != lead.photos.length - 1)
                  const SizedBox(width: AppSpacing.gridGutter),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Customer photos are not bundled with the app, so each tile renders a
/// tinted placeholder carrying the caption the API supplies.
class _PhotoTile extends StatelessWidget {
  const _PhotoTile({required this.photo});

  final LeadPhoto photo;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 4 / 3,
      child: ClipRRect(
        borderRadius: AppRadius.brMd,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.surfaceContainerHigh,
                    AppColors.surfaceContainer,
                  ],
                ),
              ),
            ),
            const Center(
              child: Icon(
                Symbols.image,
                size: 28,
                color: AppColors.outline,
              ),
            ),
            Positioned(
              right: 6,
              bottom: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 7,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: AppColors.slate900.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Symbols.zoom_in,
                      size: 11,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      photo.caption,
                      style: AppText.label10.copyWith(
                        color: Colors.white,
                        fontSize: 9.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationCard extends StatelessWidget {
  const _LocationCard({required this.lead});

  final Lead lead;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: AppRadius.lg,
      padding: const EdgeInsets.all(AppSpacing.stackMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Symbols.explore,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Service Location',
                  style: AppText.title15.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              GestureDetector(
                onTap: () {},
                child: Text(
                  'Open Maps',
                  style: AppText.label11.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          MockMapView.route(
            distanceKm: lead.distanceKm,
            driveTime: lead.driveTime ?? 'Drive time unavailable',
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Symbols.near_me,
                size: 15,
                color: AppColors.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  lead.fullAddress ?? lead.locality,
                  style: AppText.body13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AdjustPill extends StatelessWidget {
  const _AdjustPill({
    required this.label,
    required this.onTap,
    this.emphasised = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool emphasised;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: emphasised
              ? AppColors.primaryFixed
              : AppColors.surfaceContainerLow,
          borderRadius: AppRadius.brBase,
          border: Border.all(
            color: emphasised
                ? AppColors.primaryContainer.withValues(alpha: 0.4)
                : AppColors.outlineVariant,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: AppText.label11.copyWith(
            color: emphasised ? AppColors.primary : AppColors.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
