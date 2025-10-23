import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile/Component/GlobalAppBar.dart';
import 'package:mobile/Component/PieChart.dart';
import 'package:mobile/Role/RoleController.dart';
import 'package:mobile/Component/BalanceCard.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final RoleController roleC = Get.find<RoleController>();
    final now = DateTime.now();

    const double availableBalance = 6.81;
    const double totalDebit = 18.90 + 27.4 + 3.2;
    const double totalCredit = 50.0 + 12.35;

    final Map<String, double> byCategory = {
      'Groceries': 18.90,
      'Top-up': 50.00,
      'Transfer': 12.35,
      'Food & Drinks': 27.40,
      'Transport': 3.20,
    };

    return Scaffold(
      appBar: const GlobalAppBar(title: 'UniPay'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Center(
            child: Obx(() => Text(
                  roleC.isMerchant ? 'Merchant' : 'User',
                  style: Theme.of(context).textTheme.headlineSmall,
                )),
          ),
          const SizedBox(height: 16),
          BalanceCard(
            balance: availableBalance,
            updatedAt: now,
            onReload: () {},
            onTransactions: () {},
          ),
          const SizedBox(height: 16),
          const DebitCreditDonut(debit: totalDebit, credit: totalCredit),
          const SizedBox(height: 16),
          CategoryPieChart(data: byCategory),
        ],
      ),
    );
  }
}
