import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile/Component/GlobalScaffold.dart'; // 1. Import GlobalScaffold

class AdminDashboardWidget extends StatefulWidget {
  const AdminDashboardWidget({super.key});

  @override
  State<AdminDashboardWidget> createState() => _AdminDashboardWidgetState();
}

class _AdminDashboardWidgetState extends State<AdminDashboardWidget> {
  String _selectedRange = '7D';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    // 2. Use GlobalScaffold instead of Scaffold
    return GlobalScaffold(
      title: 'Analytics Dashboard', // Sets the App Bar title

      // 3. Wrap body in a Container with primary color to keep your Blue background design
      body: Container(
        color: cs.primary,
        width: double.infinity,
        height: double.infinity,
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.only(top: 16, bottom: 24), // Add some spacing
          child: Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- OLD HEADER ROW REMOVED (Title & Logout are now in GlobalScaffold/Drawer) ---

              // 4. Your existing Stats Cards
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(24, 0, 24, 0),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        value: '1,247',
                        label: 'Today',
                        valueColor: const Color(0xFF105DFB),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        value: '28,456',
                        label: 'This Month',
                        valueColor: const Color(0xFF02CA79),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        value: '342K',
                        label: 'This Year',
                        valueColor: const Color(0xFFEE8B60),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 5. New User Growth Section
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(24, 0, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'New User Growth',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.white),
                        ),
                        // Chip Selector
                        Row(
                          children: [
                            _buildChoiceChip('7D'),
                            const SizedBox(width: 8),
                            _buildChoiceChip('30D'),
                            const SizedBox(width: 8),
                            _buildChoiceChip('90D'),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Center(
                          // Using Icon as placeholder if image fails or for cleaner demo
                          child: Image.network(
                            'https://images.unsplash.com/photo-1692859415442-94eabe7a7488?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w0NTYyMDF8MHwxfHJhbmRvbXx8fHx8fHx8fDE3NjI5NDIyNTd8&ixlib=rb-4.1.0&q=80&w=1080',
                            width: double.infinity,
                            height: 160,
                            fit: BoxFit.cover,
                            errorBuilder: (c, o, s) => const Icon(
                                Icons.bar_chart,
                                size: 50,
                                color: Colors.grey),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 6. Monthly Overview Section
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(24, 0, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Monthly Overview',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      height: 250,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: PageView(
                          children: [
                            _buildMonthlyPage(
                                'January 2024', '+12.5%', '2,847', '1,923'),
                            _buildMonthlyPage(
                                'February 2024', '+8.3%', '3,124', '2,156'),
                            _buildMonthlyPage(
                                'March 2024', '+15.7%', '3,567', '2,489'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(
                  height: 80), // Extra space for scrolling above bottom nav
            ],
          ),
        ),
      ),
    );
  }

  // Helper Widget for Stats to keep code clean
  Widget _buildStatCard(
      {required String value,
      required String label,
      required Color valueColor}) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: valueColor),
          ),
          Text(
            label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF5A5C60)),
          ),
        ],
      ),
    );
  }

  // Helper for Choice Chips
  Widget _buildChoiceChip(String label) {
    final isSelected = _selectedRange == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedRange = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF105DFB) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                isSelected ? const Color(0xFF105DFB) : const Color(0xFFE6E6E6),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF5A5C60),
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  // Helper for Monthly Page View
  Widget _buildMonthlyPage(
      String month, String growth, String peak, String avg) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                month,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87),
              ),
              Text(
                growth,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF02CA79)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Container(
              color: Colors.grey[100],
              width: double.infinity,
              child: const Center(
                  child: Icon(Icons.show_chart, size: 40, color: Colors.grey)),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Peak: $peak users',
                  style:
                      const TextStyle(fontSize: 12, color: Color(0xFF5A5C60))),
              Text('Avg: $avg users',
                  style:
                      const TextStyle(fontSize: 12, color: Color(0xFF5A5C60))),
            ],
          ),
        ],
      ),
    );
  }
}
