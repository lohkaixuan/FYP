import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:mobile/Api/apimodel.dart';
import 'package:mobile/Api/apis.dart';
import 'package:mobile/Controller/auth.dart';
import 'package:mobile/Controller/TransactionModelConverter.dart';
import 'package:mobile/QR/QRUtlis.dart';
import 'package:mobile/Utils/api_dialogs.dart';

import '../Component/TransactionCard.dart' as ui;
import 'RoleController.dart';

class TransactionController extends GetxController {
      final api = Get.find<ApiService>();

<<<<<<< HEAD
  
  final rawTransactions = <TransactionModel>[].obs;

  
  final transactions = <ui.TransactionModel>[].obs;

  
  // final trnsGrpByType = <TransactionGroup>[].obs;
  // final trnsGrpByCategory = <TransactionGroup>[].obs;
  // final trnsByDebitCredit = <TransactionGroup>[].obs;
  // final trnsByCategory = <TransactionGroup>[].obs;

=======
      // Raw transactions from API
      final rawTransactions = <TransactionModel>[].obs;

  // UI-mapped transactions
  final transactions = <ui.TransactionModel>[].obs;

>>>>>>> 4cec63ed80e44df6bfced19a3befc5329bd1b3f1
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
    final tx = await api.createTransaction(
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

<<<<<<< HEAD
    
    rawTransactions.add(data);
    transactions.add(data.toUI());
=======
    rawTransactions.add(tx);
    transactions.add(tx.toUI());

        final alertMap = api.lastBudgetAlert as Map<String, dynamic>?;
    if (alertMap != null && alertMap['exceeded'] == true) {
      final msg = (alertMap['message'] as String?)?.toString() ?? 'Budget exceeded.';
      ApiDialogs.showError(msg, fallbackTitle: 'Budget Warning');
    }
>>>>>>> 4cec63ed80e44df6bfced19a3befc5329bd1b3f1
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

<<<<<<< HEAD
    try {
      await api.transfer(
        fromWalletId: fromWalletId,
        toWalletId: toWalletId,
        amount: amount,
        detail: detail,
        categoryCsv: categoryCsv,
      );

      
=======
>>>>>>> 4cec63ed80e44df6bfced19a3befc5329bd1b3f1
      try {
        await api.transfer(
          fromWalletId: fromWalletId,
          toWalletId: toWalletId,
          amount: amount,
          detail: detail,
          categoryCsv: categoryCsv,
        );

        // Refresh transactions after transfer
        try {
          await getAll();
          await Get.find<AuthController>().refreshMe();
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
      Future.microtask(() => isLoading.value = false);
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
      Future.microtask(() => isLoading.value = false);
    }
  }

  Future<void> getAll() async {
    try {
      isLoading.value = true;
      final authController = Get.find<AuthController>();
      final roleController = Get.find<RoleController>();
      final userId =
          roleController.isUser ? authController.user.value?.userId : null;
      const merchantId = null;
      const bankId = null;
      final walletId = roleController.isUser
          ? roleController.userWalletId.value
          : roleController.merchantWalletId.value;

      final now = DateTime.now();

      final data = await api.listTransactions(
        userId,
        merchantId,
        bankId,
        walletId,
        null,
        null,
        
      );

      if (data is List<TransactionModel>) {
<<<<<<< HEAD
        
        rawTransactions.assignAll(data);

        
=======
        rawTransactions.assignAll(data);
>>>>>>> 4cec63ed80e44df6bfced19a3befc5329bd1b3f1
        final convertedData = data.map((item) => item.toUI()).toList();
        transactions.assignAll(convertedData);
      }
      // Always refresh user to sync wallet balances (user + merchant)
      await authController.refreshMe();
    } catch (ex, stack) {
      lastError.value = stack.toString();
    } finally {
      Future.microtask(() => isLoading.value = false);
    }
  }

<<<<<<< HEAD
  
=======
>>>>>>> 4cec63ed80e44df6bfced19a3befc5329bd1b3f1
  void updateFilter(String? filterType) async {
    currentFilter.value = filterType;

    if (filterType == 'debit' || filterType == 'credit') {
      await filterTransactions(type: filterType);
    } else if (filterType != null && filterType.isNotEmpty) {
      await filterTransactions(category: filterType);
    } else {
<<<<<<< HEAD
      await filterTransactions(); 
    }
  }

  
=======
      await filterTransactions();
    }
  }

>>>>>>> 4cec63ed80e44df6bfced19a3befc5329bd1b3f1
  Future<void> filterTransactions({
    String? type,
    String? category,
  }) async {
    try {
      isLoading.value = true;

<<<<<<< HEAD
      
=======
>>>>>>> 4cec63ed80e44df6bfced19a3befc5329bd1b3f1
      if (rawTransactions.isEmpty) {
        await getAll();
      }

      final activeWalletId = Get.find<RoleController>().activeWalletId;
<<<<<<< HEAD
      
      var filtered = List<TransactionModel>.from(rawTransactions);

      
=======
      var filtered = List<TransactionModel>.from(rawTransactions);

>>>>>>> 4cec63ed80e44df6bfced19a3befc5329bd1b3f1
      if (type != null && type.isNotEmpty) {
        final lower = type.toLowerCase();
        filtered = filtered.where((tx) {
          final isDebit = tx.from == activeWalletId.value;
          final isCredit = tx.to == activeWalletId.value;
          if (lower == 'debit') {
            return isDebit;
          } else if (lower == 'credit') {
            return isCredit;
          }
          return false;
        }).toList();
      }

<<<<<<< HEAD
      
=======
>>>>>>> 4cec63ed80e44df6bfced19a3befc5329bd1b3f1
      if (category != null && category.isNotEmpty) {
        final lower = category.toLowerCase();
        filtered =
            filtered.where((tx) => (tx.category ?? '').toLowerCase() == lower).toList();
      }

<<<<<<< HEAD
      
=======
>>>>>>> 4cec63ed80e44df6bfced19a3befc5329bd1b3f1
      final converted = filtered.map((tx) => tx.toUI()).toList();
      transactions.assignAll(converted);
    } catch (ex) {
      lastError.value = ex.toString();
    } finally {
      Future.microtask(() => isLoading.value = false);
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

  Future<WalletContact?> lookupContact(
    String query, {
    String? walletId,
  }) async {
    final normalized = query.trim();
    final dto = await api.lookupWalletContact(
      search: normalized.isEmpty ? null : normalized,
      walletId: walletId,
    );
    if (dto == null) return null;
    return WalletContact.fromLookupResult(dto);
  }
}
