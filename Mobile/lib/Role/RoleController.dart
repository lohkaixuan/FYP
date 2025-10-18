import 'package:get/get.dart';

// 🧠 定义角色枚举
enum UserRole { user, merchant }

class RoleController extends GetxController {
  // ✅ 当前角色（可监听）
  final Rx<UserRole> currentRole = UserRole.user.obs;

  // ✅ 设置角色
  void setRole(UserRole role) {
    currentRole.value = role;
  }

  // ✅ 获取当前角色
  UserRole get role => currentRole.value;

  // ✅ 判断是否商家
  bool get isMerchant => currentRole.value == UserRole.merchant;
}
