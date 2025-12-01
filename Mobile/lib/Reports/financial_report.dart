import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile/Component/GlobalScaffold.dart';
import 'package:mobile/Controller/ReportController.dart';
import 'package:mobile/Controller/TransactionController.dart';
import 'package:mobile/Reports/report_detail.dart';

class FinancialReport extends StatelessWidget {
  const FinancialReport({super.key});

  @override
  Widget build(BuildContext context) {
    final ReportController c = Get.put(ReportController(), permanent: true);
    final TransactionController txController =
        Get.find<TransactionController>();
    final Rxn<int> selectedYear = Rxn<int>();

    return GlobalScaffold(
      title: 'Financial Reports',
      body: Obx(() {
        final allTx = txController.rawTransactions
            .where((t) => t.timestamp != null)
            .toList();

        final monthsToShow = selectedYear.value == null
            ? c.months
            : c.months
                .where((m) => m.month.year == selectedYear.value)
                .toList();

        final monthsWithTransaction = monthsToShow
            .where((m) =>
                allTx.any((t) =>
                    t.timestamp!.year == m.month.year &&
                    t.timestamp!.month == m.month.month) ||
                (c.ready[m.key] ?? false) ||
                (c.responses[m.key] != null))
            .toList();

        final List<int> allYears = [
          ...c.months.map((m) => m.month.year),
          ...allTx.map((t) => t.timestamp!.year),
        ]
            .toSet()
            .toList()
          ..sort((a, b) => b.compareTo(a));

        final List<int> uniqueYears = monthsWithTransaction
            .map((m) => m.month.year)
            .toSet()
            .toList()
          ..sort((a, b) => b.compareTo(a));

        final Map<int, List<ReportMonthItem>> monthsByYear = {};
        for (var m in monthsWithTransaction) {
          final year = m.month.year;
          monthsByYear.putIfAbsent(year, () => []).add(m);
        }

        return Column(
          children: [
            if (uniqueYears.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const SizedBox(
                      height: 16,
                    ),
                    Expanded(
                      child: Obx(() {
                        return DropdownButtonFormField(
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Filter by year',
                            border: OutlineInputBorder(),
                          ),
                          initialValue: selectedYear.value,
                          items: [
                            const DropdownMenuItem<int>(
                              value: null,
                              child: Text('All'),
                            ),
                            ...allYears.map(
                              (m) => DropdownMenuItem(
                                value: m,
                                child: Text(m.toString()),
                              ),
                            )
                          ],
                          onChanged: (val) => selectedYear.value = val,
                        );
                      }),
                    ),
                    const SizedBox(width: 8),

                    // Clear filter button
                    Obx(() {
                      if (selectedYear.value == null) {
                        return const SizedBox();
                      }
                      return TextButton(
                        onPressed: () => selectedYear.value = null,
                        child: const Text("Clear"),
                      );
                    }),
                  ],
                ),
              ),
            Expanded(
              child: uniqueYears.isEmpty
                  ? const Center(child: Text('No transactions to display yet.'))
                  : ListView(
                      children: [
                        for (final year in uniqueYears) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Text(
                              year.toString(),
                              style:
                                  Theme.of(context).textTheme.labelLarge?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                        fontWeight: FontWeight.w700,
                                      ),
                            ),
                          ),
                          if (monthsByYear[year] != null)
                            ...monthsByYear[year]!.map((m) {
                              return Obx(() {
                                final pdfResponse = c.responses[m.key];
                                final pdfUrl = pdfResponse?.downloadUrl;
                                final monthTx = allTx
                                    .where((t) =>
                                        t.timestamp!.year == m.month.year &&
                                        t.timestamp!.month == m.month.month)
                                    .toList();
                                final income = monthTx
                                    .where((t) => t.amount > 0)
                                    .fold<double>(0, (sum, t) => sum + t.amount);
                                final expenses = monthTx
                                    .where((t) => t.amount < 0)
                                    .fold<double>(
                                        0, (sum, t) => sum + t.amount.abs());
                                final isReady = c.ready[m.key] ?? false;
                                final Color statusColor =
                                    isReady ? Colors.green : Colors.orange;
                                final String subtitle = monthTx.isEmpty
                                    ? 'No transactions recorded'
                                    : '${monthTx.length} transactions | '
                                        '+RM ${income.toStringAsFixed(2)} / '
                                        '-RM ${expenses.toStringAsFixed(2)}';

                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 4),
                                  child: Card(
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      side: BorderSide(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .outlineVariant,
                                      ),
                                    ),
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 10),
                                      leading: CircleAvatar(
                                        backgroundColor: Theme.of(context)
                                            .colorScheme
                                            .primary
                                            .withOpacity(0.12),
                                        child: Icon(
                                          isReady
                                              ? Icons.insert_chart_outlined_rounded
                                              : Icons.schedule_rounded,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                        ),
                                      ),
                                      title: Text(
                                        m.label,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                                fontWeight: FontWeight.w700),
                                      ),
                                      subtitle: Text(
                                        subtitle,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                      ),
                                      trailing: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color:
                                                  statusColor.withOpacity(0.12),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              border: Border.all(
                                                color:
                                                    statusColor.withOpacity(0.25),
                                              ),
                                            ),
                                            child: Text(
                                              isReady ? 'Ready' : 'Pending',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .labelSmall
                                                  ?.copyWith(
                                                    color: statusColor,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                            ),
                                          ),
                                          if (pdfUrl != null)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  top: 6.0),
                                              child: Text(
                                                'PDF available',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .labelSmall
                                                    ?.copyWith(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .primary,
                                                    ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      onTap: () => Get.to(
                                        () => const ReportDetailPage(),
                                        arguments: {
                                          'pdfUrl': pdfUrl,
                                          'month': m.month.toIso8601String(),
                                          'label': m.label,
                                        },
                                      ),
                                    ),
                                  ),
                                );
                              });
                            })
                        ],
                      ],
                    ),
            ),
          ],
        );
      }),
    );
  }
}
