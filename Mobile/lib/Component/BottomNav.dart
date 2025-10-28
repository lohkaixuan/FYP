import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile/Account/Account.dart';
import 'package:mobile/Component/SecurityCode.dart';
import 'package:mobile/Controller/BottomNavController.dart';
import 'package:mobile/Home/home.dart';
import 'package:mobile/Transaction/Transactionpage.dart';
import 'package:mobile/QR/QRpage.dart';
import 'package:mobile/Reports/financial_report.dart';
import 'package:mobile/Transfer/transfer.dart';

class BottomNavApp extends StatelessWidget {
  const BottomNavApp({super.key});

  @override
  Widget build(BuildContext context) {
    final navController = Get.find<BottomNavController>();

    // Local pages & items (stable, independent of controller shape)
    final pages = <Widget>[
      const HomeScreen(),
      const Transactions(),
      const QR(),
      const TransferScreen(),
      const Account(),
    ];

    final navItems = <BottomNavigationBarItem>[
      const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
      const BottomNavigationBarItem(
          icon: Icon(Icons.receipt_long), label: 'Transactions'),
      const BottomNavigationBarItem(icon: Icon(Icons.qr_code), label: 'QR'),
      const BottomNavigationBarItem(
          icon: Icon(Icons.assessment), label: 'Reports'),
      const BottomNavigationBarItem(
          icon: Icon(Icons.notifications), label: 'Notifications'),
    ];

    return Obx(() {
      final theme = Theme.of(context);

      // Adapt to either selectedIndex or index on your controller
      final dyn = navController as dynamic;
      final int idx =
          (dyn.selectedIndex?.value as int?) ?? (dyn.index?.value as int?) ?? 0;
      final safeIndex = idx.clamp(0, pages.length - 1);

      return Scaffold(
        // Page content
        body: pages[safeIndex],

        // Bottom bar themed by AppTheme (light/dark)
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
            backgroundColor: theme.bottomNavigationBarTheme.backgroundColor ??
                theme.colorScheme.surface,
            currentIndex: safeIndex,
            onTap: (i) {
              // route to controller method
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
            items: navItems,

            // Colors & text styles from AppTheme via ThemeData
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
