import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile/Auth/auth.dart';
import 'package:mobile/Api/apimodel.dart';

class GlobalDrawer extends StatelessWidget {
  const GlobalDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    final cs = Theme.of(context).colorScheme;

    return Obx(() {
      final AppUser? user = auth.user.value;
      final name = user?.userName ?? 'Guest';
      final sub = user?.email ?? user?.phone ?? 'Not logged in';
      final roles = auth.role.value.isEmpty ? '—' : auth.role.value;

      return Drawer(
        child: SafeArea(
          child: Column(
            children: [
              UserAccountsDrawerHeader(
                currentAccountPicture: CircleAvatar(
                  backgroundColor: cs.primaryContainer,
                  child: const Icon(Icons.person),
                ),
                accountName: Text(name),
                accountEmail: Text('$sub   ·   roles: $roles'),
              ),
              ListTile(
                leading: const Icon(Icons.home),
                title: const Text('Home'),
                onTap: () => Get.offAllNamed('/home'),
              ),
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Account'),
                onTap: () => Get.offAllNamed('/account'),
              ),
              ListTile(
                leading: const Icon(Icons.qr_code_scanner),
                title: const Text('Scan / Pay'),
                onTap: () => Get.offAllNamed('/transfer'),
              ),
              const Spacer(),
              ListTile(
                leading: Icon(Icons.logout, color: cs.error),
                title: Text('Logout', style: TextStyle(color: cs.error)),
                onTap: () async {
                  await auth.logout();
                  Get.offAllNamed('/login');
                },
              ),
            ],
          ),
        ),
      );
    });
  }
}

