import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/theme/text_styles.dart';
import '../../core/theme/tokens.dart';
import 'chips.dart';

/// A navigation row in the profile menu groups: an icon tile, a title with
/// an optional inline badge, a subtitle, an optional trailing badge or text,
/// and a chevron.
class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.trailingText,
    this.titleBadge,
    this.onTap,
    this.iconBackground = AppColors.surfaceContainer,
    this.iconForeground = AppColors.primary,
    this.showChevron = true,
  });

  final IconData icon;
  final String title;
  final String? subtitle;

  /// A badge widget before the chevron, e.g. "Verified" or "8 Uploads".
  final Widget? trailing;

  /// Plain trailing text before the chevron, e.g. "Manage", "Change".
  final String? trailingText;

  /// A badge rendered inline after the title, e.g. "PRO".
  final Widget? titleBadge;

  final VoidCallback? onTap;
  final Color iconBackground;
  final Color iconForeground;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              IconTile(
                icon: icon,
                size: 36,
                iconSize: 19,
                background: iconBackground,
                foreground: iconForeground,
                radius: AppRadius.md,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.body13.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.onSurface,
                            ),
                          ),
                        ),
                        if (titleBadge != null) ...[
                          const SizedBox(width: 6),
                          titleBadge!,
                        ],
                      ],
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.label11.copyWith(
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                trailing!,
              ] else if (trailingText != null) ...[
                const SizedBox(width: 8),
                Text(
                  trailingText!,
                  style: AppText.label11.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              if (showChevron) ...[
                const SizedBox(width: 4),
                const Icon(
                  Symbols.chevron_right,
                  size: 20,
                  color: AppColors.outline,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
