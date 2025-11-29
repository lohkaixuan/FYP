// lib/api/apimodel.dart
import 'package:get/get.dart';
import 'package:mobile/Controller/RoleController.dart';

class AppUser {
  final String userId;
  final String userName;
  final String email;
  final String phone;
  final double balance;
  final DateTime? lastLogin;
  final bool isDeleted;
  // Wallet identifiers
  final String? walletId; // back-compat = personal wallet
  final String? userWalletId; // personal wallet
  final String? merchantWalletId; // merchant wallet (if any)
  final double? userWalletBalance;
  final double? merchantWalletBalance;
  final String? merchantName;
  final String? icNumber;
  final int? age;

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
    this.userWalletBalance,
    this.merchantWalletBalance,
    this.merchantName,
    this.isDeleted = false,
    this.icNumber, // New
    this.age,
  });

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
        // Fix: Match server's camelCase 'userId'
        userId: (j['userId'] ?? j['user_id'] ?? '').toString(),

        // Fix: Match server's camelCase 'userName'
        userName: (j['userName'] ?? j['user_name'] ?? 'Unknown').toString(),

        // Fix: Match server's camelCase 'email'
        email: (j['email'] ?? j['user_email'] ?? '').toString(),

        // Fix: Match server's camelCase 'phoneNumber'
        phone: (j['phoneNumber'] ?? j['user_phone_number'] ?? '').toString(),

        // Fix: Match server's camelCase 'balance'
        balance: _toDouble(j['balance'] ?? j['user_balance']),

        // Fix: Match server's camelCase 'lastLogin'
        lastLogin: (j['lastLogin'] != null)
            ? DateTime.tryParse(j['lastLogin'].toString())
            : null,

        isDeleted: j['is_deleted'] == true || j['isDeleted'] == true,

        walletId: j['walletId']?.toString() ?? j['wallet_id']?.toString(),
        userWalletId: j['userWalletId']?.toString() ??
            j['user_wallet_id']?.toString() ??
            j['walletId']?.toString(),

        merchantWalletId: j['merchantWalletId']?.toString() ??
            j['merchant_wallet_id']?.toString(),

        userWalletBalance:
            _toDoubleOrNull(j['userWalletBalance'] ?? j['user_wallet_balance']),

        merchantWalletBalance: _toDoubleOrNull(
            j['merchantWalletBalance'] ?? j['merchant_wallet_balance']),

        merchantName: j['merchantName'] ?? j['merchant_name'],
        icNumber: j['icNumber']?.toString() ??
            j['user_ic_number']?.toString() ??
            j['ICNumber']?.toString(),
        age: (j['userAge'] ?? j['user_age'] ?? j['UserAge']) as int?,
      );

  static double? _toDoubleOrNull(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String && value.isEmpty) return null;
    return double.tryParse(value.toString());
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }
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

class PasscodeInfo {
  final String? passcode;
  PasscodeInfo({this.passcode});
  factory PasscodeInfo.fromJson(Map<String, dynamic> j) =>
      PasscodeInfo(passcode: j['passcode']?.toString());
}

class ApiMessage {
  final String message;
  ApiMessage({required this.message});
  factory ApiMessage.fromJson(Map<String, dynamic> j) =>
      ApiMessage(message: (j['message'] ?? '').toString());
}

abstract class AccountBase {
  String get accId;
  double? get accBalance;
}

class Wallet implements AccountBase {
  final String walletId;
  final String walletNumber;
  final double balance;
  Wallet(
      {required this.walletId,
      required this.walletNumber,
      required this.balance});
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
  final String? bankLinkId;
  final String? bankLinkProviderId;
  final String? bankLinkExternalRef;

  BankAccount({
    required this.bankAccountId,
    this.bankName,
    this.bankAccountNumber,
    this.userBalance,
    this.bankLinkId,
    this.bankLinkProviderId,
    this.bankLinkExternalRef,
  });
  factory BankAccount.fromJson(Map<String, dynamic> j) => BankAccount(
        bankAccountId:
            (j['bankAccountId'] ?? j['bank_account_id'] ?? '').toString(),
        bankName: j['bankName'] ?? j['bank_name'],
        bankAccountNumber: j['bankAccountNumber'] ?? j['bank_account_number'],
        userBalance: j['bankUserBalance'] ?? j['bank_user_balance'],
        bankLinkId: (j['bankLinkId'] ?? j['bank_link_id'])?.toString(),
        bankLinkProviderId: (j['bankLinkProviderId'] ??
                j['providerId'] ??
                (j['bankLink']?['providerId']))
            ?.toString(),
        bankLinkExternalRef: (j['bankLinkExternalAccountRef'] ??
                j['externalAccountRef'] ??
                j['bankLink']?['externalAccountRef'])
            ?.toString(),
      );

