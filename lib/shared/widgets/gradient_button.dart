import 'package:flutter/material.dart';

import '../../core/theme/gradients.dart';
import '../../core/theme/text_styles.dart';
import '../../core/theme/tokens.dart';

/// The primary CTA across every screen: a gradient-filled pill or rounded
/// rectangle with an optional trailing icon and a soft purple glow.
class GradientButton extends StatelessWidget {
  const GradientButton({
    super.key,
    required this.label,
    this.onPressed,
    this.gradient = AppGradients.cta,
    this.icon,
    this.leadingIcon,
    this.radius = AppRadius.md,
    this.height = 48,
    this.textStyle,
    this.enabled = true,
    this.busy = false,
    this.fillColor,
    this.shadows = AppShadows.primaryGlow,
  });

  final String label;
  final VoidCallback? onPressed;
  final Gradient gradient;

  /// Trailing icon, typically `Symbols.arrow_forward`.
  final IconData? icon;

  /// Leading icon, typically `Symbols.bolt` on lead actions.
  final IconData? leadingIcon;

  final double radius;
  final double height;
  final TextStyle? textStyle;
  final bool enabled;

  /// Replaces the icon with a spinner and blocks taps.
  final bool busy;

  /// Overrides the gradient with a flat colour — used for the success state
  /// after a quote is sent or a lead accepted.
  final Color? fillColor;

  final List<BoxShadow> shadows;

  @override
  Widget build(BuildContext context) {
    final isActive = enabled && !busy && onPressed != null;
    final br = BorderRadius.circular(radius);

    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          gradient: fillColor == null ? gradient : null,
          color: fillColor,
          borderRadius: br,
          boxShadow: isActive ? shadows : const [],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isActive ? onPressed : null,
            borderRadius: br,
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (busy) ...[
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ] else if (leadingIcon != null) ...[
                    Icon(leadingIcon, size: 20, color: Colors.white, fill: 1),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      style: (textStyle ?? AppText.title15).copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (icon != null && !busy) ...[
                    const SizedBox(width: 8),
                    Icon(icon, size: 20, color: Colors.white),
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

/// The glass / outline secondary action: translucent fill with a coloured
/// border. Used for "Cancel", "Decline", "Call Now" and similar.
class OutlineActionButton extends StatelessWidget {
  const OutlineActionButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.radius = AppRadius.md,
    this.height = 48,
    this.foreground = AppColors.primary,
    this.borderColor,
    this.background = AppColors.surfaceContainerLowest,
    this.textStyle,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double radius;
  final double height;
  final Color foreground;
  final Color? borderColor;
  final Color background;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final br = BorderRadius.circular(radius);

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: background,
        borderRadius: br,
        border: Border.all(
          color: borderColor ?? AppColors.outlineVariant,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: br,
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18, color: foreground),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: (textStyle ?? AppText.title15).copyWith(
                      color: foreground,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A circular icon button on a glass/white chip — the back and help buttons
/// in every app bar use this.
class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.size = 40,
    this.iconSize = 20,
    this.background = AppColors.surfaceContainerLowest,
    this.foreground = AppColors.onSurface,
    this.borderColor,
    this.tooltip,
    this.fill = 0,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final double size;
  final double iconSize;
  final Color background;
  final Color foreground;
  final Color? borderColor;
  final String? tooltip;
  final double fill;

  @override
  Widget build(BuildContext context) {
    final button = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background,
        shape: BoxShape.circle,
        border: borderColor == null ? null : Border.all(color: borderColor!),
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: Icon(icon, size: iconSize, color: foreground, fill: fill),
        ),
      ),
    );

    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}
