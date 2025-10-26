// lib/Component/UniPayCharts.dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:mobile/Component/AppTheme.dart';
import 'package:get/get.dart';

class DebitCreditDonut extends StatelessWidget {
  final double debit; // 支出（负数也行，会自动取绝对值）
  final double credit; // 收入/充值
  const DebitCreditDonut(
      {super.key, required this.debit, required this.credit});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final double d = debit.abs();
    final double c = credit.abs();
    final total = (d + c);
    final sections = [
      PieChartSectionData(
        value: d == 0 ? 0.0001 : d,
        color: Colors.redAccent,
        title: total == 0 ? '0%' : '${(d / total * 100).toStringAsFixed(0)}%',
        radius: 42,
        titleStyle: theme.textTheme.labelMedium
            ?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
      ),
      PieChartSectionData(
        value: c == 0 ? 0.0001 : c,
        color: Colors.green,
        title: total == 0 ? '0%' : '${(c / total * 100).toStringAsFixed(0)}%',
        radius: 42,
        titleStyle: theme.textTheme.labelMedium
            ?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
      ),
    ];

    return _ChartCard(
      title: 'Debit vs Credit',
      onViewDetailsClicked: () => Get.toNamed(
        '/home/debit-credit-details',
        arguments: [
          {'title': 'Debit', 'amount': debit, 'color': Colors.redAccent},
          {'title': 'Credit', 'amount': credit, 'color': Colors.green},
        ],
      ),
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
            _LegendItem(color: Colors.redAccent, label: 'Debit'),
            const SizedBox(width: 12),
            _LegendItem(color: Colors.green, label: 'Credit'),
            const SizedBox(width: 12),
          ],
        ),
      ),
    );
  }
}

class CategoryPieChart extends StatelessWidget {
  /// map of category -> absolute amount
  final Map<String, double> data;
  const CategoryPieChart({super.key, required this.data});

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
    final total = data.values.fold<double>(0, (p, n) => p + n.abs());
    final sections = <PieChartSectionData>[];

    for (int i = 0; i < entries.length; i++) {
      final e = entries[i];
      final val = e.value.abs();
      final color = colors[i % colors.length];
      sections.add(
        PieChartSectionData(
          value: val == 0 ? 0.0001 : val,
          color: color,
          title: total == 0 ? '' : '${(val / total * 100).toStringAsFixed(0)}%',
          radius: 44,
          titleStyle: theme.textTheme.labelMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    return _ChartCard(
      title: 'By Category',
      onViewDetailsClicked: () => Get.toNamed('/home/spendingDetails'),
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
              for (int i = 0; i < entries.length; i++)
                _LegendItem(
                  color: colors[i % colors.length],
                  label: entries[i].key,
                ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 6),
        Text(label, style: theme.textTheme.labelMedium),
      ],
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String title;
  final Widget child;
  final VoidCallback? onViewDetailsClicked;
  const _ChartCard(
      {required this.title, required this.child, this.onViewDetailsClicked});

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
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 32),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'View Details',
                      style: AppTheme.textLink,
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
