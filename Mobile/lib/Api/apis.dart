// apis.dart
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:get/get.dart'
    hide // ← 隐藏会冲突的类型
        MultipartFile,
        FormData,
        Response;
import 'package:mobile/Api/dioclient.dart'; // ← your DioClient (with TokenController.getToken in interceptor)
import 'package:mobile/Api/apimodel.dart';
import 'package:mobile/Api/tokenController.dart'; // ← your models: LoginRequest/Response, AppUser, Txn, WalletBalance, etc.
import 'dart:io';
import 'package:path/path.dart' as p;
import 'dart:typed_data';

// Global, single Dio client instance

class ApiService {
  final Dio _dio = DioClient().dio;
  final token = Get.find<TokenController>();

  // ---------------- AuthController ----------------
  // POST /api/auth/login
  Future<AuthResult> login({
    String? email,
    String? phone,
    String? password,
  }) async {
    final res = await _dio.post('/api/auth/login', data: {
      'user_email': email,
      'user_phone_number': phone,
      'user_password': password,
    });
    final data = res.data as Map<String, dynamic>;
    final auth = AuthResult.fromJson(data);
    return auth;
  }

  // POST /api/auth/logout
  Future<void> logout() async {
    await _dio.post('/api/auth/logout');
    token.clearToken();
  }

  // POST /api/auth/register/user
  Future<Map<String, dynamic>> registerUser({
    required String name,
    required String password,
    required String ic,
    String? email,
    String? phone,
    // int? age,
  }) async {
    final res = await _dio.post('/api/auth/register/user', data: {
      'user_name': name,
      'user_password': password,
      'user_ic_number': ic,
      'user_email': email,
      'user_phone_number': phone,
      // 'user_age': age,
    });
    return Map<String, dynamic>.from(res.data);
  }

  // POST /api/auth/register/merchant-apply (multipart)
  Future<Map<String, dynamic>> merchantApply({
    required String ownerUserId,
    required String merchantName,
    String? merchantPhone,
    File? docFile, // mobile/desktop
    Uint8List? docBytes, // web
    String? docName, // web
  }) async {
    final form = FormData();

    form.fields
      ..add(MapEntry('owner_user_id', ownerUserId))
      ..add(MapEntry('merchant_name', merchantName));
    if (merchantPhone != null) {
      form.fields.add(MapEntry('merchant_phone_number', merchantPhone));
    }

    if (docFile != null) {
      form.files.add(MapEntry(
        'merchant_doc',
        await MultipartFile.fromFile(docFile.path,
            filename: p.basename(docFile.path)),
      ));
    } else if (docBytes != null) {
      form.files.add(MapEntry(
        'merchant_doc',
        MultipartFile.fromBytes(docBytes, filename: docName ?? 'document.bin'),
      ));
    }

    final res =
        await _dio.post('/api/auth/register/merchant-apply', data: form);
    return Map<String, dynamic>.from(res.data);
  }

  // POST /api/auth/admin/approve-merchant/{merchantId}
  Future<void> adminApproveMerchant(String merchantId) async {
    await _dio.post('/api/auth/admin/approve-merchant/$merchantId');
  }

  // POST /api/auth/admin/approve-thirdparty/{userId}
  Future<void> adminApproveThirdParty(String userId) async {
    await _dio.post('/api/auth/admin/approve-thirdparty/$userId');
  }

  // POST /api/auth/register/thirdparty
  Future<Map<String, dynamic>> registerThirdParty({
    required String name,
    required String password,
    String? ic,
    String? email,
    String? phone,
    int? age,
  }) async {
    final res = await _dio.post('/api/auth/register/thirdparty', data: {
      'user_name': name,
      'user_password': password,
      'user_ic_number': ic,
      'user_email': email,
      'user_phone_number': phone,
      'user_age': age,
    });
    return Map<String, dynamic>.from(res.data);
  }

  // ---------------- UsersController ----------------
  // GET /api/users/me
  Future<AppUser> me() async {
    final res = await _dio.get('/api/users/me');
    return AppUser.fromJson(Map<String, dynamic>.from(res.data));
    // 需要 Bearer
  }

  // GET /api/users
  Future<List<AppUser>> listUsers() async {
    final res = await _dio.get('/api/users');
    final list = (res.data as List).cast<Map<String, dynamic>>();
    return list.map(AppUser.fromJson).toList();
  }

