import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart'; // Ensure you have intl package or format manually
import 'package:mobile/Api/apis.dart';
import 'package:mobile/Component/GlobalScaffold.dart';

class ManageAPIWidget extends StatefulWidget {
  const ManageAPIWidget({super.key});

  @override
  State<ManageAPIWidget> createState() => _ManageAPIWidgetState();
}

class _ManageAPIWidgetState extends State<ManageAPIWidget> {
  // State variables
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
      // Call the new method in ApiService
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
    // Formatting date
    final String formattedDate = DateFormat('hh:mm:ss a').format(_lastChecked);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return GlobalScaffold(
      title: 'API Management',
      actions: [
        // Icon Refresh Button
        IconButton(
          onPressed: _isLoading ? null : _checkHealth,
          icon: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Icon(Icons.refresh_rounded, color: Colors.white),
          tooltip: 'Refresh Status',
        ),
        const SizedBox(width: 8),
      ],
      body: Container(
        color: cs.primary, // Light grey background
        width: double.infinity,
        height: double.infinity,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Server Status Monitor',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Last updated: $formattedDate',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),

            // Server Node Card
            _buildServerCard(context),

            const SizedBox(height: 24),

            // Informational / "Not Empty" filler
            _buildInfoSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildServerCard(BuildContext context) {
    // final theme = Theme.of(context);
    final isOnline = _isOnline;
    final color = isOnline ? const Color(0xFF02CA79) : const Color(0xFFFF5963);
    final statusText = isOnline ? "OPERATIONAL" : "OFFLINE";
    final icon = isOnline ? Icons.check_circle_rounded : Icons.error_rounded;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            blurRadius: 10,
            color: const Color(0xFF101213).withOpacity(0.05),
            offset: const Offset(0, 5),
          )
        ],
        border: Border.all(
          color: isOnline
              ? Colors.green.withOpacity(0.2)
              : Colors.red.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Row starts here
            Row(
              children: [
                // 1. Status Icon
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 30),
                ),
                const SizedBox(width: 16),

                // 2. Text Info (Wrapped in Expanded to prevent overflow)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Primary Backend API',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'https://fyp-1-izlh.onrender.com',
                        maxLines: 1, // Ensure single line
                        overflow: TextOverflow.ellipsis, // Add ... if too long
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // 3. Status Badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10, // Slightly smaller to save space
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
            // Row ends here

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),

            // Metrics Row (Unchanged)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetricItem('Endpoint', '/healthz', Icons.link_rounded),
                _buildMetricItem(
                    'Latency', '${_latency}ms', Icons.speed_rounded,
                    valueColor: _latency > 500 ? Colors.orange : Colors.black),
                _buildMetricItem('Protocol', 'HTTPS', Icons.security_rounded),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildMetricItem(String label, String value, IconData icon,
      {Color? valueColor}) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: valueColor ?? Colors.black,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE0E3E7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: Colors.grey),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              "This monitor pings the server's health check endpoint directly. "
              "If the status is OFFLINE, the mobile app may not function correctly. "
              "Please contact the system administrator.",
              style: TextStyle(
                color: Color(0xFF57636C),
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
