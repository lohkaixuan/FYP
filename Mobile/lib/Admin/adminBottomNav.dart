import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'controller/adminBottomNavController.dart';
import 'adminDashboard.dart';
import 'manageAPI.dart';
import 'manageUser.dart';
import 'registerThridParty.dart';
import 'manageThridParty.dart';
import 'manageMerchant.dart';

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

    const nestedId = 1; // Nested navigator id

    // Map index -> bottom nav route
    final indexToRoute = {
      0: '/admin/dashboard',
      1: '/admin/manage-api',
      2: '/admin/manage-users',
      3: '/admin/register-third-party',
      4: '/admin/manage-third-party',
    };

    return Obx(() {
      final theme = Theme.of(context);
      final int idx = navController.selectedIndex.value;
      final safeIndex = idx.clamp(0, pages.length - 1);

      return Scaffold(
        body: Navigator(
          key: Get.nestedKey(nestedId),
          initialRoute: '/admin/dashboard',
          onGenerateRoute: (settings) {
            Widget page;
            switch (settings.name) {
              case '/admin/dashboard':
                page = pages[0];
                break;
              case '/admin/manage-api':
                page = pages[1];
                break;
              case '/admin/manage-users':
                page = pages[2];
                break;
              case '/admin/register-third-party':
                page = pages[3];
                break;
              case '/admin/manage-third-party':
                page = pages[4];
                break;
              case '/admin/merchantManagement': // extra page not in bottom nav
                page = const ManageMercahntWidget();
                break;
              default:
                page = pages[safeIndex];
            }
            return MaterialPageRoute(builder: (_) => page, settings: settings);
          },
        ),
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: safeIndex,
          onTap: (i) {
            navController.changeIndex(i);
            final route = indexToRoute[i] ?? '/admin/dashboard';
            Get.offNamed(route,
                id: nestedId); // navigate within nested navigator
          },
          items: navItems,
          selectedItemColor: theme.colorScheme.primary,
          unselectedItemColor: theme.colorScheme.onSurfaceVariant,
          selectedLabelStyle:
              const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          unselectedLabelStyle:
              const TextStyle(fontSize: 11, fontWeight: FontWeight.w400),
        ),
      );
    });
  }
}
