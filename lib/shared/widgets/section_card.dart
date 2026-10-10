import 'package:flutter/material.dart';

import '../../core/theme/text_styles.dart';
import '../../core/theme/tokens.dart';
import 'chips.dart';
import 'glass_card.dart';

/// The onboarding form card: an icon tile, a title and subtitle over a
/// hairline divider, then the fields.
///
/// Step 1 uses three of these ("Owner & Business Identity", "Contact &
/// Communications", "Referral & City Hub"); step 2 and the add-service form
/// use the same shape.
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.children,
    this.subtitle,
    this.trailing,
    this.iconBackground = AppColors.primaryFixed,
    this.iconForeground = AppColors.primary,
    this.radius = AppRadius.xl,
    this.glass = true,
    this.gap = AppSpacing.stackMd,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final List<Widget> children;
  final Color iconBackground;
  final Color iconForeground;
  final double radius;

  /// Step 1 uses the glass treatment; the location step and add-service form
  /// use solid white cards with a hairline border.
  final bool glass;

  final double gap;

  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconTile(
              icon: icon,
              size: 32,
              iconSize: 18,
              background: iconBackground,
              foreground: iconForeground,
              radius: AppRadius.base,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppText.title15.copyWith(fontWeight: FontWeight.w700),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 1),
                    Text(
                      subtitle!,
                      style: AppText.label11.copyWith(
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            ?trailing,
          ],
        ),
        const SizedBox(height: 12),
        const Divider(height: 1, color: AppColors.outlineVariant),
        const SizedBox(height: 16),
        for (var i = 0; i < children.length; i++) ...[
          children[i],
          if (i != children.length - 1) SizedBox(height: gap),
        ],
      ],
    );

    if (glass) {
      return GlassCard(
        radius: radius,
        opacity: 0.90,
        blur: 8,
        padding: const EdgeInsets.all(AppSpacing.stackMd),
        child: content,
      );
    }

    return SolidCard(
      radius: radius,
      borderColor: AppColors.outlineVariant.withValues(alpha: 0.7),
      padding: const EdgeInsets.all(AppSpacing.stackMd),
      child: content,
    );
  }
}

/// A small uppercase section label, as used above the profile menu groups
/// and the service-catalog list.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text.toUpperCase(),
              style: AppText.label11.copyWith(
                color: AppColors.secondary,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.7,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// A labelled form field wrapper: a `label-md` label above the control, with
/// optional required marker and a right-aligned helper hint.
class FieldLabel extends StatelessWidget {
  const FieldLabel({
    super.key,
    required this.label,
    required this.child,
    this.required = false,
    this.hint,
    this.badge,
  });

  final String label;
  final Widget child;
  final bool required;

  /// Right-aligned helper, e.g. "Publicly displayed", "(Optional)".
  final String? hint;

  /// Right-aligned widget that replaces [hint], e.g. the ₹500 bonus badge.
  final Widget? badge;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: RichText(
                text: TextSpan(
                  text: label,
                  style: AppText.labelMd.copyWith(
                    color: AppColors.onSurfaceVariant,
                    letterSpacing: 0.2,
                  ),
                  children: [
                    if (required)
                      const TextSpan(
                        text: ' *',
                        style: TextStyle(color: AppColors.error),
                      ),
                  ],
                ),
              ),
            ),
            if (badge != null)
              badge!
            else if (hint != null)
              Text(
                hint!,
                style: AppText.label10.copyWith(
                  fontWeight: FontWeight.w500,
                  color: AppColors.outline,
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}
