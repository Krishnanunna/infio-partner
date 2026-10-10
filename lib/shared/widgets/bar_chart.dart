import 'package:flutter/material.dart';

import '../../core/theme/gradients.dart';
import '../../core/theme/text_styles.dart';
import '../../core/theme/tokens.dart';

/// One column of the weekly lead-velocity chart.
class ChartBar {
  const ChartBar({
    required this.label,
    required this.value,
    this.isPeak = false,
  });

  /// Axis label, e.g. "M", "T", "W".
  final String label;

  /// Lead count for the day.
  final int value;

  /// The peak day gets the gradient fill and a floating value chip.
  final bool isPeak;
}

/// The "Weekly Lead Velocity" chart: seven rounded-top bars with no axes or
/// gridlines, the peak day elevated and labelled.
class WeeklyBarChart extends StatelessWidget {
  const WeeklyBarChart({
    super.key,
    required this.bars,
    this.height = 144,
    this.barMaxWidth = 24,
  });

  final List<ChartBar> bars;
  final double height;
  final double barMaxWidth;

  @override
  Widget build(BuildContext context) {
    if (bars.isEmpty) return SizedBox(height: height);

    final maxValue = bars.map((b) => b.value).reduce((a, b) => a > b ? a : b);
    final safeMax = maxValue == 0 ? 1 : maxValue;

    return SizedBox(
      height: height,
      child: Column(
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final bar in bars)
                  Expanded(
                    child: _Bar(
                      bar: bar,
                      fraction: bar.value / safeMax,
                      maxWidth: barMaxWidth,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          const Divider(height: 1, color: AppColors.outlineVariant),
          const SizedBox(height: 6),
          Row(
            children: [
              for (final bar in bars)
                Expanded(
                  child: Text(
                    bar.label,
                    textAlign: TextAlign.center,
                    style: AppText.label10.copyWith(
                      color: bar.isPeak
                          ? AppColors.primary
                          : AppColors.onSurfaceVariant,
                      fontWeight:
                          bar.isPeak ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.bar,
    required this.fraction,
    required this.maxWidth,
  });

  final ChartBar bar;
  final double fraction;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (bar.isPeak) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Text(
              '${bar.value}',
              style: AppText.label10.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 4),
        ],
        Flexible(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: fraction),
                duration: const Duration(milliseconds: 650),
                curve: Curves.easeOutCubic,
                builder: (context, t, _) {
                  return Container(
                    width: maxWidth,
                    height: (constraints.maxHeight * t).clamp(2.0, double.infinity),
                    decoration: BoxDecoration(
                      gradient: bar.isPeak ? AppGradients.cta : null,
                      color: bar.isPeak
                          ? null
                          : AppColors.primaryFixedDim.withValues(alpha: 0.7),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(6),
                      ),
                      boxShadow: bar.isPeak ? AppShadows.primaryGlow : const [],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
