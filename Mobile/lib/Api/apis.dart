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
    print("API LOGIN RESPONSE DATA: $data"); // Debug print
    final auth = AuthResult.fromJson(data);
    return auth;
  }

  // POST /api/auth/passcode/register
  Future<ApiMessage> registerPasscode(String passcode) async {
    final res = await _dio.post('/api/auth/passcode/register', data: {
      'passcode': passcode,
    });
    return ApiMessage.fromJson(Map<String, dynamic>.from(res.data));
  }

  // PUT /api/auth/passcode/change
  Future<ApiMessage> changePasscode({
    required String currentPasscode,
    required String newPasscode,
  }) async {
    final res = await _dio.put('/api/auth/passcode/change', data: {
      'current_passcode': currentPasscode,
      'new_passcode': newPasscode,
    });
    return ApiMessage.fromJson(Map<String, dynamic>.from(res.data));
  }

  // GET /api/auth/passcode
  Future<PasscodeInfo> getPasscode({String? userId}) async {
    final query = <String, dynamic>{};
    if (userId != null && userId.isNotEmpty) {
      query['user_id'] = userId;
    }
    final res = await _dio.get('/api/auth/passcode',
        queryParameters: query.isEmpty ? null : query);
    return PasscodeInfo.fromJson(Map<String, dynamic>.from(res.data));
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
    try {
      // 1. Point to the new endpoint defined in UsersController.cs
      final res = await _dio.get('/api/users/all-users');

      // 2. Parse the response
      final list = (res.data as List).cast<Map<String, dynamic>>();

      // 3. Convert to AppUser models
      // Your AppUser.fromJson already handles snake_case keys (user_id, user_name)
      // so no changes are needed in apimodel.dart.
      return list.map(AppUser.fromJson).toList();
    } catch (e) {
      print("Error fetching all users: $e");
      rethrow;
    }
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

  // POST /api/wallet/reload // New endpoint!
  Future<Map<String, dynamic>> reload({
    required String walletId,
    required double amount,
    required String providerId,
    required String externalSourceId, // This is the Stripe Token/Source ID!
  }) async {
    final res = await _dio.post('/api/wallet/reload', data: {
      'wallet_id': walletId,
      'amount': amount,
      'provider_id': providerId,
      'external_source_id': externalSourceId,
    });
    // Returning a Map for consistency, similar to 'pay' and 'transfer' endpoints.
    return Map<String, dynamic>.from(res.data);
  }

  // POST /api/wallet/pay (standard / nfc / qr)
  Future<Map<String, dynamic>> payStandard({
    required String fromWalletId,
    required String toWalletId,
    required double amount,
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

  Future<WalletLookupResult?> lookupWalletContact({
    String? search,
    String? walletId,
  }) async {
    String? norm(String? s) {
      final value = s?.trim();
      return (value == null || value.isEmpty) ? null : value;
    }

    final params = <String, dynamic>{};
    final resolvedWalletId = norm(walletId);
    final resolvedSearch = norm(search);

    if (resolvedWalletId != null) {
      params['wallet_id'] = resolvedWalletId;
    }
    if (resolvedSearch != null) {
      params['search'] = resolvedSearch;
    }

    if (params.isEmpty) return null;

    try {
      final res = await _dio.get('/api/wallet/lookup', queryParameters: params);
      final data = Map<String, dynamic>.from(res.data as Map);
      return WalletLookupResult.fromJson(data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null;
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> payNfc({
    required String fromWalletId,
    required String toWalletId,
    required double amount,
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
    double? amount, // 可覆盖
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
    required double amount,
    String? detail,
    String? categoryCsv,
  }) async {
    final body = {
      "from_wallet_id": fromWalletId,
      "to_wallet_id": toWalletId,
      "amount": amount,
      "detail": detail,
      "category_csv": categoryCsv,
    };

    // 看看发送出去的 JSON
    // ignore: avoid_print
    print("[ApiService.transfer] body = $body");

    final res = await _dio.post('/api/wallet/transfer', data: body);
    return Map<String, dynamic>.from(res.data);
  }

  // ---------------- TransactionsController ----------------
  // POST /api/transactions
  Future<TransactionModel> createTransaction({
    required String type, // "pay"/"topup"/"transfer" etc.
    required String from,
    required String to,
    required double amount,
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
    if (merchantId != null && merchantId.isNotEmpty)
      queryParams['merchantId'] = merchantId;
    if (bankId != null && bankId.isNotEmpty) queryParams['bankId'] = bankId;
    if (walletId != null && walletId.isNotEmpty)
      queryParams['walletId'] = walletId;
    if (type != null && type.isNotEmpty) queryParams['type'] = type;
    if (category != null && category.isNotEmpty)
      queryParams['category'] = category;
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
  // ---------------- Report APIs ----------------
  Future<MonthlyReportResponse> generateMonthlyReport({
    required String role, // "user" | "merchant" | "thirdparty"
    required String monthIso, // e.g. "2025-10-01"
    String? userId,
    String? merchantId,
    String? providerId,
  }) async {
    final body = <String, dynamic>{
      'Role': role,
      'Month': monthIso,
      'UserId': userId,
      'MerchantId': merchantId,
      'ProviderId': providerId,
    }..removeWhere((k, v) => v == null);

    final res = await _dio.post('/api/report/monthly/generate', data: body);

    return MonthlyReportResponse.fromJson(
      Map<String, dynamic>.from(res.data as Map),
    );
  }

  /// GET /api/report/{id}/download -> bytes (PDF)
  Future<Response<List<int>>> downloadReport(String id) {
    return _dio.get<List<int>>(
      '/api/report/$id/download',
      options: Options(responseType: ResponseType.bytes),
    );
  }

  // ---------------- Admin / Management helpers ----------------

// ----- USERS -----
// PUT /api/Users/{id}  (update user info)
  Future<AppUser> updateUser(
      String userId, Map<String, dynamic> payload) async {
    // The C# controller is [HttpPut("{id}")]
    final res = await _dio.put('/api/users/$userId', data: payload);
    // Response structure: { message: "...", user: {...} }
    return AppUser.fromJson(Map<String, dynamic>.from(res.data['user']));
  }

// PATCH /api/users/{id}/status  (soft-deactivate)
  Future<void> updateUserStatus(String userId, String status) async {
    await _dio.patch('/api/users/$userId/status', data: {'status': status});
  }

// POST /api/auth/admin/reset-password/{userId}
// NOTE: If your backend uses a different endpoint for admin-initiated reset, adjust accordingly.
  Future<void> resetPassword(String targetUserId) async {
    // Matches C# [HttpPost("{id:guid}/reset-password")] in UsersController
    await _dio.post('/api/Users/$targetUserId/reset-password');
  }

  // POST /api/Users/{id}/reset-password  —— 用户自己改密码用
  Future<void> resetMyPassword({
    required String userId,
    required String currentPassword,
    required String newPassword,
  }) async {
    await _dio.post(
      '/api/Users/$userId/reset-password',
      data: {
        // 下面两个 key 要跟你后端 DTO 对上：
        // 例如 ResetPasswordDto { string CurrentPassword; string NewPassword; }
        'current_password': currentPassword,
        'new_password': newPassword,
      },
    );
  }

// ----- MERCHANTS -----
// GET /api/merchants
  Future<List<Merchant>> listMerchants() async {
    final res = await _dio.get('/api/merchants');
    final list = (res.data as List).cast<Map<String, dynamic>>();
    return list.map(Merchant.fromJson).toList();
  }

// GET /api/merchants/{id}
  Future<Merchant> getMerchant(String id) async {
    final res = await _dio.get('/api/merchants/$id');
    return Merchant.fromJson(Map<String, dynamic>.from(res.data));
  }

// PATCH /api/merchants/{id} (update merchant info)
  Future<Merchant> updateMerchant(
      String merchantId, Map<String, dynamic> payload) async {
    final res = await _dio.patch('/api/merchants/$merchantId', data: payload);
    return Merchant.fromJson(Map<String, dynamic>.from(res.data));
  }

// PATCH /api/merchants/{id}/status
  Future<void> updateMerchantStatus(String merchantId, String status) async {
    await _dio
        .patch('/api/merchants/$merchantId/status', data: {'status': status});
  }

// ----- THIRD-PARTIES / PROVIDERS -----
// GET /api/providers
  Future<List<ProviderModel>> listThirdParties() async {
    final res = await _dio.get('/api/providers');
    final list = (res.data as List).cast<Map<String, dynamic>>();
    return list.map(ProviderModel.fromJson).toList();
  }

// GET /api/providers/{id}
  Future<ProviderModel> getThirdParty(String id) async {
    final res = await _dio.get('/api/providers/$id');
    return ProviderModel.fromJson(Map<String, dynamic>.from(res.data));
  }

// PATCH /api/providers/{id} (update provider info)
  Future<ProviderModel> updateThirdParty(
      String providerId, Map<String, dynamic> payload) async {
    final res = await _dio.patch('/api/providers/$providerId', data: payload);
    return ProviderModel.fromJson(Map<String, dynamic>.from(res.data));
  }

// PATCH /api/providers/{id}/status
  Future<void> updateThirdPartyStatus(String providerId, String status) async {
    await _dio
        .patch('/api/providers/$providerId/status', data: {'status': status});
  }

// POST /api/auth/admin/reset-thirdparty-password/{providerId}
// (If third-party accounts have their own user account and allow password reset)
  Future<void> adminResetThirdPartyPassword(String providerId,
      {String? newPassword}) async {
    final body = <String, dynamic>{};
    if (newPassword != null) body['new_password'] = newPassword;
    await _dio.post('/api/auth/admin/reset-thirdparty-password/$providerId',
        data: body);
  }

  Future<List<DirectoryAccount>> listDirectory() async {
    // Calling the endpoint seen in UserController.cs
    final res = await _dio
        .get('/api/users/directory', queryParameters: {'role': 'all'});

    final list = (res.data as List).cast<Map<String, dynamic>>();
    return list.map(DirectoryAccount.fromJson).toList();
  }

  Future<bool> checkHealth() async {
    try {
      // The screenshot shows /healthz returns 200 OK with body "ok"
      final res = await _dio.get('/healthz');
      return res.statusCode == 200;
    } catch (e) {
      print("Health check failed: $e");
      return false;
    }
  }

  // ✅ NEW: Download Merchant Document as Bytes
  // GET /api/Merchant/{merchantId}/doc
  Future<Response<List<int>>> downloadMerchantDoc(String merchantId) {
    return _dio.get<List<int>>(
      '/api/Merchant/$merchantId/doc',
      options: Options(responseType: ResponseType.bytes),
    );
  }

  // ✅ UPDATED: Reject Merchant using POST (Soft Delete)
  // Matches the C# [HttpPost]
  Future<void> adminRejectMerchant(String merchantId) async {
    await _dio.post('/api/auth/admin/reject-merchant/$merchantId');
  }
}
