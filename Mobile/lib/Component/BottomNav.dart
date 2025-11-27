import 'package:flutter/material.dart';
import 'package:get/get.dart';

// 控制器
import 'package:mobile/Controller/BottomNavController.dart';
import 'package:mobile/Controller/RoleController.dart';

// ===== User / Merchant 页面 =====
import 'package:mobile/Home/home.dart';
import 'package:mobile/Transaction/Transactionpage.dart';
import 'package:mobile/QR/QRpage.dart';
import 'package:mobile/Reports/financial_report.dart';
import 'package:mobile/Account/Account.dart';

// ===== Admin 页面 =====
import 'package:mobile/Admin/adminDashboard.dart';
import 'package:mobile/Admin/manageAPI.dart';
import 'package:mobile/Admin/manageUser.dart';
import 'package:mobile/Admin/manageThridParty.dart';
import 'package:mobile/Admin/registerThridParty.dart';
import 'package:mobile/Admin/manageMerchant.dart'; // 这个可以用 Get.to 打开

class BottomNavApp extends StatelessWidget {
  const BottomNavApp({super.key});

  @override
  Widget build(BuildContext context) {
    final navController = Get.find<BottomNavController>();
    final roleController = Get.find<RoleController>();

    return Obx(() {
      final theme = Theme.of(context);
      final String role = roleController.activeRole.value; // 'admin' / 'user' / 'merchant'
      final bool isAdmin = role == 'admin';

      // ---------- 根据角色准备 pages / nav items ----------
      late final List<Widget> pages;
      late final List<BottomNavigationBarItem> navItems;

      if (isAdmin) {
        // 🧑‍💼 ADMIN 底部导航
        pages = const [
          AdminDashboardWidget(),
          ManageAPIWidget(),
          ManageUserWidget(),
          RegisterProviderWidget(),
          ManageProviderWidget(),
        ];

        navItems = const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.api), label: 'Manage API'),
          BottomNavigationBarItem(icon: Icon(Icons.group), label: 'Users'),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_add),
            label: 'Register 3rd',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.manage_accounts),
            label: 'Manage 3rd',
          ),
        ];
      } else {
        // 👤 USER / MERCHANT 共用底部导航
        pages = const [
          HomeScreen(),
          Transactions(),
          QR(),
          FinancialReport(),
          Account(),
        ];

        navItems = const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Transactions',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.qr_code), label: 'QR'),
          BottomNavigationBarItem(
            icon: Icon(Icons.assessment),
            label: 'Reports',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle_outlined),
            label: 'Account',
          ),
        ];
      }

      // ---------- 从 BottomNavController 读当前 index ----------
      final dyn = navController as dynamic;
      final int idx =
          (dyn.selectedIndex?.value as int?) ?? (dyn.index?.value as int?) ?? 0;
      final int safeIndex = idx.clamp(0, pages.length - 1);

      // ---------- UI ----------
      return Scaffold(
        // 直接根据 index 切 page（没有 nested Navigator）
        body: pages[safeIndex],

        // Bottom bar 用 AppTheme 配色
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: theme.bottomNavigationBarTheme.backgroundColor ??
                theme.colorScheme.surface,
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 6,
                offset: Offset(0, -1),
              ),
            ],
          ),
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            backgroundColor:
                theme.bottomNavigationBarTheme.backgroundColor ??
                    theme.colorScheme.surface,
            currentIndex: safeIndex,
            items: navItems,
            onTap: (i) {
              // 只更新 controller，不再走 Navigator
              if (dyn.changeIndex != null) {
                dyn.changeIndex(i);
              } else if (dyn.setIndex != null) {
                dyn.setIndex(i);
              } else if (dyn.selectedIndex != null) {
                dyn.selectedIndex.value = i;
              } else if (dyn.index != null) {
                dyn.index.value = i;
              }
            },
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
