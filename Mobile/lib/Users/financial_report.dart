import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';

class FinancialReportScreen extends StatelessWidget {
  const FinancialReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const DefaultTabController(
      length: 2,
      child: Scaffold(
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.all(10),
              child: Text(
                'Financial Reports',
                style: TextStyle(fontSize: 20, color: Colors.black),
              ),
            ),

            TabBar(
              tabs: [
                Tab(text: 'Monthly'),
                Tab(text: 'Yearly'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  ReportWidget(viewMode: 0, selectedPeriod: 'January'),
                  ReportWidget(viewMode: 1, selectedPeriod: '2025'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ReportWidget extends StatefulWidget {
  //0 for monthly and 1 for yearly
  final int viewMode;
  final String selectedPeriod;

  const ReportWidget({
    super.key,
    required this.viewMode,
    required this.selectedPeriod,
  });

  @override
  State<ReportWidget> createState() => _ReportWidgetState();
}

class _ReportWidgetState extends State<ReportWidget> {
  late String _selectedPeriod;
  late double _totalIncome;
  late double _totalExpense;
  late double _totalSavings;
  // late List<Expense> _expenses;
  // Map<String, Expense> pieChartData = {};

  // TODO: Only list the months available.
  final List<String> months = const [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  // TODO: Get the income, expenses and savings from database.
  void getDetails() async {
    // _totalIncome = await getIncome();
    // _totalExpense = await getExpense();
    // _totalSavings = await getSaving();
    // _expenses = jsonDecode(await getExpenses());
    _totalIncome = 0;
    _totalExpense = 0;
    _totalSavings = 0;
  }

  // Color _getColor(String category) {
  //   return Colors
  //       .primaries[pieChartData.keys.toList().indexOf(category) %
  //           Colors.primaries.length]
  //       .shade700;
  // }

  @override
  void initState() {
    super.initState();
    _selectedPeriod = widget.selectedPeriod;
    getDetails();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: BoxBorder.all(color: Colors.black, width: 2),
          borderRadius: const BorderRadius.all(Radius.circular(15)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_selectedPeriod, style: const TextStyle(color: Colors.grey)),
                DropdownMenu(
                  initialSelection: _selectedPeriod,
                  dropdownMenuEntries: months
                      .map(
                        (month) => DropdownMenuEntry<String>(
                          value: month,
                          label: month,
                        ),
                      )
                      .toList(),
                  onSelected: (value) {
                    setState(() {
                      _selectedPeriod = value.toString();
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      Text(
                        'INCOME',
                        style: TextStyle(color: Colors.grey.shade400),
                      ),
                      Text(
                        'RM $_totalIncome',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      Text(
                        'EXPENSES',
                        style: TextStyle(color: Colors.grey.shade400),
                      ),
                      Text(
                        'RM $_totalExpense',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      Text(
                        'SAVINGS',
                        style: TextStyle(color: Colors.grey.shade400),
                      ),
                      Text(
                        'RM $_totalSavings',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      Text(
                        'SAVINGS RATE',
                        style: TextStyle(color: Colors.grey.shade400),
                      ),
                      Text(
                        '${_totalSavings / _totalIncome * 100}%',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const DottedBorder(
              options: RoundedRectDottedBorderOptions(
                radius: Radius.circular(16),
                padding: EdgeInsets.all(20),
              ),
              child: Center(child: Text('Income vs. Expenses Chart')),
            ),
            const SizedBox(height: 10),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Expenses Breakdown'),
            ),
            const SizedBox(height: 10),
            const DottedBorder(
              options: RoundedRectDottedBorderOptions(
                radius: Radius.circular(16),
                padding: EdgeInsets.all(20),
              ),
              child: Center(child: Text('Expense Breakdown Chart')),
            ),
            // ListView.builder(
            //   itemCount: _expenses.length,
            //   itemBuilder: (context, index) {
            //     final expense = _expenses[index];
            //     final category = expense.keys.first;
            //     final expenseValue = expense.values.first;
            //     final percentage = _totalExpense / expenseValue;

            //     return ListTile(
            //       leading: Container(
            //         height: 16,
            //         width: 16,
            //         decoration: BoxDecoration(color: _getColor(category)),
            //       ),
            //       title: Text(category),
            //       trailing: Column(
            //         children: [
            //           Text(
            //             'RM $expenseValue',
            //             style: TextStyle(
            //               color: Color.fromARGB(255, 55, 65, 81),
            //             ),
            //           ),
            //           Text(
            //             '$percentage%',
            //             style: TextStyle(
            //               color: Colors.grey.shade400,
            //               fontSize: 10,
            //             ),
            //           ),
            //         ],
            //       ),
            //     );
            //   },
            // ),
          ],
        ),
      ),
    );
  }
}
