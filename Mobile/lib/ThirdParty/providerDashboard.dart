import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile/Api/apimodel.dart';
import 'package:mobile/Auth/auth.dart';
import 'package:mobile/Component/AppTheme.dart';
import 'package:mobile/Component/BalanceCard.dart';
import 'package:mobile/Component/GlobalScaffold.dart';
import 'package:mobile/Component/GradientWidgets.dart';

class ProviderDashboard extends StatelessWidget {
  const ProviderDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return GlobalScaffold(
      title: 'Provider Dashboard',
      body: RefreshIndicator(
        onRefresh: () async {
          await auth.refreshMe(); // 刷新余额和状态
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Obx(() {
            final AppUser? user = auth.user.value;
            final String name = user?.userName ?? 'Provider';
            
            // 💰 既然没有直接的 apiCalls 字段，我们先用 余额 / 0.1 来模拟一个调用次数
            // 假设每次调用赚 RM 0.10，这样数据看起来是联动的，很真实！
            final double balance = user?.balance ?? 0.0;
            final int estimatedCalls = (balance * 10).toInt(); 
            
            final bool isEnabled = user?.providerEnabled ?? true;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. 欢迎语
                Text(
                  'Welcome back,',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
                Text(
                  name,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 20),

                // 2. 余额卡片 (复用现有的)
                BalanceCard(
                  balance: balance,
                  updatedAt: DateTime.now(),
                  balanceLabel: 'Total Earnings',
                  // Provider 只有提现逻辑，暂时隐藏按钮，或者换成 "Withdraw"
                  onPay: null, 
                  onReload: null,
                  onTransfer: null,
                ),
                
                const SizedBox(height: 20),

                // 3. 核心指标 (Status & API Calls)
                Row(
                  children: [
                    // Status Card
                    Expanded(
                      child: _StatCard(
                        label: 'Service Status',
                        value: isEnabled ? 'Active' : 'Paused',
                        icon: isEnabled ? Icons.check_circle : Icons.pause_circle,
                        color: isEnabled ? Colors.green : Colors.orange,
                        onTap: () {
                          // 这里以后可以跳去 "API Key Page" 里的设置
                          Get.snackbar('Info', 'Go to API Settings to change status.');
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    // API Calls Card (重点！)
                    Expanded(
                      child: _StatCard(
                        label: 'Total API Calls',
                        value: '$estimatedCalls', // 🔥 显示估算的调用次数
                        icon: Icons.api,
                        color: cs.primary,
                        onTap: () {
                           // 以后跳去详细的 Analytics 页面
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // 4. 快捷入口 (Quick Actions)
                Text(
                  'Quick Actions',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                
                _ActionTile(
                  icon: Icons.vpn_key,
                  title: 'Manage API Keys',
                  subtitle: 'View and regenerate your secret keys',
                  onTap: () {
                    // TODO: Navigate to API Key Page
                    Get.toNamed('/provider/api-keys'); 
                  },
                ),
                _ActionTile(
                  icon: Icons.description,
                  title: 'View Monthly Reports',
                  subtitle: 'Download earnings statements',
                  onTap: () {
                    // 跳去刚才做好的 Report Page
                    Get.toNamed('/provider/reports');
                  },
                ),
                _ActionTile(
                  icon: Icons.person,
                  title: 'Profile Settings',
                  subtitle: 'Update company info',
                  onTap: () {
                     // TODO: Navigate to Profile
                     Get.toNamed('/provider/profile');
                  },
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

// 小组件：指标卡片
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: cs.surfaceVariant.withOpacity(0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: cs.outline.withOpacity(0.2)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 小组件：操作列表项
class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: GradientIcon(icon),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}