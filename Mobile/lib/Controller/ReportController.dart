// ==================================================
// Program Name   : ReportController.dart
// Purpose        : Controller for fetching and managing reports
// Developer      : Mr. Loh Kai Xuan
// Student ID     : TP074510
// Course         : Bachelor of Software Engineering (Hons)
// Created Date   : 15 November 2025
// Last Modified  : 4 January 2026
// ==================================================
import 'dart:io' show Platform;
import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:mobile/Api/apis.dart';
import 'package:mobile/Utils/api_dialogs.dart';
import 'package:mobile/Api/apimodel.dart';
import 'package:mobile/Controller/RoleController.dart';
import 'package:mobile/Utils/file_utlis.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:mobile/Api/apis.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:typed_data';

class ReportMonthItem {
  final DateTime month;
  final String label;
  ReportMonthItem({required this.month, required this.label});
  String get key =>
      "${month.year.toString().padLeft(4, '0')}-${month.month.toString().padLeft(2, '0')}";
}

class ReportController extends GetxController {
  final ApiService api = Get.find<ApiService>();
  final RoleController roleC = Get.find<RoleController>();
  final selectedYear = DateTime.now().year.obs;
  final months = <ReportMonthItem>[].obs;
  final ready = <String, bool>{}.obs;
  final responses = <String, MonthlyReportResponse>{}.obs;
  final loading = false.obs;

  @override
  void onInit() {
    super.onInit();
    recomputeMonthsForYear(selectedYear.value);
  }

  void setYear(int y) {
    if (selectedYear.value == y) return;
    selectedYear.value = y;
    recomputeMonthsForYear(y);
  }

  void recomputeMonthsForYear(int year) {
    final now = DateTime.now();
    final list = <ReportMonthItem>[];
    for (int i = 0; i < 12; i++) {
      final m = DateTime(now.year, now.month - i, 1);
      list.add(ReportMonthItem(
        month: m,
        label: "${m.year}-${m.month.toString().padLeft(2, '0')}",
      ));
    }

    months.value = list;
  }

  Future<void> generateForMonth(DateTime month) async {
    final now = DateTime.now();
    final firstOfThisMonth = DateTime(now.year, now.month, 1);
    final firstOfSelected = DateTime(month.year, month.month, 1);

    if (!firstOfSelected.isBefore(firstOfThisMonth)) {
      ApiDialogs.showError(
        'You can only generate reports for past months.',
        fallbackTitle: 'Generate Failed',
      );
      return;
    }

    final key =
        "${month.year.toString().padLeft(4, '0')}-${month.month.toString().padLeft(2, '0')}";

    loading.value = true;
    try {
      final role = roleC.activeRole.value; // 'user' | 'merchant' | 'thirdparty'
      String? userId;
      String? merchantId;
      String? providerId;

      if (role == 'merchant') {
        merchantId = roleC.userId.value;
      } else if (role == 'thirdparty') {
        providerId = roleC.userId.value;
      } else {
        userId = roleC.userId.value;
      }

      final monthIso =
          "${month.year.toString().padLeft(4, '0')}-${month.month.toString().padLeft(2, '0')}-01";
      final resp = await api.generateMonthlyReport(
        role: role,
        monthIso: monthIso,
        userId: userId,
        merchantId: merchantId,
        providerId: providerId,
      );

      responses[key] = resp;
      ready[key] = true;
      update();

      ApiDialogs.showSuccess(
        'Report Ready',
        'Generated ${resp.month}',
      );
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final data = e.response?.data;
      String msg = 'Request failed (HTTP $status)';
      if (data is Map && data['message'] is String) {
        msg = data['message'] as String;
      } else if (data != null) {
        msg = data.toString();
      }
      if (status == 500) {
        msg =
            'Server cannot generate this report.\næœåŠ¡å™¨ç”ŸæˆæŠ¥è¡¨å¤±è´¥ï¼Œè¯·ç¨åŽå†è¯•æˆ–æ¢ä¸€ä¸ªæœˆä»½ï½ž';
      }

      ApiDialogs.showError(
        msg,
        fallbackTitle: 'Generate Failed',
      );
    } catch (e) {
      ApiDialogs.showError(
        e,
        fallbackTitle: 'Generate Failed',
      );
    } finally {
      loading.value = false;
    }
  }

