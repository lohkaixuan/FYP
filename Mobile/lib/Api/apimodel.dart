// lib/api/apimodel.dart
import 'dart:convert';

import 'package:get/get.dart';
import 'package:mobile/Controller/RoleController.dart';

class AppUser {
  final String userId;
  final String userName;
  final String email;
  final String phone;
  final double balance;
  final DateTime? lastLogin;
  // Wallet identifiers
  final String? walletId; // back-compat = personal wallet
  final String? userWalletId; // personal wallet
  final String? merchantWalletId; // merchant wallet (if any)

  AppUser({
    required this.userId,
    required this.userName,
    required this.email,
    required this.phone,
    required this.balance,
    this.lastLogin,
    this.walletId,
    this.userWalletId,
    this.merchantWalletId,
  });

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
        userId: j['user_id'] ?? j['userId'] ?? j['UserId'],
        userName: j['user_name'] ?? j['UserName'],
        email: j['user_email'] ?? j['Email'],
        phone: j['user_phone_number'] ?? j['PhoneNumber'],
        balance: j['user_balance'] ?? j['Balance'],
        lastLogin: (j['last_login'] != null)
            ? DateTime.tryParse(j['last_login'].toString())
            : null,
        walletId: j['wallet_id']?.toString(),
        userWalletId:
            j['user_wallet_id']?.toString() ?? j['wallet_id']?.toString(),
        merchantWalletId: j['merchant_wallet_id']?.toString(),
      );
}

class AuthResult {
  final String token;
  final String role;
  final AppUser user;
  AuthResult({required this.token, required this.role, required this.user});
  factory AuthResult.fromJson(Map<String, dynamic> j) => AuthResult(
        token: j['token'],
        role: j['role'],
        user: AppUser.fromJson(j['user']),
      );
}

abstract class AccountBase {
  String get accId;
  double? get accBalance;
}

class Wallet implements AccountBase {
  final String walletId;
  final String walletNumber;
  final double balance;
  Wallet({required this.walletId, required this.walletNumber, required this.balance});
  factory Wallet.fromJson(Map<String, dynamic> j) => Wallet(
        walletId: j['wallet_id'].toString(),
        walletNumber: j['wallet_number'].toString(),
        balance: j['wallet_balance'] ?? 0,
      );
  @override
  String get accId => walletId;
  @override
  double get accBalance => balance;
}

class BankAccount implements AccountBase {
  final String bankAccountId;
  final String? bankName;
  final String? bankAccountNumber;
  final double? userBalance;

  BankAccount({
    required this.bankAccountId,
    this.bankName,
    this.bankAccountNumber,
    this.userBalance,
  });
  factory BankAccount.fromJson(Map<String, dynamic> j) => BankAccount(
        bankAccountId: (j['bankAccountId'] ?? '').toString(),
        bankName: j['bankName'],
        bankAccountNumber: j['bankAccountNumber'],
        userBalance: j['bankUserBalance'],
      );

  Map<String, dynamic> toJson() => {
        'bankAccountId': bankAccountId,
        'bankName': bankName,
        'bankAccountNumber': bankAccountNumber,
        'bankUserBalance': userBalance,
      };

  @override
  String get accId => bankAccountNumber ?? 'No Account Number';
  @override
  double get accBalance => userBalance ?? 0;
}

class WalletSummary {
  final String walletId;
  final String? walletNumber;
  final double balance;
  final DateTime? lastUpdate;

  WalletSummary({
    required this.walletId,
    this.walletNumber,
    required this.balance,
    this.lastUpdate,
  });

  factory WalletSummary.fromJson(Map<String, dynamic> json) {
    final id = (json['wallet_id'] ?? json['walletId'] ?? '').toString();
    final number = json['wallet_number'] ?? json['walletNumber'];
    final balanceRaw = json['wallet_balance'] ?? json['walletBalance'] ?? 0;
    final lastRaw = json['last_update'] ?? json['lastUpdate'];

    return WalletSummary(
      walletId: id,
      walletNumber: number?.toString(),
      balance: (balanceRaw is num)
          ? balanceRaw.toDouble()
          : double.tryParse(balanceRaw.toString()) ?? 0,
      lastUpdate: lastRaw == null
          ? null
          : DateTime.tryParse(lastRaw.toString()),
    );
  }
}

