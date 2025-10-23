// apis.dart
import 'package:dio/dio.dart';
import 'package:mobile/Api/dioclient.dart';  // ← your DioClient (with TokenController.getToken in interceptor)
import 'package:mobile/Api/apimodel.dart';   // ← your models: LoginRequest/Response, AppUser, Txn, WalletBalance, etc.

// Global, single Dio client instance
final DioClient dioClient = DioClient();

class ApiService {
  ApiService();

  // ---- AUTH ----

  /// POST /api/auth/login -> { token, role, user }
  Future<LoginResponse> login(LoginRequest dto) async {
    final res = await dioClient.dio.post('auth/login', data: dto.toJson());
    return LoginResponse.fromJson(res.data as Map<String, dynamic>);
  }

  /// POST /api/auth/logout
  Future<void> logout() async {
    await dioClient.dio.post('auth/logout');
  }

  // ---- USERS ----

  /// GET /api/users/me
  Future<AppUser> getMe() async {
    final res = await dioClient.dio.get('users/me');
    return AppUser.fromJson(res.data as Map<String, dynamic>);
  }

  /// GET /api/users
  Future<List<AppUser>> listUsers() async {
    final res = await dioClient.dio.get('users');
    final data = res.data as List;
    return data.map((e) => AppUser.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// GET /api/users/{id}
  Future<AppUser?> getUser(String id) async {
    final res = await dioClient.dio.get('users/$id');
    if (res.statusCode == 200 && res.data != null) {
      return AppUser.fromJson(res.data as Map<String, dynamic>);
    }
    return null;
  }

  // ---- TRANSACTIONS ----

  /// GET /api/transaction
  Future<List<Txn>> listTransactions() async {
    final res = await dioClient.dio.get('transaction');
    final data = res.data as List;
    return data.map((e) => Txn.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// GET /api/transaction/by-wallet/{walletId}
  Future<List<Txn>> transactionsByWallet(String walletId) async {
    final res = await dioClient.dio.get('transaction/by-wallet/$walletId');
    final data = res.data as List;
    return data.map((e) => Txn.fromJson(e as Map<String, dynamic>)).toList();
  }

  // ---- WALLET ----

  /// POST /api/wallet/topup
  Future<WalletBalance> topUp(TopUpRequest dto) async {
    final res = await dioClient.dio.post('wallet/topup', data: dto.toJson());
    return WalletBalance.fromJson(res.data as Map<String, dynamic>);
  }

  /// POST /api/wallet/pay
  /// returns a map with 'from' and 'to' balances
  Future<Map<String, WalletBalance>> pay(PayRequest dto) async {
    final res = await dioClient.dio.post('wallet/pay', data: dto.toJson());
    final j = res.data as Map<String, dynamic>;
    return {
      'from': WalletBalance(
        walletId: j['from_wallet_id'].toString(),
        walletBalance: (j['from_balance'] as num),
      ),
      'to': WalletBalance(
        walletId: j['to_wallet_id'].toString(),
        walletBalance: (j['to_balance'] as num),
      ),
    };
  }

  // ---- BANK ACCOUNT ----

  /// GET /api/bankaccount
  Future<List<BankAccount>> listBankAccounts() async {
    final res = await dioClient.dio.get('bankaccount');
    final data = res.data as List;
    return data.map((e) => BankAccount.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// POST /api/bankaccount
  Future<BankAccount> createBankAccount(Map<String, dynamic> body) async {
    final res = await dioClient.dio.post('bankaccount', data: body);
    return BankAccount.fromJson(res.data as Map<String, dynamic>);
  }

  // ---- (optional) tiny helper for safe calls ----

  /// Wrap any Future with basic Dio error surfacing.
  /// Example: `await safe(() => login(dto));`
  Future<T> safe<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on DioException catch (e) {
      // You can customize error handling here (e.response?.statusCode)
      rethrow;
    }
  }
}
