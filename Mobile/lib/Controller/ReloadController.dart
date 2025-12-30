import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe;
import 'package:mobile/Api/apimodel.dart';
import 'package:mobile/Api/apis.dart';
import 'package:mobile/Controller/RoleController.dart';
import 'package:mobile/Transfer/transfer.dart'; 
import 'package:mobile/Utils/api_dialogs.dart';

class ReloadController extends GetxController {
  final api = Get.find<ApiService>();
  final roleC = Get.find<RoleController>();

  final amountCtrl = TextEditingController(text: "20.00");

  final providers = <ProviderModel>[].obs;
  final selectedProvider = Rx<ProviderModel?>(null);

  final stripe.CardFieldInputDetails? cardDetails = null;
  var card = Rx<stripe.CardFieldInputDetails?>(null);

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
      ApiDialogs.showError(
        e,
        fallbackTitle: 'Provider Error',
      );
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
      ApiDialogs.showError(
        e,
        fallbackTitle: 'Stripe',
        fallbackMessage: 'Failed to fetch provider key.',
      );
    }
  }

  Future<void> initStripe(String key) async {
    try {
      stripe.Stripe.publishableKey = key;
      await stripe.Stripe.instance.applySettings();

      publishableKey.value = key;
      stripeReady.value = true;
    } catch (e) {
      stripeReady.value = false;
      ApiDialogs.showError(
        e,
        fallbackTitle: 'Stripe Init Failed',
      );
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
    ApiDialogs.showError(
      err,
      fallbackTitle: 'Validation Error',
    );
    return;
  }

  // 额外防呆：providerId / publishableKey / card 都再检查一遍
  final provider = selectedProvider.value;
  final providerId = provider?.providerId;
  final keyNow = stripe.Stripe.publishableKey;
  final cardDetails = card.value;

  print("🚀 startReload: providerId=$providerId");
  print("🚀 startReload: Stripe.publishableKey=$keyNow");
  print("🚀 startReload: card.complete=${cardDetails?.complete}");

  if (providerId == null || providerId.isEmpty) {
    ApiDialogs.showError(
      "No Stripe provider selected",
      fallbackTitle: 'Error',
    );
    return;
  }

  if (keyNow.isEmpty) {
    ApiDialogs.showError(
      "Stripe is not initialised (no key)",
      fallbackTitle: 'Stripe Error',
    );
    return;
  }

  if (cardDetails == null || !cardDetails.complete) {
    ApiDialogs.showError(
      "Card details are incomplete",
      fallbackTitle: 'Stripe Error',
    );
    return;
  }

  processing.value = true;

  try {
    // 这里顺便把邮编 / 国家等 billing 信息也带进去，避免插件内部访问 null
   final paymentMethod = await stripe.Stripe.instance.createPaymentMethod(
  params: const stripe.PaymentMethodParams.card(
    paymentMethodData: stripe.PaymentMethodData(),
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
    ApiDialogs.showError(
      e,
      fallbackTitle: 'Stripe Error',
    );
  } finally {
    processing.value = false;
  }
}


}