class MerchantWalletInfo {
  final String merchantId;
  final String merchantName;
  final String? merchantPhoneNumber;
  final WalletSummary wallet;

  MerchantWalletInfo({
    required this.merchantId,
    required this.merchantName,
    this.merchantPhoneNumber,
    required this.wallet,
  });

  factory MerchantWalletInfo.fromJson(Map<String, dynamic> json) {
    final merchantId =
        (json['merchant_id'] ?? json['merchantId'] ?? '').toString();
    final merchantName =
        (json['merchant_name'] ?? json['merchantName'] ?? '').toString();
    final merchantPhone =
        json['merchant_phone_number'] ?? json['merchantPhoneNumber'];

    return MerchantWalletInfo(
      merchantId: merchantId,
      merchantName: merchantName,
      merchantPhoneNumber: merchantPhone?.toString(),
      wallet: WalletSummary.fromJson(json),
    );
  }
}

class WalletLookupResult {
  final String userId;
  final String userName;
  final String? username;
  final String? email;
  final String? phoneNumber;
  final WalletSummary userWallet;
  final MerchantWalletInfo? merchantWallet;

  WalletLookupResult({
    required this.userId,
    required this.userName,
    this.username,
    this.email,
    this.phoneNumber,
    required this.userWallet,
    this.merchantWallet,
  });

