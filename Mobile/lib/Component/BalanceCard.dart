// lib/Component/BalanceCard.dart
import 'package:flutter/material.dart';

class BalanceCard extends StatelessWidget {
  final double balance;          // RM balance
  final DateTime updatedAt;      // last updated
  final VoidCallback? onReload;  // "+ Reload" tap
  final VoidCallback? onTransactions; // "Transactions >" tap

  const BalanceCard({
    super.key,
    required this.balance,
    required this.updatedAt,
    this.onReload,
    this.onTransactions,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top label
          Text(
            'Available Balance',
            style: theme.textTheme.labelMedium?.copyWith(
              color: cs.onPrimary.withOpacity(.9),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),

          // Big number + tiny shield icon + >
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'RM ${balance.toStringAsFixed(2)}',
                style: theme.textTheme.displaySmall?.copyWith(
                  color: cs.onPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.verified_rounded, size: 20, color: cs.secondary),
              const SizedBox(width: 2),
              Icon(Icons.chevron_right, size: 22, color: cs.onPrimary),
            ],
          ),
          const SizedBox(height: 8),

          // updated time
          Text(
            'Updated on ${_fmtDate(updatedAt)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onPrimary.withOpacity(.85),
            ),
          ),
          const SizedBox(height: 14),

          // actions row
          Row(
            children: [
              // + Reload (white pill)
              TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: cs.primary,
                  backgroundColor: cs.onPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                onPressed: onReload,
                icon: const Icon(Icons.add),
                label: const Text('Reload'),
              ),
              const SizedBox(width: 12),

              // Transactions >
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: cs.onPrimary,
                ),
                onPressed: onTransactions,
                child: const Text('Transactions  >'),
              ),
            ],
          )
        ],
      ),
    );
  }

  String _fmtDate(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(dt.day)} ${_month(dt.month)} ${dt.year}, ${two(dt.hour)}:${two(dt.minute)}';
  }

  String _month(int m) {
    const names = [
      'Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    return names[m-1];
  }
}
