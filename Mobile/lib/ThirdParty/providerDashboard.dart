import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile/Api/apimodel.dart';
import 'package:mobile/Auth/auth.dart';
import 'package:mobile/Component/AppTheme.dart';
import 'package:mobile/Component/BalanceCard.dart';
import 'package:mobile/Component/GlobalScaffold.dart';
import 'package:mobile/Component/GradientWidgets.dart';
import 'package:fl_chart/fl_chart.dart';

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
            final user = auth.user.value;
            final name = user?.userName ?? 'Provider';
            final double base = (user?.balance ?? 0.0) == 0.0 ? 200.0 : (user?.balance ?? 200.0);
            final double seed = base / 10;
            final int totalCalls = (seed * 50).toInt();

            final bool isEnabled = user?.providerEnabled ?? true;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Header (稍微紧凑一点)
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: cs.primaryContainer,
                      child: Text(name[0].toUpperCase(),
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: cs.onPrimaryContainer)),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Welcome back,',
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: cs.onSurfaceVariant)),
                        Text(name,
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const Spacer(),
                    // 状态标签
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border:
                            Border.all(color: Colors.green.withOpacity(0.5)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.circle, size: 8, color: Colors.green),
                          SizedBox(width: 6),
                          Text('System Online',
                              style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // 🔥 2. 升级版 API Chart
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Traffic Overview',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('Last 7 Days',
                        style: TextStyle(
                            color: cs.onSurfaceVariant, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 12),

                Container(
                  height: 240,
                  padding: const EdgeInsets.fromLTRB(10, 24, 24, 10),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: cs.outlineVariant.withOpacity(0.3)), // 细微边框
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4))
                    ],
                  ),
                  child: LineChart(
                    LineChartData(
                      // ✨ 改动1: 打开网格线，看起来更专业
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: true,
                        horizontalInterval: 1,
                        verticalInterval: 1,
                        getDrawingHorizontalLine: (value) => FlLine(
                            color: cs.outlineVariant.withOpacity(0.1),
                            strokeWidth: 1),
                        getDrawingVerticalLine: (value) => FlLine(
                            color: cs.outlineVariant.withOpacity(0.1),
                            strokeWidth: 1),
                      ),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              const days = [
                                'Mon',
                                'Tue',
                                'Wed',
                                'Thu',
                                'Fri',
                                'Sat',
                                'Sun'
                              ];
                              if (value.toInt() >= 0 &&
                                  value.toInt() < days.length) {
                                return Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(days[value.toInt()],
                                        style: TextStyle(
                                            fontSize: 10,
                                            color: cs.onSurfaceVariant)));
                              }
                              return const SizedBox();
                            },
                            interval: 1,
                          ),
                        ),
                        leftTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false)), // 保持简洁
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: [
                            FlSpot(0, seed * 0.5),
                            FlSpot(1, seed * 1.5),
                            FlSpot(2, seed * 0.8),
                            FlSpot(3, seed * 2.0),
                            FlSpot(4, seed * 1.2),
                            FlSpot(5, seed * 0.4),
                            FlSpot(6, seed * 0.9),
                          ],
                          isCurved: true,
                          color: cs.primary,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            // ✨ 改动2: 渐变色填充
                            gradient: LinearGradient(
                              colors: [
                                cs.primary.withOpacity(0.3),
                                cs.primary.withOpacity(0.0),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // 3. 核心指标 (横排显示，稍微小一点)
                Row(
                  children: [
                    Expanded(
                      child: _SmallStat(
                        label: 'Requests',
                        value: '$totalCalls',
                        icon: Icons.cloud_upload_outlined,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SmallStat(
                        label: 'Success %',
                        value: '99.8%',
                        icon: Icons.check_circle_outline,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SmallStat(
                        label: 'Avg Latency',
                        value: '45ms', // 模拟数据
                        icon: Icons.speed,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),
                // 🔥 4. 新增：最近日志 (Recent Logs)
                // 这块内容加上去，页面马上就不空了！
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Recent Logs',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    TextButton(onPressed: () {}, child: const Text('View All'))
                  ],
                ),
                _LogItem(
                    method: 'POST',
                    path: '/api/wallet/pay',
                    status: 200,
                    time: '2 mins ago'),
                _LogItem(
                    method: 'GET',
                    path: '/api/users/me',
                    status: 200,
                    time: '5 mins ago'),
                _LogItem(
                    method: 'POST',
                    path: '/api/wallet/transfer',
                    status: 400,
                    time: '12 mins ago'), // 模拟一个失败

                const SizedBox(height: 24),

                // 5. Quick Actions
                const Text('Management',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),

                // 复用你的 ActionTile
                _ActionTile(
                  icon: Icons.vpn_key,
                  title: 'API Keys',
                  subtitle: 'Credentials & Security',
                  onTap: () => Get.toNamed('/provider/api-key'),
                ),
                _ActionTile(
                  icon: Icons.analytics,
                  title: 'Reports',
                  subtitle: 'Monthly statements',
                  onTap: () => Get.toNamed('/provider/reports'),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

// ✨ 新增：更紧凑的指标卡片
class _SmallStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _SmallStat(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 8),
          Text(value,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Text(label,
              style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }
}

// 📋 补上这个丢失的类定义
class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionTile({
    super.key,
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
        // 注意：这里用到了 GradientIcon，确保你头部 import 了 GradientWidgets.dart
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

// ✨ 新增：日志条目 Mock
class _LogItem extends StatelessWidget {
  final String method;
  final String path;
  final int status;
  final String time;

  const _LogItem(
      {required this.method,
      required this.path,
      required this.status,
      required this.time});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isSuccess = status >= 200 && status < 300;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isSuccess
                  ? Colors.green.withOpacity(0.1)
                  : Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text('$status',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isSuccess ? Colors.green : Colors.red)),
          ),
          const SizedBox(width: 10),
          Text(method,
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Expanded(
              child: Text(path,
                  style: const TextStyle(fontSize: 12, fontFamily: 'Monospace'),
                  overflow: TextOverflow.ellipsis)),
          Text(time,
              style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }
}
