import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:get/get.dart';
import 'package:mobile/Api/apimodel.dart';
import 'package:mobile/Budget/create_budget.dart';
import 'package:mobile/Component/AppTheme.dart';
import 'package:mobile/Component/PieChart.dart';
import 'package:mobile/Controller/BudgetController.dart';

class BudgetChart extends StatelessWidget {
  final List<BudgetSummaryItem> summary;
  final bool isLoading;

  const BudgetChart(
      {super.key, required this.summary, required this.isLoading});

  double _getYLimit(List<BudgetSummaryItem> summary) {
    double yLimit = 0;
    for (var item in summary) {
      final spent = (item.spent ?? 0).toDouble();
      final remaining = (item.remaining ?? 0).toDouble();
      final total = spent + remaining;
      debugPrint(
          "Category ${item.category}: spent=$spent, remaining=$remaining, total=$total");
      if (total > yLimit) yLimit = total;
    }
    debugPrint("YLimit = $yLimit");
    return yLimit > 0 ? yLimit * 1.2 : 1;
  }

  List<BarChartGroupData> _createBarGroups(List<BudgetSummaryItem> summary) {
    return summary.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: item.spent.toDouble() + item.remaining.toDouble(),
            rodStackItems: [
              BarChartRodStackItem(0, item.spent.toDouble(), Colors.red),
              BarChartRodStackItem(
                  item.spent.toDouble(),
                  item.spent.toDouble() + item.remaining.toDouble(),
                  Colors.green),
            ],
            width: 40,
          ),
        ],
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    // Convert List<BudgetSummaryItem> into Map<String, double>.
    final remainingPerCategory = {
      for (var item in summary) item.category: item.remaining.toDouble(),
    };

    // Convert Map<String, double> to list.
    final entries = remainingPerCategory.entries.toList();
    if (entries.isNotEmpty) {
      debugPrint("${entries[0].key},${entries[0].value}");
    }

    // Prepare data for 'View Details'.
    final data = summary.map((entry) {
      return {
        'title': entry.category,
        'amount': entry.remaining,
        'color': null
      };
    }).toList();

    return remainingPerCategory.isEmpty
        ? ChartCard(
            title: 'Remaining Budget',
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(AppTheme.rMd),
              ),
              padding: const EdgeInsets.all(12),
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () => Get.to(const CreateBudgetScreen()),
                        ),
                        const Text(
                          'No budget data available. Please click on the + button to add a new budget.',
                          style: TextStyle(fontSize: 16, color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
            ),
          )
        : ChartCard(
            title: 'Remaining Budget',
            onViewDetailsClicked: () =>
                Get.toNamed('/home/budget-details', arguments: data),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(AppTheme.rMd),
              ),
              padding: const EdgeInsets.all(12),
              child: AspectRatio(
                aspectRatio: 1.3,
                child: Column(
                  children: [
                    AspectRatio(
                      aspectRatio: 1.8,
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.center,
                          maxY: _getYLimit(summary),
                          barGroups: _createBarGroups(summary),
                          titlesData: FlTitlesData(
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(
                                  showTitles: false), // Add this line
                            ),
                            leftTitles: const AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 50,
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  final index = value.toInt();
                                  if (index < 0 || index >= summary.length) {
                                    return const SizedBox();
                                  }
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(summary[index].category),
                                  );
                                },
                                reservedSize: 50,
                              ),
                            ),
                          ),
                          gridData: const FlGridData(show: true),
                          borderData: FlBorderData(show: false),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Wrap(spacing: 12, runSpacing: 6, children: [
                      LegendItem(color: Colors.red, label: 'Spent'),
                      LegendItem(color: Colors.green, label: 'Remaining'),
                    ]),
                  ],
                ),
              ),
            ),
          );
  }
}
