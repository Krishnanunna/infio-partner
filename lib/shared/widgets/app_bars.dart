import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/theme/gradients.dart';
import '../../core/theme/text_styles.dart';
import '../../core/theme/tokens.dart';
import 'chips.dart';
import 'gradient_button.dart';

/// Shared glass backdrop for both app-bar variants.
class _GlassBar extends StatelessWidget {
  const _GlassBar({required this.child});

  final Widget child;
  static const _opacity = 0.85;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: _opacity),
            border: const Border(
              bottom: BorderSide(color: AppColors.outlineVariant, width: 1),
            ),
          ),
          child: SafeArea(bottom: false, child: child),
        ),
      ),
    );
  }
}

/// The onboarding wizard bar: back button, stacked title with an "InFio
/// Business" overline, a "Step N of 4" pill, and a gradient progress bar.
class WizardAppBar extends StatelessWidget implements PreferredSizeWidget {
  const WizardAppBar({
    super.key,
    required this.title,
    required this.step,
    this.totalSteps = 4,
    this.overline = 'InFio Business',
    this.onBack,
    this.trailing,
    this.showProgress = true,
  });

  final String title;
  final int step;
  final int totalSteps;
  final String overline;
  final VoidCallback? onBack;
  final Widget? trailing;
  final bool showProgress;

  double get _progress => (step / totalSteps).clamp(0.0, 1.0);

  @override
  Size get preferredSize => Size.fromHeight(showProgress ? 62 : 56);

  @override
  Widget build(BuildContext context) {
    return _GlassBar(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 56,
            child: Row(
              children: [
                const SizedBox(width: 12),
                CircleIconButton(
                  icon: Symbols.arrow_back,
                  size: 36,
                  iconSize: 18,
                  background: AppColors.surfaceContainerLowest,
                  foreground: AppColors.primary,
                  tooltip: 'Go back',
                  onPressed: onBack ?? () => Navigator.of(context).maybePop(),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.titleMd.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Row(
                        children: [
                          Container(
                            width: 5,
                            height: 5,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            overline,
                            style: AppText.label10.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                trailing ??
                    StatusChip.primary(
                      label: 'Step $step of $totalSteps',
                      dense: true,
                    ),
                const SizedBox(width: 12),
              ],
            ),
          ),
          if (showProgress)
            SizedBox(
              height: 6,
              child: Align(
                alignment: Alignment.centerLeft,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Stack(
                      children: [
                        Container(
                          height: 6,
                          color: AppColors.surfaceContainerHigh,
                        ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 320),
                          curve: Curves.easeOut,
                          height: 6,
                          width: constraints.maxWidth * _progress,
                          decoration: const BoxDecoration(
                            gradient: AppGradients.cta,
                            borderRadius: BorderRadius.horizontal(
                              right: Radius.circular(4),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The non-wizard bar: back button, title with optional subtitle, an
/// optional status pill, and trailing action icons.
class StandaloneAppBar extends StatelessWidget implements PreferredSizeWidget {
  const StandaloneAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.statusChip,
    this.actions = const [],
    this.onBack,
    this.showBack = true,
    this.leading,
    this.titleStyle,
  });

  final String title;
  final String? subtitle;
  final Widget? statusChip;
  final List<Widget> actions;
  final VoidCallback? onBack;
  final bool showBack;
  final Widget? leading;
  final TextStyle? titleStyle;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return _GlassBar(
      child: SizedBox(
        height: 64,
        child: Row(
          children: [
            const SizedBox(width: 12),
            if (leading != null)
              leading!
            else if (showBack)
              CircleIconButton(
                icon: Symbols.arrow_back,
                size: 40,
                iconSize: 20,
                background: AppColors.surfaceContainerLowest,
                foreground: AppColors.onSurface,
                tooltip: 'Go back',
                onPressed: onBack ?? () => Navigator.of(context).maybePop(),
              ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: titleStyle ?? AppText.headlineLgMobile,
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.label11.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (statusChip != null) ...[
              const SizedBox(width: 8),
              statusChip!,
            ],
            ...actions,
            const SizedBox(width: 12),
          ],
        ),
      ),
    );
  }
}
