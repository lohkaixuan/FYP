import 'package:flutter/material.dart';
import 'package:mobile/Users/budget.dart';
import 'package:mobile/Users/dashboard.dart';

class DashboardNavigation extends StatelessWidget {
  const DashboardNavigation({super.key});

  @override
  Widget build(BuildContext context) {
    return Navigator(
      onGenerateRoute: (settings) {
        if (settings.name == '/balanceDetails'){
          // TODO: Add balance details page here.
          // return MaterialPageRoute(builder: (_) => const BalanceScreen());
        }
        if (settings.name == '/budgetDetails'){
          return MaterialPageRoute(builder: (_) => const BudgetScreen());
        }
        if (settings.name == '/transactionDetails'){
          // TODO: Add transaction details page here.
          // return MaterialPageRoute(builder: (_) => const TransactionScreen());
        }
        return MaterialPageRoute(builder: (_) => const DashboardScreen());
      },
    );
  }
}