import 'package:mobile/Api/apimodel.dart' as api;
import 'package:mobile/Component/TransactionCard.dart' as ui;

// Transform TransactionModel from API version to the UI version
extension TransformTransactionForUI on api.TransactionModel {
  ui.TransactionModel toUI() {
    final isTopUp = type.toLowerCase() == "top-up";
    final counterparty = amount < 0 ? to : from;

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
      category: category,
      status: setStatus(status),
    );
  }
}
