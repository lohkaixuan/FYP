import 'package:get/get.dart';

// 角色（当前查看的钱包视图）
enum UserRole { user, merchant }

class RoleController extends GetxController {
  // 当前查看的角色（决定看到哪个钱包）
  final Rx<UserRole> currentRole = UserRole.user.obs;

  // 账号是否具备“商家能力”（决定是否显示 subtitle + toggle）
  final RxBool hasMerchant = false.obs;

  // === Actions ===
  void setRole(UserRole role) => currentRole.value = role;
  void setHasMerchant(bool value) => hasMerchant.value = value;

  // 仅当账号具备商家能力时才允许切换
  void toggleRole() {
    if (!hasMerchant.value) return;
    currentRole.value =
        currentRole.value == UserRole.merchant ? UserRole.user : UserRole.merchant;
  }

  // === Getters ===
  UserRole get role => currentRole.value;
  bool get isMerchantView => currentRole.value == UserRole.merchant;

  // 🪝 兼容旧代码（RoleGate 用的是 isMerchant）
  bool get isMerchant => isMerchantView;
}