  factory WalletLookupResult.fromJson(Map<String, dynamic> json) {
    final userJson =
        (json['user'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    final userId = (userJson['user_id'] ??
            json['user_id'] ??
            json['userId'] ??
            userJson['UserId'] ??
            json['UserId'] ??
            '')
        .toString();
    final userName = (userJson['user_name'] ??
            json['user_name'] ??
            json['userName'] ??
            userJson['UserName'] ??
            json['UserName'] ??
            '')
        .toString();
    final username =
        (userJson['user_username'] ?? json['user_username'] ?? userName)
            .toString();
    final email =
        (userJson['user_email'] ?? json['user_email'] ?? json['userEmail'])
            ?.toString();
    final phone = (userJson['user_phone_number'] ??
            json['user_phone_number'] ??
            json['userPhoneNumber'])
        ?.toString();

    Map<String, dynamic> walletJson =
        (json['user_wallet'] as Map<String, dynamic>?) ??
            <String, dynamic>{};
    if (walletJson.isEmpty) {
      walletJson = {
        'wallet_id': json['wallet_id'],
        'wallet_number': json['wallet_number'],
        'wallet_balance': json['wallet_balance'],
        'last_update': json['last_update'],
      };
    }

    final merchantJson =
        json['merchant_wallet'] as Map<String, dynamic>? ?? null;

    return WalletLookupResult(
      userId: userId,
      userName: userName,
      username: username,
      email: email,
      phoneNumber: phone,
      userWallet: WalletSummary.fromJson(walletJson),
      merchantWallet:
          merchantJson == null ? null : MerchantWalletInfo.fromJson(merchantJson),
    );
  }
}

class TransactionModel {
  final String id;
  final String type;
  final String from;
  final String to;
  final double amount;
  final String? item;
  final String? detail;
  final String? paymentMethod;
  final String? status;
  final String? category; // single canonical
  final String? predictedCat;
  final num? predictedConf;
  final DateTime? timestamp;
  final DateTime? lastUpdate;

  TransactionModel(
      {required this.id,
      required this.type,
      required this.from,
      required this.to,
      required this.amount,
      this.item,
      this.detail,
      this.paymentMethod,
      this.status,
      this.category,
      this.predictedCat,
      this.predictedConf,
      this.timestamp,
      this.lastUpdate});

  factory TransactionModel.fromJson(Map<String, dynamic> j) => TransactionModel(
        id: j['transaction_id']?.toString() ??
            j['transactionId']?.toString() ??
            '',
        type: j['transaction_type'] ?? '',
        from: j['transaction_from']?.toString() ?? '',
        to: j['transaction_to']?.toString() ?? '',
        amount: j['transaction_amount'] ?? 0,
        item: j['transaction_item'],
        detail: j['transaction_detail'],
        paymentMethod: j['payment_method'],
        status: j['transaction_status'],
        category: j['category'],
        predictedCat: j['PredictedCategory']?.toString(),
        predictedConf: j['PredictedConfidence'],
        timestamp: (j['transaction_timestamp'] != null)
            ? DateTime.tryParse(j['transaction_timestamp'].toString())
            : null,
        lastUpdate: (j['last_update'] != null)
            ? DateTime.tryParse(j['last_update'].toString())
            : null,
      );

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

class TransactionGroup{
  final String type;
  final double totalAmount;
  final List<TransactionModel> transactions;

  TransactionGroup({
    required this.type,
    required this.totalAmount,
    required this.transactions,
  });

  factory TransactionGroup.fromJson(Map<String, dynamic> json) {
    return TransactionGroup(
      type: (json['type'] as String?) ?? '',
      totalAmount: (json['totalAmount'] as num).toDouble(),
      transactions: (json['transactions'] as List)
          .map((transaction) => TransactionModel.fromJson(transaction))
          .toList(),
    );
  }
}


class CategorizeInput {
  final String merchant;
  final String description;
  final String? mcc;
  final double amount;
  final String currency; // "MYR"
  final String country; // "MY"

  CategorizeInput({
    required this.merchant,
    required this.description,
    this.mcc,
    required this.amount,
    this.currency = 'MYR',
    this.country = 'MY',
  });

  Map<String, dynamic> toJson() => {
        'merchant': merchant,
        'description': description,
        'mcc': mcc,
        'amount': amount,
        'currency': currency,
        'country': country,
      };
}

class CategorizeOutput {
  final String category;
  final num confidence;
  CategorizeOutput({required this.category, required this.confidence});
  factory CategorizeOutput.fromJson(Map<String, dynamic> j) => CategorizeOutput(
        category: (j['category'] ?? '').toString(),
        confidence: j['confidence'] ?? 0,
      );
}

class Budget {
  final String? budgetId;
  final String category;
  final double limitAmount;
  final DateTime start;
  final DateTime end;
  Budget({
    this.budgetId,
    required this.category,
    required this.limitAmount,
    required this.start,
    required this.end,
  });
  Map<String, dynamic> toJson() {
    final roleController = Get.find<RoleController>();
    final map = {
      'UserId': roleController.userId.value,
      'Category': category,
      'LimitAmount': limitAmount,
      'CycleStart': start.toUtc().toIso8601String(),
      'CycleEnd': end.toUtc().toIso8601String(),
    };
    return map;
  }
}

class BudgetSummaryItem {
  final String category;
  final double limitAmount;
  final double spent;
  final double remaining;
  final double percent;
  BudgetSummaryItem({
    required this.category,
    required this.limitAmount,
    required this.spent,
    required this.remaining,
    required this.percent,
  });
  factory BudgetSummaryItem.fromJson(Map<String, dynamic> j) =>
      BudgetSummaryItem(
        category: j['category'] ?? '',
        limitAmount: j['limitAmount'] ?? 0,
        spent: j['spent'] ?? 0,
        remaining: j['remaining'] ?? 0,
        percent: (j['percent'] ?? 0).toDouble(),
      );
}

class ProviderBalance {
  final String linkId;
  final double balance;
  ProviderBalance({required this.linkId, required this.balance});
  factory ProviderBalance.fromJson(Map<String, dynamic> j) => ProviderBalance(
        linkId: j['linkId']?.toString() ?? '',
        balance: j['balance'] ?? 0,
      );
}

class MonthlyReportResponse {
  final String reportId;
  final String role;
  final String month; // ISO like 2025-10-01
  final String downloadUrl;
  MonthlyReportResponse({
    required this.reportId,
    required this.role,
    required this.month,
    required this.downloadUrl,
  });
  factory MonthlyReportResponse.fromJson(Map<String, dynamic> j) =>
      MonthlyReportResponse(
        reportId: j['reportId']?.toString() ?? j['id']?.toString() ?? '',
        role: j['role'] ?? '',
        month: j['month'] ?? '',
        downloadUrl: j['downloadUrl'] ?? j['url'] ?? '',
      );
}
