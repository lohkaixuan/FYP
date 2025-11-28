import 'package:flutter/material.dart';
import 'package:mobile/Component/AppTheme.dart';

class MonthCard extends StatelessWidget {
  final DateTime month;
  final bool isReady;
  final VoidCallback? onTap;

  const MonthCard({
    super.key,
    required this.month,
    this.isReady = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    // Leading icon
    const IconData leadingIcon = Icons.insert_chart_outlined_rounded;
    final Color iconColor = isReady ? Colors.green : Colors.orange;

    // Status pill
    final String statusLabel = isReady ? 'Ready' : 'Pending';
    final Color statusFg = isReady ? Colors.green.shade700 : Colors.orange.shade700;
    final Color statusBg = statusFg.withAlpha(110);

    // Month label
    final label = '${month.year}-${month.month}'; // e.g., "2025-1"

    // Gradient
    final gradient = AppTheme.primaryGradient.withOpacity(0.3);

    return Card(
      elevation: 0,
      color: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: BoxDecoration(
          gradient: gradient,
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                // Leading icon box
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: cs.primary.withAlpha(120),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(leadingIcon, color: iconColor),
                ),
                const SizedBox(width: 12),

                // Month label
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                  ),
                ),

                // Status pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: statusFg.withAlpha(125)),
                  ),
                  child: Text(
                    statusLabel,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: statusFg,
                      fontWeight: FontWeight.w700,
                      letterSpacing: .2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
