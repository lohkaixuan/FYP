import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:mobile/Component/AppTheme.dart';
import 'package:mobile/Component/GlobalAppBar.dart';

class Expense {
  final String category;
  final double amount;

  const Expense({required this.category, required this.amount});

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      category: json['category'] as String,
      amount: (json['amount'] as num).toDouble(),
    );
  }
}

class ReportDetails {
  final double income;
  final double expense;
  final double savings;

  const ReportDetails(
      {required this.income, required this.expense, required this.savings});

  double get getSavingRate => income == 0 ? 0 : (savings / income) * 100;

  factory ReportDetails.fromJson(Map<String, dynamic> json) {
    return ReportDetails(
      income: (json['income'] as num).toDouble(),
      expense: (json['expense'] as num).toDouble(),
      savings: (json['savings'] as num).toDouble(),
    );
  }
}

class FinancialReport extends StatelessWidget {
  const FinancialReport({super.key});

  @override
  Widget build(BuildContext context) {
    return const DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: GlobalAppBar(
          title: 'Financial Reports',
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
  late Future<ReportDetails> _report;
  late List<Expense> _expenses;

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

  // final ReportService _reportService = ReportService();

  // TODO: Get the income, expenses and savings from database.
  // TODO: Get the expenses (grouped by category) from database.
  void _getReport() {
    setState(() {
      // _report = widget.viewMode == 0? _reportService.getMonthlyReport(month): _reportService.getYearlyReport(year);
      // _expenses = widget.viewMode == 0? _reportService.getMonthlyExpenseBreakdown(month): _reportService.getYearlyExpenseBreakdown(year);
      _report = Future.value(
        const ReportDetails(
          income: 1000,
          expense: 300,
          savings: 700,
        ),
      );
      _expenses = [
        const Expense(category: 'Food', amount: 150),
        const Expense(category: 'Transport', amount: 60),
        const Expense(category: 'Utilities', amount: 90),
      ];
    });
  }

  Color _getColor(String category) {
    return Colors
        .primaries[_expenses.indexWhere((e) => e.category == category) %
            Colors.primaries.length]
        .shade600;
  }

  @override
  void initState() {
    super.initState();
    _selectedPeriod = widget.selectedPeriod;
    _getReport();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: FutureBuilder<ReportDetails>(
        future: _report,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (!snapshot.hasData) {
            return const Center(child: Text("No Data Found."));
          }

          final report = snapshot.data!;
          return Container(
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
                    Text(_selectedPeriod, style: AppTheme.textSmallGrey),
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
                    ReportDetail(title: 'INCOME', value: 'RM ${report.income}'),
                    ReportDetail(
                        title: 'EXPENSES', value: 'RM ${report.expense}'),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    ReportDetail(
                        title: 'SAVINGS', value: 'RM ${report.savings}'),
                    ReportDetail(
                        title: 'SAVINGS RATE',
                        value: '${report.getSavingRate}%'),
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
                const SizedBox(height: 5),
                Expanded(
                  child: ListView.builder(
                    itemCount: _expenses.length,
                    itemBuilder: (context, index) {
                      final expense = _expenses[index];
                      final category = expense.category;
                      final expenseValue = expense.amount;
                      final percentage = report.expense == 0
                          ? 0
                          : expenseValue / report.expense * 100;

                      return Padding(
                        padding: const EdgeInsets.all(5),
                        child: Card(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: Colors.grey.shade600)),
                          child: ListTile(
                            leading: Container(
                              height: 16,
                              width: 16,
                              decoration:
                                  BoxDecoration(color: _getColor(category)),
                            ),
                            title: Text(category),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'RM $expenseValue',
                                  style: AppTheme.textMediumBlack,
                                ),
                                Text(
                                  '$percentage%',
                                  style: AppTheme.textSmallGrey,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class ReportDetail extends StatelessWidget {
  final String title;
  final String value;

  const ReportDetail({super.key, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 1,
      child: Column(
        children: [
          Text(
            title,
            style: AppTheme.textSmallGrey,
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
