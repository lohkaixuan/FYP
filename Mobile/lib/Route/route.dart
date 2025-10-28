import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:mobile/Component/SplashScreen.dart';
import 'package:mobile/Auth/login.dart'; // 你已有
import 'package:mobile/Auth/register.dart'; // 你已有
import 'package:mobile/Component/BottomNav.dart';
import 'package:mobile/Reports/debit_credit.dart';
import 'package:mobile/Transaction/transaction_details.dart';
import 'package:mobile/Transfer/transfer.dart'; // 你的导航壳(Home 在第1个Tab)

class AppPages {
  static const INITIAL = '/home';

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
          page: () => const DebitCreditScreen(),
        ), // TODO: Place the true debit and credit details page here.
        GetPage(
          name: '/spendingDetails',
          page: () => const Placeholder(),
        ), // TODO: Place the true spending details page here.
      ],
    ), // 登录后进入这里
    GetPage(name: '/transfer', page: () => const TransferScreen()),
    GetPage(name: '/transactionDetails', page: () => TransactionDetails()),
  ];
}
