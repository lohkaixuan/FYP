// models.dart
import 'dart:convert';

/// ========= AUTH =========
/// Login request matches AuthController.LoginDto
/// C#: LoginDto(string? user_email, string? user_phone_number, string? user_password, string? user_passcode)
class LoginRequest {
  final String? userEmail;
  final String? userPhoneNumber;
  final String? userPassword;
  final String? userPasscode;

  LoginRequest({
    this.userEmail,
    this.userPhoneNumber,
    this.userPassword,
    this.userPasscode,
  });

  Map<String, dynamic> toJson() => {
        'user_email': userEmail,
        'user_phone_number': userPhoneNumber,
        'user_password': userPassword,
        'user_passcode': userPasscode,
      };
}

/// C#: AuthController.Login returns { token, role, user }
class LoginResponse {
  final String token;
  final String role;
  final AppUser user;

  LoginResponse({required this.token, required this.role, required this.user});

  factory LoginResponse.fromJson(Map<String, dynamic> json) => LoginResponse(
        token: json['token'] ?? '',
        role: json['role'] ?? '',
        user: AppUser.fromJson(json['user'] as Map<String, dynamic>),
      );
}

/// ========= USER =========
/// C#: Users table shape used in multiple controllers (UsersController.Me/Get)
class AppUser {
  final String userId;
  final String userName;
  final int? userAge;
  final String? userEmail;
  final String? userPhoneNumber;
  final String? userIcNumber;
  final String? userPasscode; // DEV ONLY (server echoes in login)
  final String? userPassword; // DEV ONLY (server echoes in login)
  final String? jwtToken;
  final num? userBalance;
  final String? userRole; // roleId as Guid (server side)

  AppUser({
    required this.userId,
    required this.userName,
    this.userAge,
    this.userEmail,
    this.userPhoneNumber,
    this.userIcNumber,
    this.userPasscode,
    this.userPassword,
    this.jwtToken,
    this.userBalance,
    this.userRole,
  });

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
        userId: j['user_id'] as String,
        userName: j['user_name'] ?? '',
        userAge: j['user_age'] as int?,
        userEmail: j['user_email'] as String?,
        userPhoneNumber: j['user_phone_number'] as String?,
        userIcNumber: j['user_ic_number'] as String?,
        userPasscode: j['user_passcode'] as String?,
        userPassword: j['user_password'] as String?,
        jwtToken: j['jwt_token'] as String?,
        userBalance: j['user_balance'] as num?,
        userRole: j['user_role']?.toString(),
      );
}

/// ========= WALLET / BANK / TXN =========
/// C#: WalletController.TopUpDto(Guid wallet_id, decimal amount, Guid from_bank_account_id)
class TopUpRequest {
  final String walletId;
  final num amount;
  final String fromBankAccountId;
  TopUpRequest({
    required this.walletId,
    required this.amount,
    required this.fromBankAccountId,
  });
  Map<String, dynamic> toJson() => {
        'wallet_id': walletId,
        'amount': amount,
        'from_bank_account_id': fromBankAccountId,
      };
}

/// C#: WalletController.PayDto(...)
class PayRequest {
  final String fromWalletId;
  final String toWalletId;
  final num amount;
  final String? item;
  final String? detail;
  final String? category;

  PayRequest({
    required this.fromWalletId,
    required this.toWalletId,
    required this.amount,
    this.item,
    this.detail,
    this.category,
  });

  Map<String, dynamic> toJson() => {
        'from_wallet_id': fromWalletId,
        'to_wallet_id': toWalletId,
        'amount': amount,
        'item': item,
        'detail': detail,
        'category': category,
      };
}

/// Minimal wallet shape for topup/pay responses
class WalletBalance {
  final String walletId;
  final num walletBalance;
  WalletBalance({required this.walletId, required this.walletBalance});
  factory WalletBalance.fromJson(Map<String, dynamic> j) => WalletBalance(
        walletId: (j['wallet_id'] ?? j['to_wallet_id'] ?? j['from_wallet_id']).toString(),
        walletBalance: (j['wallet_balance'] ?? j['from_balance'] ?? j['to_balance']) as num,
      );
}

/// C#: Transaction entity (TransactionController.List/ByWallet)
class Txn {
  final String? id; // not explicitly returned, but you may have it in model
  final String? type; // transaction_type: "topup", "pay", etc.
  final String? from;
  final String? to;
  final String? fromWalletId;
  final String? toWalletId;
  final num? amount;
  final String? status;
  final String? paymentMethod;
  final String? item;
  final String? detail;
  final String? category;
  final String? timestamp;

  Txn({
    this.id,
    this.type,
    this.from,
    this.to,
    this.fromWalletId,
    this.toWalletId,
    this.amount,
    this.status,
    this.paymentMethod,
    this.item,
    this.detail,
    this.category,
    this.timestamp,
  });

  factory Txn.fromJson(Map<String, dynamic> j) => Txn(
        type: j['transaction_type'] as String?,
        from: j['transaction_from'] as String?,
        to: j['transaction_to'] as String?,
        fromWalletId: j['from_wallet_id']?.toString(),
        toWalletId: j['to_wallet_id']?.toString(),
        amount: j['transaction_amount'] as num?,
        status: j['transaction_status'] as String?,
        paymentMethod: j['payment_method'] as String?,
        item: j['transaction_item'] as String?,
        detail: j['transaction_detail'] as String?,
        category: j['category'] as String?,
        timestamp: j['transaction_timestamp']?.toString(),
      );
}

/// C#: BankAccount minimal shape (BankAccountController.List/Create)
class BankAccount {
  final String bankAccountId;
  final String? bankAccountNumber;
  final num? bankUserBalance;
  BankAccount({
    required this.bankAccountId,
    this.bankAccountNumber,
    this.bankUserBalance,
  });
  factory BankAccount.fromJson(Map<String, dynamic> j) => BankAccount(
        bankAccountId: j['bankAccountId']?.toString() ?? j['bank_account_id']?.toString() ?? '',
        bankAccountNumber: j['bankAccountNumber']?.toString() ?? j['bank_account_number']?.toString(),
        bankUserBalance: j['bankUserBalance'] as num? ?? j['bank_user_balance'] as num?,
      );
}
