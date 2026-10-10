import 'package:flutter/material.dart';

/// Design tokens transcribed from `hyperlocal_glass_modern/DESIGN.md`.
///
/// These are the single source of truth for colour, radius and spacing.
/// Screens must compose from here rather than re-declaring hex values.
abstract final class AppColors {
  // Primary ramp
  static const primary = Color(0xFF8A19D8);
  static const onPrimary = Color(0xFFFFFFFF);
  static const primaryContainer = Color(0xFFA540F3);
  static const onPrimaryContainer = Color(0xFFFFFFFF);
  static const primaryFixed = Color(0xFFF2DAFF);
  static const primaryFixedDim = Color(0xFFE0B6FF);
  static const onPrimaryFixed = Color(0xFF2E004E);
  static const onPrimaryFixedVariant = Color(0xFF6C00AE);
  static const inversePrimary = Color(0xFFE0B6FF);
  static const surfaceTint = Color(0xFF8B1BD9);

  // Surfaces
  static const surface = Color(0xFFF9F9FF);
  static const surfaceDim = Color(0xFFD3DAEA);
  static const surfaceBright = Color(0xFFF9F9FF);
  static const surfaceContainerLowest = Color(0xFFFFFFFF);
  static const surfaceContainerLow = Color(0xFFF0F3FF);
  static const surfaceContainer = Color(0xFFE7EEFE);
  static const surfaceContainerHigh = Color(0xFFE2E8F8);
  static const surfaceContainerHighest = Color(0xFFDCE2F3);
  static const surfaceVariant = Color(0xFFDCE2F3);
  static const onSurface = Color(0xFF151C27);
  static const onSurfaceVariant = Color(0xFF4D4354);
  static const inverseSurface = Color(0xFF2A313D);
  static const inverseOnSurface = Color(0xFFEBF1FF);

  // Outlines
  static const outline = Color(0xFF7F7386);
  static const outlineVariant = Color(0xFFD0C1D7);

  // Secondary
  static const secondary = Color(0xFF5F5E5E);
  static const onSecondary = Color(0xFFFFFFFF);
  static const secondaryContainer = Color(0xFFE5E2E1);
  static const onSecondaryContainer = Color(0xFF656464);

  // Tertiary (amber / warm accents: ratings, highlights, cautions)
  static const tertiary = Color(0xFF835400);
  static const onTertiary = Color(0xFFFFFFFF);
  static const tertiaryContainer = Color(0xFFA46A00);
  static const onTertiaryContainer = Color(0xFFFFFFFF);
  static const tertiaryFixed = Color(0xFFFFDDB5);
  static const tertiaryFixedDim = Color(0xFFFFB958);
  static const onTertiaryFixed = Color(0xFF2A1800);
  static const onTertiaryFixedVariant = Color(0xFF643F00);

  // Error
  static const error = Color(0xFFBA1A1A);
  static const onError = Color(0xFFFFFFFF);
  static const errorContainer = Color(0xFFFFDAD6);
  static const onErrorContainer = Color(0xFF93000A);

  // --- Accents present in the Stitch markup but absent from DESIGN.md ---

  /// WhatsApp brand green, used on the WhatsApp CTA and alert opt-in.
  static const whatsapp = Color(0xFF25D366);
  static const whatsappDark = Color(0xFF128C7E);

  /// Success / verified green used for "Verified" pills and sent-quote states.
  static const success = Color(0xFF16A34A);
  static const successBright = Color(0xFF22C55E);
  static const successDark = Color(0xFF15803D);
  static const successSurface = Color(0xFFD1FAE5);
  static const successBorder = Color(0xFFA7F3D0);
  static const onSuccessSurface = Color(0xFF065F46);

  /// Blue analytics accent — the partner side of the marketplace.
  static const analyticsBlue = Color(0xFF2563EB);
  static const analyticsBlueSurface = Color(0xFFEFF6FF);
  static const analyticsBlueDark = Color(0xFF1D4ED8);

  /// Amber, for ratings and the pending-admin-approval card.
  static const amber = Color(0xFFC2410C);
  static const amberSurface = Color(0xFFFFF7ED);
  static const amberSurfaceAlt = Color(0xFFFFEDD5);
  static const amberBorder = Color(0xFFFED7AA);
  static const amberText = Color(0xFF9A3412);
  static const star = Color(0xFFF59E0B);

  /// Rose, for the urgent lead treatment.
  static const rose = Color(0xFFE11D48);
  static const roseSurface = Color(0xFFFFF1F2);
  static const roseBorder = Color(0xFFFECDD3);

  /// Neutral slate ramp used by the location and payment screens.
  static const slate50 = Color(0xFFF8FAFC);
  static const slate100 = Color(0xFFF1F5F9);
  static const slate200 = Color(0xFFE2E8F0);
  static const slate400 = Color(0xFF94A3B8);
  static const slate500 = Color(0xFF64748B);
  static const slate900 = Color(0xFF0F172A);

  /// Glass fills and strokes.
  static const glassFill = Color(0xC7FFFFFF); // white @ ~78%
  static const glassStroke = Color(0x99FFFFFF); // white @ 60%
}

/// Corner radii. 8 for controls, 12 for most cards, 16 for containers,
/// 24 for the onboarding section cards.
abstract final class AppRadius {
  static const sm = 4.0;
  static const base = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const full = 9999.0;

  static const brSm = BorderRadius.all(Radius.circular(sm));
  static const brBase = BorderRadius.all(Radius.circular(base));
  static const brMd = BorderRadius.all(Radius.circular(md));
  static const brLg = BorderRadius.all(Radius.circular(lg));
  static const brXl = BorderRadius.all(Radius.circular(xl));
}

/// 4px baseline spacing scale.
abstract final class AppSpacing {
  static const unit = 4.0;
  static const stackSm = 8.0;
  static const gridGutter = 12.0;
  static const stackMd = 16.0;
  static const containerMargin = 20.0;
  static const stackLg = 24.0;
}
