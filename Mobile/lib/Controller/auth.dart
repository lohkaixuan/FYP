// ==================================================
// Program Name   : auth.dart
// Purpose        : Controller for authentication flows
// Developer      : Mr. Loh Kai Xuan 
// Student ID     : TP074510 
// Course         : Bachelor of Software Engineering (Hons) 
// Created Date   : 15 November 2025
// Last Modified  : 4 January 2026 
// ==================================================
import 'dart:typed_data';
import 'dart:convert';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'package:mobile/Controller/BottomNavController.dart';
import 'package:mobile/Utils/api_dialogs.dart';
import 'package:mobile/Api/apis.dart';
import 'package:mobile/Controller/tokenController.dart';
import 'package:mobile/Api/apimodel.dart';
import 'package:mobile/Controller/RoleController.dart';
import 'package:mobile/Utils/app_helpers.dart';

class AuthController extends GetxController {
  final ApiService api; 
  final TokenController tokenC; 
  AuthController(this.api, this.tokenC);
  // ========= Reactive State =========
  final isLoading = false.obs;
  final isLoggedIn = false.obs;
  final role = ''.obs;
  final user = Rxn<AppUser>();
  final lastError = ''.obs;
  final lastOk = false.obs; 
  final merchantPending = false.obs; 
  final newlyCreatedUserId = ''.obs; 
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

