import 'package:flutter/material.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:get/instance_manager.dart';
import 'package:get/utils.dart';
import 'package:mobile/Component/AppTheme.dart';
import 'package:mobile/Component/GlobalAppBar.dart';
import 'package:mobile/Component/TransactionCard.dart';
import 'package:mobile/Controller/TransactionController.dart';

enum TransactionType { transfer, pay, topup }

extension TransactionTypeExtension on TransactionType {
  String get label {
    switch (this) {
      case TransactionType.transfer:
        return 'Transfer';
      case TransactionType.pay:
        return 'Pay';
      case TransactionType.topup:
        return 'Top Up';
    }
  }
}

enum PaymentMethod { wallet, bank }

extension PaymentMethodExtension on PaymentMethod {
  String get label {
    switch (this) {
      case PaymentMethod.wallet:
        return 'Wallet';
      case PaymentMethod.bank:
        return 'Bank';
    }
  }
}

class Transaction {
  final TransactionType type;
  final String from;
  final String to;
  final double amount;
  final DateTime timestamp;
  final String item;
  final String detail;
  final String category;
  final PaymentMethod paymentMethod;
  final TxStatus status;
  final DateTime lastUpdate;

  Transaction(this.to, this.amount, this.timestamp, this.item, this.detail,
      this.category, this.paymentMethod, this.status, this.lastUpdate,
      {required this.type, required this.from});

  Map<String, dynamic> toMap() {
    return {
      'Type': type,
      'From': from,
      'To': to,
      'Amount': amount,
      'Timestamp': timestamp,
      'Item': item,
      'Detail': detail,
      'Category': category,
      'Payment Method': paymentMethod,
      'Status': status,
      'Last Update': lastUpdate
    };
  }
}

class TransactionDetails extends StatefulWidget {

  const TransactionDetails({super.key});

  @override
  State<TransactionDetails> createState() => _TransactionDetailsState();
}

class _TransactionDetailsState extends State<TransactionDetails> {
  final transactionController = Get.find<TransactionController>();
  

  @override
  void initState(){
    super.initState();

    final String? transactionId = Get.parameters['id']; 
    if (transactionId != null){
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadDetails(transactionId);
      });
    }
  }

  void _loadDetails(String transactionId) {
    Future.microtask(() => transactionController.get(id: transactionId));
  }
  
  Color _getStatusColor(String status) {
    String convertedStatus = status.toLowerCase();
    if (convertedStatus == "success") {
      return Colors.green.shade300;
    } else if (convertedStatus == "failed") {
      return Colors.red.shade300;
    } else if (convertedStatus == "pending"){
      return Colors.yellow;
    }
    return Colors.grey;
  }

  String _displayValue(dynamic item) {
    if (item is DateTime) {
      return _formatTimestamp(item);
    } else if (item is double) {
      return 'RM ${item.toStringAsFixed(2)}';
    } 
    return item;
  }

  String _formatTimestamp(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${dt.year}-${two(dt.month)}-${two(dt.day)} ${two(dt.hour)}:${two(dt.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GlobalAppBar(
        title: 'Transaction Details',
      ),
      body: Obx(
        () {
          if (transactionController.isLoading.value){
            return const Center(child: CircularProgressIndicator());
          }

          final transaction = transactionController.transaction.value;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  side: const BorderSide(width: 0.7, color: Colors.grey),
                  borderRadius: BorderRadius.circular(16)),
              child: transaction == null
                  ? const Center(
                      child: Text('Invalid transaction!',
                          style: TextStyle(color: Colors.red)))
                  : Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'RM ${transaction.amount.toStringAsFixed(2)}',
                            style: AppTheme.textBigBlack.copyWith(
                                color: Theme.of(context).colorScheme.onSurface),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _getStatusColor(transaction.status!),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: _getStatusColor(transaction.status!)
                                      .withOpacity(.25)),
                            ),
                            child: Text(
                              transaction.status!,
                              style: AppTheme.textMediumBlack.copyWith(
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: 50,
                          ),
                          ...transaction
                              .toMap()
                              .entries
                              .where((item) => item.key != 'Amount'  && item.value != null)
                              .map((item) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 5),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    item.key,
                                    style: AppTheme.textMediumBlack.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface),
                                  ),
                                  Text(
                                    _displayValue(item.value),
                                    style: AppTheme.textMediumBlack.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface,
                                        fontWeight: FontWeight.normal),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
            ),
          );
        },
      ),
    );
  }
}
