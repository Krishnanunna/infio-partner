import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/theme/text_styles.dart';
import '../../core/theme/tokens.dart';
import 'chips.dart';

/// A plan feature bullet.
///
/// Three variants appear on the membership screens: an included feature with
/// a filled check, an excluded feature struck through with a cancel icon,
/// and a highlighted feature that sits in its own tinted sub-row with a
/// trailing tier badge ("PRO", "Top Tier").
class FeatureRow extends StatelessWidget {
  const FeatureRow({
    super.key,
    required this.text,
    this.boldPrefix,
    this.included = true,
    this.highlighted = false,
    this.badge,
    this.icon,
    this.iconColor,
    this.textStyle,
  });

  /// The feature copy. Any leading emphasised run goes in [boldPrefix].
  final String text;

  /// Rendered bold ahead of [text], e.g. "Unlimited" in "Unlimited leads".
  final String? boldPrefix;

  final bool included;

  /// Renders the row on a tinted panel with a border, as the "Verified Pro
  /// Partner Badge" row does.
  final bool highlighted;

  /// Trailing tier badge text.
  final String? badge;

  final IconData? icon;
  final Color? iconColor;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final resolvedIcon =
        icon ?? (included ? Symbols.check_circle : Symbols.cancel);
    final resolvedIconColor = iconColor ??
        (included ? AppColors.primary : AppColors.outline);

    final baseStyle = (textStyle ?? AppText.body13).copyWith(
      color: included ? AppColors.onSurface : AppColors.outline,
      decoration: included ? null : TextDecoration.lineThrough,
    );

    final row = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Opacity(
          opacity: included ? 1 : 0.4,
          child: Icon(
            resolvedIcon,
            size: 18,
            color: resolvedIconColor,
            fill: 1,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: baseStyle,
              children: [
                if (boldPrefix != null)
                  TextSpan(
                    text: '$boldPrefix ',
                    style: baseStyle.copyWith(fontWeight: FontWeight.w700),
                  ),
                TextSpan(text: text),
              ],
            ),
          ),
        ),
        if (badge != null) ...[
          const SizedBox(width: 8),
          StatusChip.primarySolid(label: badge!, radius: AppRadius.sm),
        ],
      ],
    );

    if (!highlighted) return row;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: AppRadius.brMd,
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: row,
    );
  }
}