  // GET /api/users/{id}
  Future<AppUser> getUser(String id) async {
    final res = await _dio.get('/api/users/$id');
    return AppUser.fromJson(Map<String, dynamic>.from(res.data));
  }

  // ---------------- BankAccountController ----------------
  // GET /api/bankaccount
  Future<List<BankAccount>> listBankAccounts(String userId) async {
    final res =
        await _dio.get('/api/bankaccount', queryParameters: {'userId': userId});
    final list = (res.data as List).cast<Map<String, dynamic>>();
    return list.map(BankAccount.fromJson).toList();
  }

  // POST /api/bankaccount
  Future<BankAccount> createBankAccount(BankAccount b) async {
    final res = await _dio.post('/api/bankaccount', data: b.toJson());
    return BankAccount.fromJson(Map<String, dynamic>.from(res.data));
  }

  // ---------------- WalletController ----------------
  // GET /api/wallet/{id}
  Future<Wallet> getWallet(String id) async {
    final res = await _dio.get('/api/wallet/$id');
    return Wallet.fromJson(Map<String, dynamic>.from(res.data));
  }

  // POST /api/wallet/topup
  Future<Wallet> topUp({
    required String walletId,
    required num amount,
    required String fromBankAccountId,
  }) async {
    final res = await _dio.post('/api/wallet/topup', data: {
      'wallet_id': walletId,
      'amount': amount,
      'from_bank_account_id': fromBankAccountId,
    });
    final j = Map<String, dynamic>.from(res.data);
    return Wallet(
      walletId: j['wallet_id'].toString(),
      walletNumber: j['wallet_number'].toString(),
      balance: j['wallet_balance'] ?? 0,
    );
  }

  // POST /api/wallet/pay (standard / nfc / qr)
  Future<Map<String, dynamic>> payStandard({
    required String fromWalletId,
    required String toWalletId,
    required num amount,
    String? item,
    String? detail,
    String? categoryCsv,
  }) async {
    final res = await _dio.post('/api/wallet/pay', data: {
      'mode': 'standard',
      'from_wallet_id': fromWalletId,
      'to_wallet_id': toWalletId,
      'amount': amount,
      'item': item,
      'detail': detail,
      'category_csv': categoryCsv,
    });
    return Map<String, dynamic>.from(res.data);
  }

  Future<Map<String, dynamic>> payNfc({
    required String fromWalletId,
    required String toWalletId,
    required num amount,
    String? item,
    String? detail,
    String? categoryCsv,
  }) async {
    final res = await _dio.post('/api/wallet/pay', data: {
      'mode': 'nfc',
      'from_wallet_id': fromWalletId,
      'to_wallet_id': toWalletId,
      'amount': amount,
      'item': item,
      'detail': detail,
      'category_csv': categoryCsv,
    });
    return Map<String, dynamic>.from(res.data);
  }

  Future<Map<String, dynamic>> payQr({
    required String fromWalletId,
    required String qrDataJson, // 前端生成的 JSON
    num? amount, // 可覆盖
    String? detail,
    String? categoryCsv,
  }) async {
    final res = await _dio.post('/api/wallet/pay', data: {
      'mode': 'qr',
      'from_wallet_id': fromWalletId,
      'qr_data': qrDataJson,
      'amount': amount,
      'detail': detail,
      'category_csv': categoryCsv,
    });
    return Map<String, dynamic>.from(res.data);
  }

  // POST /api/wallet/transfer (A2A)
  Future<Map<String, dynamic>> transfer({
    required String fromWalletId,
    required String toWalletId,
    required num amount,
    String? detail,
    String? categoryCsv,
  }) async {
    final res = await _dio.post('/api/wallet/transfer', data: {
      'from_wallet_id': fromWalletId,
      'to_wallet_id': toWalletId,
      'amount': amount,
      'detail': detail,
      'category_csv': categoryCsv,
    });
    return Map<String, dynamic>.from(res.data);
  }

  // ---------------- TransactionsController ----------------
  // POST /api/transactions
  Future<TransactionModel> createTransaction({
    required String type, // "pay"/"topup"/"transfer" etc.
    required String from,
    required String to,
    required num amount,
    DateTime? timestamp,
    String? item,
    String? detail,
    String? mcc,
    String? paymentMethod,
    String? overrideCategoryCsv,
  }) async {
    final res = await _dio.post('/api/transactions', data: {
      'transaction_type': type,
      'transaction_from': from,
      'transaction_to': to,
      'transaction_amount': amount,
      'transaction_timestamp': timestamp?.toIso8601String(),
      'transaction_item': item,
      'transaction_detail': detail,
      'mcc': mcc,
      'payment_method': paymentMethod,
      'override_category_csv': overrideCategoryCsv,
    });
    return TransactionModel.fromJson(Map<String, dynamic>.from(res.data));
  }

