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

  
  final rawTransactions = <TransactionModel>[].obs;

  
  final transactions = <ui.TransactionModel>[].obs;

  
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
      final userId = roleController.isUser ? authController.user.value?.userId : null;
      const merchantId = null;
      const bankId = null;
      final walletId = roleController.isUser
        ? roleController.userWalletId.value
        : roleController.merchantWalletId.value;

      final data = await api.listTransactions(
        userId,
        merchantId,
        bankId,
        walletId,
      );

      if (data is List<TransactionModel>) {
        
        rawTransactions.assignAll(data);

        
        final convertedData = data.map((item) => item.toUI()).toList();
        transactions.assignAll(convertedData);
      }
    } catch (ex, stack) {
      lastError.value = stack.toString();
    } finally {
      Future.microtask(() => isLoading.value = false);
    }
  }

  
  void updateFilter(String? filterType) async {
    currentFilter.value = filterType;

    if (filterType == 'debit' || filterType == 'credit') {
      await filterTransactions(type: filterType);
    } else if (filterType != null && filterType.isNotEmpty) {
      await filterTransactions(category: filterType);
    } else {
      await filterTransactions(); 
    }
  }

  
  Future<void> filterTransactions({
    String? type,
    String? category,
  }) async {
    try {
      isLoading.value = true;

      
      if (rawTransactions.isEmpty) {
        await getAll();
      }

      final activeWalletId = Get.find<RoleController>().activeWalletId;
      
      var filtered = List<TransactionModel>.from(rawTransactions);

      
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

      
      if (category != null && category.isNotEmpty) {
        final lower = category.toLowerCase();
        filtered = filtered
            .where(
              (tx) => (tx.category ?? '').toLowerCase() == lower,
            )
            .toList();
      }

      
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

  Future<WalletContact?> lookupContact(String query) async {
    final dto = await api.lookupWalletContact(search: query);
    if (dto == null) return null;
    return WalletContact.fromLookupResult(dto);
  }
}
