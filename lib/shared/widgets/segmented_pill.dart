import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/theme/gradients.dart';
import '../../core/theme/text_styles.dart';
import '../../core/theme/tokens.dart';

/// One option inside a [SegmentedPill].
class SegmentOption<T> {
  const SegmentOption({
    required this.value,
    required this.label,
    this.icon,
    this.badge,
  });

  final T value;
  final String label;
  final IconData? icon;

  /// Small badge rendered beside the label, e.g. "Save 20%" or "-20%".
  final String? badge;
}

/// A segmented control rendered as a pill track with a raised selected chip.
///
/// Used for the billing cycle (Monthly / Annual), years of experience,
/// and the pricing structure toggle.
class SegmentedPill<T> extends StatelessWidget {
  const SegmentedPill({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    this.trackColor = AppColors.surfaceContainerLow,
    this.selectedGradient,
    this.selectedColor = AppColors.surfaceContainerLowest,
    this.selectedForeground = AppColors.primary,
    this.unselectedForeground = AppColors.onSurfaceVariant,
    this.radius = AppRadius.full,
    this.height = 44,
    this.padding = 4,
    this.textStyle,
    this.showBorder = true,
  });

  final List<SegmentOption<T>> options;
  final T value;
  final ValueChanged<T> onChanged;

  final Color trackColor;

  /// When set, the selected chip is gradient-filled with white text, as on
  /// the wizard step-4 billing toggle.
  final Gradient? selectedGradient;

  final Color selectedColor;
  final Color selectedForeground;
  final Color unselectedForeground;
  final double radius;
  final double height;
  final double padding;
  final TextStyle? textStyle;
  final bool showBorder;

  @override
  Widget build(BuildContext context) {
    final innerRadius = radius >= AppRadius.full ? AppRadius.full : radius - 2;

    return Container(
      height: height,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: trackColor,
        borderRadius: BorderRadius.circular(radius),
        border: showBorder
            ? Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.5))
            : null,
      ),
      child: Row(
        children: [
          for (final option in options)
            Expanded(
              child: _Segment<T>(
                option: option,
                selected: option.value == value,
                onTap: () => onChanged(option.value),
                radius: innerRadius,
                selectedGradient: selectedGradient,
                selectedColor: selectedColor,
                selectedForeground: selectedForeground,
                unselectedForeground: unselectedForeground,
                textStyle: textStyle,
              ),
            ),
        ],
      ),
    );
  }
}

class _Segment<T> extends StatelessWidget {
  const _Segment({
    required this.option,
    required this.selected,
    required this.onTap,
    required this.radius,
    required this.selectedGradient,
    required this.selectedColor,
    required this.selectedForeground,
    required this.unselectedForeground,
    required this.textStyle,
  });

  final SegmentOption<T> option;
  final bool selected;
  final VoidCallback onTap;
  final double radius;
  final Gradient? selectedGradient;
  final Color selectedColor;
  final Color selectedForeground;
  final Color unselectedForeground;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final usesGradient = selected && selectedGradient != null;
    final fg = selected
        ? (usesGradient ? Colors.white : selectedForeground)
        : unselectedForeground;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: selected && !usesGradient ? selectedColor : null,
          gradient: usesGradient ? selectedGradient : null,
          borderRadius: BorderRadius.circular(radius),
          boxShadow: selected ? AppShadows.card : const [],
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (option.icon != null) ...[
                Icon(option.icon, size: 15, color: fg),
                const SizedBox(width: 5),
              ],
              Flexible(
                child: Text(
                  option.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: (textStyle ?? AppText.label11).copyWith(
                    color: fg,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
              if (option.badge != null) ...[
                const SizedBox(width: 5),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: selected && !usesGradient
                        ? AppColors.primary
                        : AppColors.primaryFixed,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Text(
                    option.badge!,
                    style: AppText.label10.copyWith(
                      fontSize: 9,
                      color: selected && !usesGradient
                          ? Colors.white
                          : AppColors.onPrimaryFixedVariant,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A selectable chip used for specializations, service sub-types, durations
/// and category filters.
///
/// Selected state fills with primary and shows a leading check; unselected
/// shows a neutral fill, and in the "addable" variant a leading plus.
class ChoicePill extends StatelessWidget {
  const ChoicePill({
    super.key,
    required this.label,
    required this.selected,
    this.onTap,
    this.showLeadingIcon = true,
    this.count,
    this.selectedColor = AppColors.primaryContainer,
    this.unselectedColor = AppColors.slate100,
    this.radius = AppRadius.full,
    this.dense = false,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  /// Shows a check when selected and a plus when not — the specialization
  /// chips on the location step do this.
  final bool showLeadingIcon;

  /// Appends a count, e.g. "AC & Cooling (2)".
  final int? count;

  final Color selectedColor;
  final Color unselectedColor;
  final double radius;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? Colors.white : AppColors.onSurfaceVariant;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(
          horizontal: dense ? 10 : 14,
          vertical: dense ? 7 : 9,
        ),
        decoration: BoxDecoration(
          color: selected ? selectedColor : unselectedColor,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: selected
                ? selectedColor
                : AppColors.outlineVariant.withValues(alpha: 0.6),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showLeadingIcon) ...[
              Icon(
                selected ? Symbols.check : Symbols.add,
                size: 15,
                color: fg,
              ),
              const SizedBox(width: 5),
            ],
            Flexible(
              child: Text(
                count == null ? label : '$label ($count)',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.label11.copyWith(
                  color: fg,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