  Map<String, dynamic> toJson() => {
        'bankAccountId': bankAccountId,
        'bankName': bankName,
        'bankAccountNumber': bankAccountNumber,
        'bankUserBalance': userBalance,
        'bankLinkId': bankLinkId,
        'bankLinkProviderId': bankLinkProviderId,
        'bankLinkExternalAccountRef': bankLinkExternalRef,
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
      lastUpdate:
          lastRaw == null ? null : DateTime.tryParse(lastRaw.toString()),
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
  final String preferredWalletType;
  final String? preferredWalletId;
  final String? matchType;

  WalletLookupResult({
    required this.userId,
    required this.userName,
    this.username,
    this.email,
    this.phoneNumber,
    required this.userWallet,
    this.merchantWallet,
    required this.preferredWalletType,
    this.preferredWalletId,
    this.matchType,
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
        (json['user_wallet'] as Map<String, dynamic>?) ?? <String, dynamic>{};
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

    final preferredTypeRaw = json['preferred_wallet_type'] ??
        json['preferredWalletType'] ??
        json['match_type'] ??
        json['matchType'];
    final preferredIdRaw = json['preferred_wallet_id'] ??
        json['preferredWalletId'] ??
        json['wallet_id'] ??
        json['walletId'];

    return WalletLookupResult(
      userId: userId,
      userName: userName,
      username: username,
      email: email,
      phoneNumber: phone,
      userWallet: WalletSummary.fromJson(walletJson),
      merchantWallet: merchantJson == null
          ? null
          : MerchantWalletInfo.fromJson(merchantJson),
      preferredWalletType:
          (preferredTypeRaw ?? 'user').toString().toLowerCase(),
      preferredWalletId: preferredIdRaw?.toString(),
      matchType: (json['match_type'] ?? json['matchType'])?.toString(),
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

class TransactionGroup {
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

class Merchant {
  final String merchantId;
  final String merchantName;
  final String? merchantPhoneNumber;
  final String? merchantDocUrl;
  final String? ownerUserId;
  final String? status;
  final String? address;

  Merchant({
    required this.merchantId,
    required this.merchantName,
    this.merchantPhoneNumber,
    this.merchantDocUrl,
    this.ownerUserId,
    this.status,
    this.address,
  });

  factory Merchant.fromJson(Map<String, dynamic> j) => Merchant(
        merchantId: j['merchant_id']?.toString() ?? '',
        merchantName: j['merchant_name'] ?? '',
        merchantPhoneNumber: j['merchant_phone_number'],
        merchantDocUrl: j['merchant_doc'],
        ownerUserId: j['owner_user_id']?.toString(),
        status: j['status'],
        address: j['address'],
      );

  Map<String, dynamic> toJson() => {
        'merchant_id': merchantId,
        'merchant_name': merchantName,
        'merchant_phone_number': merchantPhoneNumber,
        'merchant_doc': merchantDocUrl,
        'owner_user_id': ownerUserId,
        'status': status,
        'address': address,
      };
}

class ProviderModel {
  final String providerId;
  final String name;
  final String? baseUrl;
  final bool enabled;
  final String? ownerUserId; // <--- Add this

  ProviderModel({
    required this.providerId,
    required this.name,
    this.baseUrl,
    this.enabled = true,
    this.ownerUserId, // <--- Add this
  });

  factory ProviderModel.fromJson(Map<String, dynamic> j) => ProviderModel(
        providerId: j['provider_id']?.toString() ?? '',
        name: j['name'] ?? '',
        baseUrl: j['base_url'],
        enabled: j['enabled'] ?? true,
        ownerUserId: j['owner_user_id']?.toString(), // <--- Add this
      );

  Map<String, dynamic> toJson() => {
        'provider_id': providerId,
        'name': name,
        'base_url': baseUrl,
        'enabled': enabled,
        'owner_user_id': ownerUserId, // <--- Add this
      };
}

// Add this class to lib/Api/apimodel.dart

class DirectoryAccount {
  final String id;
  final String role; // "user", "merchant", "provider"
  final String name;
  final String? phone;
  final String? email;
  final DateTime? lastLogin;
  final bool isDeleted;
  final String? ownerUserId;
  final String? merchantId;
  final String? providerId;

  DirectoryAccount({
    required this.id,
    required this.role,
    required this.name,
    this.phone,
    this.email,
    this.lastLogin,
    required this.isDeleted,
    this.ownerUserId,
    this.merchantId,
    this.providerId,
  });

  // Helper for Status Badge
  String get status => isDeleted ? 'Deactivated' : 'Active';

  factory DirectoryAccount.fromJson(Map<String, dynamic> j) => DirectoryAccount(
        // Handle both camelCase (standard) and PascalCase (C# default)
        id: (j['id'] ?? j['Id'] ?? '').toString(),
        role: (j['role'] ?? j['Role'] ?? '').toString().toLowerCase(),
        name: (j['name'] ?? j['Name'] ?? 'Unknown').toString(),
        phone: j['phone']?.toString() ?? j['Phone']?.toString(),
        email: j['email']?.toString() ?? j['Email']?.toString(),
        lastLogin: (j['lastLogin'] != null || j['LastLogin'] != null)
            ? DateTime.tryParse((j['lastLogin'] ?? j['LastLogin']).toString())
            : null,
        isDeleted: j['isDeleted'] == true || j['IsDeleted'] == true,
        ownerUserId:
            j['ownerUserId']?.toString() ?? j['OwnerUserId']?.toString(),
        merchantId: j['merchantId']?.toString() ?? j['MerchantId']?.toString(),
        providerId: j['providerId']?.toString() ?? j['ProviderId']?.toString(),
      );
}
