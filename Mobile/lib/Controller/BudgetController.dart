import 'package:get/get.dart';
import 'package:mobile/Api/apimodel.dart';
import 'package:mobile/Api/apis.dart';
import 'package:mobile/Auth/auth.dart';

class BudgetController extends GetxController{
  final api = Get.find<ApiService>();
  final authController = Get.find<AuthController>();

  final budgetSummary = <BudgetSummaryItem>[].obs;
  final isLoading = false.obs;
  final lastError = "".obs; 
  final lastOk = "".obs;

  Future<void> getSummary() async {
    lastOk.value = "";
    lastError.value = "";
    try {
      isLoading.value = true;
      final budgetList = await api.budgetSummary(authController.user.value!.userId);
      budgetSummary.assignAll(budgetList);
      lastOk.value = "Successfully retrieve summary.";
      lastError.value = "";
    } catch (ex) {
      lastError.value = ex.toString();
    } finally{
      Future.microtask(() => isLoading.value = false);
    }
  }

  Future<void> createBudget(Budget b) async {
    lastOk.value = "";
    lastError.value = "";
    try {
      isLoading.value = true;
      await api.createBudget(b);
      final newBudgetSummary = await api.budgetSummary(authController.user.value!.userId);
      budgetSummary.assignAll(newBudgetSummary);
      lastOk.value = "Successfully create budget.";
      lastError.value = "";
    } catch (ex) {
      lastError.value = ex.toString();
    } finally {
      Future.microtask(() => isLoading.value = false);
    }
  }
}