import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile/Component/BottomNavController.dart';
import 'package:mobile/Home/home.dart';
import 'package:mobile/Component/AppTheme.dart';

// Placeholder pages — replace these with your actual pages later
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = AppTheme.kBlue;
    final background = AppTheme.kWhite;

    return Obx(() {
      final pages = <Widget>[
        const HomeScreen(),
        const Transactions(),
        const QR(),
        const Report(),
        const Notifications(),
      ];

      final navItems = <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: const Icon(Icons.home),
          label: "Home",
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.receipt_long),
          label: "Transactions",
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.qr_code),
          label: "QR",
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.assessment),
          label: "Reports",
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.notifications),
          label: "Notifications",
        ),
      ];

      final safeIndex = navController.selectedIndex.value.clamp(0, pages.length - 1);

      return Scaffold(
        backgroundColor: background,
        body: pages[safeIndex],
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            color: AppTheme.kWhite,
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 6,
                offset: Offset(0, -1),
              ),
            ],
          ),
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            backgroundColor: background,
            currentIndex: safeIndex,
            onTap: navController.changeIndex,
            items: navItems,

            // 🎨 Apply AppTheme colors & text styles
            selectedItemColor: primary,
            unselectedItemColor: Colors.grey,
            selectedLabelStyle: AppTheme.bottomNavLabelStyle(primary),
            unselectedLabelStyle: AppTheme.bottomNavLabelStyle(Colors.grey),

            showUnselectedLabels: true,
            elevation: 0,
          ),
        ),
      );
    });
  }
}
