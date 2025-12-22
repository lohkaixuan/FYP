import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:mobile/Component/AppTheme.dart';
import 'package:mobile/Component/GradientWidgets.dart';
import 'package:mobile/Component/GlobalScaffold.dart';
import 'package:mobile/Controller/adminController.dart';

class AdminDashboardWidget extends StatefulWidget {
  const AdminDashboardWidget({super.key});

  @override
  State<AdminDashboardWidget> createState() => _AdminDashboardWidgetState();
}

class _AdminDashboardWidgetState extends State<AdminDashboardWidget> {
  final AdminController controller = Get.find<AdminController>();

  @override
  void initState() {
    super.initState();
    controller.loadDashboardStats();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final txt = theme.textTheme;

    return GlobalScaffold(
      title: 'Analytics Dashboard',
      body: Container(
        // FIXED: Removed 'color: cs.primary' so it uses the Theme's default background
        width: double.infinity,
        height: double.infinity,
        child: RefreshIndicator(
          onRefresh: () => controller.loadDashboardStats(),
          color: cs.primary,
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(top: 16, bottom: 24),
            child: Obx(() {
              if (controller.isLoadingStats.value) {
                return Center(
                  child: CircularProgressIndicator(color: cs.primary),
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- ROW 1: TOP STATS ---
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            context,
                            value:
                                'RM ${controller.totalVolumeToday.value.toStringAsFixed(0)}',
                            label: "Today's Volume",
                            icon: Icons.attach_money,
                            isMoney: true,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            context,
                            value: '${controller.activeUserCount.value}',
                            label: 'Active Users',
                            icon: Icons.people,
                            isMoney: false,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // --- ROW 2: MONEY FLOW GRAPH ---
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Money Flow (7 Days)',
                          style: txt
                              .titleLarge, // Inherits correct color from Theme
                        ),
                        const SizedBox(height: 12),
                        Container(
                          height: 220,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: cs.surface,
                            borderRadius: BorderRadius.circular(AppTheme.rMd),
                            // Optional: Add subtle border for better contrast in dark mode
                            border: Border.all(
                                color: cs.outline.withOpacity(0.1), width: 1),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            ],
                          ),
                          child: LineChart(
                            LineChartData(
                              lineTouchData: LineTouchData(
                                touchTooltipData: LineTouchTooltipData(
                                  getTooltipColor: (_) => cs.inverseSurface,
                                  getTooltipItems:
                                      (List<LineBarSpot> touchedBarSpots) {
                                    return touchedBarSpots.map((barSpot) {
                                      return LineTooltipItem(
                                        barSpot.y.toStringAsFixed(0),
                                        TextStyle(
                                          color: cs.onInverseSurface,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          fontFamily: 'Outfit',
                                        ),
                                      );
                                    }).toList();
                                  },
                                ),
                              ),
                              gridData: const FlGridData(show: false),
                              titlesData: FlTitlesData(
                                leftTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                topTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                rightTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (val, meta) {
                                      final date = DateTime.now().subtract(
                                          Duration(days: 6 - val.toInt()));
                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(top: 8.0),
                                        child: Text(
                                          DateFormat('E')
                                              .format(date)
                                              .substring(0, 1),
                                          style: txt.labelSmall?.copyWith(
                                            color: cs.onSurfaceVariant,
                                          ),
                                        ),
                                      );
                                    },
                                    interval: 1,
                                  ),
                                ),
                              ),
                              borderData: FlBorderData(show: false),
                              lineBarsData: [
                                LineChartBarData(
                                  spots: controller.weeklySpots.toList(),
                                  isCurved: true,
                                  color: cs.primary,
                                  barWidth: 3,
                                  dotData: const FlDotData(show: false),
                                  belowBarData: BarAreaData(
                                    show: true,
                                    // Make gradient fill slightly more transparent
                                    color: cs.primary.withOpacity(0.1),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // --- ROW 3: CATEGORIES ---
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Spending Categories',
                          style: txt.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        Container(
                          height: 200,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: cs.surface,
                            borderRadius: BorderRadius.circular(AppTheme.rMd),
                            border: Border.all(
                                color: cs.outline.withOpacity(0.1), width: 1),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            ],
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: PieChart(
                                  PieChartData(
                                    sections:
                                        controller.categorySections.toList(),
                                    sectionsSpace: 2,
                                    centerSpaceRadius: 40,
                                  ),
                                ),
                              ),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _legendItem(context, Colors.blue, "Food"),
                                  _legendItem(
                                      context, Colors.orange, "Transport"),
                                  _legendItem(
                                      context, Colors.green, "Shopping"),
                                  _legendItem(context, Colors.purple, "Others"),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // --- ROW 4: RECENT ACTIVITY ---
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Recent Live Activity',
                          style: txt.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        Container(
                          decoration: BoxDecoration(
                            color: cs.surface,
                            borderRadius: BorderRadius.circular(AppTheme.rMd),
                            border: Border.all(
                                color: cs.outline.withOpacity(0.1), width: 1),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            ],
                          ),
                          child: ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: controller.recentTransactions.length,
                            separatorBuilder: (c, i) => Divider(
                              height: 1,
                              indent: 16,
                              endIndent: 16,
                              color: cs.outline.withOpacity(0.5),
                            ),
                            itemBuilder: (context, index) {
                              final tx = controller.recentTransactions[index];

                              final String displayName = (tx.to.trim().isEmpty)
                                  ? 'Unknown Recipient'
                                  : tx.to;

                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: cs.primary.withOpacity(0.1),
                                  child: Icon(
                                    tx.type == 'pay'
                                        ? Icons.shopping_bag
                                        : Icons.swap_horiz,
                                    color: cs.primary,
                                    size: 20,
                                  ),
                                ),
                                title: Text(
                                  displayName,
                                  style: txt.titleSmall,
                                ),
                                subtitle: Text(
                                  tx.type.toUpperCase(),
                                  style: txt.bodySmall?.copyWith(
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                                trailing: Text(
                                  '- RM ${tx.amount.toStringAsFixed(2)}',
                                  style: txt.labelLarge?.copyWith(
                                    color: cs.error,
                                  ),
                                ),
                              );
                            },
                          ),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 80),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String value,
    required String label,
    required IconData icon,
    required bool isMoney,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final txt = theme.textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppTheme.rMd),
        border: Border.all(color: cs.outline.withOpacity(0.1), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          isMoney
              ? GradientIcon(icon, size: 28)
              : Icon(icon, color: cs.secondary, size: 28),
          const SizedBox(height: 12),
          Text(
            value,
            style: txt.headlineMedium?.copyWith(
              color: cs.onSurface,
              fontSize: 22,
            ),
          ),
          Text(label,
              style: txt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _legendItem(BuildContext context, Color color, String text) {
    final txt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(width: 12, height: 12, color: color),
          const SizedBox(width: 8),
          Text(
            text,
            style: txt.labelMedium?.copyWith(color: cs.onSurface),
          ),
        ],
      ),
    );
  }
}
