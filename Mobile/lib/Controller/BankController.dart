// ==================================================
// Program Name   : BankController.dart
// Purpose        : Controller for bank linking and account actions
// Developer      : Mr. Loh Kai Xuan 
// Student ID     : TP074510 
// Course         : Bachelor of Software Engineering (Hons) 
// Created Date   : 15 November 2025
// Last Modified  : 4 January 2026 
// ==================================================
import 'package:get/get.dart';
import 'package:mobile/Api/apimodel.dart';
import 'package:mobile/Api/apis.dart';
import 'package:mobile/Controller/auth.dart';

class BankController extends GetxController {
  final api = Get.find<ApiService>();
  final accounts = <BankAccount>[].obs;
  final isLoading = false.obs;
  final lastError = ''.obs;
  final lastOk = false.obs;

  bool _fetching = false;

  Future<void> getBankAccounts({bool forceRefreshMeIfNeeded = true}) async {
    if (_fetching) return;
    _fetching = true;

    try {
      isLoading.value = true;
      lastError.value = '';
      lastOk.value = false;

      final auth = Get.find<AuthController>();
      var userId = auth.user.value?.userId ?? '';
      if (userId.isEmpty && forceRefreshMeIfNeeded) {
        await auth.refreshMe();
        userId = auth.user.value?.userId ?? '';
      }

      if (userId.isEmpty) {
        lastError.value = 'No user id found (not logged in yet)';
        return;
      }
      final accountList = await api.listBankAccounts(userId);
      accounts.assignAll(accountList);

      lastOk.value = true;
    } catch (e) {
      lastError.value = e.toString();
      lastOk.value = false;
    } finally {
      _fetching = false;
      Future.microtask(() => isLoading.value = false);
    }
  }
}
