import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile/Component/AppTheme.dart';
import 'package:mobile/Component/GlobalScaffold.dart';
import 'package:mobile/Component/GradientWidgets.dart';
import 'package:mobile/Controller/ReportController.dart';

class ReportDetailPage extends StatelessWidget {
  const ReportDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments as Map? ?? {};
    final label = (args['label'] as String?) ?? 'Report';
    final monthIso = (args['month'] as String?) ?? DateTime.now().toIso8601String();
    final month = DateTime.tryParse(monthIso) ?? DateTime.now();
    final key = "${month.year.toString().padLeft(4, '0')}-${month.month.toString().padLeft(2, '0')}";
    final c = Get.find<ReportController>();

    return GlobalScaffold(
      title: label,
      body: Obx(() {
        final isReady = c.ready[key] == true;
        final loading = c.loading.value;
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: BrandGradientButton(
                      onPressed: loading ? null : () => c.generateFor(month),
                      child: loading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Generate Report'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: (!isReady || loading) ? null : () => c.downloadFor(month),
                      child: const Text('Download PDF'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const DottedBorder(
                        options: RoundedRectDottedBorderOptions(
                          radius: Radius.circular(16),
                          padding: EdgeInsets.all(20),
                        ),
                        child: SizedBox(
                          height: 160,
                          child: Center(child: Text('Income vs. Expenses Chart (placeholder)')),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Summary', style: AppTheme.textMediumBlack),
                    const SizedBox(height: 8),
                    const Row(
                      children: [
                        _MiniStat(title: 'INCOME', value: 'RM 0.00'),
                        _MiniStat(title: 'EXPENSES', value: 'RM 0.00'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Row(
                      children: [
                        _MiniStat(title: 'SAVINGS', value: 'RM 0.00'),
                        _MiniStat(title: 'SAVINGS RATE', value: '0%'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String title;
  final String value;
  const _MiniStat({required this.title, required this.value});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Text(title, style: AppTheme.textSmallGrey),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

