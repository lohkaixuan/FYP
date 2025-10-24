import 'package:flutter/material.dart';
import 'package:mobile/Merchant/mer_navigation.dart';
import 'package:mobile/Merchant/mer_financial.dart';
import 'package:mobile/Merchant/mer_profile.dart';
import 'package:mobile/Merchant/mer_dashboard.dart';
  
void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: MerchantHomeScreen(),
  ));
}

class MerchantHomeScreen extends StatefulWidget {
  const MerchantHomeScreen({super.key});

  @override
  State<MerchantHomeScreen> createState() => _MerchantHomeState();
}

class _MerchantHomeState extends State<MerchantHomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    MerchantDashboardScreen(), // Dashboard / Home Page
    MerchantReportScreen(), // 报告页
    Placeholder(), // maybe Orders
    ProfilePage(), // 个人资料页
  ];

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: const MerchantQRWidget(),
      bottomNavigationBar: MerchantNavigation(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}
