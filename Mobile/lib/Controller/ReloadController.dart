import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:mobile/Api/apimodel.dart';
import 'package:mobile/Api/apis.dart';
import 'package:mobile/Controller/RoleController.dart';

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
      Get.snackbar("Error", err,
          backgroundColor: Colors.orange, colorText: Colors.white);
      return;
    }

    processing.value = true;
    try {
      // 1) Create Payment Method
      final paymentMethod = await Stripe.instance.createPaymentMethod(
        params: const PaymentMethodParams.card(
          paymentMethodData: PaymentMethodData(),
        ),
      );

      // 2) Push to security screen to confirm + call backend
      Get.toNamed("/security-code", arguments: {
        "type": "topup",
        "providerId": selectedProvider.value!.providerId,
        "walletId": roleC.walletId,
        "amount": double.parse(amountCtrl.text),
        "externalSourceId": paymentMethod.id,
      });
    } catch (e) {
      Get.snackbar("Stripe Error", e.toString(),
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      processing.value = false;
    }
  }
}
