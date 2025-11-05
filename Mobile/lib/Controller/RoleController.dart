// lib/Controllers/RoleController.dart
import 'package:get/get.dart';
import 'package:mobile/Auth/authController.dart';
import 'package:mobile/Utils/app_helpers.dart';

class RoleController extends GetxController {
  final roles = <String>{}.obs;        // 已拥有的角色（小写）
  final activeRole = 'user'.obs;       // 当前激活：user | merchant | admin | provider

  // Global identity + wallets
  final userId = ''.obs;
  final userWalletId = ''.obs;         // 个人钱包
  final merchantWalletId = ''.obs;     // 商家钱包（可空）
  final activeWalletId = ''.obs;       // 当前激活角色对应的钱包（只在 user/merchant 下有意义）

  // 便捷 getter
  bool get hasUser => roles.contains('user');
  bool get hasMerchant => roles.contains('merchant');
  bool get hasAdmin => roles.contains('admin');
  bool get hasProvider => roles.contains('provider');

  bool get isUser => activeRole.value == 'user';
  bool get isMerchant => activeRole.value == 'merchant';
  bool get isAdmin => activeRole.value == 'admin';
  bool get isProvider => activeRole.value == 'provider';

  /// 从 Auth 同步（登录/刷新/冷启动后调用）
  void syncFromAuth(AuthController auth) {
    final parsed = AppHelpers.parseRoles(auth.role.value);
    final fixed = AppHelpers.ensureMerchantImpliesUser(parsed);
    roles
      ..clear()
      ..addAll(fixed);
    activeRole.value = AppHelpers.pickDefaultActive(roles);

    // Sync identity + wallet ids from AppUser
    final u = auth.user.value;
    userId.value = (u?.userId ?? '').toString();
    userWalletId.value = (u?.userWalletId ?? u?.walletId ?? '').toString();
    merchantWalletId.value = (u?.merchantWalletId ?? '').toString();
    _recomputeActiveWallet();
  }

  void setActive(String r) {
    final v = r.toLowerCase();
    if (roles.contains(v)) {
      activeRole.value = v;
      _recomputeActiveWallet();
    }
  }

  /// 登录后去哪个初始路由
  String nextInitialRoute() {
    if (hasAdmin) return '/admin';
    if (hasProvider) return '/provider';
    return '/home';
  }

  void _recomputeActiveWallet() {
    // Default to personal wallet
    var current = userWalletId.value;
    if (activeRole.value == 'merchant' && merchantWalletId.value.isNotEmpty) {
      current = merchantWalletId.value;
    }
    activeWalletId.value = current;
  }
}
