import 'package:flutter/material.dart';

import '../../core/theme/gradients.dart';
import '../../core/theme/text_styles.dart';
import '../../core/theme/tokens.dart';

/// The InFio mark.
///
/// The Stitch exports load the logo from a remote URL. Drawing it instead
/// keeps the app free of network assets and matches the growth screen,
/// which already renders the mark as a gradient tile with the letters "In".
class InfioLogo extends StatelessWidget {
  const InfioLogo({
    super.key,
    this.size = 40,
    this.radius = AppRadius.md,
    this.shape = BoxShape.rectangle,
  });

  final double size;
  final double radius;
  final BoxShape shape;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: AppGradients.ctaDiagonal,
        shape: shape,
        borderRadius:
            shape == BoxShape.circle ? null : BorderRadius.circular(radius),
        boxShadow: AppShadows.primaryGlow,
      ),
      child: Text(
        'In',
        style: AppText.title15.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: size * 0.42,
        ),
      ),
    );
  }
}

/// The stacked wordmark: "InFio" over a coloured sub-label.
class InfioWordmark extends StatelessWidget {
  const InfioWordmark({
    super.key,
    this.subLabel = 'BUSINESS',
    this.titleSize = 22,
  });

  final String subLabel;
  final double titleSize;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'InFio',
          style: AppText.headlineLgMobile.copyWith(
            fontSize: titleSize,
            fontWeight: FontWeight.w800,
            height: 1.1,
          ),
        ),
        Text(
          subLabel,
          style: AppText.label10.copyWith(
            color: AppColors.primaryContainer,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.6,
          ),
        ),
      ],
    );
  }
}

/// Soft ambient colour blobs behind a screen's content, as the auth screens
/// use. Rendered under the scroll view inside a [Stack].
class AmbientBlobs extends StatelessWidget {
  const AmbientBlobs({super.key, this.blobs = const []});

  final List<AmbientBlob> blobs;

  /// The purple-and-neutral pairing used on the landing and login screens.
  static const partner = [
    AmbientBlob(
      top: -60,
      right: -70,
      size: 280,
      color: AppColors.primaryFixed,
      opacity: 0.55,
    ),
    AmbientBlob(
      top: 300,
      left: -90,
      size: 300,
      color: AppColors.surfaceVariant,
      opacity: 0.5,
    ),
  ];

  /// The emerald-tinted set used by the consumer signup screen.
  static const consumer = [
    AmbientBlob(
      top: -70,
      left: -60,
      size: 280,
      color: Color(0xFF6EE7B7),
      opacity: 0.3,
    ),
    AmbientBlob(
      top: 220,
      right: -80,
      size: 300,
      color: AppColors.primaryFixed,
      opacity: 0.45,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          for (final blob in blobs)
            Positioned(
              top: blob.top,
              left: blob.left,
              right: blob.right,
              bottom: blob.bottom,
              child: Container(
                width: blob.size,
                height: blob.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      blob.color.withValues(alpha: blob.opacity),
                      blob.color.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class AmbientBlob {
  const AmbientBlob({
    required this.size,
    required this.color,
    this.opacity = 0.4,
    this.top,
    this.left,
    this.right,
    this.bottom,
  });

  final double size;
  final Color color;
  final double opacity;
  final double? top;
  final double? left;
  final double? right;
  final double? bottom;
}
