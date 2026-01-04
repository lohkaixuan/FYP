// ==================================================
// Program Name   : Transcation_list.dart
// Purpose        : Transaction list view
// Developer      : Mr. Loh Kai Xuan 
// Student ID     : TP074510 
// Course         : Bachelor of Software Engineering (Hons) 
// Created Date   : 15 November 2025
// Last Modified  : 4 January 2026 
// ==================================================
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile/Component/TransactionCard.dart';

class TransactionList extends StatelessWidget {
  final List<TransactionModel> items;
  const TransactionList({super.key, required this.items});
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

    final sorted = [...items]
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, ),
      itemCount: sorted.length,
      separatorBuilder: (_, __) => const SizedBox(height: 1),
      itemBuilder: (context, index) {
        final tx = sorted[index];
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
