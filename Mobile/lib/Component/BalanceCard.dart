// lib/Component/BalanceCard.dart
import 'package:flutter/material.dart';
import 'package:mobile/Component/AppTheme.dart';
import 'package:mobile/Component/GradientWidgets.dart';

class BalanceCard extends StatelessWidget {
  final double balance;          // RM balance
  final DateTime updatedAt;      // last updated
  final String balanceLabel;     // e.g. User Wallet / Merchant Wallet
  final VoidCallback? onReload;  // "+ Reload" tap
  final VoidCallback? onPay; // "Pay" tap
  final VoidCallback? onTransfer; // "Transfer" tap

  const BalanceCard({
    super.key,
    required this.balance,
    required this.updatedAt,
    this.balanceLabel = 'Available Balance',
    this.onReload,
    this.onPay,
    this.onTransfer,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top label
          Text(
            balanceLabel,
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
              // Reload
              Expanded(
                child: FilledButton.tonal(
                  onPressed: onReload,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      GradientIcon(Icons.add, size: 28),
                      SizedBox(height: 6),
                      Text('Reload'),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Pay
              Expanded(
                child: FilledButton.tonal(
                  onPressed: onPay,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      GradientIcon(Icons.payment, size: 28),
                      SizedBox(height: 6),
                      Text('Pay'),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Transfer
              Expanded(
                child: FilledButton.tonal(
                  onPressed: onTransfer,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      GradientIcon(Icons.swap_horiz, size: 28),
                      SizedBox(height: 6),
                      Text('Transfer'),
                    ],
                  ),
                ),
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
