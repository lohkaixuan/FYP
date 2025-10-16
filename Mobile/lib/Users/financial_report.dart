import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';

class FinancialReportScreen extends StatelessWidget {
  const FinancialReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
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
  late int _income;
  late int _expenses;
  late int _savings;

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
    _income = 0;
    _expenses = 0;
    _savings = 0;
  }

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
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: BoxBorder.all(color: Colors.black, width: 2),
          borderRadius: BorderRadius.all(Radius.circular(15)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_selectedPeriod, style: TextStyle(color: Colors.grey)),
                DropdownMenu(
                  initialSelection: _selectedPeriod,
                  dropdownMenuEntries: months
                      .map(
                        (month) =>
                            DropdownMenuEntry<String>(value: month, label: month),
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
                        'RM $_income',
                        style: TextStyle(
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
                        'RM $_expenses',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
                        'RM $_savings',
                        style: TextStyle(
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
                        '${_savings / _income * 100}%',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            DottedBorder(
              options: RoundedRectDottedBorderOptions(radius: Radius.circular(16), padding: EdgeInsets.all(20)),
              child: Center(child: Text('Income vs. Expenses Chart')),
            ),
          ],
        ),
      ),
    );
  }
}
