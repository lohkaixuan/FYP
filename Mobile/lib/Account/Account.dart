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
        final bool hasMerchantAccount = roleC.hasMerchant;
        final name = u?.userName ?? 'User';
        final email = u?.email ?? '-';
        final phone = u?.phone ?? '-';
        final userId = u?.userId ?? auth.newlyCreatedUserId.value;

        // 👉 读 pending 状态
        final bool isPending = auth.merchantPending.value;

        // 👉 只有纯 user 且也没有 pending 申请，才算 "可以申请商家"
        final bool isUserOnly = auth.isUser &&
            !auth.isMerchant &&
            !auth.isAdmin &&
            !auth.isProvider &&
            !isPending;

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
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                    onPressed: () => Get.toNamed('/merchant-apply'),
                  ),
                ),

              /// 1. 个人资料按钮 (My Profile - Personal)
              const SizedBox(height: 40),
              FilledButton.tonalIcon(
                // 👇 改成跳去查看页 (UserProfilePage)
                onPressed: () => Get.toNamed('/account/profile'), 
                icon: const Icon(Icons.person),
                label: const Text('My Profile (Personal)'),
              ),

              const SizedBox(height: 12),
              // 2️⃣ 如果已经有 merchant account
              if (hasMerchantAccount) 
                FilledButton.tonalIcon(
                  onPressed: () => Get.toNamed('/account/merchant-profile'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.orange.shade100,
                    foregroundColor: Colors.orange.shade900,
                  ),
                  icon: const Icon(Icons.store),
                  label: const Text('Merchant Profile (Shop)'),
                ),

              // 🟡 已申请，等待审核：这时候按钮已经不会出现，只显示这行文字
              if (isPending)
                Text(
                  'Your merchant application is pending admin approval.',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: cs.onSurfaceVariant),
                ),

              // 3️⃣ 如果已经是 merchant（admin 批准后）
              if (!isUserOnly && !isPending)
                Text(
                  'Merchant features enabled.',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: cs.onSurfaceVariant),
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
        SizedBox(
            width: 110,
            child: Text('$k:',
                style: const TextStyle(fontWeight: FontWeight.bold))),
        Expanded(child: Text(v)),
      ],
    );
  }
}
