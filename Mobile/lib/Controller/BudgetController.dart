import 'package:get/get.dart';
import 'package:mobile/Api/apimodel.dart';
import 'package:mobile/Api/apis.dart';
import 'package:mobile/Auth/auth.dart';

class BudgetController extends GetxController{
  final api = Get.find<ApiService>();

  final budgetSummary = <BudgetSummaryItem>[].obs;
  final isLoading = false.obs;
  final lastError = "".obs; 
  final lastOk = "".obs;

  Future<void> getSummary() async {
    try {
      isLoading.value = true;
      final authController = Get.find<AuthController>();
      final budgetList = await api.budgetSummary(authController.user.value!.userId);
      budgetSummary.assignAll(budgetList);
    } catch (ex) {
      lastError.value = ex.toString();
    } finally{
      isLoading.value = false;
    }
  }
}