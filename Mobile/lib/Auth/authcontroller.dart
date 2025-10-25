// authcontroller.dart
import 'package:get/get.dart';
import 'package:mobile/Api/apis.dart';
import 'package:mobile/Api/tokenController.dart';
import 'package:mobile/Api/apimodel.dart';
import 'package:mobile/Utils/app_helpers.dart';

class AuthController extends GetxController {
  final ApiService api;          // ✅ 构造注入
  final TokenController tokenC;  // ✅ 构造注入
  AuthController(this.api, this.tokenC);

  // reactive state
  final isLoading = false.obs;
  final isLoggedIn = false.obs;
  final role = ''.obs;
  final user = Rxn<AppUser>();     // ← 统一模型名
  final lastError = ''.obs;

  bool get isUser => AppHelpers.hasRole(role.value, 'user');
  bool get isMerchant => AppHelpers.hasRole(role.value, 'merchant');
  bool get isAdmin => AppHelpers.hasRole(role.value, 'admin');
  bool get isProvider => AppHelpers.hasRole(role.value, 'provider');


  // ===== Lifecycle =====
  @override
  void onInit() {
    super.onInit();
  }

  // =====================
  //        AUTH
  // =====================

  Future<void> loginFlexible({ String? email, String? phone, String? password}) async {
    try {
      isLoading.value = true;
      final res = await api.login(
        email: email,
        phone: phone,
        password: password,
      );
      // ✅ 单一真相：只存到 TokenController
      await tokenC.saveToken(res.token);
      role.value = res.role;
      user.value = res.user;
      print('Logged in user: ${user.value?.userName}, role: ${role.value}');
      isLoggedIn.value = true;
      isLoading.value = false;
      Get.offAllNamed('/home');
    } catch (e) {
      lastError.value = e.toString();
      isLoggedIn.value = false;
    } 
  }

  Future<void> logout() async {
    await api.logout();
    await tokenC.clearToken();
    user.value = null;
    role.value = '';
    isLoggedIn.value = false;
  }

  /// Fetch /me profile
  Future<bool> refreshMe() async {
    try {
      isLoading.value = true;
      final me = await api.me();
      user.value = me;
      // If backend also provides role in /me you can set role here.
      // role.value = me.role ?? role.value;
      return true;
    } catch (e) {
      lastError.value = e.toString();
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // =====================
  //     REGISTRATIONS
  // =====================

  /// User registration (普通用户)
  Future<void> registerUser({
    required String name,
    required String password,
    required String ic,
    String? email,
    String? phone,
    int? age,
  }) async {
    try {
      isLoading.value = true;
      await api.registerUser(
        name: name,
        password: password,
        ic: ic,
        email: email,
        phone: phone,
        age: age,
      );
      Get.offAndToNamed('/login');
      isLoading.value = false;

    } catch (e) {
      lastError.value = e.toString();
    } 
  }

  /// Third-party registration (服务提供商 / 第三方)
  Future<bool> registerThirdParty({
    required String name,
    required String password,
    String? ic,
    String? email,
    String? phone,
    int? age,
  }) async {
    try {
      isLoading.value = true;
      await api.registerThirdParty(
        name: name,
        password: password,
        ic: ic,
        email: email,
        phone: phone,
        age: age,
      );
      return true;
    } catch (e) {
      lastError.value = e.toString();
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // =====================
  //  MERCHANT / APPROVAL
  // =====================

  /// Merchant apply (multipart with optional docFile)
  Future<bool> merchantApply({
    required String ownerUserId,
    required String merchantName,
    String? merchantPhone,
    // Use dart:io File in your UI and pass it here (nullable)
    dynamic docFile, // File? 类型，写 dynamic 以避UI层导入冲突；ApiService 会处理
  }) async {
    try {
      isLoading.value = true;
      await api.merchantApply(
        ownerUserId: ownerUserId,
        merchantName: merchantName,
        merchantPhone: merchantPhone,
        docFile: docFile,
      );
      return true;
    } catch (e) {
      lastError.value = e.toString();
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Admin approve merchant
  Future<bool> adminApproveMerchant(String merchantId) async {
    try {
      isLoading.value = true;
      await api.adminApproveMerchant(merchantId);
      return true;
    } catch (e) {
      lastError.value = e.toString();
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Admin approve third-party
  Future<bool> adminApproveThirdParty(String userId) async {
    try {
      isLoading.value = true;
      await api.adminApproveThirdParty(userId);
      return true;
    } catch (e) {
      lastError.value = e.toString();
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // =====================
  //     UTIL HELPERS
  // =====================

  /// Ensure user is authenticated (has token & profile ok)
  Future<bool> ensureAuthenticated() async {
    if (tokenC.token.value.isEmpty) return false;
    if (user.value == null) {
      return await refreshMe();
    }
    return true;
  }
}
