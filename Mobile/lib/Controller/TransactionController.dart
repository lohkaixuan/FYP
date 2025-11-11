import 'package:get/get.dart';
import 'package:mobile/Api/apimodel.dart' as api_model;
import 'package:mobile/Api/apis.dart';
import 'package:mobile/Auth/auth.dart';
import 'package:mobile/Component/TransactionCard.dart' as ui;
import 'package:mobile/Controller/RoleController.dart';
import 'package:mobile/Controller/TransactionModelConverter.dart';

class TransactionController extends GetxController {
  final api = Get.find<ApiService>();

  final transactions = <ui.TransactionModel>[].obs;
  final transaction = Rxn<api_model.TransactionModel>();
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
    String? detail, String? categoryCsv,
  }) async {
    isLoading.value = true;
  lastError.value = "";
  try {
    // 调用 apis.dart 里的 transfer()  -> POST /api/wallet/transfer
    await api.transfer(
      fromWalletId: fromWalletId,
      toWalletId: toWalletId,
      amount: amount,
      detail: detail,
      categoryCsv: categoryCsv,
    );
    try {
      await getAll();
    } catch (_) {
      // 刷新失败不致命，忽略
    }
  } catch (e) {
    lastError.value = e.toString();
    rethrow;
  } finally {
    isLoading.value = false;
  }
  }

  Future<void> get(String id) async {
    try{
      isLoading.value = true;
      final data = await api.getTransaction(id);
      transaction.value = data;
    } catch(ex){
      lastError.value = ex.toString();
    } finally{
      isLoading.value = false;
    }
  }

  Future<void> getAll() async {
    try{
      isLoading.value = true;
      final authController = Get.find<AuthController>();
      final roleController = Get.find<RoleController>();
      final userId = authController.user.value?.userId;
      // TODO: Get the ids from database.
      const merchantId = null;
      const bankId = null;
      final walletId = roleController.walletId;

      final data = await api.listTransactions(userId, merchantId, bankId, walletId);
      
      final convertedData = data.map((item) => item.toUI()).toList();
      transactions.assignAll(convertedData);
    }catch(ex){
      lastError.value = ex.toString();
    }finally{
      isLoading.value = false;
    }
  }

  Future<void> setFinalCategory({
    required String transactionId,
    String? category,
  }) async {
    try{
      await api.setFinalCategory(txId: transactionId, categoryCsv: category);
      lastOk.value = "Successfully updated final category of transaction ($transactionId)!";
    }catch(ex){
      lastError.value = ex.toString();
    }    
  }

  Future<api_model.CategorizeOutput> categorize(api_model.CategorizeInput input) async {
    final data = await api.categorize(input);
    return data;
  }
}
