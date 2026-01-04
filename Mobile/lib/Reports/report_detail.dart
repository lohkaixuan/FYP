// ==================================================
// Program Name   : report_detail.dart
// Purpose        : Report detail screen UI
// Developer      : Mr. Loh Kai Xuan 
// Student ID     : TP074510 
// Course         : Bachelor of Software Engineering (Hons) 
// Created Date   : 15 November 2025
// Last Modified  : 4 January 2026 
// ==================================================
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile/Component/GlobalScaffold.dart';
import 'package:mobile/Component/GradientWidgets.dart';
import 'package:mobile/Controller/ReportController.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class ReportDetailPage extends StatefulWidget {
  const ReportDetailPage({super.key});

  @override
  State<ReportDetailPage> createState() => _ReportDetailPageState();
}

class _ReportDetailPageState extends State<ReportDetailPage> {
  final ReportController c = Get.find<ReportController>();
  late final DateTime month;
  late final String label;
  late final String monthKey;

  @override
  void initState() {
    super.initState();

    final args = Get.arguments as Map? ?? {};
    label = (args['label'] as String?) ?? 'Report';
    final monthIso = (args['month'] as String?) ?? DateTime.now().toIso8601String();
    month = DateTime.tryParse(monthIso) ?? DateTime.now();
    monthKey = "${month.year.toString().padLeft(4, '0')}-${month.month.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return GlobalScaffold(
      title: label,
      body: Obx(() {
        final bool isReady = c.ready[monthKey] == true;
        final bool loading = c.loading.value;
        final bytes = c.currentPdfBytes.value;

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: BrandGradientButton(
                      onPressed: (loading || isReady)
                          ? null
                          : () => c.generateForMonth(month),
                      child: loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(isReady ? 'Report Ready' : 'Generate Report'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: (!isReady || loading)
                          ? null
                          : () => c.downloadFor(month),
                      child: const Text('Download & Open'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.share),
                    onPressed: (!isReady || loading)
                        ? null
                        : () => c.shareFor(month),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: loading
                    ? const Center(child: CircularProgressIndicator())
                    : (bytes == null
                        ? const Center(
                            child: Text(
                              'Tap "Generate Report" then "Download & Open"\nThe PDF will be downloaded, opened and previewed here.',
                              textAlign: TextAlign.center,
                            ),
                          )
                        : SfPdfViewer.memory(bytes)),
              ),
            ],
          ),
        );
      }),
    );
  }
}
