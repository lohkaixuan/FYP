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

<<<<<<< HEAD
  
=======
  // ðŸ‘‡ åªæ¢è¿™ä¸€æ®µ
>>>>>>> 4cec63ed80e44df6bfced19a3befc5329bd1b3f1
  Future<void> generateForMonth(DateTime month) async {
    final now = DateTime.now();
    final firstOfThisMonth = DateTime(now.year, now.month, 1);
    final firstOfSelected = DateTime(month.year, month.month, 1);

<<<<<<< HEAD
    
=======
    // 1) ä¸å…è®¸å½“å‰æœˆå’Œæœªæ¥æœˆä»½
    // 1) Only allow generating past months
>>>>>>> 4cec63ed80e44df6bfced19a3befc5329bd1b3f1
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
<<<<<<< HEAD
      
=======
      // 2) å–å½“å‰è§’è‰² & userId
>>>>>>> 4cec63ed80e44df6bfced19a3befc5329bd1b3f1
      final role = roleC.activeRole.value; // 'user' | 'merchant' | 'thirdparty'
      String? userId;
      String? merchantId;
      String? providerId;

      if (role == 'merchant') {
<<<<<<< HEAD
        
=======
        // å¦‚æžœä½ åŽç«¯æ˜¯ç”¨ MerchantId å•ç‹¬ç»‘å®šï¼Œè¿™é‡Œæ”¹æˆ merchantId
>>>>>>> 4cec63ed80e44df6bfced19a3befc5329bd1b3f1
        merchantId = roleC.userId.value;
      } else if (role == 'thirdparty') {
        providerId = roleC.userId.value;
      } else {
        userId = roleC.userId.value;
      }

<<<<<<< HEAD
      
      final monthIso =
          "${month.year.toString().padLeft(4, '0')}-${month.month.toString().padLeft(2, '0')}-01";

      
=======
      // 3) Month ç”¨ YYYY-MM-01
      final monthIso =
          "${month.year.toString().padLeft(4, '0')}-${month.month.toString().padLeft(2, '0')}-01";

      // 4) è°ƒç”¨ API
>>>>>>> 4cec63ed80e44df6bfced19a3befc5329bd1b3f1
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

<<<<<<< HEAD
      
=======
      // å°è¯•æŠŠåŽç«¯ 400 çš„ message æŠ½å‡ºæ¥
>>>>>>> 4cec63ed80e44df6bfced19a3befc5329bd1b3f1
      String msg = 'Request failed (HTTP $status)';
      if (data is Map && data['message'] is String) {
        msg = data['message'] as String;
      } else if (data != null) {
        msg = data.toString();
      }

<<<<<<< HEAD
      
=======
      // 500 å•ç‹¬æç¤º
>>>>>>> 4cec63ed80e44df6bfced19a3befc5329bd1b3f1
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

<<<<<<< HEAD
    
=======
    // ç»™é¢„è§ˆç”¨çš„ç¼“å­˜
>>>>>>> 4cec63ed80e44df6bfced19a3befc5329bd1b3f1
    currentPdfBytes.value = bytes;

    final fileName =
        'wallet-report-${month.year}-${month.month.toString().padLeft(2, '0')}.pdf';

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

<<<<<<< HEAD
      
=======
      // âœ… ä¸‹è½½å®ŒæˆåŽè‡ªåŠ¨æ‰“å¼€
>>>>>>> 4cec63ed80e44df6bfced19a3befc5329bd1b3f1
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
    ApiDialogs.showError(
      e,
      fallbackTitle: 'Share error',
    );
  } finally {
    loading.value = false;
  }
}


}
