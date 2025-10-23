import 'package:flutter/material.dart';
import 'package:mobile/Users/appbar.dart';
import 'package:mobile/Users/dashboard_nav.dart';
import 'package:mobile/Users/financial_report.dart';
import 'package:mobile/Users/navigation.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeState();
}

class _HomeState extends State<HomeScreen> {
  bool _isToggled = false; // State variable for toggle switch
  int _selectedIndex_navigation = 0; // State variable for selected navigation index

  // Function to handle toggle switch changes
  void _handleToggle(bool value) {
    setState(() {
      _isToggled = value;
    });
  }

  // List of screens corresponding to each navigation item
  final List<Widget> _screens = <Widget>[
    const DashboardNavigation(),
    const Placeholder(),
    const FinancialReportScreen(),
    const Placeholder(),
    // TODO: Add other screen widgets here
    // Placeholder widgets for different screens
    // Index 4 for QR Scanner screen
  ];

  // Function to handle navigation item taps
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex_navigation = index;
      debugPrint("Index: $_selectedIndex_navigation");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: MyAppBar(isToggled: _isToggled, onToggle: _handleToggle),
        body: IndexedStack(
          index: _selectedIndex_navigation,
          children: _screens,
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: const QRWidget(),
        bottomNavigationBar: MyNavigation(selectedIndex: _selectedIndex_navigation, onItemTapped: _onItemTapped,),
      );
  }
}
