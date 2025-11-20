// lib/Transaction/Transactions.dart
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

    // 使用 Rx 包装 UI 过滤状态
    final Rxn<DateTime> selectedMonth = Rxn<DateTime>();

    return GlobalScaffold(
      title: 'Transactions',
      body: Obx(() {
        // 全部交易
        final allTx = controller.transactions.toList();

        // ------------------------
        // ① 计算所有“有交易的月份”
        // ------------------------
        final Map<String, DateTime> monthSet = {};
        for (var tx in allTx) {
          final t = tx.timestamp;
          final key = '${t.year}-${t.month}';
          monthSet[key] = DateTime(t.year, t.month);
        }
        final List<DateTime> availableMonths = monthSet.values.toList()
          ..sort((a, b) => b.compareTo(a)); // 最新排前

        // ------------------------
        // ② 根据 selectedMonth 过滤
        // ------------------------
        final List<ui.TransactionModel> filtered = selectedMonth.value == null
            ? allTx
            : allTx.where((tx) {
                return tx.timestamp.year == selectedMonth.value!.year &&
                    tx.timestamp.month == selectedMonth.value!.month;
              }).toList();

        return Column(
          children: [
            // ------------------------
            // 🔽 ③ 月份过滤下拉框
            // ------------------------
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

                    // 清除 filter 按钮
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

            // ------------------------
            // 🔄 ④ 列表 + 下拉刷新
            // ------------------------
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
