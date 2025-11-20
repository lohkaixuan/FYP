import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:mobile/Api/apimodel.dart';
import 'package:mobile/Api/apis.dart';
import 'package:mobile/Auth/auth.dart';
import 'package:mobile/Controller/TransactionModelConverter.dart';
import 'package:mobile/QR/QRUtlis.dart';

import '../Component/TransactionCard.dart' as ui;
import 'RoleController.dart';

class TransactionController extends GetxController {
  final api = Get.find<ApiService>();

  // 原始后端模型（给过滤用）
  final rawTransactions = <TransactionModel>[].obs;

  // UI 用模型（给页面显示用）
  final transactions = <ui.TransactionModel>[].obs;

  // 其他 groupBy 的 RxList 先不要，用不到就删掉/注释掉
  // final trnsGrpByType = <TransactionGroup>[].obs;
  // final trnsGrpByCategory = <TransactionGroup>[].obs;
  // final trnsByDebitCredit = <TransactionGroup>[].obs;
  // final trnsByCategory = <TransactionGroup>[].obs;

  final transaction = Rxn<TransactionModel>();
  final currentFilter = RxnString();
  final isLoading = false.obs;
  final lastError = "".obs;
  final lastOk = "".obs;

  Future<void> create({
    required String type,
    required String from,
    required String to,
    required double amount,
    DateTime? timestamp,
    String? item,
    String? detail,
    String? mcc,
    String? paymentMethod,
    String? overrideCategoryCsv,
  }) async {
    final data = await api.createTransaction(
      type: type,
      from: from,
      to: to,
      amount: amount,
      timestamp: timestamp,
      item: item,
      detail: detail,
      mcc: mcc,
      paymentMethod: paymentMethod,
      overrideCategoryCsv: overrideCategoryCsv,
    );

    // 同步更新 raw + ui
    rawTransactions.add(data);
    transactions.add(data.toUI());
  }

  Future<void> walletTransfer({
    required String fromWalletId,
    required String toWalletId,
    required double amount,
    DateTime? timestamp,
    String? item,
    String? detail,
    String? categoryCsv,
  }) async {
    isLoading.value = true;
    lastError.value = "";

    try {
      await api.transfer(
        fromWalletId: fromWalletId,
        toWalletId: toWalletId,
        amount: amount,
        detail: detail,
        categoryCsv: categoryCsv,
      );

      // 成功后刷新列表 -> 会更新 rawTransactions + transactions
      try {
        await getAll();
      } catch (_) {}
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final data = e.response?.data;

      lastError.value =
          'HTTP $status: ${data ?? e.message ?? 'Unknown Dio error'}';

      rethrow;
    } catch (e) {
      lastError.value = e.toString();
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> get(String id) async {
    try {
      isLoading.value = true;
      final data = await api.getTransaction(id);
      transaction.value = data;
    } catch (ex) {
      lastError.value = ex.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> getAll() async {
    try {
      isLoading.value = true;
      final authController = Get.find<AuthController>();
      final roleController = Get.find<RoleController>();
      final userId = authController.user.value?.userId;
      const merchantId = null;
      const bankId = null;
      final walletId = roleController.walletId;


      final data = await api.listTransactions(
        userId,
        merchantId,
        bankId,
        walletId,
      );

      if (data is List<TransactionModel>) {
        // ✅ 把后端回来的全部放进 rawTransactions.obx
        rawTransactions.assignAll(data);

        // ✅ 同时转成 UI model 放进 transactions.obx
        final convertedData = data.map((item) => item.toUI()).toList();
        transactions.assignAll(convertedData);
      }
    } catch (ex, stack) {
    
      lastError.value = stack.toString();
    } finally {
      isLoading.value = false;
    }
  }

  // 用来切换「全部 / debit / credit / 某个分类」
  void updateFilter(String? filterType) async {
    currentFilter.value = filterType;

    if (filterType == 'debit' || filterType == 'credit') {
      await filterTransactions(type: filterType);
    } else if (filterType != null && filterType.isNotEmpty) {
      await filterTransactions(category: filterType);
    } else {
      await filterTransactions(); // 无参数 = 显示全部
    }
  }

  // ✅ 简化版：只在本地 rawTransactions 上过滤，不再打 API
  Future<void> filterTransactions({
    String? type,
    String? category,
  }) async {
    try {
      isLoading.value = true;

      // 如果还没加载过，就先从后端拉一次
      if (rawTransactions.isEmpty) {
        await getAll();
      }

      // 以 rawTransactions 为数据源
      var filtered = List<TransactionModel>.from(rawTransactions);

      // 按 type 过滤：debit / credit / 其他
      if (type != null && type.isNotEmpty) {
        final lower = type.toLowerCase();
        filtered = filtered
            .where((tx) => tx.type.toLowerCase() == lower)
            .toList();
      }

      // 按 category 过滤：F&B, Shopping 等
      if (category != null && category.isNotEmpty) {
        final lower = category.toLowerCase();
        filtered = filtered
            .where(
              (tx) => (tx.category ?? '').toLowerCase() == lower,
            )
            .toList();
      }

      // 最终更新 UI 用的 list
      final converted = filtered.map((tx) => tx.toUI()).toList();
      transactions.assignAll(converted);
    } catch (ex) {
      lastError.value = ex.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> setFinalCategory({
    required String transactionId,
    String? category,
  }) async {
    try {
      await api.setFinalCategory(txId: transactionId, categoryCsv: category);
      lastOk.value =
          "Successfully updated final category of transaction ($transactionId)!";
    } catch (ex) {
      lastError.value = ex.toString();
    }
  }
  
  Future<WalletContact?> lookupContact(String query) async {
    final dto = await api.lookupWalletContact(search: query);
    if (dto == null) return null;
    return WalletContact.fromLookupResult(dto);
  }
}
