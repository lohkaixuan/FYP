// ==================================================
// Program Name   : PieChart.dart
// Purpose        : Pie chart widget component
// Developer      : Mr. Loh Kai Xuan 
// Student ID     : TP074510 
// Course         : Bachelor of Software Engineering (Hons) 
// Created Date   : 15 November 2025
// Last Modified  : 4 January 2026 
// ==================================================
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:mobile/Component/AppTheme.dart';
import 'package:get/get.dart';
import 'package:mobile/Transaction/Transactionpage.dart';

class DebitCreditDonut extends StatelessWidget {
  final double debit; 
  final double credit; 
  final bool isLoading;
  const DebitCreditDonut(
      {super.key,
      required this.debit,
      required this.credit,
      required this.isLoading});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final double d = debit.abs();
    final double c = credit.abs();
    final total = (d + c);
    final sections = [
      if (d > 0)
        PieChartSectionData(
          value: d,
          color: Colors.redAccent,
          title: '',
          radius: 36,
          titleStyle: theme.textTheme.labelMedium
              ?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      if (c > 0)
        PieChartSectionData(
          value: c,
          color: Colors.green,
          title: '',
          radius: 36,
          titleStyle: theme.textTheme.labelMedium
              ?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
        ),
    ];

    return total == 0
        ? ChartCard(
            title: 'Debit vs Credit',
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                color: cs.surfaceVariant,
                borderRadius: BorderRadius.circular(AppTheme.rMd),
              ),
              padding: const EdgeInsets.all(12),
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : const Center(
                      child: Text(
                        'No transaction data available.',
                        style: TextStyle(fontSize: 16, color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ),
            ),
          )
        : ChartCard(
            title: 'Debit vs Credit',
            onViewDetailsClicked: () => Get.toNamed(
              '/home/debit-credit-details',
              arguments: [
                {
                  'title': 'Debit',
                  'amount': debit,
                  'color': Colors.redAccent,
                  'onTap': () => Get.to(() => const Transactions(),
                      arguments: {"filter": 'debit'})
                },
                {
                  'title': 'Credit',
                  'amount': credit,
                  'color': Colors.green,
                  'onTap': () => Get.to(() => const Transactions(),
                      arguments: {"filter": 'credit'})
                },
              ],
            ),
            child: Container(
              decoration: BoxDecoration(
                color: cs.surfaceVariant,
                borderRadius: BorderRadius.circular(AppTheme.rMd),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AspectRatio(
                    aspectRatio: 1.5,
                    child: PieChart(
                      PieChartData(
                        centerSpaceRadius: 36,
                        sectionsSpace: 2,
                        startDegreeOffset: -90,
                        sections: sections,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 6,
                    alignment: WrapAlignment.center,
                    children: [
                      LegendItem(
                          color: Colors.redAccent,
                          label: 'Debit',
                          percentage: total == 0 ? 0 : (d / total) * 100),
                      LegendItem(
                          color: Colors.green,
                          label: 'Credit',
                          percentage: total == 0 ? 0 : (c / total) * 100),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          );
  }
}

class CategoryPieChart extends StatelessWidget {
  final Map<String, double> data;
  final bool isLoading;
  const CategoryPieChart(
      {super.key, required this.data, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final colors = <Color>[
      cs.primary,
      cs.secondary,
      cs.tertiary,
      Colors.teal,
      Colors.orange,
      Colors.pink,
      Colors.indigo,
    ];

    final entries = data.entries.toList();
    final List<Map<String, dynamic>> detailsData = List.generate(
      entries.length,
      (index) => {
        'title': entries[index].key,
        'amount': entries[index].value,
        'color': colors[index % colors.length],
      },
    );
    final total = data.values.fold<double>(0, (p, n) => p + n.abs());
    final sections = <PieChartSectionData>[];
    final List<Map<String, dynamic>> legendData = [];

    for (int i = 0; i < entries.length; i++) {
      final e = entries[i];
      final val = e.value.abs();
      final color = colors[i % colors.length];
      sections.add(
        PieChartSectionData(
          value: val,
          color: color,
          title: '',
          radius: 36,
          titleStyle: theme.textTheme.labelMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
      legendData.add({
        'label': e.key,
        'color': color,
        'percentage': total == 0 ? 0 : (val / total) * 100,
      });
    }

    return data.isEmpty
        ? ChartCard(
            title: 'By Category',
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                color: cs.surfaceVariant,
                borderRadius: BorderRadius.circular(AppTheme.rMd),
              ),
              padding: const EdgeInsets.all(12),
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : const Center(
                      child: Text(
                        'No transaction data available.',
                        style: TextStyle(fontSize: 16, color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ),
            ),
          )
        : ChartCard(
            title: 'By Category',
            onViewDetailsClicked: () =>
                Get.toNamed('/home/spendingDetails', arguments: detailsData),
            child: Container(
              decoration: BoxDecoration(
                color: cs.surfaceVariant,
                borderRadius: BorderRadius.circular(AppTheme.rMd),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  AspectRatio(
                    aspectRatio: 1.8,
                    child: PieChart(
                      PieChartData(
                        centerSpaceRadius: 36,
                        sectionsSpace: 2,
                        startDegreeOffset: -90,
                        sections: sections,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    runSpacing: 6,
                    children: [
                      for (final item in legendData)
                        LegendItem(
                          color: item['color'],
                          label: item['label'],
                          percentage: item['percentage'],
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          );
  }
}

class LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final double? percentage;
  const LegendItem(
      {super.key, required this.color, required this.label, this.percentage});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    String percentageText = '';
    // Calculate text: Use '<1%' for percentages between 0 and 1, otherwise round to nearest integer.
    if (percentage != null) {
      if (percentage! >= 1.0) {
        percentageText = '${percentage!.toStringAsFixed(0)}%';
      } else if (percentage! < 1) {
        percentageText = '<1%';
      }
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 6),
        Text('$label ${percentageText.isNotEmpty ? '($percentageText)' : ''}',
            style: theme.textTheme.labelMedium),
      ],
    );
  }
}

class ChartCard extends StatelessWidget {
  final String title;
  final Widget child;
  final VoidCallback? onViewDetailsClicked;
  const ChartCard(
      {super.key,
      required this.title,
      required this.child,
      this.onViewDetailsClicked});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Card(
      elevation: 0,
      color: cs.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      )),
                ),
                if (onViewDetailsClicked != null)
                  TextButton(
                    onPressed: onViewDetailsClicked,
                    child: Text(
                      'View Details',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: cs.primary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}
