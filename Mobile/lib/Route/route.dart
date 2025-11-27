import 'package:get/get.dart';
import 'package:flutter/material.dart';

import 'package:mobile/Account/Account.dart';
import 'package:mobile/Budget/create_budget.dart';
import 'package:mobile/Component/SplashScreen.dart';
import 'package:mobile/Auth/login.dart';
import 'package:mobile/Auth/register.dart';
import 'package:mobile/Component/BottomNav.dart';
import 'package:mobile/QR/QRpage.dart';
import 'package:mobile/Component/chart_details.dart';
import 'package:mobile/Transaction/Transactionpage.dart';
import 'package:mobile/Transaction/transaction_details.dart';
import 'package:mobile/Transfer/transfer.dart';

class AppPages {
  static const INITIAL = '/login';

  static final routes = <GetPage>[
    // 🔹 Splash & Auth
    GetPage(name: '/splash', page: () => const SplashScreen()),
    GetPage(name: '/login', page: () => const Login()),
    GetPage(name: '/signup', page: () => const Register()),

    // 🔹 Main app shell (role-based BottomNavApp: user / merchant / admin 都走这里)
    GetPage(
      name: '/home',
      page: () => const BottomNavApp(),
      children: [
        // 这些是从 Home 图表点进去的子页面
        GetPage(
          name: '/debit-credit-details',
          page: () => ChartDetails(
            title: "Debit and Credit Details",
            onTapItem: (item) {
              Get.to(
                () => const Transactions(),
                arguments: {"filter": item['title'].toLowerCase()},
              );
            },
          ),
        ),
        GetPage(
          name: '/spendingDetails',
          page: () => ChartDetails(
            title: "Spending Details",
            onTapItem: (item) {
              Get.to(
                () => const Transactions(),
                arguments: {"filter": item['title'].toLowerCase()},
              );
            },
          ),
        ),
        GetPage(
          name: '/budget-details',
          page: () => ChartDetails(
            title: "Budget Details",
            iconButton: IconButton(
              onPressed: () => Get.to(const CreateBudgetScreen()),
              icon: const Icon(Icons.add),
            ),
          ),
        ),
      ],
    ),

    // 🔹 直接打开的功能页（不在 bottom nav 里的深层页面）
    GetPage(
      name: '/reload',
      page: () => TransferScreen(mode: 'reload'),
    ),
    GetPage(
      name: '/pay',
      page: () => const QR(),
    ),
    GetPage(
      name: '/transfer',
      page: () => TransferScreen(mode: 'transfer'),
    ),
    GetPage(
      name: '/transactionDetails',
      page: () => const TransactionDetails(),
    ),
    GetPage(
      name: '/account',
      page: () => const Account(),
    ),

    // 🔹 给兼容用的 /admin 入口（可选）
    // 如果你项目里有地方写 Get.offAllNamed('/admin')，
    // 这里让它同样走 BottomNavApp，由 RoleController 决定显示 admin 导航。
    GetPage(
      name: '/admin',
      page: () => const BottomNavApp(),
    ),
  ];
}
