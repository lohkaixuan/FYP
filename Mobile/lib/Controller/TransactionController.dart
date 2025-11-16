import 'package:get/get.dart';
import 'package:mobile/Api/apimodel.dart';
import 'package:mobile/Api/apis.dart';
import 'package:mobile/Auth/auth.dart';
import 'package:mobile/Component/TransactionCard.dart' as ui;
import 'package:mobile/Controller/RoleController.dart';
import 'package:mobile/Controller/TransactionModelConverter.dart';

class TransactionController extends GetxController {
  final api = Get.find<ApiService>();

  final transactions = <ui.TransactionModel>[].obs;
  final trnsGrpByType = <TransactionGroup>[].obs;
  final trnsGrpByCategory = <TransactionGroup>[].obs;
  final trnsByDebitCredit = <TransactionGroup>[].obs;
  final trnsByCategory = <TransactionGroup>[].obs;
  final transaction = Rxn<TransactionModel>();
  final currentFilter = RxnString();
  final isLoading = false.obs;
  final lastError = "".obs;
  final lastOk = "".obs;

  Future<void> create({
    required String type,
    required String from,
    required String to,
    required num amount,
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
    final convertedData = data.toUI();
    transactions.add(convertedData);
  }

  Future<void> get({required String id}) async {
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
      // TODO: Get the ids from database.
      const merchantId = null;
      const bankId = null;
      final walletId = roleController.walletId;

      final data = await api.listTransactions(userId, merchantId, bankId, walletId);

      final convertedData = (data as List<TransactionModel>).map((item) {
        return item.toUI();
      }).toList();
      transactions.assignAll(convertedData);
    } catch (ex) {
      lastError.value = ex.toString();
    } finally {
      isLoading.value = false;
    }
  }

  void updateFilter(String? filterType) async {
    currentFilter.value = filterType;
    if (filterType == 'debit' || filterType == 'credit') {
      await filterTransactions(type: filterType);
    } else if (filterType != null) {
      await filterTransactions(category: filterType);
    } else {
      await filterTransactions();
    }
  }

  Future<void> filterTransactions(
      {String? type,
      String? category,
      bool groupByType = false,
      bool groupByCategory = false}) async {
    try {
      isLoading.value = true;
      final authController = Get.find<AuthController>();
      final roleController = Get.find<RoleController>();
      final userId = authController.user.value?.userId;
      // TODO: Get the ids from database.
      const merchantId = null;
      const bankId = null;
      final walletId = roleController.walletId;

      // Filter by type or category will get count.
      final data = await api.listTransactions(userId, merchantId, bankId,
          walletId, type, category, groupByType, groupByCategory);

      if (type != null || category != null || groupByType || groupByCategory) {
        final rows = data as List<TransactionGroup>;
        if (type != null) {
          trnsByDebitCredit.assignAll(rows);
        } else if (category != null) {
          trnsByCategory.assignAll(rows);
        } else if (groupByType) {
          trnsGrpByType.assignAll(rows);
        } else if (groupByCategory) {
          trnsGrpByCategory.assignAll(rows);
        }
      } else {
        final models = data as List<TransactionModel>;
        final convertedData = models
            .map((item) {
              return item.toUI();
            })
            .toList();
        transactions.assignAll(convertedData);
      }
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

  Future<CategorizeOutput> categorize(CategorizeInput input) async {
    final data = await api.categorize(input);
    return data;
  }
}
