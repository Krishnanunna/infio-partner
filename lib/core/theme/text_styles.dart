import 'package:flutter/material.dart';

import 'tokens.dart';

/// The Inter type scale from DESIGN.md.
///
/// Sizes are expressed as fontSize with an explicit `height` derived from the
/// design's line-height (lineHeight / fontSize), so vertical rhythm matches
/// the HTML exports.
abstract final class AppText {
  static const _family = 'Inter';

  /// 32/40 w700, -0.02em
  static const displayLg = TextStyle(
    fontFamily: _family,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 40 / 32,
    letterSpacing: -0.64,
    color: AppColors.onSurface,
  );

  /// 24/32 w700
  static const headlineLg = TextStyle(
    fontFamily: _family,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 32 / 24,
    color: AppColors.onSurface,
  );

  /// 22/28 w700 — the mobile headline used by most screen titles.
  static const headlineLgMobile = TextStyle(
    fontFamily: _family,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    height: 28 / 22,
    color: AppColors.onSurface,
  );

  /// 18/24 w600
  static const titleMd = TextStyle(
    fontFamily: _family,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 24 / 18,
    color: AppColors.onSurface,
  );

  /// 16/24 w400
  static const bodyLg = TextStyle(
    fontFamily: _family,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 24 / 16,
    color: AppColors.onSurface,
  );

  /// 14/20 w400
  static const bodySm = TextStyle(
    fontFamily: _family,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 20 / 14,
    color: AppColors.onSurfaceVariant,
  );

  /// 12/16 w600 +0.05em — metadata, category tags, section headers.
  static const labelMd = TextStyle(
    fontFamily: _family,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 16 / 12,
    letterSpacing: 0.6,
    color: AppColors.onSurfaceVariant,
  );

  // --- Supporting sizes the exports rely on but the scale does not name ---

  static const label11 = TextStyle(
    fontFamily: _family,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    height: 16 / 11,
    color: AppColors.onSurfaceVariant,
  );

  static const label10 = TextStyle(
    fontFamily: _family,
    fontSize: 10,
    fontWeight: FontWeight.w700,
    height: 14 / 10,
    letterSpacing: 0.5,
    color: AppColors.onSurfaceVariant,
  );

  static const body13 = TextStyle(
    fontFamily: _family,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 18 / 13,
    color: AppColors.onSurfaceVariant,
  );

  static const title15 = TextStyle(
    fontFamily: _family,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 20 / 15,
    color: AppColors.onSurface,
  );

  static const title20 = TextStyle(
    fontFamily: _family,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 26 / 20,
    color: AppColors.onSurface,
  );

  /// Big numeric readouts: plan prices, metric tile values.
  static const numeral = TextStyle(
    fontFamily: _family,
    fontSize: 28,
    fontWeight: FontWeight.w800,
    height: 32 / 28,
    color: AppColors.onSurface,
  );
}
