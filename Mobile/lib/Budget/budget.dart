import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
// import 'package:ui/budget_provider.dart';
// import 'package:ui/model/budget_summary.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  // List<Budget> budgets = []; // TODO: Make sure Budget is a defined class
  // late BudgetProvider budgetProvider;
  bool loading = false;

  // Map<String, BudgetSummary> pieChartData = {};
  Map<String, double> categoryPercentages = {};
  double totalSpending = 100.0;
  List<PieChartSectionData> sections = [];

  @override
  void initState() {
    super.initState();
    // budgetProvider = BudgetProvider();
    fetchBudgets();
  }

  void fetchBudgets() async {
    // final listOfBudgets = await getBudgetsFromDatabase(); // TODO: Implement this function to fetch budgets from the database
    // NOTE: The function must return a JSON string representing a list of budgets
    setState(() {
      // budgets = jsonDecode(listOfBudgets);
      // pieChartData = budgetProvider.groupByCategory(budgets);
      // calculateTotalSpending();
      // _createSections();
      loading = false;
    });
  }

  // void calculateTotalSpending() {
  //   totalSpending = budgets.fold(0.0, (sum, item) => sum + item.spentAmount);
  // }

  // void _createSections() {
  //   pieChartData = {
  //     'Food': BudgetSummary(spentAmount: 40, allocatedAmount: 100),
  //     'Transportation': BudgetSummary(spentAmount: 30, allocatedAmount: 100),
  //     'Shopping': BudgetSummary(spentAmount: 20, allocatedAmount: 100),
  //     'Entertainment': BudgetSummary(spentAmount: 10, allocatedAmount: 100),
  //   };
  //   sections = pieChartData.entries.map((entry) {
  //     final percentage = (entry.value.spentAmount / totalSpending) * 100;
  //     categoryPercentages[entry.key] = percentage;
  //     return PieChartSectionData(
  //       value: entry.value.spentAmount,
  //       color: _getColor(entry.key),
  //       title: '${percentage.toStringAsFixed(1)}%',
  //       titleStyle: const TextStyle(
  //         fontSize: 12,
  //         fontWeight: FontWeight.bold,
  //         color: Colors.white,
  //       ),
  //       radius: 70,
  //     );
  //   }).toList();
  // }

  // Color _getColor(String category) {
  //   return Colors
  //       .primaries[pieChartData.keys.toList().indexOf(category) %
  //           Colors.primaries.length]
  //       .shade700;
  // }

  @override
  Widget build(BuildContext context) {
    final entries = categoryPercentages.entries.toList();
    debugPrint("${entries[0].key},${entries[0].value}");

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                BackButton(
                  color: Colors.black,
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Budget Tracker',
                      style: TextStyle(fontSize: 20, color: Colors.black),
                    ),
                    //IconButton(onPressed: createBudget, icon: Icon(Icons.add)),
                  ],
                ),
              ],
            ),
            // if (loading)
            //   Center(child: CircularProgressIndicator())
            // else if (pieChartData.isEmpty)
            //   Center(
            //     child: Center(
            //       child: Text(
            //         'No budget data available.',
            //         style: TextStyle(fontSize: 16, color: Colors.red),
            //       ),
            //     ),
            //   )
            // else
            Container(
              height: 300,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.grey, width: 2),
              ),
              child: Row(
                
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    flex: 1,
                    child: PieChart(
                      PieChartData(
                        sections: sections,
                        sectionsSpace: 4,
                        centerSpaceRadius: 10,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: entries.length,
                      itemBuilder: (context, index) {
                        final entry = entries[index];
                        return ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            height: 16,
                            width: 16,
                            decoration: const BoxDecoration(
                              color: Colors.black //_getColor(entry.key),
                            ),
                          ),
                          title: Text("${entry.key} - ${entry.value}%"),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // if (budgets.isEmpty)
            //   Center(
            //     child: Text(
            //       'No budgets available. Please add a budget.',
            //       style: TextStyle(fontSize: 16, color: Colors.red),
            //     ),
            //   )
            // else
            // Expanded(
            //   child: ListView.builder(
            //     itemCount: budgets.length,
            //     itemBuilder: (context, index) {
            //       final item = budgets[index];
            //       final category =
            //           item['category']; // TODO: Check if Budget has "category" field
            //       final spentAmount =
            //           item['spentAmount']; // TODO: Check if Budget has "spentAmount" field
            //       final allocatedAmount =
            //           item['allocatedAmount']; // TODO: Check if Budget has "allocatedAmount" field
            //       return ListTile(
            //         leading: Icon(Icons.category_outlined),
            //         title: Text(category, style: TextStyle(color: Colors.black)),
            //         subtitle: Text(
            //           '${spentAmount.toStringAsFixed(2)} of ${allocatedAmount.toStringAsFixed(2)}',
            //           style: TextStyle(color: Colors.grey),
            //         ),
            //         trailing: Column(
            //           children: [
            //             Text(
            //               '${spentAmount / allocatedAmount * 100}%',
            //               style: TextStyle(color: Colors.grey),
            //             ),
            //             ClipRRect(
            //               borderRadius: BorderRadius.circular(10),
            //               child: LinearProgressIndicator(
            //                 value: spentAmount / allocatedAmount,
            //                 minHeight: 10,
            //                 backgroundColor: Colors.grey[300],
            //                 valueColor: AlwaysStoppedAnimation<Color>(
            //                   Color.fromARGB(255, 75, 85, 99),
            //                 ),
            //               ),
            //             ),
            //           ],
            //         ),
            //       );
            //     },
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}
