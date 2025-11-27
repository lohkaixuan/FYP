// authcontroller.dart
import 'dart:typed_data';

import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'package:mobile/Controller/BottomNavController.dart';
import 'package:mobile/Utils/api_dialogs.dart';
import 'package:mobile/Api/apis.dart';
import 'package:mobile/Api/tokenController.dart';
import 'package:mobile/Api/apimodel.dart';
import 'package:mobile/Controller/RoleController.dart';
import 'package:mobile/Utils/app_helpers.dart';

class AuthController extends GetxController {
  final ApiService api; // 构造注入
  final TokenController tokenC; // 构造注入
  AuthController(this.api, this.tokenC);

  // ========= Reactive State =========
  final isLoading = false.obs;
  final isLoggedIn = false.obs;
  final role = ''.obs;
  final user = Rxn<AppUser>();
  final lastError = ''.obs;
  final lastOk = false.obs; // 统一成功标记
  final merchantPending = false.obs; // 商家申请是否待审核
  final newlyCreatedUserId = ''.obs; // 最近注册/登录解析到的 userId
  final bottomNav = Get.find<BottomNavController>();

  bool get isUser => AppHelpers.hasRole(role.value, 'user');
  bool get isMerchant => AppHelpers.hasRole(role.value, 'merchant');
  bool get isAdmin => AppHelpers.hasRole(role.value, 'admin');
  bool get isProvider => AppHelpers.hasRole(role.value, 'provider');

  // ========= Lifecycle =========
  @override
  void onInit() {
    super.onInit();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    // 若本地已有 token，尝试刷新 /me
    if (tokenC.token.value.isNotEmpty) {
      await refreshMe();
      isLoggedIn.value = user.value != null;
    }
  }

  // ========= AUTH =========

