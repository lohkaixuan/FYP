// ==================================================
// Program Name   : Transactionpage.dart
// Purpose        : Transaction page container
// Developer      : Mr. Loh Kai Xuan 
// Student ID     : TP074510 
// Course         : Bachelor of Software Engineering (Hons) 
// Created Date   : 15 November 2025
// Last Modified  : 4 January 2026 
// ==================================================
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile/Component/GlobalScaffold.dart';
import 'package:mobile/Component/TransactionCard.dart' as ui;
import 'package:mobile/Controller/TransactionController.dart';
import 'Transcation_list.dart';

class Transactions extends StatelessWidget {
  const Transactions({super.key});
  String _formatMonthLabel(DateTime dt) {
    const monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${monthNames[dt.month - 1]} ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<TransactionController>();
    final Rxn<DateTime> selectedMonth = Rxn<DateTime>();
    return GlobalScaffold(
      title: 'Transactions',
      body: Obx(() {
        final allTx = controller.transactions.toList();
        final Map<String, DateTime> monthSet = {};
        for (var tx in allTx) {
          final t = tx.timestamp;
          final key = '${t.year}-${t.month}';
          monthSet[key] = DateTime(t.year, t.month);
        }
        final List<DateTime> availableMonths = monthSet.values.toList()
          ..sort((a, b) => b.compareTo(a));
        final List<ui.TransactionModel> filtered = selectedMonth.value == null
            ? allTx
            : allTx.where((tx) {
                return tx.timestamp.year == selectedMonth.value!.year &&
                    tx.timestamp.month == selectedMonth.value!.month;
              }).toList();

        return Column(
          children: [
            if (availableMonths.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const SizedBox(height: 16,),
                    Expanded(
                      child: Obx(() {
                        return DropdownButtonFormField<DateTime>(
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Filter by month',
                            border: OutlineInputBorder(),
                          ),
                          value: selectedMonth.value,
                          items: availableMonths
                              .map(
                                (m) => DropdownMenuItem<DateTime>(
                                  value: m,
                                  child: Text(_formatMonthLabel(m)),
                                ),
                              )
                              .toList(),
                          onChanged: (val) => selectedMonth.value = val,
                        );
                      }),
                    ),
                    const SizedBox(width: 8),
                    Obx(() {
                      if (selectedMonth.value == null) {
                        return const SizedBox();
                      }
                      return TextButton(
                        onPressed: () => selectedMonth.value = null,
                        child: const Text("Clear"),
                      );
                    }),
                  ],
                ),
              ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await controller.getAll();
                },
                child: filtered.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: const [
                          SizedBox(height: 120),
                          Center(
                            child: Text(
                              'No Transactions Found!',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ),
                        ],
                      )
                    : TransactionList(items: filtered),
              ),
            ),
          ],
        );
      }),
    );
  }
}
