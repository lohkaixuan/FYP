
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile/Api/apimodel.dart';
import 'package:mobile/Auth/auth.dart';
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
  final AuthController authController = Get.find<AuthController>();

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
    // Load raw transactions; no grouping
    await transactionController.getAll();
  }

  @override
  Widget build(BuildContext context) {
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
          Obx(() {
            final AppUser? me = authController.user.value;
            final bool merchantActive =
                roleC.activeRole.value == 'merchant' &&
                    (me?.merchantWalletBalance != null);
            final double balance = merchantActive
                ? (me?.merchantWalletBalance ?? 0.0)
                : (me?.userWalletBalance ?? me?.balance ?? 0.0);
            final DateTime updatedAt = me?.lastLogin ?? DateTime.now();
            return BalanceCard(
              balance: balance,
              updatedAt: updatedAt,
              onReload: () {
                Get.toNamed("/reload");
              },
              onPay: () {
                Get.toNamed("/pay");
              },
              onTransfer: () {
                Get.toNamed("/transfer");
              },
            );
          }),
          const SizedBox(height: 16),
          Obx(() {
            final txs = transactionController.rawTransactions;
            double debit = 0.0;
            double credit = 0.0;
            for (final t in txs) {
              if (t.amount < 0) {
                debit += t.amount.abs();
              } else if (t.amount > 0) {
                credit += t.amount;
              }
            }
            return DebitCreditDonut(
              debit: debit,
              credit: credit,
              isLoading: transactionController.isLoading.value,
            );
          }),
          const SizedBox(height: 16),
          Obx(() {
            final Map<String, double> data = {};
            for (final t in transactionController.rawTransactions) {
              final String key = (t.category != null && t.category!.trim().isNotEmpty)
                  ? t.category!.trim()
                  : t.type;
              final double amt = t.amount.abs();
              data.update(key, (v) => v + amt, ifAbsent: () => amt);
            }
            return CategoryPieChart(
              data: data,
              isLoading: transactionController.isLoading.value,
            );
          }),
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
