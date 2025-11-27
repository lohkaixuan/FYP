import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile/Component/GlobalScaffold.dart';
import 'package:mobile/Controller/ReportController.dart';
import 'package:mobile/Reports/month_card.dart';
import 'package:mobile/Reports/report_detail.dart';

class FinancialReport extends StatelessWidget {
  const FinancialReport({super.key});

  @override
  Widget build(BuildContext context) {
    final ReportController c = Get.put(ReportController(), permanent: true);
    final Rxn<int> selectedYear = Rxn<int>();

    return GlobalScaffold(
      title: 'Financial Reports',
      body: Obx(() {
        final monthsToShow = selectedYear.value == null
            ? c.months
            : c.months
                .where((m) => m.month.year == selectedYear.value)
                .toList();

        final monthsWithTransaction = monthsToShow
            .where((m) =>
                (c.ready[m.key] ?? false) || (c.responses[m.key] != null))
            .toList();

        final List<int> allYears = c.months
            .map((m) => m.month.year)
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

                    // 清除 filter 按钮
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
              child: ListView(
                children: [
                  for (final year in uniqueYears) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        year.toString(),
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
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

                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 4),
                            child: SizedBox(
                              width: double.infinity,
                              child: MonthCard(
                                month: m.month,
                                isReady: c.ready[m.key] ?? false,
                                onTap: () => Get.to(
                                    () => const ReportDetailPage(),
                                    arguments: {
                                      'pdfUrl': pdfUrl,
                                      'month': m.month.toIso8601String(),
                                      'label': m.label,
                                    }),
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
