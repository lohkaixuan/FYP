// ==================================================
// Program Name   : providerReport.dart
// Purpose        : Third-party provider report page
// Developer      : Mr. Loh Kai Xuan 
// Student ID     : TP074510 
// Course         : Bachelor of Software Engineering (Hons) 
// Created Date   : 15 November 2025
// Last Modified  : 4 January 2026 
// ==================================================
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile/Component/GlobalScaffold.dart';
import 'package:mobile/Controller/ReportController.dart';
import 'package:mobile/Reports/month_card.dart'; 
import 'package:mobile/Reports/report_detail.dart'; 

class ProviderReportPage extends StatelessWidget {
  const ProviderReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ReportController c = Get.put(ReportController());
    return GlobalScaffold(
      title: 'Provider Reports',
      body: Obx(() {
        final months = c.months;
        if (months.isEmpty) {
          return const Center(child: Text('No report cycles available.'));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: months.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final item = months[index];
            final key = item.key; 
            final bool isReady = (c.ready[key] ?? false) || c.responses.containsKey(key);

            return MonthCard(
              month: item.month,
              isReady: isReady,
              onTap: () {
                Get.to(
                  () => const ReportDetailPage(),
                  arguments: {
                    'label': item.label,
                    'month': item.month.toIso8601String(),
                    'pdfUrl': c.responses[key]?.downloadUrl,
                  },
                );
              },
            );
          },
        );
      }),
    );
  }
}