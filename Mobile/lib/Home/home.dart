import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mobile/Api/apimodel.dart';
import 'package:mobile/Controller/auth.dart';
import 'package:mobile/Budget/budget.dart';
import 'package:mobile/Component/GlobalScaffold.dart';
import 'package:mobile/Component/PieChart.dart';
import 'package:mobile/Component/GlobalDrawer.dart';
import 'package:mobile/Controller/BudgetController.dart';
import 'package:mobile/Controller/RoleController.dart';
import 'package:mobile/Component/BalanceCard.dart';
import 'package:mobile/Controller/TransactionController.dart';
import 'package:mobile/Utils/wallet_view.dart';

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
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();

    ever(roleC.activeRole, (String newRole) {
      _fetchTransactions();
      _fetchBudgets();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // This makes sure the indicator triggers after the widget is built
      _refreshIndicatorKey.currentState?.show();
    });
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
    return GlobalScaffold(
      title: 'UniPay',
      body: RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: () async {
          final String previousActiveRole = roleC.activeRole.value;
          await authController.refreshMe();
          roleC.syncFromAuth(authController);
          await _fetchTransactions();

          if (roleC.roles.contains(previousActiveRole)) {
            roleC.activeRole.value = previousActiveRole;
          }
        },
        child: ListView(
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

              final wallet = WalletViewState.resolve(
                user: me,
                merchantActive: roleC.activeRole.value == 'merchant',
              );

              return BalanceCard(
                balance: wallet.balance,
                updatedAt: wallet.lastUpdated,
                balanceLabel: '${wallet.label} Balance',
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
                final String key =
                    (t.category != null && t.category!.trim().isNotEmpty)
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

            Obx(() {
              if (roleC.isUser) {
                return BudgetChart(
                  summary: budgetController.budgetSummary.toList(),
                  isLoading: budgetController.isLoading.value,
                );
              }
              return const SizedBox.shrink();
            })
          ],
        ),
      ),
    );
  }
}
