import 'package:get/get.dart';
import 'package:mobile/Api/apimodel.dart' as api;
import 'package:mobile/Component/TransactionCard.dart' as ui;
import 'package:mobile/Controller/RoleController.dart';

// Transform TransactionModel from API version to the UI version
extension TransformTransactionForUI on api.TransactionModel {
  ui.TransactionModel toUI() {
    final isTopUp = type.toLowerCase() == "topup";
    final counterparty = amount < 0 ? to : from;

    final activeWalletId = Get.find<RoleController>().activeWalletId.value;

    String flow;
    if (from == activeWalletId) {
        flow = 'debit';
    } else if (to == activeWalletId) {
        flow = 'credit';
    } else {
        flow = 'unknown'; 
    }

    ui.TxStatus setStatus(String? status) {
      final statusInString = status?.toLowerCase();
      if (statusInString == "pending") {
        return ui.TxStatus.pending;
      } else if (statusInString == "success") {
        return ui.TxStatus.success;
      } else {
        return ui.TxStatus.failed;
      }
    }

    return ui.TransactionModel(
      id: id,
      timestamp: timestamp ?? DateTime.now(),
      counterparty: counterparty,
      amount: amount.toDouble(),
      isTopUp: isTopUp,
      flowType: flow,
      category: category,
      status: setStatus(status),
    );
  }
}
