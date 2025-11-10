import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:get/get.dart';
import 'package:mobile/Api/apimodel.dart';
import 'package:mobile/Component/AppTheme.dart';
import 'package:mobile/Component/PieChart.dart';

class BudgetChart extends StatelessWidget {
  final List<BudgetSummaryItem> summary;

  const BudgetChart({super.key, required this.summary});

  List<PieChartSectionData> _createSections(
      Map<String, double> remainingPerCategory) {
    remainingPerCategory.entries.map((entry) {
      return PieChartSectionData(
        value: entry.value,
        color: _getColor(entry.key, remainingPerCategory),
        title: '${entry.value}%',
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        radius: 70,
      );
    }).toList();
    return [];
  }

  Color _getColor(String category, Map<String, double> remainingPerCategory) {
    return Colors
        .primaries[remainingPerCategory.keys.toList().indexOf(category) %
            Colors.primaries.length]
        .shade700;
  }

  @override
  Widget build(BuildContext context) {
    // Convert List<BudgetSummaryItem> into Map<String, double>.
    final remainingPerCategory = {
      for (var item in summary) item.category: item.percent,
    };

    // Convert Map<String, double> to list.
    final entries = remainingPerCategory.entries.toList();
    if (entries.isNotEmpty) {
      debugPrint("${entries[0].key},${entries[0].value}");
    }

    // Prepare data for 'View Details'.
    final chartData = summary.map((entry) {
      return {
        'title': entry.category,
        'amount': entry.remaining,
        'color': _getColor(entry.category, remainingPerCategory)
      };
    }).toList();

    // Create sections for PieChart.
    final sections = _createSections(remainingPerCategory);

    return remainingPerCategory.isEmpty
        ? const ChartCard(
            title: 'Remaining Budget',
            child: SizedBox(
              height: 150,
              child: Center(
                child: Text(
                  'No budget data available.',
                  style: TextStyle(fontSize: 16, color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          )
        : ChartCard(
            title: 'Remaining Budget',
            onViewDetailsClicked: () =>
                Get.toNamed('/home/budget-details', arguments: chartData),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(AppTheme.rMd),
              ),
              padding: const EdgeInsets.all(12),
              child: AspectRatio(
                aspectRatio: 1.8,
                child: Row(
                  children: [
                    Expanded(
                      child: PieChart(
                        PieChartData(
                          centerSpaceRadius: 36,
                          sectionsSpace: 2,
                          startDegreeOffset: -90,
                          sections: sections,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 6,
                        children: entries.map((entry) {
                          final color =
                              _getColor(entry.key, remainingPerCategory);
                          return LegendItem(color: color, label: entry.key);
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
  }
}
