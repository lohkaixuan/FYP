import 'package:flutter/material.dart';

/// Transaction status
enum TxStatus { success, pending, failed }
extension TxStatusExtension on TxStatus {
  String get label {
    switch (this) {
      case TxStatus.success:
        return 'Success';
      case TxStatus.pending:
        return 'Pending';
      case TxStatus.failed:
        return 'Failed';
    }
  }
}

/// Simple data model for a transaction
class TransactionModel {
  final String id;
  final DateTime timestamp;     // 时间
  final String counterparty;    // 对方（pay to / sent to / top-up source）
  final double amount;          // 金额（负数=支出，正数=收入/充值）
  final bool isTopUp;           // 是否充值
  final String? category;       // 分类（Food / Transport / Bills ...）
  final TxStatus status;        // 状态

  const TransactionModel({
    required this.id,
    required this.timestamp,
    required this.counterparty,
    required this.amount,
    this.isTopUp = false,
    this.category,
    this.status = TxStatus.success,
  });
}

/// Pretty card that follows AppTheme (light/dark)
class TransactionCard extends StatelessWidget {
  final TransactionModel tx;
  final VoidCallback? onTap;

  const TransactionCard({
    super.key,
    required this.tx,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final bool isDebit = tx.amount < 0;  // 支出（红色）
    final bool isCredit = tx.amount > 0; // 收入/充值（绿色）

    // amount color: red for debit, green for credit/top-up
    final Color amountColor = isDebit ? Colors.red : Colors.green;

    // status color & icon
    final _StatusVisual sv = _statusVisual(tx.status, cs);

    // leading icon logic
    final IconData leadingIcon = tx.isTopUp
        ? Icons.account_balance_wallet   // top-up
        : (isDebit ? Icons.north_east : Icons.south_west);

    final String primaryLabel = tx.isTopUp
        ? 'Top-up'
        : (isDebit ? 'Paid to' : 'Received from');

    // category chip color (soft surface tint)
    final Color catBg = cs.primary.withOpacity(0.08);
    final Color catFg = cs.primary;

    return Card(
      elevation: 0,
      color: cs.surface,
      surfaceTintColor: cs.surfaceTint,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              // leading icon box
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: cs.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(leadingIcon, color: cs.primary),
              ),
              const SizedBox(width: 12),

              // title + subtitle + chips
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Line 1: Paid to / Received from / Top-up + name
                    Text(
                      '$primaryLabel ${tx.counterparty}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Line 2: timestamp
                    Text(
                      _formatTimestamp(tx.timestamp),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w400,
                      ),
                    ),

                    // Line 3: category chip (optional)
                    if (tx.category != null && tx.category!.trim().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: catBg,
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text(
                            tx.category!,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: catFg,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // amount + status
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Amount
                  Text(
                    _formatMYR(tx.amount),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: amountColor,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Status pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: sv.bg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: sv.fg.withOpacity(.25)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(sv.icon, size: 14, color: sv.fg),
                        const SizedBox(width: 4),
                        Text(
                          sv.label,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: sv.fg,
                            fontWeight: FontWeight.w700,
                            letterSpacing: .2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Simple MYR formatter without intl
  String _formatMYR(double amount) {
    final abs = amount.abs().toStringAsFixed(2);
    return amount < 0 ? '-RM $abs' : 'RM $abs';
  }

  // Simple timestamp: yyyy-MM-dd HH:mm
  String _formatTimestamp(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${dt.year}-${two(dt.month)}-${two(dt.day)} ${two(dt.hour)}:${two(dt.minute)}';
  }

  _StatusVisual _statusVisual(TxStatus st, ColorScheme cs) {
    switch (st) {
      case TxStatus.success:
        return _StatusVisual(
          label: 'Success',
          fg: Colors.green.shade700,
          bg: Colors.green.withOpacity(.10),
          icon: Icons.check_circle_rounded,
        );
      case TxStatus.pending:
        return _StatusVisual(
          label: 'Pending',
          fg: cs.tertiary, // a softer accent from scheme
          bg: cs.tertiary.withOpacity(.12),
          icon: Icons.schedule_rounded,
        );
      case TxStatus.failed:
        return _StatusVisual(
          label: 'Failed',
          fg: Colors.red.shade700,
          bg: Colors.red.withOpacity(.10),
          icon: Icons.error_rounded,
        );
    }
  }
}

/// Small helper for status visuals
class _StatusVisual {
  final String label;
  final Color fg;
  final Color bg;
  final IconData icon;
  _StatusVisual({
    required this.label,
    required this.fg,
    required this.bg,
    required this.icon,
  });
}
