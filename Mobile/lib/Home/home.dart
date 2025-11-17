import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile/Api/apimodel.dart';
import 'package:mobile/Budget/budget.dart';
import 'package:mobile/Component/GlobalScaffold.dart';
import 'package:mobile/Component/PieChart.dart';
import 'package:mobile/Component/GlobalDrawer.dart';
import 'package:mobile/Controller/BudgetController.dart';
import 'package:mobile/Controller/RoleController.dart';
import 'package:mobile/Component/BalanceCard.dart';
import 'package:mobile/Controller/TransactionController.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final RoleController roleC = Get.find<RoleController>();
  final BudgetController budgetController = Get.find<BudgetController>();
  final TransactionController transactionController =
      Get.find<TransactionController>();

  @override
  void initState() {
    super.initState();
    _fetchBudgets();
    _fetchTransactions();
  }

  // Fetch budget summary.
  Future<void> _fetchBudgets() async {
    await budgetController.getSummary();
  }

  // Fetch trnsactions
  Future<void> _fetchTransactions() async {
    // await transactionController.filterTransactions(groupByType: true);
    // await transactionController.filterTransactions(groupByCategory: true);
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    const double availableBalance = 6.81;

    final Map<String, double> byCategory = {
      'Groceries': 18.90,
      'Top-up': 50.00,
      'Transfer': 12.35,
      'Food & Drinks': 27.40,
      'Transport': 3.20,
    };

    return GlobalScaffold(
      title: 'UniPay',
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
        children: [
          // Center(
          //   child: Obx(() => Text(
          //         roleC.isMerchant ? 'Merchant' : 'User',
          //         style: Theme.of(context).textTheme.headlineSmall,
          //       )),
          // ),
          BalanceCard(
            balance: availableBalance,
            updatedAt: now,
            onReload: () {
              Get.toNamed("/reload");
            },
            onPay: () {
              Get.toNamed("/pay");
            },
            onTransfer: () {
              Get.toNamed("/transfer");
            },
          ),
          const SizedBox(height: 16),
          Obx(() {
            final debitGroup = transactionController.trnsGrpByType.firstWhere(
              (g) => g.type.toLowerCase() == 'debit',
              orElse: () => TransactionGroup(
                  type: 'debit', totalAmount: 0.0, transactions: []),
            );

            final creditGroup = transactionController.trnsGrpByType.firstWhere(
              (g) => g.type.toLowerCase() == 'credit',
              orElse: () => TransactionGroup(
                  type: 'credit', totalAmount: 0.0, transactions: []),
            );
            return DebitCreditDonut(
              debit: debitGroup.totalAmount,
              credit: creditGroup.totalAmount,
              isLoading: transactionController.isLoading.value,
            );
          }),
          const SizedBox(height: 16),
          Obx(
            () => CategoryPieChart(
              data: {
                for (var transaction in transactionController.trnsGrpByCategory)
                  transaction.type: transaction.totalAmount
              },
              isLoading: transactionController.isLoading.value,
            ),
          ),
          const SizedBox(height: 16),
          Obx(() => BudgetChart(
                summary: budgetController.budgetSummary.toList(),
                isLoading: budgetController.isLoading.value,
              ))
        ],
      ),
    );
  }
}
