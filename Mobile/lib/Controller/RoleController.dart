// lib/Controllers/RoleController.dart
import 'package:get/get.dart';
import 'package:mobile/Controller/auth.dart';
import 'package:mobile/Utils/app_helpers.dart';

class RoleController extends GetxController {
<<<<<<< HEAD
  final roles = <String>{}.obs;        
  final activeRole = 'user'.obs;       

  // Global identity + wallets
  final userId = ''.obs;
  final userWalletId = ''.obs;         
  final merchantWalletId = ''.obs;     
  final activeWalletId = ''.obs;       
=======
  final roles = <String>{}.obs; // 已拥有的角色（小写）
  final activeRole = 'user'.obs; // 当前激活：user | merchant | admin | provider

  // Global identity + wallets
  final userId = ''.obs;
  final userWalletId = ''.obs; // 个人钱包
  final merchantWalletId = ''.obs; // 商家钱包（可空）
  final activeWalletId = ''.obs; // 当前激活角色对应的钱包（只在 user/merchant 下有意义）
>>>>>>> 4cec63ed80e44df6bfced19a3befc5329bd1b3f1

  
  bool get hasUser => roles.contains('user');
  bool get hasMerchant => roles.contains('merchant');
  bool get hasAdmin => roles.contains('admin');
  bool get hasProvider => roles.contains('provider');

  bool get isUser => activeRole.value == 'user';
  bool get isMerchant => activeRole.value == 'merchant';
  bool get isAdmin => activeRole.value == 'admin';
  bool get isProvider => activeRole.value == 'provider';

  
  void syncFromAuth(AuthController auth, {bool preferDefaultRole = false}) {
    //fix bug
    final rawRole = auth.role.value;
    print('🚨 DEBUG RAW ROLE FROM SERVER: $rawRole');

    final parsed = AppHelpers.parseRoles(auth.role.value);
    final fixed = AppHelpers.ensureMerchantImpliesUser(parsed);
    roles
      ..clear()
      ..addAll(fixed);
    if (preferDefaultRole) {
      activeRole.value = AppHelpers.pickDefaultActive(roles);
    }

    
    if (activeRole.value == 'user') {
      if (rawRole.toLowerCase().contains('provider') ||
          rawRole.toLowerCase().contains('thirdparty')) {
        print('🚨 DEBUG: Forcing Active Role to PROVIDER');
        activeRole.value = 'provider';
        roles.add('provider');
      }
    }

    print('✅ Final Active Role: ${activeRole.value}');

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

  
  String nextInitialRoute() {
    if (hasAdmin) return '/admin';
    if (hasProvider) return '/provider';
    return '/home';
  }

  // Active wallet id based on current role
  String get walletId => isMerchant && merchantWalletId.value.isNotEmpty
      ? merchantWalletId.value
      : userWalletId.value;

  void _recomputeActiveWallet() {
    // Default to personal wallet
    var current = userWalletId.value;
    if (activeRole.value == 'merchant' && merchantWalletId.value.isNotEmpty) {
      current = merchantWalletId.value;
    }
    activeWalletId.value = current;
  }
}
