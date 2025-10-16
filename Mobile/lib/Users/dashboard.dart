import 'package:flutter/material.dart';
// import 'package:ui/budget.dart';
// import 'package:ui/budget_provider.dart';
// import 'package:ui/budget_summary.dart';
// import 'package:ui/model/budget.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            TotalBalanceWidget(),
            SizedBox(height: 15),
            BudgetWidget(),
            SizedBox(height: 15),
            RecentTransactionsWidget(),
          ],
        ),
      ),
    );
  }
}

class TotalBalanceWidget extends StatefulWidget {
  const TotalBalanceWidget({super.key});

  @override
  State<TotalBalanceWidget> createState() => _TotalBalanceWidgetState();
}

class _TotalBalanceWidgetState extends State<TotalBalanceWidget> {
  int _selectedIndex_quicklink =
      -1; // State variable for selected quick link index

  void _onTap(int index) {
    setState(() {
      _selectedIndex_quicklink = index;
    });
  }

  final List<Map<String, dynamic>> _actions = [
    {
      'icon': 'assets/icons/bank_transfer.png',
      'label': 'Bank Transfer',
      'index': 0,
    },
    {'icon': 'assets/icons/topup.png', 'label': 'Top Up', 'index': 1},
    {'icon': 'assets/icons/more.png', 'label': 'More', 'index': 2},
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black, width: 2),
        ),
        child: Card(
          margin: EdgeInsets.zero,
          color: Color.fromARGB(255, 100, 178, 230),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          clipBehavior: Clip.hardEdge,
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'TOTAL BALANCE',
                      style: TextStyle(color: Color.fromARGB(255, 55, 65, 81)),
                    ),
                    InkWell(
                      onTap: () {
                        Navigator.pushNamed(context, '/balanceDetails');
                      },
                      child: Text(
                        'View Details',
                        style: TextStyle(
                          color: Color.fromARGB(255, 26, 13, 171),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Text(
                  'RM 12,345.67',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ), // TODO: Get total balance from database
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: _actions.map((action) {
                    return InkWell(
                      onTap: () => _onTap(action['index']),
                      child: Column(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: _selectedIndex_quicklink == action['index']
                                  ? Colors.grey
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Center(child: Image.asset(action['icon'])),
                          ),
                          Text(
                            action['label'],
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class BudgetWidget extends StatefulWidget {
  const BudgetWidget({super.key});

  @override
  State<BudgetWidget> createState() => _BudgetWidgetState();
}

class _BudgetWidgetState extends State<BudgetWidget> {
  // List<Budget> budgets = []; // TODO: Make sure Budget is a defined class
  // Map<String, BudgetSummary> budgetsByCategory = {};
  // bool loading = true;
  // late BudgetProvider budgetProvider;

  Widget buildBudgetItem(
    String title,
    double spentAmount,
    double allocatedAmount,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: TextStyle(color: Colors.black)),
            Text(
              "RM ${spentAmount.toStringAsFixed(2)} / RM ${allocatedAmount.toStringAsFixed(2)}",
            ),
          ],
        ),
        SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: spentAmount / allocatedAmount,
            minHeight: 10,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              Color.fromARGB(255, 75, 85, 99),
            ),
          ),
        ),
      ],
    );
  }

  // void fetchBudgets() async {
  //   final listOfBudgets = await getBudgetsFromDatabase(); // TODO: Implement this function to fetch budgets from the database
  //   // NOTE: The function must return a JSON string representing a list of budgets
  //   setState(() {
  //     budgets = jsonDecode(listOfBudgets);
  //     budgetsByCategory = budgetProvider.groupByCategory(budgets);
  //     loading = false;
  //   });
  // }

  // @override
  // void initState() {
  //   super.initState();
  //   budgetProvider = BudgetProvider();
  //   fetchBudgets();
  // }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black, width: 2),
        ),
        child: Card(
          margin: EdgeInsets.zero,
          color: Color.fromARGB(255, 215, 215, 215),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          clipBehavior: Clip.hardEdge,
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Budget Overview',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        Navigator.pushNamed(context, '/budgetDetails');
                      },
                      child: Text(
                        'View Details',
                        style: TextStyle(
                          color: Color.fromARGB(255, 26, 13, 171),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                // for (var entry in budgetsByCategory.entries)
                //   buildBudgetItem(
                //     entry.key,
                //     entry.value.spentAmount,
                //     entry.value.allocatedAmount,
                //   ),
                buildBudgetItem('Food & Dining', 350.00, 500.00),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class RecentTransactionsWidget extends StatefulWidget {
  const RecentTransactionsWidget({super.key});

  @override
  State<RecentTransactionsWidget> createState() =>
      _RecentTransactionsWidgetState();
}

class _RecentTransactionsWidgetState extends State<RecentTransactionsWidget> {
  // TODO: Create an instance of the class that fetches transactions from the database
  // late TransactionService _transactionService;
  // List<Transaction> transactions = []; // TODO: Make sure Transaction is a defined class
  bool loading = true;

  // void fetchRecentTransactions() async {
  //   // TODO: Fetch and display recent transactions from the database
  //   final listOfTransactions = await _transactionService
  //       .getRecentTransactions();
  //   setState(() {
  //     transactions = jsonDecode(listOfTransactions);
  //     loading = false;
  //   });
  // }

  // @override
  // void initState() {
  //   super.initState();
  //   _transactionService = TransactionService();
  //   fetchRecentTransactions();
  // }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Transactions',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              InkWell(
                onTap: () {
                  Navigator.pushNamed(context, '/transactionDetails');
                },
                child: Text(
                  'View Details',
                  style: TextStyle(color: Color.fromARGB(255, 26, 13, 171)),
                ),
              ),
            ],
          ),
          if (loading)
            Padding(
              padding: EdgeInsets.only(top: 30),
              child: Center(child: CircularProgressIndicator()),
            ),
          // else if (transactions.isEmpty)
          //   Center(
          //     child: Text(
          //       'No recent transactions found.',
          //       style: TextStyle(color: Colors.red),
          //     ),
          //   )
          // else
          //   ListView.builder(
          //     itemCount: transactions.length,
          //     itemBuilder: (context, index) {
          //       final transaction = transactions[index];
          //       return ListTile(
          //         leading: Icon(transaction.name[0]),
          //         title: Text(transaction.name),
          //         subtitle: Text(
          //           transaction.date.toString(),
          //           style: TextStyle(color: Color.fromARGB(255, 55, 65, 81)),
          //         ),
          //         trailing: transaction.amount.toStringAsFixed(2) >= 0
          //             ? Text('RM ${transaction.amount.toStringAsFixed(2)}')
          //             : Text('-RM ${transaction.amount.toStringAsFixed(2)}'),
          //         tileColor: transaction.amount.toStringAsFixed(2) >= 0
          //             ? Color.fromARGB(255, 76, 175, 80)
          //             : Color.fromARGB(255, 244, 67, 54),
          //       );
          //     },
          //   ),
        ],
      ),
    );
  }
}
