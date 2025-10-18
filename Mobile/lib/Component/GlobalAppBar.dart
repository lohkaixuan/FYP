import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile/Role/RoleController.dart';

class GlobalAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;             // 可选：如果传了，会优先显示；否则显示角色
  final IconData? activeIcon;         // merchant 图标
  final IconData? inactiveIcon;       // user 图标

  const GlobalAppBar({
    Key? key,
    required this.title,
    this.subtitle,
    this.activeIcon,
    this.inactiveIcon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final RoleController roleC = Get.find<RoleController>();

    return Obx(() {
      final isMerchant = roleC.currentRole.value == UserRole.merchant;
      final roleLabel =
          roleC.currentRole.value == UserRole.merchant ? 'Merchant' : 'User';

      return AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题居中一行
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [ Text(title) ],
            ),
            // ✅ 只有 merchant 才显示副标题；内容显示当前角色（或你自定义的 subtitle）
            if (isMerchant)
              Text(
                subtitle ?? 'Role: $roleLabel',
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
          ],
        ),
        actions: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ✅ 只显示一个图标，点击切换角色；图标随角色变化
              IconButton(
                icon: Icon(
                  isMerchant
                      ? (activeIcon ?? Icons.store)       // 默认给个安全图标
                      : (inactiveIcon ?? Icons.person),
                  color: Colors.purpleAccent,
                ),
                tooltip: isMerchant ? "Switch to User" : "Switch to Merchant",
                onPressed: () {
                  roleC.setRole(
                    isMerchant ? UserRole.user : UserRole.merchant
                  );
                },
              ),
            ],
          ),
        ],
      );
    });
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
