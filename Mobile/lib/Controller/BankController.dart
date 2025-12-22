import 'package:get/get.dart';
import 'package:mobile/Api/apimodel.dart';
import 'package:mobile/Api/apis.dart';
import 'package:mobile/Controller/auth.dart';


class BankController extends GetxController{
  final api = Get.find<ApiService>();

  final accounts = <BankAccount>[].obs;
  final isLoading = false.obs;
  final lastError = "".obs; 
  final lastOk = "".obs;

  Future<void> getBankAccounts() async {
    try {
      isLoading.value = true;
      final authController = Get.find<AuthController>();
      final accountList = await api.listBankAccounts(authController.user.value!.userId);
      accounts.assignAll(accountList);
    } catch (ex) {
      lastError.value = ex.toString();
    } finally{
      Future.microtask(() => isLoading.value = false);
    }
  }
}
