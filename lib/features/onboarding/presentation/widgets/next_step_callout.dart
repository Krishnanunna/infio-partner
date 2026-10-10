import 'package:flutter/material.dart';

import '../../../../core/theme/text_styles.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../shared/widgets/chips.dart';

/// The "what comes next" preview panel at the foot of each wizard step.
class NextStepCallout extends StatelessWidget {
  const NextStepCallout({
    super.key,
    required this.icon,
    required this.stepLabel,
    required this.title,
    required this.body,
  });

  final IconData icon;

  /// e.g. "STEP 2".
  final String stepLabel;

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.stackMd),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer.withValues(alpha: 0.6),
        borderRadius: AppRadius.brXl,
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconTile(
            icon: icon,
            size: 38,
            iconSize: 19,
            shape: BoxShape.circle,
            background: AppColors.surfaceContainerLowest,
            foreground: AppColors.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    StatusChip.primarySolid(label: stepLabel, radius: AppRadius.sm),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        title,
                        style: AppText.title15.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(body, style: AppText.body13),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The "Save Draft & Exit" escape hatch used by the wizard docks.
class SaveDraftLink extends StatelessWidget {
  const SaveDraftLink({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      child: Text(
        'Save Draft & Exit',
        style: AppText.body13.copyWith(
          color: AppColors.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
