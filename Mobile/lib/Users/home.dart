import 'package:flutter/material.dart';
import 'package:mobile/Component/AppBar.dart';
import 'package:mobile/Users/AppBar.dart'; // 👈 your ToggleAppBar file

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isToggled = false;

  void _handleToggle(bool value) {
    setState(() => _isToggled = value);
    // 👉 You can also trigger theme changes or logic here
    // Example: Get.changeThemeMode(value ? ThemeMode.dark : ThemeMode.light);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ✅ Using your custom AppBar
      appBar: ToggleAppBar(
        title: 'Home',
        subtitle: 'Welcome back 👋',
        value: _isToggled,
        onChanged: _handleToggle,
        activeIcon: Icons.dark_mode_rounded,
        inactiveIcon: Icons.light_mode_rounded,
      ),

      body: Center(
        child: Text(
          _isToggled
              ? 'User'
              : 'Merchant',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
    );
  }
}
