import 'package:get/get.dart';
import 'package:mobile/Api/apimodel.dart' as api_model;
import 'package:mobile/Api/apis.dart';
import 'package:mobile/Auth/authController.dart';
import 'package:mobile/Component/TransactionCard.dart' as ui;
import 'package:mobile/Controller/TransactionModelConverter.dart';

class TransactionController extends GetxController {
  final api = Get.find<ApiService>();

  final transactions = <ui.TransactionModel>[].obs;
  final isLoading = false.obs;
  final lastError = "".obs;
  final lastOk = "".obs;

  Future<ui.TransactionModel> create({
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
    return convertedData;
  }

  Future<ui.TransactionModel> get(String id) async {
    final data = await api.getTransaction(id);
    return data.toUI();
  }

  Future<List<ui.TransactionModel>> getAll() async {
    final authController = Get.find<AuthController>();
    final userId = authController.user.value?.userId;
    // TODO: Get the ids from database.
    const merchantId = "";
    const bankId = "dc040287-351f-4073-a1c1-55c4883afb1f";
    const walletId = "bf63a534-a79c-4250-87ba-4cd4fee8f10a";

    final data = await api.listTransactions(userId, merchantId, bankId, walletId);
    final convertedData = data.map((item) => item.toUI()).toList();
    transactions.assignAll(convertedData);
    return convertedData;
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
