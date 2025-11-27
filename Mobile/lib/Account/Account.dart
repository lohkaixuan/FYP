import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile/Api/apimodel.dart';
import 'package:mobile/Component/GlobalScaffold.dart';
import 'package:mobile/Auth/auth.dart';
import 'package:mobile/Controller/RoleController.dart';

class Account extends StatelessWidget {
  const Account({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    final roleC = Get.find<RoleController>();
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return GlobalScaffold(
      title: 'Account',
      body: Obx(() {
        final AppUser? u = auth.user.value;

        // 🧍 Use AppUser directly from AuthController
        final name = u?.userName ?? 'User';
        final email = u?.email?? '-';
        final phone = u?.phone ?? '-';
        final userId = u?.userId ?? auth.newlyCreatedUserId.value;
        final isUserOnly = auth.isUser && !auth.isMerchant && !auth.isAdmin && !auth.isProvider;

        return RefreshIndicator(
          onRefresh: () async {
            await auth.refreshMe();
            Get.find<RoleController>().syncFromAuth(auth);
          },
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const SizedBox(height: 8),
              Text('Hello, $name', style: theme.textTheme.titleLarge),
              const SizedBox(height: 6),
              Text('Account Screen', style: theme.textTheme.bodyMedium),
              const SizedBox(height: 16),

              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // _kv('User ID', userId.isEmpty ? '-' : userId),
                      // const SizedBox(height: 8),
                      _kv('Email', email),
                      const SizedBox(height: 8),
                      _kv('Phone', phone),
                      const SizedBox(height: 8),
                      _kv('Active Role', roleC.activeRole.value.toUpperCase()),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              if (isUserOnly)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.store_mall_directory),
                    label: const Text('Apply to be a Merchant'),
                    onPressed: () => Get.toNamed('/signup'),
                  ),
                ),

              if (!isUserOnly)
                Text(
                  'Merchant features enabled or pending approval.',
                  style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),

              const SizedBox(height: 40),
              FilledButton.tonalIcon(
                onPressed: () async {
                  await auth.refreshMe();
                  Get.find<RoleController>().syncFromAuth(auth);
                  Get.snackbar('Refreshed', 'Profile reloaded');
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh Profile (/me)'),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _kv(String k, String v) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 110, child: Text('$k:', style: const TextStyle(fontWeight: FontWeight.bold))),
        Expanded(child: Text(v)),
      ],
    );
  }
}
