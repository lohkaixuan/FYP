import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:mobile/Api/apimodel.dart';
import 'package:mobile/Api/apimodel.dart' as api_model;
import 'package:mobile/Api/apis.dart';
import 'package:mobile/Auth/auth.dart';
import 'package:mobile/Component/TransactionCard.dart' as ui;
import 'package:mobile/Controller/RoleController.dart';
import 'package:mobile/Controller/TransactionModelConverter.dart';

import 'package:dio/dio.dart';

class TransactionController extends GetxController {
  final api = Get.find<ApiService>();

  final rawTransactions = <TransactionModel>[].obs;
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
    final convertedData = data.toUI();
    transactions.add(convertedData);
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

    // 👉 打印一下传给 backend 的参数，方便你在 console 看
    debugPrint(
      '[walletTransfer] from=$fromWalletId to=$toWalletId amount=$amount '
      'detail=$detail categoryCsv=$categoryCsv',
    );

    try {
      // 调用 apis.dart 里的 transfer()  -> POST /api/wallet/transfer
      await api.transfer(
        fromWalletId: fromWalletId,
        toWalletId: toWalletId,
        amount: amount,
        detail: detail,
        categoryCsv: categoryCsv,
      );

      // 成功后尝试刷新交易列表（失败也没关系）
      try {
        await getAll();
      } catch (_) {
        // 刷新失败不致命，忽略
      }
    } on DioException catch (e) {
      //  重点：把后端返回的 body 打出来
      final status = e.response?.statusCode;
      final data = e.response?.data;

      lastError.value =
          'HTTP $status: ${data ?? e.message ?? 'Unknown Dio error'}';

      debugPrint('[walletTransfer] DioException: $lastError');
      rethrow;
    } catch (e) {
      // 其他非 HTTP 异常
      lastError.value = e.toString();
      debugPrint('[walletTransfer] Other error: $lastError');
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
      // TODO: Get the ids from database.
      const merchantId = null;
      const bankId = null;
      final walletId = roleController.walletId;

      final data = await api.listTransactions(userId, merchantId, bankId, walletId);

      debugPrint('--- Executing getAll() ---');

      if (data is List<TransactionModel>){
        final convertedData = data.map((item) {
          return item.toUI();
        }).toList();
        transactions.assignAll(convertedData);
      }
      
    } catch (ex, stack) {
      debugPrint('--- ERROR IN getAll() ---');
      debugPrint('Exception: $ex');
      debugPrint('Stacktrace: $stack');
      lastError.value = stack.toString();
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

      debugPrint('--- Executing filterTransactions() ---');

      if (type != null || category != null || groupByType || groupByCategory) {
        if (data is List<TransactionGroup>) {
          final rows = data;
          if (type != null) {
            trnsByDebitCredit.assignAll(rows);
          } else if (category != null) {
            trnsByCategory.assignAll(rows);
          } else if (groupByType) {
            trnsGrpByType.assignAll(rows);
          } else if (groupByCategory) {
            trnsGrpByCategory.assignAll(rows);
          }
        }
      } else {
        if (data is List<TransactionModel>){
          final convertedData = data
            .map((item) {
              return item.toUI();
            })
            .toList();
          transactions.assignAll(convertedData);
        }
      }
    } catch (ex, stack) {
      debugPrint('--- ERROR IN filterTransactions() ---');
      debugPrint('Exception: $ex');
      debugPrint('Stacktrace: $stack');
      lastError.value = stack.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> filterTransactions({
    String? type,
    String? category,
    bool groupByType = false,
    bool groupByCategory = false,
  }) async {
    try {
      if (rawTransactions.isEmpty) {
        await getAll();
      }

      final source = List<TransactionModel>.from(rawTransactions);

      if (groupByType) {
        trnsGrpByType.assignAll(_groupByType(source));
      }

      if (groupByCategory) {
        trnsGrpByCategory.assignAll(_groupByCategory(source));
      }

      if (type != null && type.isNotEmpty) {
        final filtered = source
            .where(
              (tx) => tx.type.toLowerCase() == type.toLowerCase(),
            )
            .toList();
        trnsByDebitCredit.assignAll(_wrapSingleGroup(type, filtered));
      } else if (!groupByType) {
        trnsByDebitCredit.clear();
      }

      if (category != null && category.isNotEmpty) {
        final filtered = source
            .where((tx) =>
                (tx.category ?? '').toLowerCase() == category.toLowerCase())
            .toList();
        trnsByCategory.assignAll(_wrapSingleGroup(category, filtered));
      } else if (!groupByCategory) {
        trnsByCategory.clear();
      }
    } catch (ex) {
      lastError.value = ex.toString();
    }
  }

  List<TransactionGroup> _groupByType(List<TransactionModel> source) {
    final map = <String, List<TransactionModel>>{};
    for (final tx in source) {
      final key = tx.type.toLowerCase();
      map.putIfAbsent(key, () => []).add(tx);
    }

    return map.entries.map(
      (entry) {
        final txs = entry.value;
        final label = txs.first.type;
        return TransactionGroup(
          type: label,
          totalAmount: _sumAmounts(txs),
          transactions: txs,
        );
      },
    ).toList();
  }

  List<TransactionGroup> _groupByCategory(List<TransactionModel> source) {
    final map = <String, List<TransactionModel>>{};
    for (final tx in source) {
      final cat = (tx.category ?? '').trim();
      if (cat.isEmpty) {
        continue;
      }
      final key = cat.toLowerCase();
      map.putIfAbsent(key, () => []).add(tx);
    }

    return map.entries.map((entry) {
      final txs = entry.value;
      final label = txs.first.category ?? entry.key;
      return TransactionGroup(
        type: label,
        totalAmount: _sumAmounts(txs),
        transactions: txs,
      );
    }).toList();
  }

  List<TransactionGroup> _wrapSingleGroup(
    String label,
    List<TransactionModel> transactions,
  ) {
    if (transactions.isEmpty) {
      return [];
    }

    return [
      TransactionGroup(
        type: label,
        totalAmount: _sumAmounts(transactions),
        transactions: transactions,
      )
    ];
  }

  double _sumAmounts(List<TransactionModel> txs) {
    return txs.fold<double>(
      0,
      (sum, tx) => sum + tx.amount.abs(),
    );
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

  // Future<api_model.CategorizeOutput> categorize(
  //     api_model.CategorizeInput input) async {
  //   final data = await api.categorize(input);
  //   return data;
  // }
}
