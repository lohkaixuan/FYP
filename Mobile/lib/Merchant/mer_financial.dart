import 'package:flutter/material.dart';

class MerchantReportScreen extends StatelessWidget {
  const MerchantReportScreen({super.key});

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
                'Merchant Financial Reports',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
              ),
            ),
            TabBar(
              tabs: [
                Tab(text: 'Daily'),
                Tab(text: 'Monthly'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  MerchantReportWidget(viewMode: 0, selectedPeriod: 'Today'),
                  MerchantReportWidget(viewMode: 1, selectedPeriod: 'October'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MerchantReportWidget extends StatefulWidget {
  // 0 for daily, 1 for monthly
  final int viewMode;
  final String selectedPeriod;

  const MerchantReportWidget({
    super.key,
    required this.viewMode,
    required this.selectedPeriod,
  });

  @override
  State<MerchantReportWidget> createState() => _MerchantReportWidgetState();
}

class _MerchantReportWidgetState extends State<MerchantReportWidget> {
  late String _selectedPeriod;
  late double _totalSales;
  late double _expenses;
  late double _netProfit;
  late int _transactionCount;

  // Example periods
  final List<String> days = const ['Today', 'Yesterday', '2 days ago'];
  final List<String> months = const [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  void getDetails() async {
    // TODO: Replace with database logic.
    _totalSales = 2350.75;
    _expenses = 670.40;
    _netProfit = _totalSales - _expenses;
    _transactionCount = 124;
  }

  @override
  void initState() {
    super.initState();
    _selectedPeriod = widget.selectedPeriod;
    getDetails();
  }

  @override
  Widget build(BuildContext context) {
    List<String> periodList = widget.viewMode == 0 ? days : months;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black, width: 2),
          borderRadius: const BorderRadius.all(Radius.circular(15)),
        ),
        child: Column(
          children: [
            // Header row with dropdown
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_selectedPeriod, style: const TextStyle(color: Colors.grey, fontSize: 16)),
                DropdownMenu(
                  initialSelection: _selectedPeriod,
                  dropdownMenuEntries: periodList
                      .map((period) => DropdownMenuEntry<String>(value: period, label: period))
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

            // Summary cards
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      Text('TOTAL SALES', style: TextStyle(color: Colors.grey.shade600)),
                      Text('RM ${_totalSales.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      Text('EXPENSES', style: TextStyle(color: Colors.grey.shade600)),
                      Text('RM ${_expenses.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                      Text('NET PROFIT', style: TextStyle(color: Colors.grey.shade600)),
                      Text('RM ${_netProfit.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
                    ],
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      Text('TRANSACTIONS', style: TextStyle(color: Colors.grey.shade600)),
                      Text('$_transactionCount',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Average revenue per transaction
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Avg per Transaction: RM ${(_totalSales / _transactionCount).toStringAsFixed(2)}',
                style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
              ),
            ),

            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.grey.shade100,
              ),
              child: const Center(
                child: Text(
                  'No chart available yet',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),

            /*DottedBorder(
              color: Colors.blueAccent,
              dashPattern: [6, 4],
              borderType: BorderType.RRect,
              radius: const Radius.circular(16),
              padding: const EdgeInsets.all(20),
              child: const Center(
                child: Text(
                  'Sales Performance Chart',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),*/
          ],
        ),
      ),
    );
  }
}