  final Rx<Uint8List?> currentPdfBytes = Rx<Uint8List?>(null);

  Future<void> downloadFor(DateTime month) async {
    final key =
        '${month.year.toString().padLeft(4, '0')}-${month.month.toString().padLeft(2, '0')}';
    final res = responses[key];

    if (res == null) {
      ApiDialogs.showError(
        'Please generate the report first.',
        fallbackTitle: 'No report',
      );
      return;
    }

    try {
      loading.value = true;

      final api = Get.find<ApiService>();
      final dioRes = await api.downloadReport(res.reportId);

      final data = dioRes.data;
      late Uint8List bytes;
      if (data is Uint8List) {
        bytes = data;
      } else if (data is List<int>) {
        bytes = Uint8List.fromList(data);
      } else {
        throw Exception('Unknown PDF data type: ${data.runtimeType}');
      }

      currentPdfBytes.value = bytes;
      final fileName ='wallet-report-${month.year}-${month.month.toString().padLeft(2, '0')}.pdf';

      if (kIsWeb) {
        await FileUtils.downloadInWeb(
          bytes: bytes,
          fileName: fileName,
          mimeType: 'application/pdf',
        );
        ApiDialogs.showSuccess(
          'Download started',
          'Browser is saving $fileName',
        );
      } else {
        final savePath = await FileUtils.saveBytesToDevice(
          bytes: bytes,
          fileName: fileName,
        );
        await OpenFilex.open(savePath);
        ApiDialogs.showSuccess(
          'Download complete',
          'Saved to: $savePath',
        );
      }
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      String msg;
      if (status == 401) {
        msg = 'Unauthorized (401) â€“ please login again.';
      } else if (status == 500) {
        msg = 'Server error (500) â€“ cannot generate or download this report.';
      } else {
        msg = 'Download failed: ${e.message}';
      }
      ApiDialogs.showError(
        msg,
        fallbackTitle: 'Download error',
      );
    } catch (e) {
      ApiDialogs.showError(
        e,
        fallbackTitle: 'Download error',
      );
    } finally {
      loading.value = false;
    }
  }

  Future<void> shareFor(DateTime month) async {
    if (kIsWeb) {
      ApiDialogs.showError(
        'Sharing is only on mobile/desktop.',
        fallbackTitle: 'Share not supported',
      );
      return;
    }

    final key ='${month.year.toString().padLeft(4, '0')}-${month.month.toString().padLeft(2, '0')}';
    final res = responses[key];
    if (res == null) {
      ApiDialogs.showError(
        'Please generate the report first.',
        fallbackTitle: 'No report',
      );
      return;
    }

    try {
      loading.value = true;
      final api = Get.find<ApiService>();
      final dioRes = await api.downloadReport(res.reportId);
      final data = dioRes.data;
      late Uint8List bytes;
      if (data is Uint8List) {
        bytes = data;
      } else if (data is List<int>) {
        bytes = Uint8List.fromList(data);
      } else {
        throw Exception('Unknown PDF data type: ${data.runtimeType}');
      }

      final fileName ='wallet-report-${month.year}-${month.month.toString().padLeft(2, '0')}.pdf';
      final savePath = await FileUtils.saveBytesToDevice(
        bytes: bytes,
        fileName: fileName,
      );
      await Share.shareXFiles(
        [XFile(savePath, mimeType: 'application/pdf')],
        text: 'Monthly report $fileName',
      );
    } catch (e) {
      ApiDialogs.showError(
        e,
        fallbackTitle: 'Share error',
      );
    } finally {
      loading.value = false;
    }
  }
}
