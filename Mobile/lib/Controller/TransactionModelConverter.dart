// ==================================================
// Program Name   : TransactionModelConverter.dart
// Purpose        : Converts transaction API data to UI models
// Developer      : Mr. Loh Kai Xuan 
// Student ID     : TP074510 
// Course         : Bachelor of Software Engineering (Hons) 
// Created Date   : 15 November 2025
// Last Modified  : 4 January 2026 
// ==================================================
import 'package:get/get.dart';
import 'package:mobile/Api/apimodel.dart' as api;
import 'package:mobile/Component/TransactionCard.dart' as ui;
import 'package:mobile/Controller/RoleController.dart';

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
