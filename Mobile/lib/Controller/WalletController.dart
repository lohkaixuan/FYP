import 'dart:convert';

import 'package:get/get.dart';
import 'package:mobile/Api/apimodel.dart';
import 'package:mobile/Api/apis.dart';

class WalletController extends GetxController{
  final api = Get.find<ApiService>();

  final wallet = Rxn<Wallet>();
  final isLoading = false.obs;
  final lastError = "".obs; 
  final lastOk = "".obs;

  Future<void> get(String id) async {
    try{
      isLoading.value = true;
      final data = await api.getWallet(id);
      wallet.value = data;
    } catch(ex){
      lastError.value = ex.toString();
    } finally{
      isLoading.value = false;
    }
  }

  Future<void> topUpWallet({
    required String walletId,
    required double amount,
    required String fromBankAccountId,
  }) async {
    isLoading.value = true;
    lastError.value = '';

    try {
      final Wallet updatedWallet = await api.topUp(
        walletId: walletId,
        amount: amount,
        fromBankAccountId: fromBankAccountId,
      );
      wallet.value = updatedWallet;
    } catch (ex) {
      lastError.value = ex.toString();
    } finally{
      isLoading.value = false;
    }
  }
}