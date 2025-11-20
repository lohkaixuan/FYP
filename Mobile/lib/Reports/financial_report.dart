import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile/Component/GlobalScaffold.dart';
import 'package:mobile/Controller/ReportController.dart';
import 'package:mobile/Reports/report_detail.dart';

class FinancialReport extends StatelessWidget {
  const FinancialReport({super.key});

  List<int> _yearOptions() {
    final now = DateTime.now().year;
    return [now, now - 1, now - 2];
  }

  @override
  Widget build(BuildContext context) {
    final ReportController c = Get.put(ReportController(), permanent: true);

    return GlobalScaffold(
      title: 'Financial Reports',
      body: Obx(() {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  const Text('Year: '),
                  const SizedBox(width: 8),
                  DropdownButton<int>(
                    value: c.selectedYear.value,
                    items: _yearOptions()
                        .map((y) => DropdownMenuItem(value: y, child: Text(y.toString())))
                        .toList(),
                    onChanged: (y) {
                      if (y != null) c.setYear(y);
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                itemCount: c.months.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final m = c.months[index];
                  final key = m.key;
                  final isReady = c.ready[key] == true;
                  return ListTile(
                    title: Text(m.label),
                    subtitle: Text(isReady ? 'Ready' : 'Not yet'),
                    leading: Icon(
                      isReady ? Icons.check_circle : Icons.schedule,
                      color: isReady ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Get.to(() => const ReportDetailPage(), arguments: {
                        'month': m.month.toIso8601String(),
                        'label': m.label,
                      });
                    },
                  );
                },
              ),
            ),
          ],
        );
      }),
    );
  }
}
