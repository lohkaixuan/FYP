import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile/Component/BottomNavController.dart';
import 'package:mobile/Users/home.dart';

// ✅ 只保留一个 Controller 来源：如果你用本地的，就注释掉另外一个。


// ====== 如果你已经有这些页面，请删掉这些占位并改为你的真实页面 ======
class Transactions extends StatelessWidget {
  const Transactions({super.key});
  @override
  Widget build(BuildContext context) => const Center(child: Text('Transactions Page'));
}

class QR extends StatelessWidget {
  const QR({super.key});
  @override
  Widget build(BuildContext context) => const Center(child: Text('QR Page'));
}

class Report extends StatelessWidget {
  const Report({super.key});
  @override
  Widget build(BuildContext context) => const Center(child: Text('Reports Page'));
}

class Notifications extends StatelessWidget {
  const Notifications({super.key});
  @override
  Widget build(BuildContext context) => const Center(child: Text('Notifications Page'));
}
// ===========================================================

class BottomNavApp extends StatelessWidget {
  BottomNavApp({super.key});

  final BottomNavController navController = Get.find<BottomNavController>();
  // final AuthController _auth = Get.find<AuthController>();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Obx(() {
      // base pages —— ⚠️ pages 与 navItems 必须数量一致、顺序一致
      final pages = <Widget>[
        HomeScreen(),
        const Transactions(),
        const QR(),
        const Report(),
        const Notifications(),
      ];

      final navItems = <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(Icons.home, color: theme.iconTheme.color),
          label: "Home",
        ),
        BottomNavigationBarItem(
          // ❌ Icons.transactions 不存在，换成合法图标
          icon: Icon(Icons.receipt_long, color: theme.iconTheme.color),
          label: "Transactions",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.qr_code, color: theme.iconTheme.color),
          label: "QR",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.assessment, color: theme.iconTheme.color),
          label: "Reports",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.notifications, color: theme.iconTheme.color),
          label: "Notifications",
        ),
      ];

      // 小防呆：避免 index 越界
      final safeIndex = navController.selectedIndex.value.clamp(0, pages.length - 1);

      return Scaffold(
        body: pages[safeIndex],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: safeIndex,
          onTap: navController.changeIndex,
          items: navItems,
          backgroundColor: theme.bottomNavigationBarTheme.backgroundColor,
          selectedItemColor: theme.bottomNavigationBarTheme.selectedItemColor,
          unselectedItemColor: theme.bottomNavigationBarTheme.unselectedItemColor,
          selectedLabelStyle: theme.textTheme.labelLarge,
          unselectedLabelStyle: theme.textTheme.labelLarge?.copyWith(
            color: theme.bottomNavigationBarTheme.unselectedItemColor,
          ),
          type: BottomNavigationBarType.fixed,
        ),
      );
    });
  }
}
