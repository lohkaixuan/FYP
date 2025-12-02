import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile/Component/GlobalScaffold.dart';
import 'package:mobile/Controller/ReportController.dart';
import 'package:mobile/Reports/month_card.dart'; // 👈 复用你现有的组件
import 'package:mobile/Reports/report_detail.dart'; // 👈 复用你现有的详情页

class ProviderReportPage extends StatelessWidget {
  const ProviderReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    // 初始化 ReportController
    // 确保 RoleController.activeRole 已经是 'provider' 或 'thirdparty'
    final ReportController c = Get.put(ReportController());

    return GlobalScaffold(
      title: 'Provider Reports',
      body: Obx(() {
        // 直接使用 ReportController 里算好的月份列表 (fiscal year style)
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
            final key = item.key; // e.g., "2025-10"

            // 检查 Controller 里的状态
            // ready[key] == true 表示刚生成成功
            // responses[key] != null 表示已经有生成过的记录
            final bool isReady = (c.ready[key] ?? false) || c.responses.containsKey(key);

            return MonthCard(
              month: item.month,
              isReady: isReady,
              onTap: () {
                // 跳转到通用的 ReportDetailPage
                // 只要 RoleController.activeRole 是对的，Controller 就会传正确的 role 给后端
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