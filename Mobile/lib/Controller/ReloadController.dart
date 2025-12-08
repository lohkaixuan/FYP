import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:mobile/Api/apimodel.dart';
import 'package:mobile/Api/apis.dart';
import 'package:mobile/Controller/RoleController.dart';
import 'package:mobile/Transfer/transfer.dart'; 

class ReloadController extends GetxController {
  final api = Get.find<ApiService>();
  final roleC = Get.find<RoleController>();

  final amountCtrl = TextEditingController(text: "20.00");

  final providers = <ProviderModel>[].obs;
  final selectedProvider = Rx<ProviderModel?>(null);

  final CardFieldInputDetails? cardDetails = null;
  var card = Rx<CardFieldInputDetails?>(null);

  var loadingProviders = false.obs;
  var stripeReady = false.obs;
  var publishableKey = "".obs;

  var processing = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadProviders();
  }

  Future<void> loadProviders() async {
    loadingProviders.value = true;

    try {
      final all = await api.listThirdParties();
      final enabled = all.where((p) => p.enabled).toList();

      providers.assignAll(enabled);

      if (enabled.isNotEmpty) {
        selectedProvider.value = enabled.first;
        fetchProviderKey(enabled.first.providerId);
      }
    } catch (e) {
      Get.snackbar("Provider Error", e.toString(),
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      loadingProviders.value = false;
    }
  }

  Future<void> fetchProviderKey(String providerId) async {
    stripeReady.value = false;

    try {
      final detail = await api.getThirdParty(providerId);
      print("Fetched provider public  detail : $detail + id: $providerId + key: ${detail.publicKey}+ enabled: ${detail.enabled}+ name: ${detail.name}+ desc: }+");

      final key = (detail.publicKey ?? ""); // 建议加 trim
      print("Fetched provider public  key: $key");

      if (key == null || key.isEmpty) {
        throw "Provider publishable key missing";
      }

      await initStripe(key);
    } catch (e) {
      Get.snackbar("Stripe", "Failed: $e",
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  Future<void> initStripe(String key) async {
    try {
      Stripe.publishableKey = key;
      await Stripe.instance.applySettings();

      publishableKey.value = key;
      stripeReady.value = true;
    } catch (e) {
      stripeReady.value = false;
      Get.snackbar("Stripe", "Init failed: $e",
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  String? validate() {
    final amount = double.tryParse(amountCtrl.text.trim());
    if (amount == null || amount <= 0) return "Invalid amount";

    if (selectedProvider.value == null) return "Select provider";

    if (!stripeReady.value) return "Stripe key not loaded";

    if (card.value == null || !(card.value?.complete ?? false)) {
      return "Card incomplete";
    }

    if (roleC.walletId.isEmpty) return "No wallet found";

    return null;
  }

  /// MAIN FUNCTION: Start Stripe Reload
  Future<void> startReload() async {
  final err = validate();
  if (err != null) {
    Get.snackbar(
      "Error",
      err,
      backgroundColor: Colors.orange,
      colorText: Colors.white,
    );
    return;
  }

  // 额外防呆：providerId / publishableKey / card 都再检查一遍
  final provider = selectedProvider.value;
  final providerId = provider?.providerId;
  final keyNow = Stripe.publishableKey;
  final cardDetails = card.value;

  print("🚀 startReload: providerId=$providerId");
  print("🚀 startReload: Stripe.publishableKey=$keyNow");
  print("🚀 startReload: card.complete=${cardDetails?.complete}");

  if (providerId == null || providerId.isEmpty) {
    Get.snackbar("Error", "No Stripe provider selected",
        backgroundColor: Colors.orange, colorText: Colors.white);
    return;
  }

  if (keyNow.isEmpty) {
    Get.snackbar("Stripe Error", "Stripe is not initialised (no key)",
        backgroundColor: Colors.red, colorText: Colors.white);
    return;
  }

  if (cardDetails == null || !cardDetails.complete) {
    Get.snackbar("Stripe Error", "Card details are incomplete",
        backgroundColor: Colors.red, colorText: Colors.white);
    return;
  }

  processing.value = true;

  try {
    // 这里顺便把邮编 / 国家等 billing 信息也带进去，避免插件内部访问 null
   final paymentMethod = await Stripe.instance.createPaymentMethod(
  params: const PaymentMethodParams.card(
    paymentMethodData: PaymentMethodData(),
  ),
);



    print("✅ paymentMethod.id = ${paymentMethod.id}");

    final tx = TransferDetails(
  type: "topup",
  fromAccountId: roleC.walletId,       // 你要记钱是谁的钱
  toAccountId: roleC.walletId,         // 充值目标钱包
  amount: double.parse(amountCtrl.text),
  category: "reload",
  detail: "Stripe reload",
  item: "Stripe",
  providerId: providerId,
  externalSourceId: paymentMethod.id,
);

// 这里把整个对象当 arguments 传过去
Get.toNamed("/security-code", arguments: tx);
  } catch (e, st) {
    print("🔥 Stripe createPaymentMethod error: $e\n$st");
    Get.snackbar("Stripe Error", e.toString(),
        backgroundColor: Colors.red, colorText: Colors.white);
  } finally {
    processing.value = false;
  }
}


}