  String _roleFromJwt(String jwt) {
    try {
      final parts = jwt.split('.');
      if (parts.length != 3) return '';
      final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );
      final map = json.decode(payload) as Map<String, dynamic>;
      final r = map['role'] ?? map['roles'] ?? map['Role'] ?? map['Roles'];
      if (r == null) return '';
      if (r is String) return r;
      if (r is List) return r.join(',');
      return r.toString();
    } catch (_) {
      return '';
    }
  }

  Future<void> _bootstrap() async {
    if (tokenC.token.value.isNotEmpty) {
      await refreshMe();
      isLoggedIn.value = user.value != null;
    }
  }

  /// Flexible login:  email/phone + password
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
        print('[AUTH] Refreshed /me; role=${role.value}');
      final roleC = Get.find<RoleController>();

      roleC.syncFromAuth(this, preferDefaultRole: true);
      bottomNav.reset();
      if (Get.isDialogOpen ?? false) Get.back(); 
      if (role.value == 'admin') {
        Get.offAllNamed('/admin');
      } else if (role.value.contains('thirdparty') ||
          role.value.contains('provider')) {
        Get.offAllNamed('/provider/dashboard');
      } else {
        Get.offAllNamed('/home');
      }
    } catch (e) {
      if (e is DioException) {
        ApiDialogs.showError(
          e,
          fallbackTitle: 'Login Failed',
          fallbackMessage: 'Invalid credentials.',
        );
      }
      lastError.value = ApiDialogs.formatErrorMessage(e);
      isLoggedIn.value = false;
      lastOk.value = false;
    } finally {
      Future.microtask(() => isLoading.value = false);
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
      roleC.syncFromAuth(this);
      bottomNav.reset();
      if (Get.isDialogOpen ?? false) Get.back();

      if (role.value == 'admin') {
        Get.offAllNamed('/admin');
      } else if (role.value.contains('thirdparty') ||
          role.value.contains('provider')) {
        Get.offAllNamed('/provider');
      } else {
        Get.offAllNamed('/home');
      }
    } catch (e) {
      if (e is DioException) {
        ApiDialogs.showError(
          e,
          fallbackTitle: 'Login Failed',
          fallbackMessage: 'Invalid credentials.',
        );
      }
      lastError.value = ApiDialogs.formatErrorMessage(e);
      isLoggedIn.value = false;
      lastOk.value = false;
    } finally {
      Future.microtask(() => isLoading.value = false);
    }
  }

  /// Logout
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
      lastError.value = ApiDialogs.formatErrorMessage(e);
      lastOk.value = false;
    } finally {
      Future.microtask(() => isLoading.value = false);
    }
  }

  Future<void> refreshMe() async {
    try {
      isLoading.value = true;
      lastError.value = '';
      lastOk.value = false;
      print("[AUTH] refreshMe start");

      final me = await api.me();
      print("[AUTH] refreshMe me.user_wallet_balance=${me.userWalletBalance} me.merchant_wallet_balance=${me.merchantWalletBalance} role=${me.roleName ?? role.value}");
      user.value = me;
      var newRole = (me.roleName ?? role.value).toString().toLowerCase();
      if (newRole.isEmpty && tokenC.token.value.isNotEmpty) {
        newRole = _roleFromJwt(tokenC.token.value).toLowerCase();
      }
      if (newRole.isEmpty) {
        if (me.providerId != null) {
          newRole = 'provider';
        } else if (me.merchantId != null) {
          newRole = 'merchant';
        } else {
          newRole = 'user';
        }
      }
      role.value = newRole;

      Get.find<RoleController>().syncFromAuth(
        this,
        preferDefaultRole: false,
      );
      print('✅ Refreshed /me; role=${role.value}');
      isLoggedIn.value = true;
      lastOk.value = true;
    } catch (e) {
      lastError.value = ApiDialogs.formatErrorMessage(e);
      lastOk.value = false;
      await tokenC.clearToken();
      user.value = null;
      role.value = '';
      isLoggedIn.value = false;
      print("[AUTH] refreshMe failed $e");
    } finally {
      Future.microtask(() => isLoading.value = false);
    }
  }

  // ========= REGISTRATIONS =========
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
      );

      final uid =
          (res['userId'] ?? res['UserId'] ?? res['id'] ?? '').toString();
      if (uid.isNotEmpty) newlyCreatedUserId.value = uid;

      lastOk.value = true;
    } catch (e) {
      if (e is DioException) {
        ApiDialogs.showError(e, fallbackTitle: 'Register Failed');
      }
      lastError.value = ApiDialogs.formatErrorMessage(e);
      lastOk.value = false;
    } finally {
      Future.microtask(() => isLoading.value = false);
    }
  }

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
      lastError.value = ApiDialogs.formatErrorMessage(e);
      lastOk.value = false;
    } finally {
      Future.microtask(() => isLoading.value = false);
    }
  }

  // ========= MERCHANT / APPROVAL =========
  Future<void> merchantApply({
    required String ownerUserId,
    required String merchantName,
    String? merchantPhone,
    dynamic docFile,
    Uint8List? docBytes,
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
        docFile: docFile,
        docBytes: docBytes,
        docName: docName,
      );

      merchantPending.value = true;
      lastOk.value = true;
    } catch (e) {
      lastError.value = ApiDialogs.formatErrorMessage(e);
      lastOk.value = false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> adminApproveMerchant(String merchantId) async {
    try {
      isLoading.value = true;
      lastError.value = '';
      lastOk.value = false;

      await api.adminApproveMerchant(merchantId);
      lastOk.value = true;
    } catch (e) {
      lastError.value = ApiDialogs.formatErrorMessage(e);
      lastOk.value = false;
    } finally {
      Future.microtask(() => isLoading.value = false);
    }
  }

  Future<void> adminApproveThirdParty(String userId) async {
    try {
      isLoading.value = true;
      lastError.value = '';
      lastOk.value = false;

      await api.adminApproveThirdParty(userId);
      lastOk.value = true;
    } catch (e) {
      lastError.value = ApiDialogs.formatErrorMessage(e);
      lastOk.value = false;
    } finally {
      Future.microtask(() => isLoading.value = false);
    }
  }

  // ========= UTIL HELPERS =========
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
      }
      lastError.value = ApiDialogs.formatErrorMessage(e);
      lastOk.value = false;
    } finally {
      Future.microtask(() => isLoading.value = false);
    }
  }

  Future<dynamic> getMyPasscode() async {
    try {
      isLoading.value = true;
      lastError.value = '';
      final info = await api.getPasscode();
      return info;
    } catch (e) {
      lastError.value = ApiDialogs.formatErrorMessage(e);
      rethrow;
    } finally {
      Future.microtask(() => isLoading.value = false);
    }
  }

  Future<void> updateMyProfile({
    String? email,
    String? phone,
    String? newPassword, 
      }) async {
    try {
      isLoading.value = true;
      lastError.value = '';
      lastOk.value = false;

      final u = user.value;
      if (u == null) {
        lastError.value = 'No logged-in user';
        return;
      }

      if (isUser && !isMerchant) {
        final payload = <String, dynamic>{};

        if (email != null && email.isNotEmpty) {
          payload['user_email'] = email;
        }
        if (phone != null && phone.isNotEmpty) {
          payload['user_phone_number'] = phone;
        }

        if (payload.isEmpty && (newPassword == null || newPassword.isEmpty)) {
          lastError.value = 'Nothing to update';
          return;
        }
    // TODO: å¦‚æžœä»¥åŽæœ‰ã€Œç”¨æˆ·è‡ªå·±æ”¹å¯†ç ã€çš„ endpointï¼Œå¯ä»¥åœ¨è¿™é‡Œé¡ºä¾¿è°ƒç”¨
        // if (newPassword != null && newPassword.isNotEmpty) {
        //   await api.changeMyPassword(currentPassword: ..., newPassword: newPassword);
        // }

        if (payload.isNotEmpty) {
          final updated = await api.updateUser(u.userId!, payload);
          user.value = updated; 
        }

        lastOk.value = true;
        return;
      }

      if (isMerchant) {
        if (phone == null || phone.isEmpty) {
          lastError.value = 'Merchant phone cannot be empty';
          return;
        }
        final allMerchants = await api.listMerchants();
        Merchant? mine;
        for (final m in allMerchants) {
          if (m.ownerUserId == u.userId) {
            mine = m;
            break;
          }
        }

        if (mine == null) {
          lastError.value = 'Merchant profile not found for this user';
          return;
        }

        final payload = <String, dynamic>{
          'merchant_phone_number': phone,
        };
        await api.updateMerchant(mine.merchantId, payload);
        await refreshMe();

        lastOk.value = true;
        return;
      }

      lastError.value = 'Unsupported role for profile update';
    } catch (e) {
      lastError.value = ApiDialogs.formatErrorMessage(e);
      lastOk.value = false;
    } finally {
      isLoading.value = false;
    }
  }
}
