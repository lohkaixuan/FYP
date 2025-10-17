import 'package:flutter/material.dart';

/// A reusable AppBar with a trailing Switch toggle.
/// Use for theme toggle, feature on/off, etc.
class ToggleAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ToggleAppBar({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.leading,
    this.subtitle,
    this.onTapTitle,
    this.activeIcon,
    this.inactiveIcon,
  });

  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  final Widget? leading;                // optional custom leading
  final String? subtitle;               // optional small subtitle
  final VoidCallback? onTapTitle;       // optional tap on title
  final IconData? activeIcon;           // optional icon when ON
  final IconData? inactiveIcon;         // optional icon when OFF

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final icon = value ? (activeIcon ?? Icons.dark_mode_rounded)
                       : (inactiveIcon ?? Icons.light_mode_rounded);

    return AppBar(
      leading: leading,
      titleSpacing: 12,
      title: InkWell(
        onTap: onTapTitle,
        borderRadius: BorderRadius.circular(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            )),
            if (subtitle != null)
              Text(subtitle!, style: Theme.of(context).textTheme.labelMedium),
          ],
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Row(
            children: [
              Icon(icon),
              const SizedBox(width: 6),
              Tooltip(
                message: value ? 'On' : 'Off',
                child: Switch.adaptive(
                  value: value,
                  onChanged: onChanged,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
