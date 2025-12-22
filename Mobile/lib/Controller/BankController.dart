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

  // ✅ Prevent duplicate calls that can "jam" the page
  bool _fetching = false;

  Future<void> getBankAccounts({bool forceRefreshMeIfNeeded = true}) async {
    if (_fetching) return;
    _fetching = true;

    try {
      isLoading.value = true;
      lastError.value = '';
      lastOk.value = false;

      final auth = Get.find<AuthController>();

      // 1) get userId
      var userId = auth.user.value?.userId ?? '';

      // 2) if empty, try refreshMe once (token bypass flow)
      if (userId.isEmpty && forceRefreshMeIfNeeded) {
        await auth.refreshMe();
        userId = auth.user.value?.userId ?? '';
      }

      if (userId.isEmpty) {
        lastError.value = 'No user id found (not logged in yet)';
        return;
      }

      // 3) load accounts
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
