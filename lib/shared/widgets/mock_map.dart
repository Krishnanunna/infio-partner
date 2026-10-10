import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/theme/text_styles.dart';
import '../../core/theme/tokens.dart';

/// A design-faithful stand-in for a real map.
///
/// The Stitch exports draw the map as a dotted-grid texture with overlay
/// pins rather than real tiles, so this reproduces that exactly: no API key,
/// no network, and the coverage circle responds to the radius slider.
///
/// Two variants are used. [MockMapView.coverage] powers the onboarding
/// location step; [MockMapView.route] powers the lead detail.
class MockMapView extends StatelessWidget {
  const MockMapView.coverage({
    super.key,
    required this.radiusKm,
    this.maxRadiusKm = 30,
    this.pinLabel = 'Pinned Base',
    this.onAdjust,
    this.height = 112,
  })  : _isRoute = false,
        distanceKm = null,
        driveTime = null;

  const MockMapView.route({
    super.key,
    required this.distanceKm,
    required this.driveTime,
    this.height = 144,
  })  : _isRoute = true,
        radiusKm = 0,
        maxRadiusKm = 30,
        pinLabel = '',
        onAdjust = null;

  final bool _isRoute;

  /// Current coverage radius in km, drives the circle size.
  final double radiusKm;
  final double maxRadiusKm;
  final String pinLabel;
  final VoidCallback? onAdjust;

  /// Straight-line distance shown in the floating pill, e.g. 2.3.
  final double? distanceKm;

  /// Drive-time copy, e.g. "Approx. 15 mins drive".
  final String? driveTime;

  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppRadius.brMd,
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Stack(
          children: [
            // Base texture: the dotted grid the design uses for "map".
            Positioned.fill(
              child: CustomPaint(
                painter: _MapTexturePainter(drawRoute: _isRoute),
              ),
            ),
            if (_isRoute) ..._routeOverlay() else ..._coverageOverlay(),
          ],
        ),
      ),
    );
  }

  List<Widget> _coverageOverlay() {
    final fraction = (radiusKm / maxRadiusKm).clamp(0.15, 1.0);

    return [
      // Coverage circle, scaled by the radius slider.
      Center(
        child: _PulsingCircle(
          diameter: 40 + (height * 0.75) * fraction,
        ),
      ),
      // Centre marker.
      Center(
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: const [
              BoxShadow(
                color: Color(0x408A19D8),
                blurRadius: 10,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: const Icon(Symbols.store, size: 15, color: Colors.white),
        ),
      ),
      Positioned(
        left: 10,
        bottom: 10,
        child: _MapPill(label: pinLabel, dark: true),
      ),
      if (onAdjust != null)
        Positioned(
          right: 10,
          top: 10,
          child: GestureDetector(
            onTap: onAdjust,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.base),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1A000000),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Symbols.edit_location,
                    size: 14,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Adjust Pin',
                    style: AppText.label10.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
    ];
  }

  List<Widget> _routeOverlay() {
    return [
      // Partner pin, bottom-left.
      Positioned(
        left: 34,
        bottom: 34,
        child: _RoutePin(
          icon: Symbols.store,
          label: 'You',
          background: AppColors.slate900,
        ),
      ),
      // Customer pin, top-right.
      Positioned(
        right: 42,
        top: 22,
        child: _RoutePin(
          icon: Symbols.pin_drop,
          label: 'Customer',
          background: AppColors.primary,
          bounce: true,
        ),
      ),
      // Floating distance strip.
      Positioned(
        left: 10,
        right: 10,
        bottom: 8,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(AppRadius.base),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A000000),
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              const Text('🚗', style: TextStyle(fontSize: 13)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  driveTime ?? '',
                  style: AppText.label11.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${distanceKm?.toStringAsFixed(1)} km',
                style: AppText.label11.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    ];
  }
}

class _MapPill extends StatelessWidget {
  const _MapPill({required this.label, this.dark = false});

  final String label;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: dark ? AppColors.slate900 : Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        label,
        style: AppText.label10.copyWith(
          color: dark ? Colors.white : AppColors.onSurface,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _RoutePin extends StatelessWidget {
  const _RoutePin({
    required this.icon,
    required this.label,
    required this.background,
    this.bounce = false,
  });

  final IconData icon;
  final String label;
  final Color background;
  final bool bounce;

  @override
  Widget build(BuildContext context) {
    final pin = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: background,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, size: 14, color: Colors.white),
        ),
        const SizedBox(height: 3),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Text(
            label,
            style: AppText.label10.copyWith(
              fontSize: 9,
              color: AppColors.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );

    return bounce ? _Bounce(child: pin) : pin;
  }
}

class _Bounce extends StatefulWidget {
  const _Bounce({required this.child});

  final Widget child;

  @override
  State<_Bounce> createState() => _BounceState();
}

class _BounceState extends State<_Bounce>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, child) => Transform.translate(
        offset: Offset(0, -4 * Curves.easeInOut.transform(_c.value)),
        child: child,
      ),
      child: widget.child,
    );
  }
}

class _PulsingCircle extends StatefulWidget {
  const _PulsingCircle({required this.diameter});

  final double diameter;

  @override
  State<_PulsingCircle> createState() => _PulsingCircleState();
}

class _PulsingCircleState extends State<_PulsingCircle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, _) {
        final t = Curves.easeInOut.transform(
          (math.sin(_c.value * 2 * math.pi) + 1) / 2,
        );
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: widget.diameter * (0.94 + t * 0.12),
          height: widget.diameter * (0.94 + t * 0.12),
          decoration: BoxDecoration(
            color: AppColors.primaryContainer.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.primaryContainer.withValues(alpha: 0.35),
            ),
          ),
        );
      },
    );
  }
}

/// The map "tiles": a dotted grid on a tinted ground, plus the dashed route
/// curve on the lead-detail variant.
class _MapTexturePainter extends CustomPainter {
  _MapTexturePainter({required this.drawRoute});

  final bool drawRoute;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    canvas.drawRect(rect, Paint()..color = AppColors.surfaceContainer);

    // 16px dot grid, matching radial-gradient(#8a19d8 1px, transparent 1px).
    final dot = Paint()..color = AppColors.primary.withValues(alpha: 0.18);
    const spacing = 16.0;
    for (var y = spacing / 2; y < size.height; y += spacing) {
      for (var x = spacing / 2; x < size.width; x += spacing) {
        canvas.drawCircle(Offset(x, y), 1, dot);
      }
    }

    // Faint "roads" so the texture does not read as pure grid.
    final road = Paint()
      ..color = Colors.white.withValues(alpha: 0.55)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(0, size.height * 0.68),
      Offset(size.width, size.height * 0.52),
      road,
    );
    canvas.drawLine(
      Offset(size.width * 0.33, 0),
      Offset(size.width * 0.44, size.height),
      road,
    );

    if (!drawRoute) return;

    // Dashed route: stroke #8a19d8, dasharray 6 4, width 4.
    final path = Path()
      ..moveTo(size.width * 0.15, size.height * 0.78)
      ..cubicTo(
        size.width * 0.28,
        size.height * 0.64,
        size.width * 0.40,
        size.height * 0.85,
        size.width * 0.66,
        size.height * 0.28,
      );

    final stroke = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = (distance + 6).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), stroke);
        distance = end + 4;
      }
    }
  }

  @override
  bool shouldRepaint(_MapTexturePainter old) => old.drawRoute != drawRoute;
}