  // GET /api/transactions/{id}
  Future<TransactionModel> getTransaction(String id) async {
    final res = await _dio.get('/api/transactions/$id');
    return TransactionModel.fromJson(Map<String, dynamic>.from(res.data));
  }

  // GET /api/transactions
  Future<List<dynamic>> listTransactions(
      [String? userId,
      String? merchantId,
      String? bankId,
      String? walletId,
      String? type,
      String? category,
      bool groupByType = false,
      bool groupByCategory = false]) async {
    final queryParams = <String, dynamic>{};

    if (userId != null && userId.isNotEmpty) queryParams['userId'] = userId;
    if (merchantId != null && merchantId.isNotEmpty) queryParams['merchantId'] = merchantId;
    if (bankId != null && bankId.isNotEmpty) queryParams['bankId'] = bankId;
    if (walletId != null && walletId.isNotEmpty) queryParams['walletId'] = walletId;
    if (type != null && type.isNotEmpty) queryParams['type'] = type;
    if (category != null && category.isNotEmpty) queryParams['category'] = category;
    queryParams['groupByType'] = groupByType;
    queryParams['groupByCategory'] = groupByCategory;

    final res =
        await _dio.get('/api/transactions', queryParameters: queryParams);
    final list = res.data as List<dynamic>;

    if (type != null || category != null || groupByType || groupByCategory) {
      final rows = list 
          .map((e) => TransactionGroup.fromJson(e as Map<String, dynamic>))
          .toList();
      return rows;
    } else {
      final rows = list 
          .map((e) => TransactionModel.fromJson(e as Map<String, dynamic>))
          .toList();
      return rows;
    }
  }

  // PATCH /api/transactions/{id}/final-category
  Future<void> setFinalCategory({
    required String txId,
    String? categoryCsv,
  }) async {
    await _dio.patch('/api/transactions/$txId/final-category', data: {
      'category_csv': categoryCsv,
    });
  }

  // POST /api/transactions/categorize
  Future<CategorizeOutput> categorize(CategorizeInput input) async {
    final res =
        await _dio.post('/api/transactions/categorize', data: input.toJson());
    return CategorizeOutput.fromJson(Map<String, dynamic>.from(res.data));
  }

  // ---------------- BudgetsController ----------------
  // POST /api/budgets
  Future<void> createBudget(Budget b) async {
    await _dio.post('/api/budgets', data: jsonEncode(b.toJson()));
  }

  // GET /api/budgets/summary/{userId}
  Future<List<BudgetSummaryItem>> budgetSummary(String userId) async {
    final res = await _dio.get('/api/budgets/summary/$userId');
    final list = (res.data as List).cast<Map<String, dynamic>>();
    return list.map(BudgetSummaryItem.fromJson).toList();
  }

  // ---------------- ProviderGatewayController ----------------
  // GET /api/providers/balance/{linkId}
  Future<ProviderBalance> providerBalance(String linkId) async {
    final res = await _dio.get('/api/providers/balance/$linkId');
    return ProviderBalance.fromJson(Map<String, dynamic>.from(res.data));
  }

  // ---------------- ReportController ----------------
  // POST /api/report/monthly/generate  -> MonthlyReportResponse
  Future<MonthlyReportResponse> generateMonthlyReport({
    required String role, // "user" | "merchant" | "thirdparty"
    required String monthIso, // e.g. "2025-10-01"
    String? userId,
    String? merchantId,
    String? providerId,
  }) async {
    final body = {
      'Role': role,
      'Month': monthIso,
      'UserId': userId,
      'MerchantId': merchantId,
      'ProviderId': providerId,
    }..removeWhere((k, v) => v == null);

    final res = await _dio.post('/api/report/monthly/generate', data: body);
    return MonthlyReportResponse.fromJson(Map<String, dynamic>.from(res.data));
  }

  // GET /api/report/{id}/download -> bytes (PDF)
  Future<Response<List<int>>> downloadReport(String id) {
    return _dio.get<List<int>>(
      '/api/report/$id/download',
      options: Options(responseType: ResponseType.bytes),
    );
  }
}
