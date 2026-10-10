import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/theme/gradients.dart';
import '../../core/theme/tokens.dart';

/// The backbone of the design system.
///
/// A translucent white fill over a backdrop blur with a 1px light border.
/// DESIGN.md specifies blur(12px) with a 70-80% white fill and a white-20%
/// stroke; individual screens nudge those values, so they are parameters.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.stackMd),
    this.margin,
    this.radius = AppRadius.md,
    this.opacity = 0.80,
    this.blur = 14,
    this.borderColor,
    this.borderWidth = 1,
    this.shadows = AppShadows.card,
    this.gradient,
    this.onTap,
    this.clipBehavior = Clip.antiAlias,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double radius;

  /// White fill opacity, 0-1.
  final double opacity;

  /// Backdrop blur sigma.
  final double blur;

  final Color? borderColor;
  final double borderWidth;
  final List<BoxShadow> shadows;

  /// Overrides the flat white fill when a card is tinted (e.g. plan cards).
  final Gradient? gradient;

  final VoidCallback? onTap;
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    final br = BorderRadius.circular(radius);

    Widget content = Padding(padding: padding, child: child);

    if (onTap != null) {
      content = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: br,
          splashColor: AppColors.primary.withValues(alpha: 0.06),
          highlightColor: AppColors.primary.withValues(alpha: 0.03),
          child: content,
        ),
      );
    }

    return Container(
      margin: margin,
      decoration: BoxDecoration(borderRadius: br, boxShadow: shadows),
      child: ClipRRect(
        borderRadius: br,
        clipBehavior: clipBehavior,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: gradient == null
                  ? Colors.white.withValues(alpha: opacity)
                  : null,
              gradient: gradient,
              borderRadius: br,
              border: Border.all(
                color: borderColor ?? Colors.white.withValues(alpha: 0.65),
                width: borderWidth,
              ),
            ),
            child: content,
          ),
        ),
      ),
    );
  }
}

/// A plain (non-blurred) card for the screens that use solid white panels
/// with a hairline border rather than the glass treatment — the location
/// step, add-service form, and growth cards all do this.
class SolidCard extends StatelessWidget {
  const SolidCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.stackMd),
    this.margin,
    this.radius = AppRadius.lg,
    this.color = AppColors.surfaceContainerLowest,
    this.borderColor,
    this.borderWidth = 1,
    this.shadows = AppShadows.card,
    this.gradient,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double radius;
  final Color color;
  final Color? borderColor;
  final double borderWidth;
  final List<BoxShadow> shadows;
  final Gradient? gradient;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final br = BorderRadius.circular(radius);

    Widget content = Padding(padding: padding, child: child);

    if (onTap != null) {
      content = Material(
        color: Colors.transparent,
        child: InkWell(onTap: onTap, borderRadius: br, child: content),
      );
    }

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: gradient == null ? color : null,
        gradient: gradient,
        borderRadius: br,
        border: Border.all(
          color: borderColor ?? AppColors.outlineVariant.withValues(alpha: 0.6),
          width: borderWidth,
        ),
        boxShadow: shadows,
      ),
      child: ClipRRect(borderRadius: br, child: content),
    );
  }
}
