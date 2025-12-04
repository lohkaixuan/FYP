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
        final name = u?.userName ?? 'User';
        final email = u?.email ?? '-';
        final phone = u?.phone ?? '-';

        // 1. 获取身份状态
        final bool hasMerchantAccount = roleC.hasMerchant;
        final bool isProvider = roleC.isProvider; // 🔥 必须获取这个状态
        final bool isPending = auth.merchantPending.value;

        // 2. 判断是否显示“申请商家”按钮
        // 条件：是普通用户 + 没商家资格 + 不是管理员 + 不是Provider + 没在审核中
        final bool showApplyButton = auth.isUser &&
            !hasMerchantAccount &&
            !auth.isAdmin &&
            !isProvider && 
            !isPending;

        return RefreshIndicator(
          onRefresh: () async {
            await auth.refreshMe();
            roleC.syncFromAuth(auth);
          },
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const SizedBox(height: 8),
              Text('Hello, $name', style: theme.textTheme.titleLarge),
              const SizedBox(height: 6),
              Text('Account Screen', style: theme.textTheme.bodyMedium),
              const SizedBox(height: 16),

              // 基本信息卡片
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

              // 🟢 1. 申请商家按钮 (Provider 看不到)
              if (showApplyButton)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.store_mall_directory),
                    label: const Text('Apply to be a Merchant'),
                    onPressed: () => Get.toNamed('/merchant-apply'),
                  ),
                ),

              const SizedBox(height: 40),

              // 🔵 2. 个人资料按钮 (所有人可见)
              FilledButton.tonalIcon(
                onPressed: () => Get.toNamed('/account/profile'),
                icon: const Icon(Icons.person),
                label: const Text('My Profile (Personal)'),
              ),

              const SizedBox(height: 12),

              // 🟠 3. 商家资料按钮 (只有真正的商家可见，Provider 看不到)
              if (hasMerchantAccount && !isProvider)
                FilledButton.tonalIcon(
                  onPressed: () => Get.toNamed('/account/merchant-profile'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.orange.shade100,
                    foregroundColor: Colors.orange.shade900,
                  ),
                  icon: const Icon(Icons.store),
                  label: const Text('Merchant Profile (Shop)'),
                ),

              // 🟡 4. 审核中提示 (Provider 看不到)
              if (isPending && !isProvider)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    'Your merchant application is pending admin approval.',
                    style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ),

              // 🟢 5. 商家功能已开启提示 (只有商家可见，Provider 绝对看不到)
              // 这里加了 !isProvider 锁死
              if (hasMerchantAccount && !isProvider)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    'Merchant features enabled.',
                    style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ),

              const SizedBox(height: 40),

              // 🔄 刷新按钮
              FilledButton.tonalIcon(
                onPressed: () async {
                  await auth.refreshMe();
                  roleC.syncFromAuth(auth);
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
            child: Text('$k:', style: const TextStyle(fontWeight: FontWeight.bold))),
        Expanded(child: Text(v)),
      ],
    );
  }
}