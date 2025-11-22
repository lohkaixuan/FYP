import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'controller/adminBottomNavController.dart';
import 'adminDashboard.dart';
import 'manageAPI.dart';
import 'manageUser.dart';
import 'registerThridParty.dart';
import 'manageThridParty.dart';

class AdminBottomNavApp extends StatelessWidget {
  const AdminBottomNavApp({super.key});

  @override
  Widget build(BuildContext context) {
    final navController = Get.find<AdminBottomNavController>();

    final pages = <Widget>[
      const AdminDashboardWidget(),
      const ManageAPIWidget(),
      const ManageUserWidget(),
      const RegisterProviderWidget(),
      const ManageProviderWidget(),
    ];

    final navItems = <BottomNavigationBarItem>[
      const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Dashboard'),
      const BottomNavigationBarItem(icon: Icon(Icons.api), label: 'Manage API'),
      const BottomNavigationBarItem(icon: Icon(Icons.group), label: 'Users'),
      const BottomNavigationBarItem(
          icon: Icon(Icons.person_add), label: 'Register 3rd'),
      const BottomNavigationBarItem(
          icon: Icon(Icons.manage_accounts), label: 'Manage 3rd'),
    ];

    return Obx(() {
      final theme = Theme.of(context);
      final int idx = navController.selectedIndex.value;
      final safeIndex = idx.clamp(0, pages.length - 1);

      return Scaffold(
        body: pages[safeIndex],
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: theme.bottomNavigationBarTheme.backgroundColor ??
                theme.colorScheme.surface,
            boxShadow: const [
              BoxShadow(
                  color: Colors.black12, blurRadius: 6, offset: Offset(0, -1)),
            ],
          ),
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            backgroundColor: theme.bottomNavigationBarTheme.backgroundColor ??
                theme.colorScheme.surface,
            currentIndex: safeIndex,
            onTap: navController.changeIndex,
            items: navItems,
            selectedItemColor:
                theme.bottomNavigationBarTheme.selectedItemColor ??
                    theme.colorScheme.primary,
            unselectedItemColor:
                theme.bottomNavigationBarTheme.unselectedItemColor ??
                    theme.colorScheme.onSurfaceVariant,
            selectedLabelStyle:
                const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            unselectedLabelStyle:
                const TextStyle(fontSize: 11, fontWeight: FontWeight.w400),
            showUnselectedLabels:
                theme.bottomNavigationBarTheme.showUnselectedLabels ?? true,
            elevation: 0,
          ),
        ),
      );
    });
  }
}
