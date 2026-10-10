import 'dart:io';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/theme/gradients.dart';
import '../../core/theme/text_styles.dart';
import '../../core/theme/tokens.dart';

/// A dashed photo-upload target with the three states from the design:
/// empty-emphasised (purple dashes, the next slot to fill), empty-neutral
/// (grey dashes, later slots), and filled (the image with a delete button
/// and an optional caption).
class UploadSlot extends StatelessWidget {
  const UploadSlot({
    super.key,
    this.file,
    this.caption,
    this.slotLabel,
    this.emphasised = false,
    this.onTap,
    this.onDelete,
    this.radius = AppRadius.md,
    this.emptyIcon,
    this.emptyLabel = '+ Add',
    this.aspectRatio = 1,
    this.height,
  });

  /// When non-null the slot renders filled.
  final File? file;

  /// Overlay caption on a filled slot, e.g. "AC Unit Repair".
  final String? caption;

  /// Sub-label on an empty slot, e.g. "Slot 3".
  final String? slotLabel;

  /// Purple dashed treatment, marking the next slot to fill.
  final bool emphasised;

  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final double radius;
  final IconData? emptyIcon;
  final String emptyLabel;
  final double aspectRatio;

  /// Fixed height; when null the slot uses [aspectRatio].
  final double? height;

  @override
  Widget build(BuildContext context) {
    final content = file == null ? _empty() : _filled();

    final sized = height != null
        ? SizedBox(height: height, width: double.infinity, child: content)
        : AspectRatio(aspectRatio: aspectRatio, child: content);

    return sized;
  }

  Widget _empty() {
    final dashColor = emphasised
        ? AppColors.primary.withValues(alpha: 0.4)
        : AppColors.outlineVariant.withValues(alpha: 0.8);
    final fill = emphasised
        ? AppColors.primaryFixed.withValues(alpha: 0.2)
        : AppColors.surfaceContainerLow;

    return GestureDetector(
      onTap: onTap,
      child: CustomPaint(
        painter: _DashedBorderPainter(color: dashColor, radius: radius),
        child: Container(
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(radius),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: emphasised
                      ? AppColors.primaryContainer
                      : AppColors.surfaceContainerHigh,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  emptyIcon ??
                      (emphasised ? Symbols.add_a_photo : Symbols.add),
                  size: 17,
                  color: emphasised ? Colors.white : AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                emptyLabel,
                style: AppText.label11.copyWith(
                  fontWeight: FontWeight.w700,
                  color: emphasised
                      ? AppColors.primary
                      : AppColors.onSurfaceVariant,
                ),
              ),
              if (slotLabel != null) ...[
                const SizedBox(height: 1),
                Text(
                  slotLabel!,
                  style: AppText.label10.copyWith(
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                    color: AppColors.outline,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _filled() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.file(file!, fit: BoxFit.cover),
          if (caption != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(8, 14, 8, 6),
                decoration: const BoxDecoration(gradient: AppGradients.photoScrim),
                child: Text(
                  caption!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.label10.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          if (onDelete != null)
            Positioned(
              top: 6,
              right: 6,
              child: GestureDetector(
                onTap: onDelete,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppColors.inverseSurface.withValues(alpha: 0.75),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Symbols.close,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Paints a rounded dashed rectangle. Flutter has no dashed border, and the
/// upload slots rely on one.
class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  static const strokeWidth = 2.0;
  static const dashLength = 6.0;
  static const gapLength = 4.0;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          Radius.circular(radius),
        ),
      );

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = (distance + dashLength).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance = end + gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) =>
      old.color != color || old.radius != radius;
}
