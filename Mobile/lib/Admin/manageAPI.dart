// ==================================================
// Program Name   : manageAPI.dart
// Purpose        : Admin API management screen
// Developer      : Mr. Loh Kai Xuan 
// Student ID     : TP074510 
// Course         : Bachelor of Software Engineering (Hons) 
// Created Date   : 15 November 2025
// Last Modified  : 4 January 2026 
// ==================================================
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:mobile/Api/apis.dart';
import 'package:mobile/Component/AppTheme.dart'; 
import 'package:mobile/Component/GradientWidgets.dart'; 
import 'package:mobile/Component/GlobalScaffold.dart';
import 'package:mobile/Api/dioclient.dart';

class ManageAPIWidget extends StatefulWidget {
  const ManageAPIWidget({super.key});

  @override
  State<ManageAPIWidget> createState() => _ManageAPIWidgetState();
}

class _ManageAPIWidgetState extends State<ManageAPIWidget> {
  bool _isLoading = false;
  bool _isOnline = false;
  int _latency = 0;
  DateTime _lastChecked = DateTime.now();
  final ApiService _api = Get.find<ApiService>();

  @override
  void initState() {
    super.initState();
    _checkHealth();
  }

  Future<void> _checkHealth() async {
    setState(() {
      _isLoading = true;
    });

    final stopwatch = Stopwatch()..start();
    bool status = false;

    try {
      status = await _api.checkHealth();
    } catch (e) {
      status = false;
    }

    stopwatch.stop();

    if (mounted) {
      setState(() {
        _isOnline = status;
        _latency = stopwatch.elapsedMilliseconds;
        _lastChecked = DateTime.now();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final String formattedDate = DateFormat('hh:mm:ss a').format(_lastChecked);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final txt = theme.textTheme;

    return GlobalScaffold(
      title: 'API Management',
      actions: [
        IconButton(
          onPressed: _isLoading ? null : _checkHealth,
          icon: _isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: cs.onPrimary,
                    strokeWidth: 2,
                  ),
                )
              : Icon(Icons.refresh_rounded, color: cs.onPrimary),
          tooltip: 'Refresh Status',
        ),
        const SizedBox(width: 8),
      ],
      body: Container(
        width: double.infinity,
        height: double.infinity,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Server Status Monitor',
              style: txt.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: cs.onSurface, 
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Last updated: $formattedDate',
              style: txt.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            _buildServerCard(context),
            const SizedBox(height: 24),
            _buildInfoSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildServerCard(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final txt = theme.textTheme;
    final isOnline = _isOnline;
    final statusColor = isOnline ? AppTheme.cSuccess : cs.error;
    final statusText = isOnline ? "OPERATIONAL" : "OFFLINE";
    final icon = isOnline ? Icons.check_circle_rounded : Icons.error_rounded;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppTheme.rMd),
        boxShadow: [
          BoxShadow(
            blurRadius: 10,
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 5),
          )
        ],
        border: Border.all(
          color: statusColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: statusColor, size: 30),
                ),
                const SizedBox(width: 16),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Primary Backend API',
                        style: txt.titleMedium?.copyWith(
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DioClient.baseUrl,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurfaceVariant,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusText,
                    style: txt.labelSmall?.copyWith(
                      color: Colors.white, 
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
            Divider(color: cs.outline.withOpacity(0.2)),
            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetricItem(
                    context, 'Endpoint', '/healthz', Icons.link_rounded),
                _buildMetricItem(
                    context, 'Latency', '${_latency}ms', Icons.speed_rounded,
                    valueColor: _latency > 500 ? Colors.orange : null),
                _buildMetricItem(
                    context, 'Protocol', 'HTTPS', Icons.security_rounded),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildMetricItem(
      BuildContext context, String label, String value, IconData icon,
      {Color? valueColor}) {
    final cs = Theme.of(context).colorScheme;
    final txt = Theme.of(context).textTheme;

    return Column(
      children: [
        GradientIcon(icon, size: 20),
        const SizedBox(height: 8),
        Text(
          value,
          style: txt.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: valueColor ?? cs.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: txt.bodySmall?.copyWith(
            color: cs.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final txt = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceVariant,
        borderRadius: BorderRadius.circular(AppTheme.rSm),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: cs.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "This monitor pings the server's health check endpoint directly. "
              "If the status is OFFLINE, the mobile app may not function correctly. "
              "Please contact the system administrator.",
              style: txt.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
