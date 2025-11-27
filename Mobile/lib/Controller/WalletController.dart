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

  Future<void> reloadWallet({
    required String walletId,
    required double amount,
    required String providerId,
    required String externalSourceId,
  }) async {
    isLoading.value = true;
    lastError.value = '';
    lastOk.value = '';

    try {
      await api.reload(
        walletId: walletId,
        amount: amount,
        providerId: providerId,
        externalSourceId: externalSourceId,
      );
      lastOk.value = 'Wallet reloaded';
      await get(walletId);
    } catch (ex) {
      lastError.value = ex.toString();
    } finally{
      isLoading.value = false;
    }
  }
}
