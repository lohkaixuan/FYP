// lib/Transaction/Transactions.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile/Component/GlobalScaffold.dart';
import 'package:mobile/Component/TransactionCard.dart';
import 'package:mobile/Component/TransactionCard.dart' as ui;
import 'package:mobile/Controller/TransactionController.dart';
// import 'package:mobile/Controller/TransactionModelConverter.dart';

class Transactions extends StatefulWidget {
  const Transactions({super.key});

  @override
  State<Transactions> createState() => _TransactionsState();
}

class _TransactionsState extends State<Transactions> {
  final transactionController = Get.find<TransactionController>();
  String? currentFilterType;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await transactionController.getAll();

      final filterType = Get.arguments?['filter'] as String?;
      if (filterType != null){
        transactionController.updateFilter(filterType);
      }
    });
  }

  List<ui.TransactionModel> _getTransactionsForList() {
    // Controller already applies any active filter and exposes UI models.
    return transactionController.transactions.toList();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: GlobalScaffold(
        title: 'Transactions',
        body: Obx(
          () {
            final items = _getTransactionsForList();

            return Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                children: [
                  const TabBar(
                    tabs: [
                      Text(
                        'Monthly',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Inter',
                        ),
                      ),
                      Text(
                        'Yearly',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  // Check for an error first
                  // if (transactionController.lastError.value.isNotEmpty)
                  //   Center(
                  //     child: Text(
                  //       'Error: ${transactionController.lastError.value}',
                  //       style: const TextStyle(color: Colors.red),
                  //     ),
                  //   ),
                  if (transactionController.isLoading.value)
                    const Center(child: CircularProgressIndicator(),)
                  else
                    Expanded(
                      child: TabBarView(
                        children: [
                          TransactionList(
                            items: items,
                            sortedBy: TransactionSort.month,
                          ),
                          TransactionList(
                            items: items,
                            sortedBy: TransactionSort.year,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

enum TransactionSort { month, year }

class TransactionList extends StatefulWidget {
  final List<TransactionModel> items;
  final TransactionSort sortedBy;

  const TransactionList(
      {super.key, required this.items, required this.sortedBy});

  @override
  State<TransactionList> createState() => _TransactionListState();
}

class _TransactionListState extends State<TransactionList> {
  String? selectedMonth;
  String? selectedYear;

  // Group By Month
  Map<String, List<TransactionModel>> groupByMonth(
      List<TransactionModel> items) {
    Map<String, List<TransactionModel>> grouped = {};

    for (var item in items) {
      final date = item.timestamp;
      final key = "${date.year}-${date.month.toString().padLeft(2, '0')}";
      if (!grouped.containsKey(key)) {
        grouped[key] = [];
      }
      grouped[key]!.add(item);
    }
    return grouped;
  }

  // Group By Year
  Map<String, List<TransactionModel>> groupByYear(
      List<TransactionModel> items) {
    Map<String, List<TransactionModel>> grouped = {};

    for (var item in items) {
      final date = item.timestamp;
      final key = date.year.toString();

      if (!grouped.containsKey(key)) {
        grouped[key] = [];
      }
      grouped[key]!.add(item);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final months = [
      "January",
      "February",
      "March",
      "April",
      "May",
      "June",
      "July",
      "August",
      "September",
      "October",
      "November",
      "December"
    ];
    List<String> years = List.generate(10, (index) {
      return (DateTime.now().year - index).toString();
    });

    // Filter Items
    final filteredItems = widget.items.where((item) {
      final date = item.timestamp;
      final monthMatch =
          selectedMonth == null || selectedMonth == months[date.month - 1];
      final yearMatch =
          selectedYear == null || selectedYear == date.year.toString();
      return monthMatch && yearMatch;
    }).toList();

    // Group Items
    final groupedItems = widget.sortedBy == TransactionSort.month
        ? groupByMonth(filteredItems)
        : groupByYear(filteredItems);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 5),
          child: Row(
            children: [
              Text('Month: ',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface)),
              const SizedBox(width: 10),
              DropdownButton<String>(
                value: selectedMonth,
                items: [
                  const DropdownMenuItem(value: null, child: Text("All")),
                  ...months.map((month) => DropdownMenuItem(
                        value: month,
                        child: Text(month),
                      )),
                ],
                hint: const Text('Select a month'),
                onChanged: (value) => setState(() => selectedMonth = value),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Row(
            children: [
              Text('Year: ',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface)),
              const SizedBox(width: 10),
              DropdownButton<String>(
                value: selectedYear,
                items: [
                  const DropdownMenuItem(value: null, child: Text("All")),
                  ...years.map((year) => DropdownMenuItem(
                        value: year,
                        child: Text(year),
                      )),
                ],
                hint: const Text('Select a year'),
                onChanged: (value) => setState(() => selectedYear = value),
              ),
            ],
          ),
        ),
        groupedItems.keys.isEmpty
            ? const Center(
                child: Text(
                  'No Transactions Found!',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Inter',
                  ),
                ),
              )
            : Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  itemCount: groupedItems.keys.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final key = groupedItems.keys.elementAt(i);
                    final transactions = groupedItems[key]!;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          key,
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(
                                    alpha: 0.6,
                                    red: 128,
                                    green: 128,
                                    blue: 128),
                          ),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        ...transactions.map(
                          (transaction) {
                            return TransactionCard(
                              tx: transaction,
                              onTap: () {
                                Get.toNamed('/transactionDetails',
                                    parameters: {'id': transaction.id});
                              },
                            );
                          },
                        ),
                      ],
                    );
                  },
                ),
              ),
      ],
    );
  }
}
