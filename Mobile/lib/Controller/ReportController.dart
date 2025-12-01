import 'dart:io' show Platform;
import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:mobile/Api/apis.dart';
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
  final DateTime month; // first day of month
  final String label; // e.g. "Aug 2024"
  ReportMonthItem({required this.month, required this.label});

  String get key =>
      "${month.year.toString().padLeft(4, '0')}-${month.month.toString().padLeft(2, '0')}";
}

class ReportController extends GetxController {
  final ApiService api = Get.find<ApiService>();
  final RoleController roleC = Get.find<RoleController>();

  final selectedYear = DateTime.now().year.obs;
  final months = <ReportMonthItem>[].obs; // 12 items (Aug Y-1 .. Jul Y)
  final ready = <String, bool>{}.obs; // key -> ready
  final responses = <String, MonthlyReportResponse>{}.obs; // key -> response
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

  // Fiscal-year style: Aug (Y-1) .. Jul (Y)
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
    // final list = <ReportMonthItem>[];
    // final labels = const [
    //   'Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'
    // ];

    // final start = DateTime(year - 1, 8, 1); // Aug (Y-1)
    // for (int i = 0; i < 12; i++) {
    //   final m = DateTime(start.year, start.month + i, 1);
    //   final label = "${labels[m.month - 1]} ${m.year}";
    //   list.add(ReportMonthItem(month: m, label: label));
    // }
    // months.assignAll(list);

    // // Mark readiness: month strictly before current month is considered ready
    // final now = DateTime.now();
    // for (final m in list) {
    //   final key = m.key;
    //   final isBeforeCurrent = (m.month.year < now.year) ||
    //       (m.month.year == now.year && m.month.month < now.month);
    //   ready[key] = ready[key] ?? isBeforeCurrent; // preserve true if already generated
    // }
  }

  // 👇 只换这一段
  Future<void> generateForMonth(DateTime month) async {
    final now = DateTime.now();
    final firstOfThisMonth = DateTime(now.year, now.month, 1);
    final firstOfSelected = DateTime(month.year, month.month, 1);

    // 1) 不允许当前月和未来月份
    if (!firstOfSelected.isBefore(firstOfThisMonth)) {
      Get.snackbar(
        'Generate Failed',
        'You can only generate reports for past months.\n只能为已经结束的月份生成报表哦～',
      );
      return;
    }

    final key =
        "${month.year.toString().padLeft(4, '0')}-${month.month.toString().padLeft(2, '0')}";

    loading.value = true;
    try {
      // 2) 取当前角色 & userId
      final role = roleC.activeRole.value; // 'user' | 'merchant' | 'thirdparty'
      String? userId;
      String? merchantId;
      String? providerId;

      if (role == 'merchant') {
        // 如果你后端是用 MerchantId 单独绑定，这里改成 merchantId
        merchantId = roleC.userId.value;
      } else if (role == 'thirdparty') {
        providerId = roleC.userId.value;
      } else {
        userId = roleC.userId.value;
      }

      // 3) Month 用 YYYY-MM-01
      final monthIso =
          "${month.year.toString().padLeft(4, '0')}-${month.month.toString().padLeft(2, '0')}-01";

      // 4) 调用 API
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

      Get.snackbar('Report Ready', 'Generated ${resp.month}');
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final data = e.response?.data;

      // 尝试把后端 400 的 message 抽出来
      String msg = 'Request failed (HTTP $status)';
      if (data is Map && data['message'] is String) {
        msg = data['message'] as String;
      } else if (data != null) {
        msg = data.toString();
      }

      // 500 单独提示
      if (status == 500) {
        msg =
            'Server cannot generate this report.\n服务器生成报表失败，请稍后再试或换一个月份～';
      }

      Get.snackbar('Generate Failed', msg);
    } catch (e) {
      Get.snackbar('Generate Failed', e.toString());
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
    Get.snackbar('No report', 'Please generate the report first.');
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

    // 给预览用的缓存
    currentPdfBytes.value = bytes;

    final fileName =
        'wallet-report-${month.year}-${month.month.toString().padLeft(2, '0')}.pdf';

    if (kIsWeb) {
      await FileUtils.downloadInWeb(
        bytes: bytes,
        fileName: fileName,
        mimeType: 'application/pdf',
      );
      Get.snackbar('Download started', 'Browser is saving $fileName');
    } else {
      final savePath = await FileUtils.saveBytesToDevice(
        bytes: bytes,
        fileName: fileName,
      );

      // ✅ 下载完成后自动打开
      await OpenFilex.open(savePath);

      Get.snackbar(
        'Download complete',
        'Saved to: $savePath',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 4),
      );
    }
  } on DioException catch (e) {
    final status = e.response?.statusCode;
    String msg;
    if (status == 401) {
      msg = 'Unauthorized (401) – please login again.';
    } else if (status == 500) {
      msg = 'Server error (500) – cannot generate or download this report.';
    } else {
      msg = 'Download failed: ${e.message}';
    }
    Get.snackbar('Download error', msg);
  } catch (e) {
    Get.snackbar('Download error', e.toString());
  } finally {
    loading.value = false;
  }
}
Future<void> shareFor(DateTime month) async {
  if (kIsWeb) {
    Get.snackbar('Share not supported', 'Sharing is only on mobile/desktop.');
    return;
  }

  final key =
      '${month.year.toString().padLeft(4, '0')}-${month.month.toString().padLeft(2, '0')}';
  final res = responses[key];
  if (res == null) {
    Get.snackbar('No report', 'Please generate the report first.');
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

    final fileName =
        'wallet-report-${month.year}-${month.month.toString().padLeft(2, '0')}.pdf';

    final savePath = await FileUtils.saveBytesToDevice(
      bytes: bytes,
      fileName: fileName,
    );

    await Share.shareXFiles(
      [XFile(savePath, mimeType: 'application/pdf')],
      text: 'Monthly report $fileName',
    );
  } catch (e) {
    Get.snackbar('Share error', e.toString());
  } finally {
    loading.value = false;
  }
}


}
