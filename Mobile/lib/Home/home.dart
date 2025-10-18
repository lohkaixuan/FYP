import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile/Component/GlobalAppBar.dart';
import 'package:mobile/Role/RoleController.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
final RoleController roleC =  Get.find<RoleController>();

    return Scaffold(
      appBar: GlobalAppBar(
        title: 'Home',
        subtitle: 'Welcome back 👋',
        activeIcon: Icons.people,          // merchant icon
        inactiveIcon: Icons.shopping_cart, // user icon
      ),

      // ✅ 用 Obx 实时更新角色文字
      body: Center(
        child: Obx(() {
          return Text(
            roleC.isMerchant ? 'Merchant' : 'User',
            style: Theme.of(context).textTheme.headlineSmall,
          );
        }),
      ),
    );
  }
}
