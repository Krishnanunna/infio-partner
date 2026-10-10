import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/theme/gradients.dart';
import '../../core/theme/text_styles.dart';
import '../../core/theme/tokens.dart';

/// The sticky glass action bar that every wizard and leaf screen pins to the
/// bottom: a blurred panel with a hairline top border, a primary CTA, and an
/// optional secondary link or caption beneath it.
class BottomDock extends StatelessWidget {
  const BottomDock({
    super.key,
    required this.child,
    this.caption,
    this.secondary,
    this.padding = const EdgeInsets.fromLTRB(
      AppSpacing.containerMargin,
      12,
      AppSpacing.containerMargin,
      12,
    ),
    this.opacity = 0.92,
  });

  /// The primary action, usually a [GradientButton].
  final Widget child;

  /// Small muted text under the CTA, e.g. "Instant activation • Cancel anytime".
  final String? caption;

  /// A secondary action below the CTA, e.g. "Save Draft & Exit".
  final Widget? secondary;

  final EdgeInsetsGeometry padding;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: opacity),
            border: const Border(
              top: BorderSide(color: AppColors.outlineVariant, width: 1),
            ),
            boxShadow: AppShadows.dock,
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: padding,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  child,
                  if (secondary != null) ...[
                    const SizedBox(height: 8),
                    secondary!,
                  ],
                  if (caption != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      caption!,
                      textAlign: TextAlign.center,
                      style: AppText.label11.copyWith(
                        fontWeight: FontWeight.w400,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
