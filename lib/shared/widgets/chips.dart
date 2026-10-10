import 'package:flutter/material.dart';

import '../../core/theme/text_styles.dart';
import '../../core/theme/tokens.dart';

/// The pill vocabulary shared across screens: status badges, counters,
/// verification markers and category tags.
///
/// A single widget with named constructors keeps the many one-off pills in
/// the exports from each growing their own implementation.
class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    this.icon,
    this.background = AppColors.surfaceContainerHigh,
    this.foreground = AppColors.onSurfaceVariant,
    this.borderColor,
    this.radius = AppRadius.full,
    this.uppercase = false,
    this.dense = false,
    this.showDot = false,
    this.dotColor,
    this.iconFill = 0,
    this.textStyle,
  });

  /// Purple pill — the default "primary" marker (step badges, plan tiers).
  const StatusChip.primary({
    super.key,
    required this.label,
    this.icon,
    this.uppercase = false,
    this.dense = false,
    this.showDot = false,
    this.dotColor,
    this.iconFill = 0,
    this.textStyle,
    this.radius = AppRadius.full,
  })  : background = AppColors.primaryFixed,
        foreground = AppColors.onPrimaryFixed,
        borderColor = null;

  /// Solid purple with white text — "PRO", "Top Tier".
  const StatusChip.primarySolid({
    super.key,
    required this.label,
    this.icon,
    this.uppercase = true,
    this.dense = true,
    this.showDot = false,
    this.dotColor,
    this.iconFill = 0,
    this.textStyle,
    this.radius = AppRadius.full,
  })  : background = AppColors.primary,
        foreground = Colors.white,
        borderColor = null;

  /// Green — "Verified", "Online", "GPS Ready".
  const StatusChip.success({
    super.key,
    required this.label,
    this.icon,
    this.uppercase = false,
    this.dense = false,
    this.showDot = false,
    this.dotColor,
    this.iconFill = 0,
    this.textStyle,
    this.radius = AppRadius.full,
  })  : background = AppColors.successSurface,
        foreground = AppColors.onSuccessSurface,
        borderColor = AppColors.successBorder;

  /// Red container — the lead expiry countdown.
  const StatusChip.error({
    super.key,
    required this.label,
    this.icon,
    this.uppercase = false,
    this.dense = false,
    this.showDot = false,
    this.dotColor,
    this.iconFill = 0,
    this.textStyle,
    this.radius = AppRadius.full,
  })  : background = AppColors.errorContainer,
        foreground = AppColors.onErrorContainer,
        borderColor = null;

  /// Solid red — "URGENT".
  const StatusChip.urgent({
    super.key,
    required this.label,
    this.icon,
    this.uppercase = true,
    this.dense = true,
    this.showDot = false,
    this.dotColor,
    this.iconFill = 0,
    this.textStyle,
    this.radius = AppRadius.full,
  })  : background = AppColors.error,
        foreground = Colors.white,
        borderColor = null;

  /// Amber — "In Review", "Action Needed", ratings.
  const StatusChip.warning({
    super.key,
    required this.label,
    this.icon,
    this.uppercase = false,
    this.dense = false,
    this.showDot = false,
    this.dotColor,
    this.iconFill = 0,
    this.textStyle,
    this.radius = AppRadius.full,
  })  : background = AppColors.amberSurfaceAlt,
        foreground = AppColors.amberText,
        borderColor = AppColors.amberBorder;

  /// Neutral grey — "Standard", relative timestamps.
  const StatusChip.neutral({
    super.key,
    required this.label,
    this.icon,
    this.uppercase = false,
    this.dense = false,
    this.showDot = false,
    this.dotColor,
    this.iconFill = 0,
    this.textStyle,
    this.radius = AppRadius.full,
  })  : background = AppColors.surfaceContainerHigh,
        foreground = AppColors.onSurfaceVariant,
        borderColor = null;

  final String label;
  final IconData? icon;
  final Color background;
  final Color foreground;
  final Color? borderColor;
  final double radius;
  final bool uppercase;
  final bool dense;
  final bool showDot;
  final Color? dotColor;
  final double iconFill;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final base = textStyle ??
        (dense
            ? AppText.label10
            : AppText.label11.copyWith(fontWeight: FontWeight.w700));

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 7 : 10,
        vertical: dense ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(radius),
        border: borderColor == null ? null : Border.all(color: borderColor!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot) ...[
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: dotColor ?? foreground,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
          ],
          if (icon != null) ...[
            Icon(icon, size: dense ? 12 : 14, color: foreground, fill: iconFill),
            const SizedBox(width: 4),
          ],
          // Flexible so a long label ellipsizes instead of overflowing the
          // pill on narrow handsets.
          Flexible(
            child: Text(
              uppercase ? label.toUpperCase() : label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: base.copyWith(
                color: foreground,
                letterSpacing: uppercase ? 0.6 : base.letterSpacing,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A small square-ish tile holding an icon — the leading element of settings
/// rows, section-card headers and quick-action tiles.
class IconTile extends StatelessWidget {
  const IconTile({
    super.key,
    required this.icon,
    this.size = 36,
    this.iconSize = 20,
    this.background = AppColors.surfaceContainer,
    this.foreground = AppColors.primary,
    this.radius = AppRadius.md,
    this.gradient,
    this.fill = 0,
    this.shape = BoxShape.rectangle,
  });

  final IconData icon;
  final double size;
  final double iconSize;
  final Color background;
  final Color foreground;
  final double radius;
  final Gradient? gradient;
  final double fill;
  final BoxShape shape;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: gradient == null ? background : null,
        gradient: gradient,
        shape: shape,
        borderRadius:
            shape == BoxShape.circle ? null : BorderRadius.circular(radius),
      ),
      child: Icon(icon, size: iconSize, color: foreground, fill: fill),
    );
  }
}

/// A pulsing presence dot — used on the "Online" pill, the live lead
/// indicator and the urgent-lead alert.
class PulsingDot extends StatefulWidget {
  const PulsingDot({
    super.key,
    this.color = AppColors.successBright,
    this.size = 8,
  });

  final Color color;
  final double size;

  @override
  State<PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final t = _controller.value;
          return Stack(
            alignment: Alignment.center,
            children: [
              // Expanding halo that fades as it grows.
              Opacity(
                opacity: (1 - t).clamp(0.0, 1.0) * 0.6,
                child: Container(
                  width: widget.size * (1 + t * 1.4),
                  height: widget.size * (1 + t * 1.4),
                  decoration: BoxDecoration(
                    color: widget.color,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              child!,
            ],
          );
        },
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: widget.color,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
