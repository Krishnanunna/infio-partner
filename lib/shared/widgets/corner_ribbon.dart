import 'package:flutter/material.dart';

import '../../core/theme/gradients.dart';
import '../../core/theme/text_styles.dart';
import '../../core/theme/tokens.dart';

/// The badge that sits in the top-right corner of a featured plan card,
/// flush to the card edge with only the bottom-left corner rounded.
///
/// Appears as "RECOMMENDED", "MOST POPULAR" and "Most Popular" across the
/// three membership screens.
class CornerRibbon extends StatelessWidget {
  const CornerRibbon({
    super.key,
    required this.label,
    this.icon,
    this.gradient = AppGradients.cta,
    this.iconColor,
    this.radius = AppRadius.md,
  });

  final String label;
  final IconData? icon;
  final Gradient gradient;
  final Color? iconColor;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(radius),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: iconColor ?? Colors.white, fill: 1),
            const SizedBox(width: 4),
          ],
          Text(
            label.toUpperCase(),
            style: AppText.label10.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.7,
            ),
          ),
        ],
      ),
    );
  }
}
