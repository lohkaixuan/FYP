// lib/Component/GlobalAppBar.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile/Auth/authcontroller.dart';
import 'package:mobile/Controller/RoleController.dart';

class GlobalAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  const GlobalAppBar({super.key, required this.title});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    final roleC = Get.find<RoleController>();
    final cs = Theme.of(context).colorScheme;

    return Obx(() {
      final hasUser = roleC.hasUser;
      final hasMerchant = roleC.hasMerchant;
      final hasAdmin = roleC.hasAdmin;
      final hasProvider = roleC.hasProvider;

      return AppBar(
        titleSpacing: 8,
        title: Row(
          children: [
            Text(title),
            const SizedBox(width: 8),

            // 🏷 当前激活角色徽章
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: cs.secondaryContainer,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                roleC.activeRole.value.toUpperCase(),
                style: TextStyle(
                  color: cs.onSecondaryContainer,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            const SizedBox(width: 6),

            // 🔁 只有商家用户可以切换 (User <-> Merchant)
            if (hasUser && hasMerchant)
              PopupMenuButton<String>(
                tooltip: 'Switch Role',
                onSelected: roleC.setActive,
                itemBuilder: (ctx) => const [
                  PopupMenuItem(value: 'user', child: Text('Use as USER')),
                  PopupMenuItem(value: 'merchant', child: Text('Use as MERCHANT')),
                ],
                child: const Icon(Icons.swap_horiz),
              ),
          ],
        ),

        actions: [
          // 🧾 仅当是纯用户（没有其他角色）时显示 “申请成为商户”
          if (hasUser && !hasMerchant && !hasAdmin && !hasProvider)
            IconButton(
              tooltip: 'Apply Merchant',
              onPressed: () => Get.toNamed('/merchant-apply'),
              icon: const Icon(Icons.store_mall_directory),
            ),

          // 🧑‍💼 管理员入口
          if (hasAdmin)
            IconButton(
              tooltip: 'Admin Panel',
              onPressed: () => Get.toNamed('/admin'),
              icon: const Icon(Icons.admin_panel_settings),
            ),

          // 🤝 服务商入口
          if (hasProvider)
            IconButton(
              tooltip: 'Provider Dashboard',
              onPressed: () => Get.toNamed('/provider'),
              icon: const Icon(Icons.handshake),
            ),
        ],
      );
    });
  }
}