  /// Flexible login: 支持 email/phone + password
  /// 无导航；更新 isLoggedIn / role / user / newlyCreatedUserId
  Future<void> loginFlexible({
    String? email,
    String? phone,
    String? password,
  }) async {
    try {
      isLoading.value = true;
      lastError.value = '';
      lastOk.value = false;

      final res =
          await api.login(email: email, phone: phone, password: password);
      await tokenC.saveToken(res.token);
      role.value = res.role;
      user.value = res.user;
      final uid = user.value?.userId ?? '';
      if (uid.isNotEmpty) newlyCreatedUserId.value = uid;

      isLoggedIn.value = true;
      lastOk.value = true;
      final roleC = Get.find<RoleController>();

      roleC.syncFromAuth(this); // 你原本就有的 helper
      bottomNav.reset(); // index = 0 -> Home
      Get.back(); // 关闭登录对话框
      // 5. 根据角色进入不同入口（但都是 BottomNavApp 壳）
      if (role.value == 'admin') {
        Get.offAllNamed('/admin'); // admin 入口
      } else {
        Get.offAllNamed('/home'); // user / merchant 入口
      }
    } catch (e) {
      if (e is DioException) {
        ApiDialogs.showError(e, fallbackTitle: 'Login Failed');
      }
      lastError.value = e.toString();
      isLoggedIn.value = false;
      lastOk.value = false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> login({
    String? email,
    String? phone,
    required String password,
  }) async {
    try {
      isLoading.value = true;
      lastError.value = '';
      lastOk.value = false;

      // 1. 调用后端登录 API
      final res =
          await api.login(email: email, phone: phone, password: password);
      await tokenC.saveToken(res.token);
      role.value = res.role; // e.g. 'admin' / 'user' / 'merchant'
      user.value = res.user;

      final uid = user.value?.userId ?? '';
      if (uid.isNotEmpty) newlyCreatedUserId.value = uid;
      isLoggedIn.value = true;
      lastOk.value = true;
      final roleC = Get.find<RoleController>();
      roleC.syncFromAuth(this); // 你原本就有的 helper
      bottomNav.reset(); // index = 0 -> Home
      Get.back(); // 关闭登录对话框
      // 5. 根据角色进入不同入口（但都是 BottomNavApp 壳）
      if (role.value == 'admin') {
        Get.offAllNamed('/admin'); // admin 入口
      } else {
        Get.offAllNamed('/home'); // user / merchant 入口
      }
    } catch (e) {
      if (e is DioException) {
        ApiDialogs.showError(e, fallbackTitle: 'Login Failed');
      }
      lastError.value = e.toString();
      isLoggedIn.value = false;
      lastOk.value = false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Logout：只清状态，不导航
  Future<void> logout() async {
    try {
      isLoading.value = true;
      lastError.value = '';
      lastOk.value = false;

      await api.logout();
      await tokenC.clearToken();

      user.value = null;
      role.value = '';
      isLoggedIn.value = false;
      merchantPending.value = false;
      newlyCreatedUserId.value = '';

      lastOk.value = true;
    } catch (e) {
      lastError.value = e.toString();
      lastOk.value = false;
    } finally {
      isLoading.value = false;
    }
  }

  /// /me：刷新当前用户信息（无导航）
  Future<void> refreshMe() async {
    try {
      isLoading.value = true;
      lastError.value = '';
      lastOk.value = false;

      final me = await api.me();
      user.value = me;

      // 若后端 /me 也能给到角色，可在此同步
      // role.value = me.role ?? role.value;

      // ✅ 保底记录 userId（用于后续 merchantApply 绑定）
      final uid = me.userId ?? '';
      if (uid.isNotEmpty) newlyCreatedUserId.value = uid;

      // 同步钱包与角色（角色一般不变，但钱包需更新）
      final roleC = Get.find<RoleController>();
      roleC.syncFromAuth(this);

      lastOk.value = true;
      // 回到登录页
    } catch (e) {
      lastError.value = e.toString();
      lastOk.value = false;
    } finally {
      isLoading.value = false;
    }
  }

  // ========= REGISTRATIONS =========

  /// 注册普通用户：无导航；从返回中解析 userId 存到 newlyCreatedUserId
  Future<void> registerUser({
    required String name,
    required String password,
    required String ic,
    String? email,
    String? phone,
  }) async {
    try {
      isLoading.value = true;
      lastError.value = '';
      lastOk.value = false;

      final res = await api.registerUser(
        name: name,
        password: password,
        ic: ic,
        email: email,
        phone: phone,
      ); // Map<String, dynamic>

      // ✅ 解析 userId：兜底多种命名
      final uid =
          (res['userId'] ?? res['UserId'] ?? res['id'] ?? '').toString();
      if (uid.isNotEmpty) newlyCreatedUserId.value = uid;

      lastOk.value = true;
    } catch (e) {
      if (e is DioException) {
        ApiDialogs.showError(e, fallbackTitle: 'Register Failed');
      }
      lastError.value = e.toString();
      lastOk.value = false;
    } finally {
      isLoading.value = false;
    }
  }

  /// 注册第三方（如果需要）：无导航
  Future<void> registerThirdParty({
    required String name,
    required String password,
    String? ic,
    String? email,
    String? phone,
    int? age,
  }) async {
    try {
      isLoading.value = true;
      lastError.value = '';
      lastOk.value = false;

      await api.registerThirdParty(
        name: name,
        password: password,
        ic: ic,
        email: email,
        phone: phone,
        age: age,
      );

      lastOk.value = true;
    } catch (e) {
      lastError.value = e.toString();
      lastOk.value = false;
    } finally {
      isLoading.value = false;
    }
  }

  // ========= MERCHANT / APPROVAL =========

  /// 商家申请：成功后标记为待审核（merchantPending = true）
  /// ownerUserId 请传：newlyCreatedUserId / user.userId
  Future<void> merchantApply({
    required String ownerUserId,
    required String merchantName,
    String? merchantPhone,
    dynamic docFile, // File? 仍然用 dynamic 以避免 UI import 冲突
    Uint8List? docBytes, // ✅ new
    String? docName,
  }) async {
    try {
      isLoading.value = true;
      lastError.value = '';
      lastOk.value = false;

      await api.merchantApply(
        ownerUserId: ownerUserId,
        merchantName: merchantName,
        merchantPhone: merchantPhone,
        docFile: docFile, // ✅ pass-through
        docBytes: docBytes, // ✅ pass-through
        docName: docName, // ✅ pass-through
      );

      merchantPending.value = true;
      lastOk.value = true;
    } catch (e) {
      lastError.value = e.toString();
      lastOk.value = false;
    } finally {
      isLoading.value = false;
    }
  }

  /// 管理员：批准商户（无导航）
  Future<void> adminApproveMerchant(String merchantId) async {
    try {
      isLoading.value = true;
      lastError.value = '';
      lastOk.value = false;

      await api.adminApproveMerchant(merchantId);
      lastOk.value = true;
    } catch (e) {
      lastError.value = e.toString();
      lastOk.value = false;
    } finally {
      isLoading.value = false;
    }
  }

  /// 管理员：批准第三方（无导航）
  Future<void> adminApproveThirdParty(String userId) async {
    try {
      isLoading.value = true;
      lastError.value = '';
      lastOk.value = false;

      await api.adminApproveThirdParty(userId);
      lastOk.value = true;
    } catch (e) {
      lastError.value = e.toString();
      lastOk.value = false;
    } finally {
      isLoading.value = false;
    }
  }

  // ========= UTIL HELPERS =========

  /// 确认已鉴权：只更新状态，不返回布尔
  Future<void> ensureAuthenticated() async {
    if (tokenC.token.value.isEmpty) {
      isLoggedIn.value = false;
      return;
    }
    if (user.value == null) {
      await refreshMe();
      isLoggedIn.value = user.value != null;
    } else {
      isLoggedIn.value = true;
    }
  }

  Future<void> registerPasscode(String passcode) async {
    try {
      isLoading.value = true;
      lastError.value = '';
      lastOk.value = false;

      await api.registerPasscode(passcode);

      lastOk.value = true;
    } catch (e) {
      if (e is DioException) {
        ApiDialogs.showError(e, fallbackTitle: 'Register Failed');
      }
      lastError.value = e.toString();
      lastOk.value = false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<dynamic> getMyPasscode() async {
    try {
      isLoading.value = true;
      lastError.value = '';
      final info = await api.getPasscode(); // 不传 userId = 当前登录用户
      return info;
    } catch (e) {
      lastError.value = e.toString();
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }
}
