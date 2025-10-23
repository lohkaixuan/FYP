// lib/Transaction/Transactions.dart
import 'package:flutter/material.dart';
import 'package:mobile/Component/GlobalAppBar.dart';
import 'package:mobile/Component/TransactionCard.dart';

class Transactions extends StatelessWidget {
  const Transactions({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final items = <TransactionModel>[
      TransactionModel(
        id: 'tx_001',
        timestamp: now.subtract(const Duration(minutes: 5)),
        counterparty: '7-Eleven SS2',
        amount: -18.90,
        category: 'Groceries',
        status: TxStatus.success,
      ),
      TransactionModel(
        id: 'tx_002',
        timestamp: now.subtract(const Duration(hours: 1, minutes: 12)),
        counterparty: 'Boost Top-up',
        amount: 50.00,
        isTopUp: true,
        category: 'Top-up',
        status: TxStatus.success,
      ),
      TransactionModel(
        id: 'tx_003',
        timestamp: now.subtract(const Duration(hours: 3, minutes: 40)),
        counterparty: 'Alice Tan',
        amount: 12.35,
        category: 'Transfer',
        status: TxStatus.pending,
      ),
      TransactionModel(
        id: 'tx_004',
        timestamp: now.subtract(const Duration(days: 1, hours: 2)),
        counterparty: 'GrabFood',
        amount: -27.40,
        category: 'Food & Drinks',
        status: TxStatus.failed,
      ),
    ];

    return Scaffold(
      appBar: const GlobalAppBar(
        title: 'Transactions',
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, i) => TransactionCard(
          tx: items[i],
          onTap: () {
            // TODO: to detail page if you want
          },
        ),
      ),
    );
  }
}
