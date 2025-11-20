import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:mobile/Account/Account.dart';
import 'package:mobile/Budget/create_budget.dart';
import 'package:mobile/Component/SplashScreen.dart';
import 'package:mobile/Auth/login.dart'; // 你已有
import 'package:mobile/Auth/register.dart'; // 你已有
import 'package:mobile/Component/BottomNav.dart';
import 'package:mobile/QR/QRpage.dart';
import 'package:mobile/Component/chart_details.dart';
import 'package:mobile/Transaction/Transactionpage.dart';
import 'package:mobile/Transaction/transaction_details.dart';
import 'package:mobile/Transfer/transfer.dart'; // 你的导航壳(Home 在第1个Tab)
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:mobile/Component/SplashScreen.dart';
import 'package:mobile/Auth/login.dart'; // 你已有
import 'package:mobile/Auth/register.dart'; // 你已有
import 'package:mobile/Component/BottomNav.dart'; // 你的导航壳(Home 在第1个Tab)
import 'package:mobile/Admin/adminDashboard.dart';
import 'package:mobile/Admin/manageUser.dart';
import 'package:mobile/Admin/manageMerchant.dart';
import 'package:mobile/Admin/manageAPI.dart';


class AppPages {
  static const INITIAL = '/login';

  static final routes = <GetPage>[
    GetPage(name: '/splash', page: () => const SplashScreen()),
    GetPage(name: '/login', page: () => const Login()),
    GetPage(name: '/signup', page: () => const Register()),
    GetPage(
      name: '/home',
      page: () => const BottomNavApp(),
      children: [
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
    ), // 登录后进入这里
    GetPage(name: '/reload', page: () => TransferScreen(mode: 'reload',)),
    GetPage(name: '/pay', page: () => const QR()),
    GetPage(name: '/transfer', page: () => TransferScreen(mode: 'transfer',)),
    GetPage(
        name: '/transactionDetails', page: () => const TransactionDetails()),
    GetPage(name: '/account', page: () => const Account()),
    
    GetPage(
        name: '/debit-credit-details',
        page: () =>
            const Placeholder()), // TODO: Place the true debit and credit details page here.
    GetPage(
        name: '/spendingDetails',
        page: () =>
            const Placeholder()), // TODO: Place the true spending details page here.
    GetPage(name: '/adminHome', page: () => const AdminDashboardWidget()),
    GetPage(name: '/userManagement', page: () => const ManageUserWidget()),
    GetPage(
        name: '/merchantManagement', page: () => const ManageMercahntWidget()),
    GetPage(name: '/apiManagement', page: () => const ManageAPIWidget()),
  ];
}
