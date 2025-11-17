import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile/Component/TransactionCard.dart';

class TransactionList extends StatelessWidget {
  final List<TransactionModel> items;

  const TransactionList({super.key, required this.items});

  // 月份标题：例如 "Nov 2025"
  String _monthLabel(DateTime dt) {
    const monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${monthNames[dt.month - 1]} ${dt.year}';
  }

  bool _isSameMonth(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month;
  }

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(
        child: Text(
          'No Transactions Found!',
          style: TextStyle(
            color: Colors.red,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: 'Inter',
          ),
        ),
      );
    }

    // 确保按时间从新到旧排序（如果 controller 已经排好也没问题）
    final sorted = [...items]
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, ),
      itemCount: sorted.length,
      // 🔽 这里控制卡片之间的垂直间距（改小）
      separatorBuilder: (_, __) => const SizedBox(height: 1),
      itemBuilder: (context, index) {
        final tx = sorted[index];

        // 是否需要显示月份标题：第一条或与上一条不在同一月
        final bool showHeader = index == 0
            ? true
            : !_isSameMonth(tx.timestamp, sorted[index - 1].timestamp);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showHeader)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4 ),
                child: Text(
                  _monthLabel(tx.timestamp),
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            TransactionCard(
              tx: tx,
              onTap: () {
                Get.toNamed(
                  '/transactionDetails',
                  parameters: {'id': tx.id},
                );
              },
            ),
          ],
        );
      },
    );
  }
}
