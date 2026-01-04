// ==================================================
// Program Name   : WalletController.dart
// Purpose        : Controller managing wallet state and API calls
// Developer      : Mr. Loh Kai Xuan 
// Student ID     : TP074510 
// Course         : Bachelor of Software Engineering (Hons) 
// Created Date   : 15 November 2025
// Last Modified  : 4 January 2026 
// ==================================================
import 'dart:convert';
import 'package:get/get.dart';
import 'package:mobile/Api/apimodel.dart';
import 'package:mobile/Api/apis.dart';
import 'package:mobile/Controller/auth.dart';

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
      Future.microtask(() => isLoading.value = false);
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
      print("[RELOAD] walletId=$walletId providerId=$providerId amount=$amount");

      await api.reload(
        walletId: walletId,
        amount: amount,
        providerId: providerId,
        externalSourceId: externalSourceId,
      );
      lastOk.value = 'Wallet reloaded';
      await get(walletId);
      // Refresh auth/user to sync cached balances (user + merchant)
      await Get.find<AuthController>().refreshMe();
    } catch (ex) {
      lastError.value = ex.toString();
    } finally{
      Future.microtask(() => isLoading.value = false);
    }
  }
}
