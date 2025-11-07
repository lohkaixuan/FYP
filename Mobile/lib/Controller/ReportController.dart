import 'dart:io' show Platform;
import 'package:get/get.dart';
import 'package:mobile/Api/apis.dart';
import 'package:mobile/Api/apimodel.dart';
import 'package:mobile/Controller/RoleController.dart';
import 'package:mobile/Utils/file_utlis.dart';

class ReportMonthItem {
  final DateTime month; // first day of month
  final String label;   // e.g. "Aug 2024"
  ReportMonthItem({required this.month, required this.label});

  String get key => "${month.year.toString().padLeft(4, '0')}-${month.month.toString().padLeft(2, '0')}";
}

class ReportController extends GetxController {
  final ApiService api = Get.find<ApiService>();
  final RoleController roleC = Get.find<RoleController>();

  final selectedYear = DateTime.now().year.obs;
  final months = <ReportMonthItem>[].obs;           // 12 items (Aug Y-1 .. Jul Y)
  final ready = <String, bool>{}.obs;               // key -> ready
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
    final list = <ReportMonthItem>[];
    final labels = const [
      'Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'
    ];

    final start = DateTime(year - 1, 8, 1); // Aug (Y-1)
    for (int i = 0; i < 12; i++) {
      final m = DateTime(start.year, start.month + i, 1);
      final label = "${labels[m.month - 1]} ${m.year}";
      list.add(ReportMonthItem(month: m, label: label));
    }
    months.assignAll(list);

    // Mark readiness: month strictly before current month is considered ready
    final now = DateTime.now();
    for (final m in list) {
      final key = m.key;
      final isBeforeCurrent = (m.month.year < now.year) ||
          (m.month.year == now.year && m.month.month < now.month);
      ready[key] = ready[key] ?? isBeforeCurrent; // preserve true if already generated
    }
  }

  Future<void> generateFor(DateTime month) async {
    final key = "${month.year.toString().padLeft(4, '0')}-${month.month.toString().padLeft(2, '0')}";
    loading.value = true;
    try {
      final role = roleC.activeRole.value; // 'user' | 'merchant' | 'provider'
      String? userId;
      String? merchantId;
      String? providerId;
      if (role == 'merchant') {
        merchantId = roleC.userId.value; // backend may expect owner user id; adjust if needed
      } else if (role == 'provider') {
        providerId = roleC.userId.value;
      } else {
        userId = roleC.userId.value;
      }
      final isoMonth = DateTime(month.year, month.month, 1).toIso8601String();
      final resp = await api.generateMonthlyReport(
        role: role,
        monthIso: isoMonth,
        userId: userId,
        merchantId: merchantId,
        providerId: providerId,
      );
      responses[key] = resp;
      ready[key] = true;
      update();
      Get.snackbar('Report Ready', 'Generated ${resp.month}');
    } catch (e) {
      Get.snackbar('Generate Failed', e.toString());
    } finally {
      loading.value = false;
    }
  }

  Future<void> downloadFor(DateTime month) async {
    final key = "${month.year.toString().padLeft(4, '0')}-${month.month.toString().padLeft(2, '0')}";
    final resp = responses[key];
    if (resp == null || resp.reportId.isEmpty) {
      Get.snackbar('Unavailable', 'Please generate the report first.');
      return;
    }

    try {
      loading.value = true;
      final http = await api.downloadReport(resp.reportId);
      final bytes = http.data ?? const <int>[];
      final fname = "Report_${key}.pdf";
      if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS || Platform.isLinux || Platform.isWindows) {
        final path = await FileUtils.saveBytesToDevice(bytes: bytes, fileName: fname, subFolder: 'UniPayReports');
        Get.snackbar('Downloaded', 'Saved to $path');
      } else {
        await FileUtils.downloadInWeb(bytes: bytes, fileName: fname, mimeType: 'application/pdf');
        Get.snackbar('Downloaded', fname);
      }
    } catch (e) {
      Get.snackbar('Download Failed', e.toString());
    } finally {
      loading.value = false;
    }
  }
}

