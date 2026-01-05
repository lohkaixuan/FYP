// ==================================================
// Program Name   : BudgetController.dart
// Purpose        : Controller for budgeting actions
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
import 'package:mobile/Controller/RoleController.dart';
import 'package:mobile/Controller/TransactionController.dart';

class BudgetController extends GetxController{
  final api = Get.find<ApiService>();
  final authController = Get.find<AuthController>();
  final roleController = Get.find<RoleController>();
  final transactionController = Get.find<TransactionController>();
  final budgetSummary = <BudgetSummaryItem>[].obs;
  final isLoading = false.obs;
  final lastError = "".obs; 
  final lastOk = "".obs;

  bool _isInCurrentMonth(DateTime? ts) {
    if (ts == null) return false;
    final local = ts.toLocal();
    final now = DateTime.now();
    return local.year == now.year && local.month == now.month;
  }

  BudgetSummaryItem _withComputedSpend(BudgetSummaryItem item) {
    final walletId = roleController.activeWalletId.value;
    double spent = 0;
    for (final tx in transactionController.rawTransactions) {
      if (!_isInCurrentMonth(tx.timestamp)) continue;
      final isDebit = tx.from == walletId;
      if (!isDebit) continue;
      final cat = (tx.category ?? '').trim().toLowerCase();
      if (cat == item.category.trim().toLowerCase()) {
        spent += tx.amount.abs().toDouble();
      }
    }
    final remainingRaw = item.limitAmount - spent;
    final remaining = remainingRaw < 0 ? 0.0 : remainingRaw;
    final percent = item.limitAmount == 0
        ? 0.0
        : (spent / item.limitAmount) * 100.0;
    return BudgetSummaryItem(
      category: item.category,
      limitAmount: item.limitAmount,
      spent: spent,
      remaining: remaining,
      percent: percent,
    );
  }

  Future<void> getSummary() async {
    lastOk.value = "";
    lastError.value = "";
    try {
      isLoading.value = true;
      final budgetList = await api.budgetSummary();
      final withSpend = budgetList.map(_withComputedSpend).toList();
      budgetSummary.assignAll(withSpend);
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
      final newBudgetSummary = await api.budgetSummary();
      final withSpend = newBudgetSummary.map(_withComputedSpend).toList();
      budgetSummary.assignAll(withSpend);
      lastOk.value = "Successfully create budget.";
      lastError.value = "";
    } catch (ex) {
      lastError.value = ex.toString();
    } finally {
      Future.microtask(() => isLoading.value = false);
    }
  }
}
