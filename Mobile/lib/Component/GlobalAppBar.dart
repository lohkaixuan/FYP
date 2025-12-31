import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile/Component/AppTheme.dart';
import 'package:mobile/Auth/auth.dart';
import 'package:mobile/Controller/RoleController.dart';

class GlobalAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  const GlobalAppBar({super.key, required this.title, this.actions});

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

      final canPop = Navigator.of(context).canPop();
      return AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        centerTitle: true,
        leading: Builder(
          builder: (ctx) => canPop
              ? IconButton(
                  tooltip: 'Back',
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  onPressed: () => Get.back(),
                )
              : IconButton(
                  tooltip: 'Menu',
                  icon: const Icon(Icons.menu),
                  onPressed: () => Scaffold.of(ctx).openDrawer(),
                ),
        ),
        titleSpacing: 8,
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
          child: Row(
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white, fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 8),

              
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

              
              if (hasUser && hasMerchant)
                PopupMenuButton<String>(
                  tooltip: 'Switch Role',
                  onSelected: roleC.setActive,
                  itemBuilder: (ctx) => const [
                    PopupMenuItem(value: 'user', child: Text('Use as USER')),
                    PopupMenuItem(
                        value: 'merchant', child: Text('Use as MERCHANT')),
                  ],
                  child: const Icon(Icons.swap_horiz),
                ),
            ],
          ),
        ),
        actions: [
          
          if (hasUser && !hasMerchant && !hasAdmin && !hasProvider)
            IconButton(
              tooltip: 'Apply Merchant',
              onPressed: () => Get.toNamed('/merchant-apply'),
              icon: const Icon(Icons.store_mall_directory),
            ),

          
          // if (hasAdmin)
          //   IconButton(
          //     tooltip: 'Admin Panel',
          //     onPressed: () => Get.toNamed(''),
          //     icon: const Icon(Icons.admin_panel_settings),
          //   ),

          
          if (hasProvider)
            IconButton(
              tooltip: 'Provider Dashboard',
              onPressed: () => Get.toNamed('/provider'),
              icon: const Icon(Icons.handshake),
            ),

          ...?actions,
        ],
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.primaryGradient,
          ),
        ),
      );
    });
  }
}
