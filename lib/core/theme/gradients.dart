import 'package:flutter/material.dart';

import 'tokens.dart';

/// Named gradients lifted from the Stitch exports.
///
/// The exports use slightly different stops per screen; these constants keep
/// each variant in one place instead of inlining hex values at call sites.
abstract final class AppGradients {
  /// The standard CTA / progress-bar gradient: primary -> primary-container.
  static const cta = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [AppColors.primary, AppColors.primaryContainer],
  );

  /// Same ramp, top to bottom. Used on the onboarding step-1 continue button.
  static const ctaVertical = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.primaryContainer, AppColors.primary],
  );

  /// 135-degree variant used by the standalone membership CTA and OTP hero.
  static const ctaDiagonal = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.primary, AppColors.primaryContainer],
  );

  /// Three-stop gradient used on the video-KYC submit button and trust banner.
  static const kyc = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.primary, Color(0xFF982FE0), AppColors.primaryContainer],
  );

  /// Landing hero gradient; the third stop leans indigo for the "pro" feel.
  static const heroPro = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.primary, AppColors.primaryContainer, Color(0xFF4B5BE7)],
  );

  /// The record button on the video-KYC viewfinder.
  static const record = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.primary, Color(0xFFC15EFF)],
  );

  /// The dashboard membership card.
  static const membershipCard = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF7A14C4), AppColors.primary, Color(0xFFAB46F7)],
  );

  /// Step-4 plan CTA, which deepens toward magenta.
  static const planCta = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [AppColors.primary, Color(0xFF9626E2), Color(0xFF8E24AA)],
  );

  /// Add-service intro banner: purple into indigo.
  static const serviceBanner = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [AppColors.primary, Color(0xFF6366F1)],
  );

  /// Scrim laid over photos so overlay chips stay legible.
  static const photoScrim = LinearGradient(
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
    colors: [Color(0x99000000), Color(0x00000000)],
  );

  /// Vertical scrim for the camera viewfinder.
  static const viewfinderScrim = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0x66000000), Color(0x00000000), Color(0xB3000000)],
    stops: [0.0, 0.45, 1.0],
  );
}

/// Soft, diffused elevation. The design system calls for depth via blur and
/// tonal layering rather than heavy shadows.
abstract final class AppShadows {
  static const soft = [
    BoxShadow(color: Color(0x14000000), blurRadius: 30, offset: Offset(0, 8)),
  ];

  static const card = [
    BoxShadow(color: Color(0x0D000000), blurRadius: 20, offset: Offset(0, 4)),
  ];

  /// Purple-tinted glow under primary CTAs.
  static const primaryGlow = [
    BoxShadow(color: Color(0x408A19D8), blurRadius: 20, offset: Offset(0, 8)),
  ];

  /// Upward shadow for the sticky bottom docks.
  static const dock = [
    BoxShadow(color: Color(0x0F000000), blurRadius: 30, offset: Offset(0, -8)),
  ];
}
